`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2021 02:17:21 PM
// Design Name: 
// Module Name: my_core_tracer_defines
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

package my_core_tracer_defines;
import my_riscv_defines::*;

//U
parameter INSTR_LUI       = { 25'b?, OP_LUI };
parameter INSTR_AUIPC     = { 25'b?, OP_AUIPC };

//J
parameter INSTR_JAL       = { 25'b?, OP_JAL };

parameter INSTR_JALR      = { 17'b?, 3'b000, 5'b?, OP_JALR };

// B
parameter INSTR_BEQ      =  { 17'b?, 3'b000, 5'b?, OP_B };
parameter INSTR_BNE      =  { 17'b?, 3'b001, 5'b?, OP_B };
parameter INSTR_BLT      =  { 17'b?, 3'b100, 5'b?, OP_B };
parameter INSTR_BGE      =  { 17'b?, 3'b101, 5'b?, OP_B };
parameter INSTR_BLTU     =  { 17'b?, 3'b110, 5'b?, OP_B };
parameter INSTR_BGEU     =  { 17'b?, 3'b111, 5'b?, OP_B };

// I
parameter INSTR_ADDI     =  { 17'b?, 3'b000, 5'b?, OP_I };
parameter INSTR_SLTI     =  { 17'b?, 3'b010, 5'b?, OP_I };
parameter INSTR_SLTIU    =  { 17'b?, 3'b011, 5'b?, OP_I };
parameter INSTR_XORI     =  { 17'b?, 3'b100, 5'b?, OP_I };
parameter INSTR_ORI      =  { 17'b?, 3'b110, 5'b?, OP_I };
parameter INSTR_ANDI     =  { 17'b?, 3'b111, 5'b?, OP_I };
parameter INSTR_SLLI     =  { 7'b0000000, 10'b?, 3'b001, 5'b?, OP_I };
parameter INSTR_SRLI     =  { 7'b0000000, 10'b?, 3'b101, 5'b?, OP_I };
parameter INSTR_SRAI     =  { 7'b0100000, 10'b?, 3'b101, 5'b?, OP_I };

// R
parameter INSTR_ADD      =  { 7'b0000000, 10'b?, 3'b000, 5'b?, OP_R };
parameter INSTR_SUB      =  { 7'b0100000, 10'b?, 3'b000, 5'b?, OP_R };
parameter INSTR_SLL      =  { 7'b0000000, 10'b?, 3'b001, 5'b?, OP_R };
parameter INSTR_SLT      =  { 7'b0000000, 10'b?, 3'b010, 5'b?, OP_R };
parameter INSTR_SLTU     =  { 7'b0000000, 10'b?, 3'b011, 5'b?, OP_R };
parameter INSTR_XOR      =  { 7'b0000000, 10'b?, 3'b100, 5'b?, OP_R };
parameter INSTR_SRL      =  { 7'b0000000, 10'b?, 3'b101, 5'b?, OP_R };
parameter INSTR_SRA      =  { 7'b0100000, 10'b?, 3'b101, 5'b?, OP_R };
parameter INSTR_OR       =  { 7'b0000000, 10'b?, 3'b110, 5'b?, OP_R };
parameter INSTR_AND      =  { 7'b0000000, 10'b?, 3'b111, 5'b?, OP_R };

// SYSTEM
parameter INSTR_CSRRW    =  { 17'b?, 3'b001, 5'b?, OP_SYSTEM };
parameter INSTR_CSRRS    =  { 17'b?, 3'b010, 5'b?, OP_SYSTEM };
parameter INSTR_CSRRC    =  { 17'b?, 3'b011, 5'b?, OP_SYSTEM };
parameter INSTR_CSRRWI   =  { 17'b?, 3'b101, 5'b?, OP_SYSTEM };
parameter INSTR_CSRRSI   =  { 17'b?, 3'b110, 5'b?, OP_SYSTEM };
parameter INSTR_CSRRCI   =  { 17'b?, 3'b111, 5'b?, OP_SYSTEM };

parameter INSTR_ECALL    =  { 12'b000000000000, 13'b0, OP_SYSTEM };
parameter INSTR_MRET     =  { 12'b001100000010, 13'b0, OP_SYSTEM };
parameter INSTR_WFI      =  { 12'b000100000101, 13'b0, OP_SYSTEM };
endpackage