`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2021 08:02:33 PM
// Design Name: 
// Module Name: my_priv_module
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

import my_riscv_defines::*;

module my_priv_module
(
    input logic         clk_i,
    input logic         rst_ni,
    input logic         fetch_ready_i,
    
    input logic [11:0]  csr_addr_i,
    input logic [1:0]   c_csr_op_i,
    input logic         c_csr_imm_i,
    input logic         c_readcsr_i,
    input logic         c_writecsr_i,
    
    input logic         c_mret_i,
    
    input logic [31:0]  csr_wdata_i,    //reg to csr
    output logic [31:0] csr_rdata_o,    //csr to reg
    
    output logic        mstatus_mie_o,
    output logic [31:0] mtvec_o,
    output logic [31:0] mepc_o,
    output logic [5:0]  mcause_o,
    
    input logic         irq_taken_i,
    input logic         irq_i,
    input logic [4:0]   irq_id_i,
    input logic         exc_taken_i,
    input logic [4:0]   exc_id_i,
    input logic [31:0]  exc_pc_i,
    
    input logic         irq_done_i
    
);

    typedef struct packed {
        logic [1:0] mpp;
        logic       mpie;
        logic       mie;
    } mstatus_t;

    mstatus_t       mstatus_n, mstatus_c;
    logic [31:0]    misa_n, misa_c;
    logic [31:0]    mtvec_n, mtvec_c;
    logic [31:0]    mepc_n, mepc_c;
    logic [5:0]     mcause_n, mcause_c;
    
    logic [31:0]    csr_wdata_tmp;
        
    assign mstatus_mie_o    = mstatus_c.mie;
    assign mtvec_o          = mtvec_c;
    assign mepc_o           = mepc_c;
    assign mcause_o         = mcause_c;
    
    always_comb
    begin
        case(c_csr_op_i)
            2'b01: begin    //RW
                csr_wdata_tmp   = csr_wdata_i;
            end
            2'b10: begin    //RS
                csr_wdata_tmp   = (csr_wdata_i | csr_rdata_o); 
            end
            2'b11: begin    //RC
                csr_wdata_tmp   = ((~csr_wdata_i) & csr_rdata_o);
            end
        endcase
    end
    
    //start read logic
    always_comb
    begin
        if(c_readcsr_i) begin
            case(csr_addr_i)
                MSTATUS: begin
                    csr_rdata_o     = {19'b0, mstatus_c.mpp, 3'b0, mstatus_c.mpie, 3'b0, mstatus_c.mie, 3'b0};
                end
                MISA: begin
                    csr_rdata_o     = misa_c;
                end
                MTVEC: begin
                    csr_rdata_o     = mtvec_c;
                end
                MEPC: begin
                    csr_rdata_o     = mepc_c;
                end
                MCAUSE: begin
                    csr_rdata_o     = {mcause_c[5], 26'b0, mcause_c[4:0]};
                end
                default: begin
                    csr_rdata_o     = '0;
                end
            endcase
        end
        else begin
            csr_rdata_o    = '0;
        end
    end
    //end read logic
    
    
    //start write logic
    always_comb
    begin
        if(irq_taken_i) begin
            mepc_n          = exc_pc_i;
            mcause_n        = {irq_i, irq_id_i};
            mstatus_n.mpp   = 2'b11;    //m mode
            mstatus_n.mpie  = mstatus_c.mie;
            mstatus_n.mie   = 1'b0;
        end
        else if(exc_taken_i) begin
            mepc_n          = exc_pc_i;
            mcause_n        = {1'b0, exc_id_i};
            mstatus_n.mpp   = 2'b11;    //m mode
            mstatus_n.mpie  = mstatus_c.mie;
            mstatus_n.mie   = 1'b0;
        end
        else if(irq_done_i) begin
            mstatus_n.mpp   = 2'b11;
            mstatus_n.mie   = mstatus_c.mpie;
            mstatus_n.mpie  = 1'b1;
        end
        else if(c_writecsr_i) begin
            case(csr_addr_i)
                MSTATUS: begin
                    mstatus_n.mpp   = csr_wdata_tmp[12:11];
                    mstatus_n.mpie  = csr_wdata_tmp[7];
                    mstatus_n.mie   = csr_wdata_tmp[3];
                end
                MISA: begin
                    misa_n  = misa_c;   //no write on misa
                end
                MTVEC: begin
                    mtvec_n     = {csr_wdata_tmp[31:8], 8'b0000_0001};
                end
                MEPC: begin
                    mepc_n      = {csr_wdata_tmp[31:1], 1'b0}; //32-bit alignment
                end
                MCAUSE: begin
                    mcause_n    = {csr_wdata_tmp[31], csr_wdata_tmp[4:0]};
                end
                default: begin
                    mstatus_n   = mstatus_c;
                    misa_n      = misa_c;
                    mtvec_n     = mtvec_c;
                    mepc_n      = mepc_c;
                    mcause_n    = mcause_c;
                end
            endcase
        end
        else begin
            mstatus_n   = mstatus_c;
            misa_n      = misa_c;    //no write on misa
            mtvec_n     = mtvec_c;
            mepc_n      = mepc_c;
            mcause_n    = mcause_c;
        end
    end    
    //end write logic
    
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni) begin
            mstatus_c   <= '0;
            misa_c      <= 32'h4000_0100;
            mtvec_c     <= '0;
            mepc_c      <= '0;
            mcause_c    <= '0;
        end
        else if(fetch_ready_i) begin
            mstatus_c   <= mstatus_n;
            misa_c      <= misa_n;
            mtvec_c     <= mtvec_n;
            mepc_c      <= mepc_n;
            mcause_c    <= mcause_n;
        end
    end
    
endmodule