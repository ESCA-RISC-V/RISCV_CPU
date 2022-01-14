`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2021 01:50:55 PM
// Design Name: 
// Module Name: my_core_trace
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import my_core_tracer_defines::*;
import my_riscv_defines::*;

`define REG_S1 19:15
`define REG_S2 24:20
`define REG_S3 29:25
`define REG_S4 31:27
`define REG_D  11:07

module my_core_trace(
  input  logic        clk,
  input  logic        rst_n,

  input  logic        fetch_enable,

  input  logic [31:0] pc,
  input  logic [31:0] instr,
  input  logic        is_running,

  input  logic [31:0] rs1_value,
  input  logic [31:0] rs2_value,
  input  logic [31:0] rd_value,
  
  input  logic [31:0] mem_addr,
  input  logic [31:0] mem_wdata,

  input  logic [31:0] imm_u_type,   //u type
  input  logic [31:0] imm_j_type,  //j type
  input  logic [31:0] imm_i_type,   //i type
  input  logic [31:0] imm_csr_type,   //csr
  input  logic [31:0] imm_s_type,   //s type
  input  logic [31:0] imm_b_type  //b type
);

  integer      f;
  string       fn;
  integer      cycles;
  logic [ 4:0] rd, rs1, rs2, rs3, rs4;

  typedef struct {
    logic [ 5:0] addr;
    logic [31:0] value;
  } reg_t;

  typedef struct {
    logic [31:0] addr;
    logic        we;
    logic [ 3:0] be;
    logic [31:0] wdata;
    logic [31:0] rdata;
  } mem_acc_t;

  class instr_trace_t;
    time         simtime;
    integer      cycles;
    logic [31:0] pc;
    logic [31:0] instr;
    string       str;
    reg_t        regs_read[$];
    reg_t        regs_write[$];
    mem_acc_t    mem_access[$];

    function new ();
      str        = "";
      regs_read  = {};
      regs_write = {};
      mem_access = {};
    endfunction

    function string regAddrToStr(input logic [5:0] addr);
      begin
        // TODO: use this function to also format the arguments to the
        // instructions
        /*if (SymbolicRegs) begin // format according to RISC-V ABI
          if (addr >= 42)
            return $sformatf(" f%0d", addr-32);
          else if (addr > 32)
            return $sformatf("  f%0d", addr-32);
          else begin
            if (addr == 0)
              return $sformatf("zero");
            else if (addr == 1)
              return $sformatf("  ra");
            else if (addr == 2)
              return $sformatf("  sp");
            else if (addr == 3)
              return $sformatf("  gp");
            else if (addr == 4)
              return $sformatf("  tp");
            else if (addr >= 5 && addr <= 7)
              return $sformatf("  t%0d", addr-5);
            else if (addr >= 8 && addr <= 9)
              return $sformatf("  s%0d", addr-8);
            else if (addr >= 10 && addr <= 17)
              return $sformatf("  a%0d", addr-10);
            else if (addr >= 18 && addr <= 25)
              return $sformatf("  s%0d", addr-16);
            else if (addr >= 26 && addr <= 27)
              return $sformatf(" s%0d", addr-16);
            else if (addr >= 28 && addr <= 31)
              return $sformatf("  t%0d", addr-25);
            else
              return $sformatf("UNKNOWN %0d", addr);
          end*/
        //end else begin
          if (addr >= 42)
            return $sformatf("f%0d", addr-32);
          else if (addr > 32)
            return $sformatf(" f%0d", addr-32);
          else if (addr < 10)
            return $sformatf(" x%0d", addr);
          else
            return $sformatf("x%0d", addr);
        end
      //end
    endfunction

    function void printInstrTrace();
      mem_acc_t mem_acc;
      begin
        $fwrite(f, "%t %15d %h %h %-36s", simtime,
                                          cycles,
                                          pc,
                                          instr,
                                          str);

        foreach(regs_write[i]) begin
          if (regs_write[i].addr != 0)
            $fwrite(f, " %s=%08x", regAddrToStr(regs_write[i].addr), regs_write[i].value);
        end

        foreach(regs_read[i]) begin
          if (regs_read[i].addr != 0)
            $fwrite(f, " %s:%08x", regAddrToStr(regs_read[i].addr), regs_read[i].value);
        end

        if (mem_access.size() > 0) begin
          mem_acc = mem_access.pop_front();

          $fwrite(f, "  PA:%08x", mem_acc.addr);
        end

        $fwrite(f, "\n");
      end
    endfunction

    function void printMnemonic(input string mnemonic);
      begin
        str = mnemonic;
      end
    endfunction // printMnemonic

    function void printRInstr(input string mnemonic);
      begin
        regs_read.push_back('{rs1, rs1_value});
        regs_read.push_back('{rs2, rs2_value});
        regs_write.push_back('{rd, rd_value});
        str = $sformatf("%-16s x%0d, x%0d, x%0d", mnemonic, rd, rs1, rs2);
      end
    endfunction // printRInstr

    function void printIInstr(input string mnemonic);
      begin
        regs_read.push_back('{rs1, rs1_value});
        regs_write.push_back('{rd, rd_value});
        str = $sformatf("%-16s x%0d, x%0d, %0d", mnemonic, rd, rs1, $signed(imm_i_type));
      end
    endfunction // printIInstr

    function void printIuInstr(input string mnemonic);
      begin
        regs_read.push_back('{rs1, rs1_value});
        regs_write.push_back('{rd, rd_value});
        str = $sformatf("%-16s x%0d, x%0d, 0x%0x", mnemonic, rd, rs1, imm_i_type);
      end
    endfunction // printIuInstr

    function void printUInstr(input string mnemonic);
      begin
        regs_write.push_back('{rd, rd_value});
        str = $sformatf("%-16s x%0d, 0x%0h", mnemonic, rd, {imm_u_type[31:12], 12'h000});
      end
    endfunction // printUInstr

    function void printUJInstr(input string mnemonic);
      begin
        regs_write.push_back('{rd, rd_value});
        str =  $sformatf("%-16s x%0d, %0d", mnemonic, rd, $signed(imm_j_type));
      end
    endfunction // printUJInstr

    function void printSBInstr(input string mnemonic);
      begin
        regs_read.push_back('{rs1, rs1_value});
        regs_read.push_back('{rs2, rs2_value});
        str =  $sformatf("%-16s x%0d, x%0d, %0d", mnemonic, rs1, rs2, $signed(imm_b_type));
      end
    endfunction // printSBInstr

    function void printCSRInstr(input string mnemonic);
      logic [11:0] csr;
      begin
        csr = instr[31:20];

        regs_write.push_back('{rd, rd_value});

        if (instr[14] == 1'b0) begin
          regs_read.push_back('{rs1, rs1_value});
          str = $sformatf("%-16s x%0d, x%0d, 0x%h", mnemonic, rd, rs1, csr);
        end else begin
          str = $sformatf("%-16s x%0d, 0x%h, 0x%h", mnemonic, rd, imm_csr_type, csr);
        end
      end
    endfunction // printCSRInstr

    function void printLoadInstr();
      string mnemonic;
      logic [2:0] size;
      begin
        // detect reg-reg load and find size
        size = instr[14:12];
        if (instr[14:12] == 3'b111)
          size = instr[30:28];

        case (size)
          3'b000: mnemonic = "lb";
          3'b001: mnemonic = "lh";
          3'b010: mnemonic = "lw";
          3'b100: mnemonic = "lbu";
          3'b101: mnemonic = "lhu";
          3'b011,
          3'b111: begin
            printMnemonic("INVALID");
            return;
          end
        endcase

        regs_write.push_back('{rd, rd_value});

        if (instr[14:12] != 3'b111) begin
          // regular load
            regs_read.push_back('{rs1, rs1_value});
            str = $sformatf("%-16s x%0d, %0d(x%0d)", mnemonic, rd, $signed(imm_i_type), rs1);
          
        end else begin
          // reg-reg load
            regs_read.push_back('{rs2, rs2_value});
            regs_read.push_back('{rs1, rs1_value});
            str = $sformatf("%-16s x%0d, x%0d(x%0d)", mnemonic, rd, rs2, rs1);
          
        end
        
        
        mem_access.push_back('{mem_addr, 1'b0, 4'b0, mem_wdata, '0});
                
      end
    endfunction

    function void printStoreInstr();
      string mnemonic;
      begin

        case (instr[13:12])
          2'b00:  mnemonic = "sb";
          2'b01:  mnemonic = "sh";
          2'b10:  mnemonic = "sw";
          2'b11: begin
            printMnemonic("INVALID");
            return;
          end
        endcase

        if (instr[14] == 1'b0) begin
          // regular store
            regs_read.push_back('{rs2, rs2_value});
            regs_read.push_back('{rs1, rs1_value});
            str = $sformatf("%-16s x%0d, %0d(x%0d)", mnemonic, rs2, $signed(imm_s_type), rs1);
          
        end
        
        mem_access.push_back('{mem_addr, 1'b0, 4'b0, mem_wdata, '0});
         
      end
    endfunction // printSInstr
    
  endclass

  // cycle counter
  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0)
      cycles = 0;
    else
      cycles = cycles + 1;
  end

  // open/close output file for writing
  initial
  begin
    wait(rst_n == 1'b1);
    $sformat(fn, "my_trace_core.log");
    // $display("[TRACER] Output filename is: %s", fn);
    f = $fopen(fn, "w");
    $fwrite(f, "                Time          Cycles PC       Instr    Mnemonic\n");

  end

  final
  begin
    $fclose(f);
  end

  assign rd  = instr[`REG_D];
  assign rs1 = instr[`REG_S1];
  assign rs2 = instr[`REG_S2];
  assign rs3 = instr[`REG_S3];
  assign rs4 = instr[`REG_S4];


  // these signals are for simulator visibility. Don't try to do the nicer way
  // of making instr_trace_t visible to inspect it with your simulator. Some
  // choke for some unknown performance reasons.
  string insn_disas;
  logic [31:0] insn_pc;
  logic [31:0] insn_val;

  // log execution
  always @(negedge clk)
  begin
    instr_trace_t trace;

    // special case for WFI because we don't wait for unstalling there
    if ( fetch_enable && is_running && instr != NOP)
    begin
      trace = new ();

      trace.simtime    = $time;
      trace.cycles     = cycles;
      trace.pc         = pc;
      trace.instr      = instr;

      // use casex instead of case inside due to ModelSim bug
      casex (instr)
        // Regular opcodes
        INSTR_LUI:        trace.printUInstr("lui");
        INSTR_AUIPC:      trace.printUInstr("auipc");
        INSTR_JAL:        trace.printUJInstr("jal");
        INSTR_JALR:       trace.printIInstr("jalr");
        // BRANCH
        INSTR_BEQ:        trace.printSBInstr("beq");
        INSTR_BNE:        trace.printSBInstr("bne");
        INSTR_BLT:        trace.printSBInstr("blt");
        INSTR_BGE:        trace.printSBInstr("bge");
        INSTR_BLTU:       trace.printSBInstr("bltu");
        INSTR_BGEU:       trace.printSBInstr("bgeu");
        
        // OPIMM
        INSTR_ADDI:       trace.printIInstr("addi");
        INSTR_SLTI:       trace.printIInstr("slti");
        INSTR_SLTIU:      trace.printIInstr("sltiu");
        INSTR_XORI:       trace.printIInstr("xori");
        INSTR_ORI:        trace.printIInstr("ori");
        INSTR_ANDI:       trace.printIInstr("andi");
        INSTR_SLLI:       trace.printIuInstr("slli");
        INSTR_SRLI:       trace.printIuInstr("srli");
        INSTR_SRAI:       trace.printIuInstr("srai");
        // OP
        INSTR_ADD:        trace.printRInstr("add");
        INSTR_SUB:        trace.printRInstr("sub");
        INSTR_SLL:        trace.printRInstr("sll");
        INSTR_SLT:        trace.printRInstr("slt");
        INSTR_SLTU:       trace.printRInstr("sltu");
        INSTR_XOR:        trace.printRInstr("xor");
        INSTR_SRL:        trace.printRInstr("srl");
        INSTR_SRA:        trace.printRInstr("sra");
        INSTR_OR:         trace.printRInstr("or");
        INSTR_AND:        trace.printRInstr("and");

        // SYSTEM (CSR manipulation)
        INSTR_CSRRW:      trace.printCSRInstr("csrrw");
        INSTR_CSRRS:      trace.printCSRInstr("csrrs");
        INSTR_CSRRC:      trace.printCSRInstr("csrrc");
        INSTR_CSRRWI:     trace.printCSRInstr("csrrwi");
        INSTR_CSRRSI:     trace.printCSRInstr("csrrsi");
        INSTR_CSRRCI:     trace.printCSRInstr("csrrci");
        // SYSTEM (others)
        INSTR_ECALL:      trace.printMnemonic("ecall");
        INSTR_MRET:       trace.printMnemonic("mret");
        INSTR_WFI:        trace.printMnemonic("wfi");

        // opcodes with custom decoding
        {25'b?, OP_LOAD}:       trace.printLoadInstr();
        {25'b?, OP_STORE}:      trace.printStoreInstr();
        default:           trace.printMnemonic("INVALID");
      endcase // unique case (instr)
     
    trace.printInstrTrace();
     
      // visibility for simulator
      insn_disas = trace.str;
      insn_pc    = trace.pc;
      insn_val   = trace.instr;

    end
  end // always @ (posedge clk)

endmodule
