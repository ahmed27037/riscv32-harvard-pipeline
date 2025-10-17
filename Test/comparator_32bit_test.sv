`timescale 1ns / 1ps

module comparator_tb;

    // =====================================================
    // DUT Signals
    // =====================================================
    reg  [31:0] a, b;
    reg  unsigned_op;
    wire o_a_lt_b, o_a_eq_b;

    integer pass_count = 0;
    integer fail_count = 0;

    // =====================================================
    // Instantiate Device Under Test (DUT)
    // =====================================================
    comparator dut (
        .a(a),
        .b(b),
        .unsigned_op(unsigned_op),
        .o_a_lt_b(o_a_lt_b),
        .o_a_eq_b(o_a_eq_b)
    );

    // =====================================================
    // Test Helper Task
    // =====================================================
    task test_case;
        input [31:0] test_a;
        input [31:0] test_b;
        input test_unsigned;
        input expected_lt;
        input expected_eq;
        input [255:0] description;
        begin
            a = test_a;
            b = test_b;
            unsigned_op = test_unsigned;
            #1;

            if ((o_a_lt_b === expected_lt) && (o_a_eq_b === expected_eq)) begin
                $display("[PASS] %0s", description);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | a=%0d, b=%0d, unsigned=%b | Got: lt=%b eq=%b | Exp: lt=%b eq=%b",
                         description, test_a, test_b, test_unsigned,
                         o_a_lt_b, o_a_eq_b, expected_lt, expected_eq);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =====================================================
    // Test Sequence
    // =====================================================
    initial begin
        $dumpfile("comparator_tb.vcd");
        $dumpvars(0, comparator_tb);

        $display("===== COMPARATOR TESTBENCH =====\n");

        // -------------------------------------------------
        // UNSIGNED COMPARISONS
        // -------------------------------------------------
        $display("--- UNSIGNED COMPARISONS ---");
        test_case(32'd10, 32'd20, 1'b1, 1'b1, 1'b0, "Unsigned: 10 < 20");
        test_case(32'd20, 32'd10, 1'b1, 1'b0, 1'b0, "Unsigned: 20 > 10");
        test_case(32'd15, 32'd15, 1'b1, 1'b0, 1'b1, "Unsigned: 15 == 15");
        test_case(32'd0,  32'd0,  1'b1, 1'b0, 1'b1, "Unsigned: 0 == 0");
        test_case(32'hFFFFFFFF, 32'h00000001, 1'b1, 1'b0, 1'b0, "Unsigned: Max > 1");
        test_case(32'h00000001, 32'hFFFFFFFF, 1'b1, 1'b1, 1'b0, "Unsigned: 1 < Max");

        // -------------------------------------------------
        // SIGNED COMPARISONS: POSITIVE vs POSITIVE
        // -------------------------------------------------
        $display("\n--- SIGNED (POSITIVE vs POSITIVE) ---");
        test_case(32'd5,  32'd10, 1'b0, 1'b1, 1'b0, "Signed: 5 < 10");
        test_case(32'd10, 32'd5,  1'b0, 1'b0, 1'b0, "Signed: 10 > 5");
        test_case(32'd7,  32'd7,  1'b0, 1'b0, 1'b1, "Signed: 7 == 7");

        // -------------------------------------------------
        // SIGNED COMPARISONS: NEGATIVE vs NEGATIVE
        // -------------------------------------------------
        $display("\n--- SIGNED (NEGATIVE vs NEGATIVE) ---");
        test_case(-5, -10, 1'b0, 1'b0, 1'b0, "Signed: -5 > -10");
        test_case(-10, -5, 1'b0, 1'b1, 1'b0, "Signed: -10 < -5");
        test_case(-7, -7, 1'b0, 1'b0, 1'b1, "Signed: -7 == -7");

        // -------------------------------------------------
        // SIGNED COMPARISONS: MIXED SIGN
        // -------------------------------------------------
        $display("\n--- SIGNED (POS vs NEG / NEG vs POS) ---");
        test_case(32'd10, -5,  1'b0, 1'b0, 1'b0, "Signed: 10 > -5");
        test_case(-5,  32'd10, 1'b0, 1'b1, 1'b0, "Signed: -5 < 10");
        test_case(-10, 32'd5,  1'b0, 1'b1, 1'b0, "Signed: -10 < 5");
        test_case(32'd5, -10,  1'b0, 1'b0, 1'b0, "Signed: 5 > -10");

        // -------------------------------------------------
        // EDGE CASES
        // -------------------------------------------------
        $display("\n--- EDGE CASES ---");
        test_case(32'h80000000, 32'h7FFFFFFF, 1'b0, 1'b1, 1'b0, "Signed: min_int < max_int");
        test_case(32'h7FFFFFFF, 32'h80000000, 1'b0, 1'b0, 1'b0, "Signed: max_int > min_int");
        test_case(32'h80000000, 32'h80000000, 1'b0, 1'b0, 1'b1, "Signed: min_int == min_int");
        test_case(32'd0, -1, 1'b0, 1'b0, 1'b0, "Signed: 0 > -1");
        test_case(-1, 32'd0, 1'b0, 1'b1, 1'b0, "Signed: -1 < 0");

        // -------------------------------------------------
        // SUMMARY
        // -------------------------------------------------
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
