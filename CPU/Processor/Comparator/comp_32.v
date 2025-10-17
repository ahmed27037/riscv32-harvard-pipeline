`timescale 1ns / 1ps

module comparator(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire unsigned_op,
    output wire o_a_lt_b,
    output wire o_a_eq_b
);
    // Compare as unsigned or signed based on control signal
    assign o_a_lt_b = unsigned_op ? (a < b) : ($signed(a) < $signed(b));
    assign o_a_eq_b = (a == b);
endmodule
