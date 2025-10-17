module instruction_mem (
    input wire [31:0] i_addr,
    output wire [31:0] o_instr
);

    reg [31:0] rom [0:31];
    localparam string DEFAULT_MEMFILE = "CPU/Instruction_Mem/test_program.mem";

    initial begin
        string memfile;
        if (!$value$plusargs("IMEM=%s", memfile))
            memfile = DEFAULT_MEMFILE;

        $display("instruction_mem: loading from %s", memfile);
        $readmemh(memfile, rom);
    end

    assign o_instr = rom[i_addr[31:2]];
endmodule
