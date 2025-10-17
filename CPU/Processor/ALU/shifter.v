`timescale 1ns / 1ps


module shifter(
    input wire [31:0] data,
    input wire [4:0] sa,     // Control: shift amount (0-31)
    input wire right,        // Control: 1 = shift right, 0 = shift left
    input wire arith,        // Control: 1 = arithmetic shift, 0 = logical shift
    output wire [31:0] sh_result
);
    wire [31:0] left_shift, right_logical, right_arith;
    
    // Generate all shift types
    assign left_shift = data << sa;
    assign right_logical = data >> sa;
    assign right_arith = $signed(data) >>> sa;
    
    // Select based on control signals
    assign sh_result = right ? (arith ? right_arith : right_logical) : left_shift;

endmodule