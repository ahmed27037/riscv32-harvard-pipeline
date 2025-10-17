`timescale 1ns/1ps

module cpu_test;
    timeunit 1ns;
    timeprecision 1ps;

    localparam int unsigned MAX_CYCLES = 400;

    // Expected register values after program completes
    localparam logic [31:0] EXP_X1   = 32'h0000_0009;
    localparam logic [31:0] EXP_X2   = 32'h0000_0004;
    localparam logic [31:0] EXP_X3   = 32'h0000_000d;
    localparam logic [31:0] EXP_X5   = 32'h0000_000d;
    localparam logic [31:0] EXP_X6   = 32'h0000_001a;
    localparam logic [31:0] EXP_X7   = 32'h0000_001e;
    localparam logic [31:0] EXP_X8   = 32'h0000_001e;
    localparam logic [31:0] EXP_X9   = 32'h0000_0001;
    localparam logic [31:0] EXP_X10  = 32'h0000_0015;
    localparam logic [31:0] EXP_X11  = 32'h0000_000c;
    localparam logic [31:0] EXP_X12  = 32'h0000_001e;
    localparam logic [31:0] EXP_X13  = 32'h0000_0001;
    localparam logic [31:0] EXP_X14  = 32'hffff_fff6;

    // Expected data memory contents (actual byte addresses)
    localparam int MEM_ADDR_0 = 0;
    localparam int MEM_ADDR_1 = 4;
    localparam int MEM_ADDR_2 = 8;
    localparam int MEM_ADDR_3 = 12;
    localparam int MEM_ADDR_4 = 16;
    localparam int MEM_ADDR_5 = 20;
    localparam int MEM_ADDR_6 = 24;
    localparam int MEM_ADDR_7 = 28;

    localparam int EXP_MEM_0 = 12;
    localparam int EXP_MEM_1 = 30;
    localparam int EXP_MEM_2 = 13;
    localparam int EXP_MEM_3 = 26;
    localparam int EXP_MEM_4 = 30;
    localparam int EXP_MEM_5 = 30;
    localparam int EXP_MEM_6 = 1;
    localparam int EXP_MEM_7 = 21;

    localparam logic [31:0] FINISH_PC = 32'h0000_0054;
    localparam int unsigned DONE_REG_IDX  = 13;
    localparam int unsigned DONE_MEM_ADDR = 28;
    localparam logic [31:0] EXP_DONE_MEM = EXP_MEM_7;

    logic clk = 0;
    logic resetn = 0;

    wire [31:0] instr;
    wire [31:0] pc;
    wire [31:0] addr_out;
    wire [31:0] mem_out;

    cpu dut (
        .i_clk   (clk),
        .i_resetn(resetn),
        .instr   (instr),
        .pc      (pc),
        .addr_out(addr_out),
        .mem_out (mem_out)
    );

    always #5 clk = ~clk; // 100 MHz

    initial begin
        int unsigned cycles_to_wait;

        $dumpfile("cpu_test.vcd");
        $dumpvars(0, cpu_test);

        cycles_to_wait = MAX_CYCLES;
        if ($value$plusargs("MAX_CYCLES=%d", cycles_to_wait))
            $display("cpu_test: overriding MAX_CYCLES to %0d", cycles_to_wait);

        apply_reset();
        wait_for_program(cycles_to_wait);
        check_results();

        $display("PASS: register and memory image match expected signature");
        $display("Registers of interest:");
        $display("x1  = 0x%08h", dut.core1.register_file.reg_file[1]);
        $display("x2  = 0x%08h", dut.core1.register_file.reg_file[2]);
        $display("x3  = 0x%08h", dut.core1.register_file.reg_file[3]);
        $display("x5  = 0x%08h", dut.core1.register_file.reg_file[5]);
        $display("x6  = 0x%08h", dut.core1.register_file.reg_file[6]);
        $display("x7  = 0x%08h", dut.core1.register_file.reg_file[7]);
        $display("x8  = 0x%08h", dut.core1.register_file.reg_file[8]);
        $display("x9  = 0x%08h", dut.core1.register_file.reg_file[9]);
        $display("x10 = 0x%08h", dut.core1.register_file.reg_file[10]);
        $display("x11 = 0x%08h", dut.core1.register_file.reg_file[11]);
        $display("x12 = 0x%08h", dut.core1.register_file.reg_file[12]);
        $display("x13 = 0x%08h", dut.core1.register_file.reg_file[13]);
        $display("x14 = 0x%08h", dut.core1.register_file.reg_file[14]);

        $display("Data memory sample:");
        $display("mem[%0d] = %0d", MEM_ADDR_0, dut.dmem.ram[MEM_ADDR_0]);
        $display("mem[%0d] = %0d", MEM_ADDR_1, dut.dmem.ram[MEM_ADDR_1]);
        $display("mem[%0d] = %0d", MEM_ADDR_2, dut.dmem.ram[MEM_ADDR_2]);
        $display("mem[%0d] = %0d", MEM_ADDR_3, dut.dmem.ram[MEM_ADDR_3]);
        $display("mem[%0d] = %0d", MEM_ADDR_4, dut.dmem.ram[MEM_ADDR_4]);
        $display("mem[%0d] = %0d", MEM_ADDR_5, dut.dmem.ram[MEM_ADDR_5]);
        $display("mem[%0d] = %0d", MEM_ADDR_6, dut.dmem.ram[MEM_ADDR_6]);
        $display("mem[%0d] = %0d", MEM_ADDR_7, dut.dmem.ram[MEM_ADDR_7]);
        $finish;
    end

    task automatic apply_reset;
        resetn = 0;
        repeat (4) @(posedge clk);
        resetn = 1;
        @(posedge clk);
    endtask

    task automatic wait_for_program(input int unsigned max_cycles);
        bit done = 0;
        begin : wait_loop
            repeat (max_cycles) begin
                @(posedge clk);
                if (resetn &&
                    dut.pc == FINISH_PC &&
                    dut.core1.register_file.reg_file[DONE_REG_IDX] == EXP_X13 &&
                    dut.dmem.ram[DONE_MEM_ADDR] == EXP_DONE_MEM) begin
                    done = 1;
                    disable wait_loop;
                end
            end
        end
        if (!done) begin
            $display("DEBUG: Timeout: pc=0x%08h x13=0x%08h mem[28]=0x%08h",
                     dut.pc,
                     dut.core1.register_file.reg_file[DONE_REG_IDX],
                     dut.dmem.ram[DONE_MEM_ADDR]);
            $fatal(1, "Timeout waiting for completion.");
        end
    endtask

    task automatic check_results;
        expect_reg(1,  EXP_X1);
        expect_reg(2,  EXP_X2);
        expect_reg(3,  EXP_X3);
        expect_reg(5,  EXP_X5);
        expect_reg(6,  EXP_X6);
        expect_reg(7,  EXP_X7);
        expect_reg(8,  EXP_X8);
        expect_reg(9,  EXP_X9);
        expect_reg(10, EXP_X10);
        expect_reg(11, EXP_X11);
        expect_reg(12, EXP_X12);
        expect_reg(13, EXP_X13);
        expect_reg(14, EXP_X14);

        expect_mem(MEM_ADDR_0, EXP_MEM_0);
        expect_mem(MEM_ADDR_1, EXP_MEM_1);
        expect_mem(MEM_ADDR_2, EXP_MEM_2);
        expect_mem(MEM_ADDR_3, EXP_MEM_3);
        expect_mem(MEM_ADDR_4, EXP_MEM_4);
        expect_mem(MEM_ADDR_5, EXP_MEM_5);
        expect_mem(MEM_ADDR_6, EXP_MEM_6);
        expect_mem(MEM_ADDR_7, EXP_MEM_7);
    endtask

    task automatic expect_reg(input int idx, input logic [31:0] expected);
        logic [31:0] value = dut.core1.register_file.reg_file[idx];
        if (value !== expected)
            $fatal(1, "x%0d mismatch: got 0x%08h expected 0x%08h", idx, value, expected);
    endtask

    task automatic expect_mem(input int addr, input logic [31:0] expected);
        logic [31:0] value = dut.dmem.ram[addr];
        if (value !== expected)
            $fatal(1, "mem[%0d] mismatch: got 0x%08h expected 0x%08h", addr, value, expected);
    endtask
endmodule
