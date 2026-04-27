

typedef enum logic [2:0] { 
    add,
    sub,
    g_and,
    g_or,
    exor,
    exnor,
    shift_L,
    shift_R
} alu_e;

module alu (
    input logic [7:0] a,b,
    input alu_e  opcode,
    input logic [2:0] shift_amount,
    input logic clk,rst,enable,cin,
    output logic [7:0] result ,
    output logic zero , carry , overflow , negative
    );

    typedef struct packed {
        logic [7:0] sum;
        logic carry;
    }adder_result_t;

    adder_result_t adder_result;

    logic b_actual_bit;
    assign b_actual_bit = opcode == sub ? (~b[7]) : b[7];

    kogge_stone_adder alu_adder (
       .a(a),
       .b((opcode == sub) ? (~b) : b),
       .cin((opcode == sub) ? 1'b1 : 1'b0),
       .sum(adder_result.sum),
       .cout(adder_result.carry)
    );

    logic [7:0] shifter_result;

    barrel_shifter alu_barrel_shifter (
        .in_bits(a),
        .shift_amount(shift_amount),
        .shift_op_code((opcode == shift_L) ? left_shift : right_shift),
        .out_bits(shifter_result)
    );

    always @ (posedge clk or negedge rst) begin
        if(!rst) begin
            result <= 0;
            zero <= 0;
            carry <= 0;
            overflow <= 0;
            negative <= 0;
        end
        else if (enable) begin
            case (opcode)
                add,sub: begin
                    result <= adder_result.sum;
                    carry <= adder_result.carry;
                    negative <= (adder_result.sum[7]? 1'b1 : 1'b0);
                    zero <= (adder_result.sum == 0 ? 1'b1 : 1'b0);
                    overflow <= (((a[7] == b_actual_bit) & (a[7] != adder_result.sum[7])) ? 1'b1 : 1'b0);
                end 
                g_and: begin
                    result <= a & b;
                    carry <= 0;
                    negative <= a[7] & b[7];
                    zero <= (((a&b) == 0) ? 1'b1 : 1'b0 );
                    overflow <= 0; 

                end
                g_or: begin
                    result <= a | b;
                    carry <= 0;
                    negative <= a[7] | b[7];
                    zero <= (((a|b) == 0) ? 1'b1 : 1'b0 );
                    overflow <= 0;
                end
                exor: begin
                    result <= a ^ b;
                    carry <= 0;
                    negative <= a[7] ^ b[7];
                    zero <= (((a^b) == 0) ? 1'b1 : 1'b0 );
                    overflow <= 0;
                end
                exnor: begin
                    result <= a ~^ b;
                    carry <= 0;
                    negative <= a[7] ~^ b[7];
                    zero <= ((a^b) == 8'hFF) ? 1'b1 : 1'b0;
                    overflow <= 0;
                end

                shift_L,shift_R: begin
                    result <= shifter_result;
                    carry <= 0;
                    negative <= shifter_result [7] ? 1'b1 : 1'b0;
                    zero <=  (shifter_result == 0) ? 1'b1 : 1'b0;
                    overflow <= 0;
                end
                default: begin
                    result <= 0;
                    zero <= 0;
                    carry <= 0;
                    overflow <= 0;
                    negative <= 0;
                end 
            endcase
            
        end
    end
    
endmodule


