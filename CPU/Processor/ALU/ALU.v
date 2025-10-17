`timescale 1ns / 1ps

module alu (
    input wire [31:0] a, b,
    input wire [5:0] aluc,           // ALU Control: [5:4]=shift_type, [3]=operation_select, [2:0]=mux_select
    output wire [31:0] result
);
    
    // ========== CONTROL SIGNAL DECODING ==========
    wire [2:0] mux_select = aluc[2:0];    // Control: selects which operation output to return
    wire op_select = aluc[3];             // Control: selects between variant operations (and/or, xor/lui, add/sub, etc.)
    wire arith_ctrl = aluc[4];            // Control: for shift, 1=arithmetic 0=logical
    wire shift_dir = aluc[3];             // Control: for shift, 1=right 0=left (reuses op_select)
    
    // ========== INTERMEDIATE OPERATION OUTPUTS ==========
    wire [31:0] add_sub_out;
    wire [31:0] and_or_out;
    wire [31:0] xor_lui_out;
    wire [31:0] shift_out;
    
    // ========== ADD/SUB UNIT ==========
    // op_select: 1=subtract, 0=add
    add_sub32 add_sub_unit (
        .a(a),
        .b(b),
        .sub(op_select),
        .out(add_sub_out)
    );
    
    // ========== LOGIC UNIT (AND/OR) ==========
    // op_select: 1=OR, 0=AND
    assign and_or_out = op_select ? (a | b) : (a & b);
    
    // ========== LOGIC UNIT (XOR/LUI) ==========
    // op_select: 1=LUI (pass b), 0=XOR
    assign xor_lui_out = op_select ? b : (a ^ b);
    
    // ========== SHIFT UNIT ==========
    // shift_dir (aluc[3]): 1=right, 0=left
    // arith_ctrl (aluc[4]): 1=arithmetic, 0=logical
    shifter shift_unit (
        .data(a),
        .sa(b[4:0]),
        .right(shift_dir),
        .arith(arith_ctrl),
        .sh_result(shift_out)
    );
    
    // ========== RESULT MUX (6-to-1) ==========
    // mux_select (aluc[2:0]): chooses which operation result to output
    mux_6to1 result_mux (
        .inputA(add_sub_out),
        .inputB(),
        .inputC(and_or_out),
        .inputD(),
        .inputE(xor_lui_out),
        .inputF(shift_out),
        .select(mux_select),
        .selected_out(result)
    );

endmodule
