`timescale 1ns / 1ps

module add_sub32_tb;
    reg [31:0] a, b;
    reg sub;
    wire [31:0] out;

    integer pass_count = 0;
    integer fail_count = 0;

    // Device Under Test
    add_sub32 dut (
        .a(a),
        .b(b),
        .sub(sub),
        .out(out)
    );

    // Task: single test case (string desc replaced with reg [1023:0])
    task test_case;
        input [31:0] test_a;
        input [31:0] test_b;
        input test_sub;
        input [31:0] expected;
        input [1023:0] desc;
        begin
            a = test_a;
            b = test_b;
            sub = test_sub;
            #1; // delay to settle

            if (out === expected) begin
                $display("[PASS] %s", desc);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s | a=%0d, b=%0d, sub=%b | Got=%0d | Expected=%0d",
                         desc, test_a, test_b, test_sub, out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("===== ADD/SUB 32-BIT TESTBENCH =====\n");

        $display("--- ADDITION TESTS (sub=0) ---");
        test_case(32'd10, 32'd5, 1'b0, 32'd15, "10 + 5 = 15");
        test_case(32'd100, 32'd200, 1'b0, 32'd300, "100 + 200 = 300");
        test_case(32'd0, 32'd0, 1'b0, 32'd0, "0 + 0 = 0");
        test_case(32'd1000, 32'd2000, 1'b0, 32'd3000, "1000 + 2000 = 3000");
        test_case(32'hFFFFFFFF, 32'd1, 1'b0, 32'd0, "MAX + 1 = 0 (overflow)");

        $display("\n--- SUBTRACTION TESTS (sub=1) ---");
        test_case(32'd20, 32'd5, 1'b1, 32'd15, "20 - 5 = 15");
        test_case(32'd100, 32'd50, 1'b1, 32'd50, "100 - 50 = 50");
        test_case(32'd10, 32'd10, 1'b1, 32'd0, "10 - 10 = 0");
        test_case(32'd5, 32'd20, 1'b1, 32'hFFFFFFF1, "5 - 20 = -15 (two's complement)");
        test_case(32'd0, 32'd1, 1'b1, 32'hFFFFFFFF, "0 - 1 = -1");

        $display("\n--- SIGNED OPERATIONS ---");
        test_case(32'hFFFFFFFF, 32'd1, 1'b1, 32'hFFFFFFFE, "-1 - 1 = -2");
        test_case(32'h80000000, 32'd1, 1'b0, 32'h80000001, "-2147483648 + 1 = -2147483647");
        test_case(32'd2147483647, 32'd1, 1'b1, 32'd2147483646, "2147483647 - 1 = 2147483646");

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
