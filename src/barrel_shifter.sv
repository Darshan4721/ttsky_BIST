typedef enum logic { 
    right_shift ,
    left_shift
} shift_op_e;

module barrel_shifter (
    input  logic [7:0] in_bits,
    input  logic [2:0] shift_amount ,
    input  logic shift_op_code,
    output logic [7:0] out_bits
);
    logic [7:0] stage1_out,stage2_out;

    // stage 1
    assign stage1_out = shift_amount[2] ? 
        (shift_op_code == left_shift ? (in_bits << 4) : (in_bits >> 4))
        : in_bits;

    // stage 2
    assign stage2_out = shift_amount[1] ? 
        (shift_op_code == left_shift ? (stage1_out << 2) : (stage1_out >> 2))
        : stage1_out;

    // stage 3 
    assign out_bits = shift_amount[0] ? 
        (shift_op_code == left_shift ? (stage2_out << 1) : (stage2_out >> 1))
        : stage2_out;




endmodule


