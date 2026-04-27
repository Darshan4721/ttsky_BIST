
module misr(
    clk,rst,enable,alu_data_in,signature_out
);

    parameter width =    12;
    parameter seed  =    12'b0000_0000_0001;

    input                       clk,rst,enable;
    input	logic   [8:0]       alu_data_in;  // 9 bits input from ALU 
    output	logic   [width-1:0] signature_out; 

    logic  feedback;

    assign feedback = signature_out [11]^signature_out [6]^signature_out [3]^signature_out [2];

    always @ (posedge clk or negedge rst) begin
        if (!rst)  // reset is applied when the rst = 0 and executes when rst = 1
            signature_out <= seed;
        else begin
            if (enable) begin
                signature_out <= {
                    signature_out[10],  // msb to lsb 
                    signature_out[9],
                    signature_out[8],
                    alu_data_in[8] ^ signature_out[7],
                    alu_data_in[7] ^ signature_out[6],
                    alu_data_in[6] ^ signature_out[5],
                    alu_data_in[5] ^ signature_out[4],
                    alu_data_in[4] ^ signature_out[3],
                    alu_data_in[3] ^ signature_out[2],
                    alu_data_in[2] ^ signature_out[1],
                    alu_data_in[1] ^ signature_out[0],
                    alu_data_in[0] ^ feedback

                };
            end
        end
    end
endmodule

