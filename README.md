# Pipelined RISC-V Harvard CPU

A 5-stage RV32I processor with Harvard architecture, data forwarding, and hazard control. The pipeline mirrors the standard computer architecture textbook design: IF → ID → EXE → MEM → WB.

---

## Architecture

### High-Level CPU Architecture

```mermaid
graph TB
    subgraph IMEM ["Instruction Memory ROM"]
        IM["i_instr[31:0]<br/>Instruction Memory"]
    end
    
    CLK[i_clk]
    RST[i_resetn]
    
    subgraph CPU ["RV32I Processor Module"]
        PC[o_pc<br/>Program Counter]
        
        IF["IF Stage<br/>Instruction Fetch<br/>PC + 4"]
        ID["ID Stage<br/>Decode + RegFile<br/>Hazard Detection"]
        EX["EX Stage<br/>ALU + Forwarding<br/>Branch Compare"]
        MEM["MEM Stage<br/>Memory Access<br/>Load/Store"]
        WB["WB Stage<br/>Write Back<br/>Result MUX"]
        
        CTRL["Controller<br/>- Hazard: stall, flush<br/>- Forward: fwda, fwdb<br/>- Control: pcsrc, aluc"]
        RF["Register File<br/>32 registers x0-x31<br/>2 read + 1 write"]
    end
    
    subgraph DMEM ["Data Memory RAM"]
        DM["i_dmem[31:0]<br/>Data from Memory"]
        DOUT["o_dmem[31:0]<br/>Data to Memory"]
        DADDR["o_addr[31:0]<br/>Memory Address"]
        DMWR[o_wmem<br/>Write Enable]
    end
    
    CLK --> CPU
    RST --> CPU
    PC --> IM
    IM -->|instruction| IF
    
    IF --> ID
    ID --> RF
    ID --> EX
    EX --> MEM
    MEM --> WB
    WB --> RF
    
    CTRL -->|stall, flush| IF
    CTRL -->|fwda, fwdb| EX
    CTRL -->|pcsrc| PC
    
    DADDR --> DMEM
    DOUT --> DMEM
    DMWR --> DMEM
    DM -->|load data| MEM
```

The processor separates instruction memory (ROM) and data memory (RAM), allowing simultaneous instruction fetch and data access.

![CPU Waveform](Diagrams/waveform.png)

*The waveform shows the PC incrementing by 4 each cycle as instructions flow through the pipeline stages.*

### RISC-V Top-Level Architecture

```mermaid
flowchart LR
    IMEM["Instruction<br/>Memory<br/>i_instr"]
    
    subgraph IF ["IF Stage"]
        PC[PC Reg]
        PCA["PC+4<br/>Adder"]
        PCMUX["PC MUX<br/>3:1"]
    end
    
    IFID["IF/ID<br/>Pipeline Reg"]
    
    subgraph ID ["ID Stage"]
        DEC[Decoder]
        RF["RegFile<br/>x0-x31"]
        IMM["Imm<br/>Decode"]
        CMP[Comparator]
        HAZ["Hazard<br/>Unit"]
        FWDMUX["Forward<br/>MUX 4:1"]
    end
    
    IDEX["ID/EX<br/>Pipeline Reg"]
    
    subgraph EX ["EX Stage"]
        ALUMUX["ALU<br/>Input MUX"]
        ALU[ALU]
        DATAMUX["Data<br/>MUX 3:1"]
    end
    
    EXMEM["EX/MEM<br/>Pipeline Reg"]
    
    subgraph MEM ["MEM Stage"]
        LSMOD["Load/Store<br/>Modifier"]
    end
    
    DMEM["Data<br/>Memory<br/>i_dmem"]
    
    MEMWB["MEM/WB<br/>Pipeline Reg"]
    
    subgraph WB ["WB Stage"]
        WBMUX["WB MUX<br/>2:1"]
    end
    
    PC --> IMEM
    IMEM --> IFID
    PCA --> PCMUX
    PCMUX --> PC
    
    IFID --> DEC
    IFID --> IMM
    DEC --> RF
    RF --> FWDMUX
    FWDMUX --> CMP
    FWDMUX --> IDEX
    IMM --> IDEX
    
    IDEX --> ALUMUX
    ALUMUX --> ALU
    ALU --> DATAMUX
    DATAMUX --> EXMEM
    
    EXMEM --> LSMOD
    LSMOD --> DMEM
    DMEM --> MEMWB
    
    MEMWB --> WBMUX
    WBMUX --> RF
    
    EXMEM -.forward.-> FWDMUX
    MEMWB -.forward.-> FWDMUX
    HAZ -.stall.-> IFID
    CMP -.branch.-> PCMUX
```

### Pipeline Stages Detail

```mermaid
flowchart TD
    subgraph IF_STAGE ["IF STAGE: Instruction Fetch"]
        direction LR
        IF1["Fetch Instruction<br/><b>PC → i_instr</b><br/>Read from IMEM"]
        IF2["Compute PC+4<br/><b>PC + 4</b><br/>Next instruction address"]
        IF3["Select Next PC<br/><b>MUX: branch/jal/jalr</b><br/>Choose PC source"]
        
        IF1 --> IF2
        IF2 --> IF3
    end
    
    IF_STAGE -.IF/ID Pipeline Register.-> ID_STAGE
    
    subgraph ID_STAGE ["ID STAGE: Decode"]
        direction LR
        ID1["Decode Instruction<br/><b>opcode, funct3, funct7</b><br/>rs1, rs2, rd"]
        ID2["Read Registers<br/><b>RegFile access</b><br/>reg_rdata1, reg_rdata2"]
        ID3["Generate Immediate<br/><b>Imm decode</b><br/>Sign extension"]
        ID4["Compare Branch<br/><b>Comparator</b><br/>Branch condition"]
        ID5["Forward MUX<br/><b>Data forwarding</b><br/>Select data source"]
        
        ID1 --> ID2
        ID2 --> ID3
        ID3 --> ID4
        ID4 --> ID5
    end
    
    ID_STAGE -.ID/EX Pipeline Register.-> EX_STAGE
    
    subgraph EX_STAGE ["EX STAGE: Execute"]
        direction LR
        EX1["Select ALU Inputs<br/><b>Input MUX</b><br/>ALU operand selection"]
        EX2["Execute ALU<br/><b>ALU operation</b><br/>SLT comparison<br/>JAL: PC+4<br/>AUIPC: PC+imm"]
        EX3["Select Data<br/><b>Data MUX 3:1</b><br/>Choose result source"]
        
        EX1 --> EX2
        EX2 --> EX3
    end
    
    EX_STAGE -.EX/MEM Pipeline Register.-> MEM_STAGE
    
    subgraph MEM_STAGE ["MEM STAGE: Memory Access"]
        direction LR
        MEM1["Access Memory<br/><b>Load: i_dmem</b><br/><b>Store: o_dmem</b><br/>Byte/Half/Word"]
        MEM2["Modify Load/Store<br/><b>Sign extension</b><br/>Data alignment"]
        
        MEM1 --> MEM2
    end
    
    MEM_STAGE -.MEM/WB Pipeline Register.-> WB_STAGE
    
    subgraph WB_STAGE ["WB STAGE: Write Back"]
        direction LR
        WB1["Select Write Data<br/><b>WB MUX 2:1</b><br/>ALU or Memory"]
        WB2["Write Register<br/><b>RegFile write</b><br/>rd destination"]
        
        WB1 --> WB2
    end
```

### Data Forwarding and Hazard Handling

```mermaid
flowchart TB
    subgraph PIPE ["Pipeline Registers"]
        IFID["IF/ID<br/>id_instr<br/>rs1, rs2"]
        IDEX["ID/EX<br/>exe_rd<br/>exe_wreg<br/>exe_mem2reg"]
        EXMEM["EX/MEM<br/>mem_rd<br/>mem_wreg<br/>mem_data"]
        MEMWB["MEM/WB<br/>wb_rd<br/>wb_wreg<br/>reg_wdata"]
    end
    
    subgraph HAZARD ["Hazard Detection"]
        HAZ["Hazard Unit<br/>Check Load-Use"]
        STALL["Generate:<br/>not_stall=0<br/>flush=1"]
    end
    
    subgraph FORWARD ["Data Forwarding"]
        FWD["Forward Unit<br/>Compare rd vs rs1/rs2"]
        MUXA["MUX A 4:1<br/>Select rs1 source"]
        MUXB["MUX B 4:1<br/>Select rs2 source"]
    end
    
    subgraph SOURCES ["Data Sources"]
        RFILE["RegFile<br/>reg_rdata1<br/>reg_rdata2"]
        EXDATA["EX Stage<br/>exe_data<br/>ALU result"]
        MEMDATA["MEM Stage<br/>mem_data<br/>ALU/Memory"]
        WBDATA["WB Stage<br/>mod_rd_dmem<br/>Load result"]
    end
    
    subgraph DECODE ["ID Stage"]
        CMP[Comparator]
        ALU_IN["To ID/EX<br/>id_regdata1<br/>id_regdata2"]
    end
    
    IFID -->|"rs1, rs2"| HAZ
    IDEX -->|"exe_rd, exe_mem2reg"| HAZ
    
    HAZ -->|"Load-Use?"| STALL
    STALL -.stall pipeline.-> IFID
    STALL -.insert bubble.-> IDEX
    
    IFID -->|"rs1, rs2"| FWD
    IDEX -->|"exe_rd, exe_wreg"| FWD
    EXMEM -->|"mem_rd, mem_wreg"| FWD
    MEMWB -->|"wb_rd, wb_wreg"| FWD
    
    FWD -->|"fwda[1:0]"| MUXA
    FWD -->|"fwdb[1:0]"| MUXB
    
    RFILE -->|"00"| MUXA
    EXDATA -->|"01"| MUXA
    MEMDATA -->|"10"| MUXA
    WBDATA -->|"11"| MUXA
    
    RFILE -->|"00"| MUXB
    EXDATA -->|"01"| MUXB
    MEMDATA -->|"10"| MUXB
    WBDATA -->|"11"| MUXB
    
    MUXA --> ALU_IN
    MUXB --> ALU_IN
    ALU_IN --> CMP
```

---

## Repository Layout

```
riscv32-harvard-pipeline/
├── CPU/
│   ├── cpu.v                      # Top-level CPU wrapper
│   ├── Processor/                 # Datapath and control
│   │   ├── RV32I_processor.v     # Pipelined core
│   │   ├── regfile.v             # Register file (x0-x31)
│   │   ├── controller.v          # Hazard and forwarding logic
│   │   ├── ALU/                  # Arithmetic/logic unit
│   │   ├── Comparator/           # Branch comparisons
│   │   └── Pipeline_Registers/   # IF_ID, ID_EXE, EXE_MEM, MEM_WB, pc_reg
│   ├── Instruction_Memory/
│   │   ├── instruction_mem.v     # ROM
│   │   ├── test_program.mem      # Assembled test program
│   │   └── pipelined_cpu_test.asm # Source assembly
│   └── D_memory/
│       └── D_memory.v            # RAM (32 words)
├── Test/
│   ├── cpu_test.sv               # Full CPU testbench
│   └── processor_core_tb.sv      # Core-only testbench
└── Diagrams/                     # Architecture diagrams
```

---

## Design

**Pipeline stages:**
- IF: Instruction fetch from ROM
- ID: Decode and register file read
- EXE: ALU operations and address calculation
- MEM: Data memory access
- WB: Register file write-back

**Hazard handling:**
- Data forwarding from EXE and MEM stages to ALU inputs
- Stall on load-use hazards
- Flush on branches and jumps

**Register file:**
- 32 registers (x0-x31)
- x0 hardwired to zero
- Two read ports, one write port

---

## Running the Test

Prerequisites:
```
choco install icarus-verilog  # Windows
brew install icarus-verilog   # macOS
sudo apt install iverilog     # Linux
```

Run simulation:
```powershell
cd "riscv32-harvard-pipeline"; iverilog -g2012 -s cpu_test -o sim_cpu Test\cpu_test.sv CPU\cpu.v CPU\D_memory\D_memory.v CPU\Instruction_Memory\instruction_mem.v CPU\Processor\RV32I_processor.v CPU\Processor\regfile.v CPU\Processor\controller.v CPU\Processor\mux.v CPU\Processor\imm_decode.v CPU\Processor\load_store_modifier.v CPU\Processor\Pipeline_Registers\if_id_reg.v CPU\Processor\Pipeline_Registers\id_exe_reg.v CPU\Processor\Pipeline_Registers\exe_mem_reg.v CPU\Processor\Pipeline_Registers\mem_wb_reg.v CPU\Processor\Pipeline_Registers\pc_reg.v CPU\Processor\ALU\ALU.v CPU\Processor\ALU\shifter.v CPU\Processor\AddORSub\add_sub.v CPU\Processor\AddORSub\CLA_32.v CPU\Processor\Comparator\comp_32.v; vvp sim_cpu; gtkwave cpu_test.vcd
```

The test program exercises:
- ALU operations (add, sub, shifts, etc.)
- Load/store with different widths
- Branch and jump instructions
- Data forwarding paths
- Load-use hazards

---

## Waveform Viewing

Key signals to inspect:
- `cpu_test.dut.pc` - Program counter (increments by 4)
- `cpu_test.dut.instr` - Fetched instruction
- `cpu_test.dut.processor.register_file.reg_file[*]` - Register contents
- `cpu_test.dut.processor.controller1.o_fwda`, `o_fwdb` - Forwarding controls
- `cpu_test.dut.dmem.ram[*]` - Data memory

Look for:
- Pipeline filling in first few cycles
- PC progression and control flow changes
- Register writes and data forwarding
- Memory operations

---

## Extending

- Replace `test_program.mem` with custom programs
- Increase data memory size
- Add branch prediction
- Synthesize for FPGA and check timing/resources
