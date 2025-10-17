`timescale 1ns/1ps

module processor_core_tb;
    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [31:0] INSTR_NOP         = 32'h0000_0013; // addi x0,x0,0
    localparam logic [31:0] INSTR_ADDI_X2_4   = 32'h0040_0113;
    localparam logic [31:0] INSTR_ADDI_X3_5   = 32'h0050_0193;
    localparam logic [31:0] INSTR_ADD_X1_X2_X3= 32'h0031_00b3;
    localparam logic [31:0] INSTR_ADD_X0_X1_X1= 32'h0010_8033;
    localparam logic [31:0] INSTR_ADDI_X4_0   = 32'h0000_0213;
    localparam logic [31:0] INSTR_BEQ_SKIP    = 32'h0000_0463; // beq x0,x0,+8
    localparam logic [31:0] INSTR_ADDI_X5_1   = 32'h0010_0293; // should be skipped
    localparam logic [31:0] INSTR_ADDI_X6_6   = 32'h0060_0313;
    localparam logic [31:0] INSTR_JAL_LOOP    = 32'h0000_006f; // jal x0,0

    logic clk = 0;
    logic resetn = 0;

    wire [31:0] pc;
    wire [31:0] addr_out;
    wire [31:0] dmem_out;
    wire        wmem;

    logic [31:0] instr_rom [0:15];
    logic [31:0] instr_bus;

    processor dut (
        .i_clk   (clk),
        .i_resetn(resetn),
        .i_instr (instr_bus),
        .i_dmem  (32'b0),
        .o_pc    (pc),
        .o_addr  (addr_out),
        .o_dmem  (dmem_out),
        .o_wmem  (wmem)
    );

    assign instr_bus = instr_rom[pc[6:2]];

    always #5 clk = ~clk;

    initial begin
        foreach (instr_rom[idx])
            instr_rom[idx] = INSTR_NOP;

        instr_rom[0] = INSTR_ADDI_X2_4;
        instr_rom[1] = INSTR_ADDI_X3_5;
        instr_rom[2] = INSTR_ADD_X1_X2_X3;
        instr_rom[3] = INSTR_ADD_X0_X1_X1;
        instr_rom[4] = INSTR_ADDI_X4_0;
        instr_rom[5] = INSTR_BEQ_SKIP;
        instr_rom[6] = INSTR_ADDI_X5_1; // should be skipped
        instr_rom[7] = INSTR_ADDI_X6_6;
        instr_rom[8] = INSTR_JAL_LOOP;  // hold the core
    end

    initial begin
        repeat (2) @(posedge clk);
        resetn = 1;

        repeat (25) @(posedge clk);

        expect_reg(2, 32'd4);
        expect_reg(3, 32'd5);
        expect_reg(1, 32'd9);
        expect_reg(5, 32'd0); // instruction skipped by branch
        expect_reg(6, 32'd6);

        if (!observed_forward_check) begin
            $fatal(1, "Forwarding check never triggered.");
        end

        $display("processor_core_tb PASS");
        $finish;
    end

    bit observed_forward_check = 0;
    always @(posedge clk) begin
        if (resetn && dut.id_instr == INSTR_ADD_X0_X1_X1) begin
            observed_forward_check = 1;
            if (dut.id_regdata1 !== 32'd9 || dut.id_regdata2 !== 32'd9) begin
                $fatal(1, "Forwarding mismatch: id_regdata1=%0d id_regdata2=%0d, expected 9.",
                       dut.id_regdata1, dut.id_regdata2);
            end
        end
    end

    task automatic expect_reg(input int idx, input logic [31:0] expected);
        logic [31:0] value = dut.register_file.reg_file[idx];
        if (value !== expected) begin
            $fatal(1, "x%0d mismatch: got 0x%08h expected 0x%08h", idx, value, expected);
        end
    endtask
endmodule
