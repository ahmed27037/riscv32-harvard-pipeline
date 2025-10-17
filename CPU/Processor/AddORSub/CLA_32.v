`timescale 1ns / 1ps

// ========== 4-BIT CLA ==========
module cla_4bit (
    input wire [3:0] i_a, i_b,
    input wire c_in,
    output wire [3:0] o_sum,
    output wire c_out
);
    wire [3:0] g, p;
    wire [3:0] c;
    
    // Generate and propagate terms
    assign g = i_a & i_b;
    assign p = i_a ^ i_b;
    
    // Carry lookahead logic
    assign c[0] = g[0] | (p[0] & c_in);
    assign c[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_in);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_in);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c_in);
    
    // Sum calculation
    assign o_sum = p ^ {c[2:0], c_in};
    assign c_out = c[3];

endmodule

// ========== 8-BIT CLA ==========
module cla_8bit (
    input wire [7:0] a, b,
    input wire c_in,
    output wire [7:0] sum,
    output wire c_out
);
    wire carry_mid;
    
    cla_4bit cla4_lo (
        .i_a(a[3:0]), .i_b(b[3:0]),
        .c_in(c_in),
        .o_sum(sum[3:0]),
        .c_out(carry_mid)
    );
    
    cla_4bit cla4_hi (
        .i_a(a[7:4]), .i_b(b[7:4]),
        .c_in(carry_mid),
        .o_sum(sum[7:4]),
        .c_out(c_out)
    );

endmodule

// ========== 16-BIT CLA ==========
module cla_16bit(
    input wire [15:0] a, b,
    input wire c_in,
    output wire [15:0] sum,
    output wire c_out
);
    wire carry_mid;
    
    cla_8bit cla8_lo (
        .a(a[7:0]), .b(b[7:0]),
        .c_in(c_in),
        .sum(sum[7:0]),
        .c_out(carry_mid)
    );
    
    cla_8bit cla8_hi (
        .a(a[15:8]), .b(b[15:8]),
        .c_in(carry_mid),
        .sum(sum[15:8]),
        .c_out(c_out)
    );

endmodule

// ========== 32-BIT CLA ==========
module cla_32bit (
    input wire [31:0] a, b,
    input wire c_in,
    output wire [31:0] sum,
    output wire c_out
);
    wire carry_mid;
    
    cla_16bit cla16_lo (
        .a(a[15:0]), .b(b[15:0]),
        .c_in(c_in),
        .sum(sum[15:0]),
        .c_out(carry_mid)
    );
    
    cla_16bit cla16_hi (
        .a(a[31:16]), .b(b[31:16]),
        .c_in(carry_mid),
        .sum(sum[31:16]),
        .c_out(c_out)
    );

endmodule