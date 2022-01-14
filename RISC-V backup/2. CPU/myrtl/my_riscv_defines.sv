`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2021 05:26:03 PM
// Design Name: 
// Module Name: my_riscv_defines
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


package my_riscv_defines;

//Instr
parameter NOP       =32'h0000_0013; //addi x0, x0, 0

parameter MRET      =12'h302;
parameter ECALL     =12'h000;
parameter WFI       =12'h105;
parameter EBREAK    =12'h001;

parameter FENCE     =7'b000_1111; 

//OPCODE
parameter OP_R      =7'b011_0011;
parameter OP_I      =7'b001_0011;
parameter OP_B      =7'b110_0011;
parameter OP_LOAD   =7'b000_0011;
parameter OP_STORE  =7'b010_0011;
parameter OP_LUI    =7'b011_0111;
parameter OP_AUIPC  =7'b001_0111;
parameter OP_JAL    =7'b110_1111;
parameter OP_JALR   =7'b110_0111;
parameter OP_SYSTEM =7'b111_0011;

//Branch
parameter BEQ   =3'b000;
parameter BNE   =3'b001;
parameter BLT   =3'b100;
parameter BGE   =3'b101;
parameter BLTU  =3'b110;
parameter BGEU  =3'b111;

//CSR
parameter MSTATUS   = 12'h300;
parameter MISA      = 12'h301;
parameter MTVEC     = 12'h305;
parameter MEPC      = 12'h341;
parameter MCAUSE    = 12'h342;

//Exception cause
parameter EXC_MISALIGNED_INSTR  = 5'b00000; //0
parameter EXC_ILLEGAL_INSTR     = 5'b00010; //2
parameter EXC_ECALL_FROM_M      = 5'b01011; //11

endpackage