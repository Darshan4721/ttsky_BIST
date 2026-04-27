//`include "alu.sv"
//`include "lsfr_24_bit.sv"
//`include "misr.sv"

//i think there are 2 leds that will indicate the result one for the pass and other for the fail , 
//if the pass glow [ high ] it is passed   
// or if its off it not passed 
// i am going with this apporach is coz of clear identification       

typedef struct packed { 
    logic active;  
    logic running;  
    logic done;     
    logic pass;     
    logic failed;   
} bist_status_t;

typedef enum logic [2:0] { 
    idle,
    reset,
    run,
    lsfr_done_alu_wait,
    compare,
    done
} state_e;

typedef struct packed {
    logic one;
    logic two;
} misr_enable_t;

module bist_controller_top (
    input logic clk,rst,enable,bist_start,
    output bist_status_t overall_result
);

    logic internal_bist_rst;
    logic [7:0] cycle_count;
    state_e state;
    logic [23:0] lsfr_vlaue;

    parameter logic [11:0] GOLDEN_1 = 12'hAAA; // answer key for MISR 1
    parameter logic [11:0] GOLDEN_2 = 12'hBBB; // answer key for MISR 1


    // lsfr module 
    logic lsfr_enable;
    logic [23:0] lsfr_out;

    lsfr_24_bit_design lsfr_one (
        .clk(clk),
        .enable(lsfr_enable),
        .rst(internal_bist_rst),
        .data_out(lsfr_out)
    );

    // misr modules     

    misr_enable_t misr_enable;

    // 1st misr 
    logic [8:0] misr_one_data_in;
    logic [11:0] misr_one_data_out;


    misr misr_one (
        .clk(clk),
        .rst(internal_bist_rst),
        .enable(misr_enable.one),
        .alu_data_in(misr_one_data_in),
        .signature_out(misr_one_data_out)
    );

    // 2nd misr
    logic [8:0] misr_two_data_in;
    logic [11:0] misr_two_data_out;


    misr misr_two (
        .clk(clk),
        .rst(internal_bist_rst),
        .enable(misr_enable.two),
        .alu_data_in(misr_two_data_in),
        .signature_out(misr_two_data_out)
    );


    // alu module 

    logic [7:0] a,b;
    alu_e alu_opcode;
    logic [2:0] alu_shift_amount;
    logic cin, carry, overflow,negative,zero,alu_enable;
    logic [7:0] result;

    alu alu_bist(
        .a(a),
        .b(b),
        .cin(cin),
        .opcode(alu_opcode),         
        .shift_amount(alu_shift_amount),
        .clk(clk),
        .rst(rst),
        .enable(alu_enable),
        .result(result),
        .zero(zero),
        .negative(negative),
        .overflow(overflow),
        .carry(carry)
    );

    //soldered wires

    // lsfr to alu 

    assign a = lsfr_out[7:0];
    assign b = lsfr_out [15:8];
    assign alu_opcode = alu_e'(lsfr_out [18:16]);
    assign cin = lsfr_out [19:19];
    assign alu_shift_amount = lsfr_out [23:20];

    // alu to misr

    assign misr_one_data_in = {1'b0,result};
    assign misr_two_data_in = {5'b00000,zero,carry,negative,overflow};

    // ==========================================
    // 6. THE 3-BLOCK BIST CONTROLLER FSM
    // ==========================================

    // BLOCK 1: State Memory & Counters (Sequential)
    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            state <= idle;
            cycle_count <= 0;
        end else if (enable) begin
            case (state)
                idle: if (bist_start) state <= reset;
                reset: state <= run;
                run: begin
                    cycle_count <= cycle_count + 1;
                    if (cycle_count == 255) state <= lsfr_done_alu_wait;
                end
                lsfr_done_alu_wait: state <= compare;
                compare: state <= done;
                done: if (!bist_start) begin 
                    state <= idle;
                    cycle_count <= 0;
                end
                default: state <= idle;
            endcase
        end
    end

    // BLOCK 2: Datapath Controls (Combinational = Zero Lag)
    always_comb begin
        // Defaults to prevent latches
        internal_bist_rst = 1; 
        lsfr_enable = 0; 
        alu_enable = 0; 
        misr_enable = '{1'b0,1'b0};
        
        case (state)
            reset: begin
                internal_bist_rst = 0; 
            end
            run: begin
                lsfr_enable = 1; 
                alu_enable = 1; 
                misr_enable = '{1'b1,1'b1};
            end
            lsfr_done_alu_wait: begin
                alu_enable = 1;  
                misr_enable = '{1'b1,1'b1};
            end
        endcase
    end

    // BLOCK 3: Status LEDs (Sequential to prevent flickering)
    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            overall_result <= 5'b00000;
        end else if (enable) begin
            case (state)
                idle: overall_result <= 5'b00000;
                reset: overall_result <= 5'b10000;
                run, lsfr_done_alu_wait: overall_result <= 5'b11000;
                compare: begin
                    if ((misr_one_data_out == GOLDEN_1) && (misr_two_data_out == GOLDEN_2))
                        overall_result <= 5'b10110;
                    else
                        overall_result <= 5'b10101;
                end
            endcase
            // Clear LEDs if switch turned off in done state
            if (state == done && !bist_start) 
                overall_result <= 5'b00000;
        end
    end

endmodule


