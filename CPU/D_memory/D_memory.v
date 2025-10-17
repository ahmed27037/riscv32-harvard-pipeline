`timescale 1ns / 1ps
module Data_Memory (
    input  wire        i_clk,
    input  wire        we,
    input  wire [31:0] i_data,
    input  wire [31:0] i_addr,
    output wire [31:0] o_data
);

    reg [31:0] ram [0:31];
    integer i;

    // Initialize memory to 0
    initial begin
        for (i = 0; i < 32; i = i + 1)
            ram[i] = 32'b0;
    end

    // Write on rising clock edge when enabled
    always @(posedge i_clk) begin
        if (we)
            ram[i_addr[4:0]] <= i_data;
    end

    // Asynchronous read
    assign o_data = ram[i_addr[4:0]];

endmodule
