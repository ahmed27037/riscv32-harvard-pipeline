`timescale 1ns / 1ps

module alu_tb;

    reg  [31:0] a, b;
    reg  [5:0]  aluc;
    wire [31:0] result;

    integer pass_count = 0;
    integer fail_count = 0;

    alu dut (.a(a), .b(b), .aluc(aluc), .result(result));

    task test_case;
        input [31:0] test_a;
        input [31:0] test_b;
        input [5:0]  test_aluc;
        input [31:0] expected;
        input [255:0] desc;
        begin
            a = test_a;
            b = test_b;
            aluc = test_aluc;
            #1;
            if (result === expected) begin
                $display("[PASS] %0s", desc);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | a=0x%h, b=0x%h, aluc=6'b%b | Got=0x%h | Expected=0x%h",
                         desc, test_a, test_b, test_aluc, result, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, alu_tb);

        $display("===== ALU TESTBENCH =====\n");

        // -------------------------------------------------------
        // ADD / SUB
        // -------------------------------------------------------
        $display("--- ADD OPERATIONS ---");
        test_case(32'd10, 32'd5,   6'b000000, 32'd15, "ADD: 10 + 5 = 15");
        test_case(32'd100, 32'd200,6'b000000, 32'd300, "ADD: 100 + 200 = 300");
        test_case(32'hFFFFFFFF, 32'd1, 6'b000000, 32'd0, "ADD: 0xFFFFFFFF + 1 = 0 (overflow)");

        $display("\n--- SUB OPERATIONS ---");
        test_case(32'd20, 32'd5,   6'b001000, 32'd15, "SUB: 20 - 5 = 15");
        test_case(32'd100, 32'd50, 6'b001000, 32'd50, "SUB: 100 - 50 = 50");
        test_case(32'd5,  32'd20,  6'b001000, 32'hFFFFFFF1, "SUB: 5 - 20 = -15");

        // -------------------------------------------------------
        // LOGIC
        // -------------------------------------------------------
        $display("\n--- AND OPERATIONS ---");
        test_case(32'hFFFF0000, 32'h0000FFFF, 6'b000010, 32'h00000000, "AND");
        test_case(32'hFFFFFFFF, 32'hAAAAAAAA, 6'b000010, 32'hAAAAAAAA, "AND");
        test_case(32'h12345678, 32'h87654321, 6'b000010, 32'h02244220, "AND");

        $display("\n--- OR OPERATIONS ---");
        test_case(32'hFFFF0000, 32'h0000FFFF, 6'b001010, 32'hFFFFFFFF, "OR");
        test_case(32'h12340000, 32'h00005678, 6'b001010, 32'h12345678, "OR");

        $display("\n--- XOR OPERATIONS ---");
        test_case(32'hFFFFFFFF, 32'hFFFFFFFF, 6'b000100, 32'h00000000, "XOR");
        test_case(32'hAAAAAAAA, 32'h55555555, 6'b000100, 32'hFFFFFFFF, "XOR");

        $display("\n--- LUI OPERATIONS ---");
        test_case(32'h00000000, 32'h12345678, 6'b001100, 32'h12345678, "LUI");
        test_case(32'h00000000, 32'hFFFFFFFF, 6'b001100, 32'hFFFFFFFF, "LUI");

        // -------------------------------------------------------
        // SHIFTS
        // -------------------------------------------------------
        $display("\n--- SHIFT LEFT (SHL) ---");
        test_case(32'h00000001, 32'd4, 6'b000101, 32'h00000010, "SHL: 1<<4");

        $display("\n--- SHIFT RIGHT LOGICAL (SRL) ---");
        test_case(32'h80000000, 32'd1, 6'b001101, 32'h40000000, "SRL");
        test_case(32'hFFFFFFFF, 32'd8, 6'b001101, 32'h00FFFFFF, "SRL");

        $display("\n--- SHIFT RIGHT ARITHMETIC (SRA) ---");
        test_case(32'h80000000, 32'd1, 6'b011101, 32'hC0000000, "SRA");
        test_case(32'hFFFFFFFF, 32'd8, 6'b011101, 32'hFFFFFFFF, "SRA");

        // -------------------------------------------------------
        // EDGE CASES
        // -------------------------------------------------------
        $display("\n--- EDGE CASES ---");
        test_case(32'd0, 32'd0, 6'b000000, 32'd0, "ADD: 0+0=0");
        test_case(32'hFFFFFFFF, 32'hFFFFFFFF, 6'b001000, 32'd0, "SUB: -1 - (-1) = 0");
        test_case(32'h00000000, 32'hFFFFFFFF, 6'b000010, 32'h00000000, "AND edge");
        test_case(32'hFFFFFFFF, 32'h00000000, 6'b001010, 32'hFFFFFFFF, "OR edge");

        // -------------------------------------------------------
        // SUMMARY
        // -------------------------------------------------------
        $display("\n===== TEST SUMMARY =====");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Total : %0d\n", pass_count + fail_count);

        if (fail_count == 0)
            $display("✓ ALL TESTS PASSED!");
        else
            $display("✗ SOME TESTS FAILED!");

        $finish;
    end
endmodule
