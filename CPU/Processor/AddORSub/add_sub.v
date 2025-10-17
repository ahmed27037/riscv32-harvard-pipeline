`timescale 1ns / 1ps

module add_sub32(
    input wire [31:0] a, b,
    input wire sub,          // Control: 1 = subtract, 0 = add
    output wire [31:0] out
);
    wire [31:0] b_modified;
    wire carry_out;
    
    // Invert b if sub=1, otherwise pass b unchanged
    assign b_modified = sub ? ~b : b;
    
    // CLA performs addition; carry_in acts as +1 for two's complement
    cla_32bit cla_unit (
        .a(a),
        .b(b_modified),
        .c_in(sub),           // Control: carry_in = 1 when subtracting
        .sum(out),
        .c_out(carry_out)
    );

endmodule




