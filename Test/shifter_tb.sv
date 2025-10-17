module shifter_tb;
    logic [31:0] data;
    logic [4:0] sa;
    logic right, arith;
    logic [31:0] sh_result;
    
    int pass_count = 0, fail_count = 0;
    
    shifter dut (.data(data), .sa(sa), .right(right), .arith(arith), .sh_result(sh_result));
    
    task test_case(
        input logic [31:0] test_data,
        input logic [4:0] test_sa,
        input logic test_right,
        input logic test_arith,
        input logic [31:0] expected,
        input string desc
    );
        data = test_data;
        sa = test_sa;
        right = test_right;
        arith = test_arith;
        #1;
        
        if (sh_result == expected) begin
            $display("[PASS] %s", desc);
            pass_count++;
        end else begin
            $display("[FAIL] %s | data=0x%h, sa=%0d | Got: 0x%h | Expected: 0x%h", 
                desc, test_data, test_sa, sh_result, expected);
            fail_count++;
        end
    endtask
    
    initial begin
        $display("===== SHIFTER TESTBENCH =====\n");
        
        $display("--- LEFT SHIFT TESTS (right=0) ---");
        test_case(32'h00000001, 5'd0, 1'b0, 1'bx, 32'h00000001, "1 << 0 = 1");
        test_case(32'h00000001, 5'd1, 1'b0, 1'bx, 32'h00000002, "1 << 1 = 2");
        test_case(32'h00000001, 5'd4, 1'b0, 1'bx, 32'h00000010, "1 << 4 = 16");
        test_case(32'h00000001, 5'd31, 1'b0, 1'bx, 32'h80000000, "1 << 31 = 0x80000000");
        test_case(32'h0000FFFF, 5'd8, 1'b0, 1'bx, 32'hFFFF0000, "0xFFFF << 8 = 0xFFFF0000");
        
        $display("\n--- LOGICAL RIGHT SHIFT TESTS (right=1, arith=0) ---");
        test_case(32'h80000000, 5'd1, 1'b1, 1'b0, 32'h40000000, "0x80000000 >> 1 = 0x40000000 (logical)");
        test_case(32'hFFFFFFFF, 5'd8, 1'b1, 1'b0, 32'h00FFFFFF, "0xFFFFFFFF >> 8 = 0x00FFFFFF (logical)");
        test_case(32'h12345678, 5'd4, 1'b1, 1'b0, 32'h01234567, "0x12345678 >> 4 = 0x01234567 (logical)");
        test_case(32'h00000010, 5'd2, 1'b1, 1'b0, 32'h00000004, "16 >> 2 = 4 (logical)");
        
        $display("\n--- ARITHMETIC RIGHT SHIFT TESTS (right=1, arith=1) ---");
        test_case(32'h80000000, 5'd1, 1'b1, 1'b1, 32'hC0000000, "0x80000000 >>> 1 = 0xC0000000 (arithmetic, sign extends)");
        test_case(32'hFFFFFFFF, 5'd8, 1'b1, 1'b1, 32'hFFFFFFFF, "0xFFFFFFFF >>> 8 = 0xFFFFFFFF (arithmetic)");
        test_case(32'h7FFFFFFF, 5'd1, 1'b1, 1'b1, 32'h3FFFFFFF, "0x7FFFFFFF >>> 1 = 0x3FFFFFFF (arithmetic)");
        test_case(32'hF0000000, 5'd4, 1'b1, 1'b1, 32'hFF000000, "0xF0000000 >>> 4 = 0xFF000000 (arithmetic, sign extends)");
        
        $display("\n--- EDGE CASES ---");
        test_case(32'h00000000, 5'd31, 1'b0, 1'bx, 32'h00000000, "0 << 31 = 0");
        test_case(32'hFFFFFFFF, 5'd0, 1'b1, 1'b0, 32'hFFFFFFFF, "0xFFFFFFFF >> 0 = 0xFFFFFFFF (no shift)");
        test_case(32'h00000001, 5'd31, 1'b1, 1'b1, 32'h00000000, "1 >>> 31 = 0 (arithmetic)");
        test_case(32'h80000001, 5'd16, 1'b1, 1'b1, 32'hFFFF8000, "0x80000001 >>> 16 = 0xFFFF8000 (arithmetic)");
        
        $display("\n===== TEST SUMMARY =====");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Total:  %0d\n", pass_count + fail_count);
        
        if (fail_count == 0)
            $display("✓ ALL TESTS PASSED!");
        else
            $display("✗ SOME TESTS FAILED!");
            
        $finish;
    end

endmodule