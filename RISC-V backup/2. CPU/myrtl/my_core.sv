`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2021 06:43:34 PM
// Design Name: 
// Module Name: my_core
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

`ifndef VERILATOR
`ifndef SYNTHESIS
`ifndef PULP_FPGA_EMUL
`define TRACE_EXECUTION
`endif
`endif
`endif
 

module my_core 
#(
    parameter N_EXT_PERF_COUNTERS =  0,
    parameter INSTR_RDATA_WIDTH   = 32,
    parameter PULP_SECURE         =  0,
    parameter N_PMP_ENTRIES       = 16,
    parameter USE_PMP             =  1, //if PULP_SECURE is 1, you can still not use the PMP
    parameter PULP_CLUSTER        =  1,
    parameter FPU                 =  0,
    parameter Zfinx               =  0,
    parameter FP_DIVSQRT          =  0,
    parameter SHARED_FP           =  0,
    parameter SHARED_DSP_MULT     =  0,
    parameter SHARED_INT_MULT     =  0,
    parameter SHARED_INT_DIV      =  0,
    parameter SHARED_FP_DIVSQRT   =  0,
    parameter WAPUTYPE            =  0,
    parameter APU_NARGS_CPU       =  3,
    parameter APU_WOP_CPU         =  6,
    parameter APU_NDSFLAGS_CPU    = 15,
    parameter APU_NUSFLAGS_CPU    =  5,
    parameter DM_HaltAddress      = 32'h1A110800
) (
    
    input logic         clk_i,
    input logic         rst_ni,
    input logic         clock_en_i,
    input logic         test_en_i,
    
    input logic [31:0]  boot_addr_i,
    input logic         fetch_enable_i,
    input logic         core_id_i,
    input logic         cluster_id_i,
    input logic [N_EXT_PERF_COUNTERS-1:0] ext_perf_counters_i,    
    
    //Instruction memory interface
    output logic        instr_req_o,
    output logic [31:0] instr_addr_o,
    input logic         instr_gnt_i,
    input logic         instr_rvalid_i,
    input logic [31:0]  instr_rdata_i,
    
    //Data memory interface
    output logic        data_req_o,
    output logic [31:0] data_addr_o,
    output logic        data_we_o,            
    output logic [3:0]  data_be_o,
    output logic [31:0] data_wdata_o,
    input logic         data_gnt_i,
    input logic         data_rvalid_i,
    input logic [31:0]  data_rdata_i,
    
    //Interrupt interface
    input logic         irq_i,
    input logic [4:0]   irq_id_i,
    output logic        irq_ack_o,
    output logic [4:0]  irq_id_o,
    input logic         irq_sec_i,  //fixed to 1'b0
    
    //Debug interface
    input logic         debug_req_i
);

    //decoded control signals
    logic       c_auipc;
    logic       c_lui;
    logic       c_branch;
    logic       c_jal;
    logic       c_jalr;
    logic       c_load;
    logic       c_store;
    logic       c_regwrite;
    logic       c_alusrc;
    logic [5:0] c_alucont;
    
    logic [1:0] c_csr_op;
    logic       c_csr_imm;
    logic       c_readcsr;
    logic       c_writecsr;
    logic       c_regwrite_by_csr;
    
    logic       c_ecall;
    logic       c_wfi;
    logic       c_mret;
    
    logic       exc_illegal_instr;
    
    //Instruction pipeline
    logic [31:0]    instr_IF;
    
    //core control signals
    logic       stall;
    logic       flush;
    logic       irq_taken;
    
    //clock gating
    logic       clk, clock_en_n, clock_en_c;
    logic       sleep;
    
    //c extension
    logic       first_fetch;
    logic       id_ready;
    logic [31:0]    pc_IF;   
    logic       fetch_ready; 
    logic [31:0]    instr_ID_predecode, instr_ID, instr_decoded;
    logic       illegal_c_instr;
    logic       is_c_instr;
    logic       fetch_req;
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni)     clock_en_c  <= 1'b1;
        else            clock_en_c  <= clock_en_n;
    end
    
    assign clk  = clk_i & clock_en_c;
    
    
    
    always_ff @(posedge clk or negedge rst_ni)
    begin
        if(~rst_ni)                                 instr_ID_predecode    <= NOP;
        else if(~stall && ~sleep && fetch_ready)    instr_ID_predecode    <= instr_IF;
    end
    
    c_dec i_c_dec (
        .c_instr_i          (instr_ID_predecode[15:0]),
        .i_instr_o          (instr_decoded),
        .illegal_c_instr_o  (illegal_c_instr)
    );
    
    assign is_c_instr   = instr_ID_predecode[1:0] != 2'b11;
    assign instr_ID     = is_c_instr ? instr_decoded : instr_ID_predecode;
    assign instr_req_o  = fetch_req & id_ready;
    
    prefetcher i_prefetcher (
        .clk_i          (clk),
        .rst_ni         (rst_ni),
        
        .fetch_req_o    (fetch_req),
        .instr_rvalid_i (instr_rvalid_i),
        .instr_rdata_i  (instr_rdata_i),
        
        .fetch_addr_o   (pc_IF),
        .fetch_instr_o  (instr_IF),
        
        .first_fetch_i  (first_fetch),
        .id_ready_i     (id_ready),
        
        .instr_addr_i   (instr_addr_o),
        
        .flush_i        (flush),
        .stall_i        (stall),
        .sleep_i        (sleep),
        .fetch_ready_o  (fetch_ready)
    );
    
    //controller
    controller i_controller (
        .instr_rdata_i  (instr_ID),
        .irq_taken_i    (irq_taken),
        
        .c_auipc_o      (c_auipc),
        .c_lui_o        (c_lui),
        .c_branch_o     (c_branch),
        .c_jal_o        (c_jal),
        .c_jalr_o       (c_jalr),
        .c_load_o       (c_load),
        .c_store_o      (c_store),
        .c_regwrite_o   (c_regwrite),
        .c_alusrc_o     (c_alusrc),
        .c_alucont_o    (c_alucont),
        
        .c_csr_op_o     (c_csr_op),
        .c_csr_imm_o    (c_csr_imm),
        .c_readcsr_o    (c_readcsr),
        .c_writecsr_o   (c_writecsr),
        .c_regwrite_by_csr_o    (c_regwrite_by_csr),
        
        .c_ecall_o      (c_ecall),
        .c_wfi_o        (c_wfi),
        .c_mret_o       (c_mret),
        
        .exc_illegal_instr_o    (exc_illegal_instr)
    );
    
    datapath i_datapath (
        .clk_i          (clk),
        .rst_ni         (rst_ni),
        .fetch_en_i     (fetch_enable_i),
        .boot_addr_i    (boot_addr_i),
        
        .c_auipc_i      (c_auipc),   
        .c_lui_i        (c_lui),
        .c_branch_i     (c_branch),
        .c_jal_i        (c_jal),
        .c_jalr_i       (c_jalr),
        .c_load_i       (c_load),
        .c_store_i      (c_store),
        .c_regwrite_i   (c_regwrite),
        .c_alusrc_i     (c_alusrc),
        .c_alucont_i    (c_alucont),
        
        .c_csr_op_i     (c_csr_op),
        .c_csr_imm_i    (c_csr_imm),
        .c_readcsr_i    (c_readcsr),
        .c_writecsr_i   (c_writecsr),
        .c_regwrite_by_csr_i  (c_regwrite_by_csr),
        
        .c_ecall_i      (c_ecall),
        .c_wfi_i        (c_wfi),
        .c_mret_i       (c_mret),
        
        .instr_addr_o   (instr_addr_o),
        .instr_gnt_i    (instr_gnt_i),
        .instr_rvalid_i (instr_rvalid_i),
        .instr_rdata_i  (instr_ID),
        
        .data_req_o     (data_req_o),
        .data_addr_o    (data_addr_o),
        .data_we_o      (data_we_o),
        .data_be_o      (data_be_o),
        .data_wdata_o   (data_wdata_o),
        .data_gnt_i     (data_gnt_i),
        .data_rvalid_i  (data_rvalid_i),
        .data_rdata_i   (data_rdata_i),
        
        .stall_o        (stall), 
        .flush_o        (flush),
        
        .irq_i          (irq_i),
        .irq_id_i       (irq_id_i),
        .irq_ack_o      (irq_ack_o),
        .irq_id_o       (irq_id_o),  
        .irq_taken_o    (irq_taken),
        
        .exc_illegal_instr_i    (exc_illegal_instr),
        
        .clk_en_o       (clock_en_n),
        .sleep_o        (sleep),
        
        .first_fetch_o  (first_fetch),
        .id_ready_o     (id_ready),   
        .pc_IF_i        (pc_IF),
        .illegal_c_instr_i  (illegal_c_instr),
        .is_c_instr_i   (is_c_instr),
        .fetch_ready_i  (fetch_ready)
    );    
    
endmodule

module prefetcher (
    input logic         clk_i,
    input logic         rst_ni,
    
    output logic        fetch_req_o,   
    input logic         instr_rvalid_i,
    input logic [31:0]  instr_rdata_i, 
                  
    output logic [31:0]     fetch_addr_o,  
    output logic [31:0]     fetch_instr_o, 
                  
    input logic         first_fetch_i, 
    input logic         id_ready_i,    
                  
    input logic [31:0]  instr_addr_i,  
                  
    input logic         flush_i,       
    input logic         stall_i,       
    input logic         sleep_i,
    output logic        fetch_ready_o              
);

    logic           unaligned_is_c, aligned_is_c;
    logic [31:0]    fetch_addr_n, fetch_addr_c;
    logic [2:0]     valid_n, valid_c;
    logic [2:0][31:0]    buf_n, buf_c;
    logic [2:0]     empty_entry_pointer;
    logic [2:0]     enable_entry;
    logic           shift_buffer;
    logic           new_entry;
    logic           unaligned_valid;
    logic           fetch_unaligned;
    
    logic [31:0]    instr1;
    logic [31:0]    unaligned_instr;
        
    assign instr1           = valid_c[0] ? buf_c[0] : instr_rdata_i;
    assign unaligned_instr  = valid_c[1] ? {buf_c[1][15:0], instr1[31:16]} : {instr_rdata_i[15:0], instr1[31:16]};

    assign unaligned_is_c   = instr1[17:16] != 2'b11;
    assign aligned_is_c     = instr1[1:0] != 2'b11;
    
    assign valid_n[0]   = (valid_c[1] & shift_buffer) ? valid_c[1] : instr_rvalid_i;
    assign valid_n[1]   = (valid_c[2] & shift_buffer) ? valid_c[2] : instr_rvalid_i;
    assign valid_n[2]   = instr_rvalid_i;
    
    assign buf_n[0]     = (valid_c[1] & shift_buffer) ? buf_c[1] : instr_rdata_i;
    assign buf_n[1]     = (valid_c[2] & shift_buffer) ? buf_c[2] : instr_rdata_i;
    assign buf_n[2]     = instr_rdata_i;    
    
    assign empty_entry_pointer[0]   = ~valid_c[0];
    assign empty_entry_pointer[1]   = valid_c[0] & ~valid_c[1] & ~shift_buffer;
    assign empty_entry_pointer[2]   = valid_c[1] & ~valid_c[2] & ~shift_buffer;
    
    assign shift_buffer     = (~stall_i & ~sleep_i) & valid_c[0] & (~aligned_is_c | fetch_addr_c[1]);
    assign new_entry        = instr_rvalid_i & (stall_i | sleep_i | aligned_is_c | valid_c[0] | (fetch_unaligned & ~unaligned_valid));
    
    assign unaligned_valid  = unaligned_is_c ? 1'b1 : valid_c[1] ? 1'b1 : (valid_c[0] & instr_rvalid_i);
    assign fetch_unaligned  = fetch_addr_c[1] & ~valid_c[0];
    
    assign fetch_ready_o    = fetch_unaligned ? unaligned_valid : valid_c[0] ? 1'b1 : instr_rvalid_i;
    assign fetch_addr_n     = (first_fetch_i || flush_i) ? instr_addr_i : fetch_instr_o[1:0] != 2'b11 ? fetch_addr_c + 2 : fetch_addr_c + 4;
    assign fetch_addr_o     = fetch_addr_c;
    assign fetch_instr_o    = flush_i ? NOP : fetch_addr_o[1] ? unaligned_instr : instr1;
    
    assign fetch_req_o      = ~valid_c[1] | (~instr_rvalid_i & valid_c[1] & ~valid_c[2] & fetch_addr_c[1] & ~unaligned_is_c) | flush_i;
        
    assign enable_entry[0]  = (empty_entry_pointer[0] & new_entry & ~(fetch_unaligned &unaligned_valid)) | shift_buffer;
    assign enable_entry[1]  = (empty_entry_pointer[1] & new_entry) | (valid_c[1] & shift_buffer);
    assign enable_entry[2]  = (empty_entry_pointer[2] & new_entry) | (valid_c[2] & shift_buffer);
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni || flush_i) begin
            buf_c[0]    <= '0;
            valid_c[0]  <= 1'b0;
        end
        else if(enable_entry[0]) begin
            buf_c[0]    <= buf_n[0];
            valid_c[0]  <= valid_n[0];
        end
    end
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni || flush_i) begin
            buf_c[1]    <= '0;
            valid_c[1]  <= 1'b0;
        end
        else if(enable_entry[1]) begin
            buf_c[1]    <= buf_n[1];
            valid_c[1]  <= valid_n[1];
        end
    end
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni || flush_i) begin
            buf_c[2]    <= '0;
            valid_c[2]  <= 1'b0;
        end
        else if(enable_entry[2]) begin
            buf_c[2]    <= buf_n[2];
            valid_c[2]  <= valid_n[2];
        end
    end
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni) begin
            fetch_addr_c    <= '0;
        end
        else if(first_fetch_i || (id_ready_i && ~stall_i && ~sleep_i && fetch_ready_o)) begin
            fetch_addr_c    <= fetch_addr_n;
        end
    end

endmodule

module c_dec (
    input logic [15:0]  c_instr_i,
    output logic [31:0] i_instr_o,
    output logic        illegal_c_instr_o
);

    logic   is_c;
    logic   illegal_c_instr;
    
    assign is_c = c_instr_i[1:0] != 2'b11;
    assign illegal_c_instr_o  = is_c && illegal_c_instr;

    always_comb
    begin
        illegal_c_instr = 1'b0;
        
        case(c_instr_i[1:0])
            2'b00: begin
                case(c_instr_i[15:13])
                    3'b000: begin
                        if(c_instr_i[12:5] == '0) begin
                            illegal_c_instr = 1'b1;
                            i_instr_o   = {16'b0, c_instr_i};
                        end
                        else begin
                            illegal_c_instr = 1'b0;
                            i_instr_o   = {2'b00, c_instr_i[10:7], c_instr_i[12:11], c_instr_i[5], c_instr_i[6], 2'b00, 5'h02, 3'b000, 2'b01, c_instr_i[4:2], OP_I};
                        end                       
                    end
                    3'b010: begin
                        illegal_c_instr = 1'b0;
                        i_instr_o   = {5'b0, c_instr_i[5], c_instr_i[12:10], c_instr_i[6], 2'b00, 2'b01, c_instr_i[9:7], 3'b010, 2'b01, c_instr_i[4:2], OP_LOAD};
                    end
                    3'b110: begin
                        illegal_c_instr = 1'b0;
                        i_instr_o   = {5'b0, c_instr_i[5], c_instr_i[12], 2'b01, c_instr_i[4:2], 2'b01, c_instr_i[9:7], 3'b010, c_instr_i[11:10], c_instr_i[6], 2'b00, OP_STORE};
                    end
                    default: begin
                        illegal_c_instr = 1'b1;
                        i_instr_o   = {16'b0, c_instr_i};
                    end
                endcase
            end
            2'b01: begin
                case(c_instr_i[15:13])
                    3'b000: begin
                        if(c_instr_i[11:7] == 5'b0) begin
                            i_instr_o   = NOP;
                        end
                        else begin
                            i_instr_o   = {{7{c_instr_i[12]}}, c_instr_i[6:2], c_instr_i[11:7], 3'b000, c_instr_i[11:7], OP_I};
                        end
                        
                        illegal_c_instr = 1'b0;
                    end
                    3'b001: begin
                        illegal_c_instr = 1'b0;
                        i_instr_o   = {c_instr_i[12], c_instr_i[8], c_instr_i[10:9], c_instr_i[6], c_instr_i[7], c_instr_i[2], c_instr_i[11], c_instr_i[5:3], {9{c_instr_i[12]}}, 5'b00001, OP_JAL};
                    end
                    3'b010: begin
                        if(c_instr_i[11:7] == 5'b0) begin
                            i_instr_o   = NOP;
                        end
                        else begin
                            i_instr_o   = {{7{c_instr_i[12]}}, c_instr_i[6:2], 5'b0, 3'b000, c_instr_i[11:7], OP_I};
                        end
                        
                        illegal_c_instr = 1'b0;
                    end
                    3'b011: begin
                        illegal_c_instr = 1'b0;
                        
                        if(c_instr_i[11:7] == 5'b0) begin
                            i_instr_o   = NOP;
                        end
                        else if(c_instr_i[11:7] == 5'h02) begin
                            i_instr_o   = {{3{c_instr_i[12]}}, c_instr_i[4:3], c_instr_i[5], c_instr_i[2], c_instr_i[6], 4'b0, 5'h02, 3'b000, 5'h02, OP_I};
                            if({c_instr_i[12], c_instr_i[6:2]} == '0) illegal_c_instr   = 1'b1;
                        end
                        else begin
                            i_instr_o   = {{15{c_instr_i[12]}}, c_instr_i[6:2], c_instr_i[11:7], OP_LUI};
                            if({c_instr_i[12], c_instr_i[6:2]} == '0) illegal_c_instr   = 1'b1;
                        end
                    end
                    3'b100: begin
                        illegal_c_instr = 1'b0;
                        case(c_instr_i[11:10])
                            2'b00: begin
                                i_instr_o   = {7'b0, c_instr_i[6:2], 2'b01, c_instr_i[9:7], 3'b101, 2'b01, c_instr_i[9:7], OP_I};
                                if(c_instr_i[12] == 1'b1 || c_instr_i[6:2] == '0) illegal_c_instr   = 1'b1;
                            end
                            2'b01: begin
                                i_instr_o   = {1'b0, 1'b1, 5'b0, c_instr_i[6:2], 2'b01, c_instr_i[9:7], 3'b101, 2'b01, c_instr_i[9:7], OP_I};
                                if(c_instr_i[12] == 1'b1 || c_instr_i[6:2] == '0) illegal_c_instr   = 1'b1;
                            end
                            2'b10: begin
                                i_instr_o   = {{7{c_instr_i[12]}}, c_instr_i[6:2], 2'b01, c_instr_i[9:7], 3'b111, 2'b01, c_instr_i[9:7], OP_I};
                            end
                            2'b11: begin
                                case(c_instr_i[6:5])
                                    2'b00: begin
                                        i_instr_o   = {1'b0, 1'b1, 5'b0, 2'b01, c_instr_i[4:2], 2'b01, c_instr_i[9:7], 3'b000, 2'b01, c_instr_i[9:7], OP_R};
                                    end
                                    2'b01: begin
                                        i_instr_o   = {7'b0, 2'b01, c_instr_i[4:2], 2'b01, c_instr_i[9:7], 3'b100, 2'b01, c_instr_i[9:7], OP_R};
                                    end
                                    2'b10: begin
                                        i_instr_o   = {7'b0, 2'b01, c_instr_i[4:2], 2'b01, c_instr_i[9:7], 3'b110, 2'b01, c_instr_i[9:7], OP_R};
                                    end
                                    2'b11: begin
                                        i_instr_o   = {7'b0, 2'b01, c_instr_i[4:2], 2'b01, c_instr_i[9:7], 3'b111, 2'b01, c_instr_i[9:7], OP_R};
                                    end
                                endcase
                                
                                if(c_instr_i[12] == 1'b1)   illegal_c_instr = 1'b1;
                            end
                        endcase
                    end
                    3'b101: begin
                        illegal_c_instr = 1'b0;
                        i_instr_o   = {c_instr_i[12], c_instr_i[8], c_instr_i[10:9], c_instr_i[6], c_instr_i[7], c_instr_i[2], c_instr_i[11], c_instr_i[5:3], {9{c_instr_i[12]}}, 5'b00000, OP_JAL};
                    end
                    3'b110: begin
                        illegal_c_instr = 1'b0;
                        i_instr_o   = {{4{c_instr_i[12]}}, c_instr_i[6:5], c_instr_i[2], 5'b0, 2'b01, c_instr_i[9:7], 3'b000, c_instr_i[11:10], c_instr_i[4:3], c_instr_i[12], OP_B};
                    end
                    3'b111: begin
                        illegal_c_instr = 1'b0;
                        i_instr_o   = {{4{c_instr_i[12]}}, c_instr_i[6:5], c_instr_i[2], 5'b0, 2'b01, c_instr_i[9:7], 3'b001, c_instr_i[11:10], c_instr_i[4:3], c_instr_i[12], OP_B};
                    end
                endcase
            end
            2'b10: begin
                case(c_instr_i[15:13])
                    3'b000: begin
                        i_instr_o   = {7'b0, c_instr_i[6:2], c_instr_i[11:7], 3'b001, c_instr_i[11:7], OP_I};
                        if(c_instr_i[12] == 1'b1 || c_instr_i[6:2] == '0) illegal_c_instr   = 1'b1;
                    end
                    3'b010: begin
                        if(c_instr_i[11:7] == '0) illegal_c_instr   = 1'b1;
                        i_instr_o   = {4'b0, c_instr_i[3:2], c_instr_i[12], c_instr_i[6:4], 2'b00,  5'h02, 3'b010, c_instr_i[11:7], OP_LOAD};
                    end
                    3'b100: begin
                        if(c_instr_i[12] == 1'b0) begin
                            if(c_instr_i[11:2] == '0) begin
                                illegal_c_instr = 1'b1;
                                i_instr_o   = {16'b0, c_instr_i};
                            end
                            else if(c_instr_i[6:2] == '0) begin
                                i_instr_o   = {12'b0, c_instr_i[11:7], 3'b000, 5'b0, OP_JALR};
                            end
                            else begin
                                i_instr_o   = {7'b0, c_instr_i[6:2], 5'b0, 3'b000, c_instr_i[11:7], OP_R};
                            end
                        end
                        else begin
                            if(c_instr_i[11:2] == '0) begin
                                i_instr_o   = NOP;
                            end
                            else if(c_instr_i[6:2] == '0) begin
                                i_instr_o   = {12'b0, c_instr_i[11:7], 3'b000, 5'h01, OP_JALR};
                            end
                            else begin
                                i_instr_o   = {7'b0, c_instr_i[6:2], c_instr_i[11:7], 3'b000, c_instr_i[11:7], OP_R};
                            end
                        end
                    end
                    3'b110: begin
                        i_instr_o   = {4'b0, c_instr_i[8:7], c_instr_i[12], c_instr_i[6:2], 5'h02, 3'b010, c_instr_i[11:9], 2'b00, OP_STORE};
                    end
                    default: begin
                        i_instr_o   = {16'b0, c_instr_i};
                        illegal_c_instr = 1'b1;
                    end
                endcase
            end
            default: begin
                i_instr_o   = 32'b0;
                illegal_c_instr = 1'b1;
            end
        endcase
    end

endmodule

module controller (
    input logic [31:0]  instr_rdata_i,
    input logic         irq_taken_i,
    
    output logic        c_auipc_o,
    output logic        c_lui_o,
    output logic        c_branch_o,
    output logic        c_jal_o,
    output logic        c_jalr_o,
    output logic        c_load_o,
    output logic        c_store_o,
    output logic        c_regwrite_o,
    output logic        c_alusrc_o,
    
    output logic [5:0]  c_alucont_o,
    
    //priv instruction
    output logic [1:0]  c_csr_op_o,
    output logic        c_csr_imm_o,
    output logic        c_readcsr_o,    //read csr value
    output logic        c_writecsr_o,   //write to csr
    output logic        c_regwrite_by_csr_o,
    
    output logic        c_ecall_o,
    output logic        c_wfi_o,
    output logic        c_mret_o,
    
    output logic        exc_illegal_instr_o
);

    logic [6:0]     opcode, funct7;
    logic [2:0]     funct3;
    logic [11:0]    funct12;
    
    logic [8:0]     controls;
    logic [5:0]     alucontrols;
    logic [6:0]     csr_controls;
    
    assign {c_auipc_o, c_lui_o, c_branch_o, c_jal_o, c_jalr_o, c_load_o, c_store_o, c_regwrite_o, c_alusrc_o} = irq_taken_i ? 9'b0 : controls;
    assign {c_ecall_o, c_wfi_o, c_mret_o, c_regwrite_by_csr_o, c_csr_imm_o, c_csr_op_o} = irq_taken_i ? 7'b0 : csr_controls;
    assign c_alucont_o  = irq_taken_i ? 5'b0 : alucontrols;
    
    assign opcode   = instr_rdata_i[6:0];
    assign funct3   = instr_rdata_i[14:12];
    assign funct7   = instr_rdata_i[31:25];
    assign funct12  = instr_rdata_i[31:20];
    
    //main rv32i controller
    always_comb
    begin
        case(opcode)
            OP_R:       controls = 9'b0_0000_0010;
            OP_I:       controls = 9'b0_0000_0011;
            OP_B:       controls = 9'b0_0100_0000;
            OP_LOAD:    controls = 9'b0_0000_1011;
            OP_STORE:   controls = 9'b0_0000_0101;
            OP_LUI:     controls = 9'b0_1000_0011;
            OP_JAL:     controls = 9'b0_0010_0011;
            OP_JALR:    controls = 9'b0_0001_0011;
            OP_AUIPC:   controls = 9'b1_0000_0011;
            FENCE:      controls = 9'b0_0000_0000;  //NOP
            default:    controls = 9'b0_0000_0000;
        endcase
    end
     
    //alu operation controller
    always_comb
    begin
        case(opcode)
            OP_R: begin
                if(funct7 == 7'b000_0001) begin
                    case(funct3)
                        3'b000: alucontrols = 6'b00_0000;   //mul
                        3'b001: alucontrols = 6'b00_0001;   //mulh
                        3'b010: alucontrols = 6'b00_0010;   //mulhsu
                        3'b011: alucontrols = 6'b00_0011;   //mulhu
                        3'b100: alucontrols = 6'b00_0100;   //div
                        3'b101: alucontrols = 6'b00_0101;   //divu
                        3'b110: alucontrols = 6'b00_0110;   //rem
                        3'b111: alucontrols = 6'b00_0111;   //remu
                    endcase
                end
                else begin
                    case(funct3)
                        3'b000: begin
                            if(funct7 == 7'b010_0000)
                                alucontrols = 6'b11_0000;    //sub
                            else
                                alucontrols = 6'b10_0000;    //add
                        end
                        3'b001: alucontrols = 6'b10_0100;    //sll
                        3'b010: alucontrols = 6'b11_0111;    //slt
                        3'b011: alucontrols = 6'b11_1000;    //sltu
                        3'b100: alucontrols = 6'b10_0011;    //xor
                        3'b101: begin
                            if(funct7 == 7'b010_0000)
                                alucontrols = 6'b10_0110;    //sra
                            else
                                alucontrols = 6'b10_0101;    //srl
                        end
                        3'b110: alucontrols = 6'b10_0010;    //or
                        3'b111: alucontrols = 6'b10_0001;    //and
                    endcase
                end
            end
            OP_I: begin
                case(funct3)
                    3'b000: alucontrols = 6'b10_0000;    //addi
                    3'b001: alucontrols = 6'b10_0100;    //slli
                    3'b010: alucontrols = 6'b11_0111;    //slti
                    3'b011: alucontrols = 6'b11_1000;    //sltiu
                    3'b100: alucontrols = 6'b10_0011;    //xori
                    3'b101: begin
                        if(funct7 == 7'b010_0000)
                            alucontrols = 6'b10_0110;    //srai
                        else
                            alucontrols = 6'b10_0101;    //srli
                    end
                    3'b110: alucontrols = 6'b10_0010;    //ori
                    3'b111: alucontrols = 6'b10_0001;    //andi
                endcase
            end
            OP_B:           alucontrols = 6'b11_0000;
            OP_LOAD:        alucontrols = 6'b10_0000;
            OP_STORE:       alucontrols = 6'b10_0000;
            OP_LUI:         alucontrols = 6'b10_0000;
            OP_JAL:         alucontrols = 6'b10_0000;
            OP_JALR:        alucontrols = 6'b10_0000;
            OP_AUIPC:       alucontrols = 6'b10_0000;
            default:        alucontrols = 6'b10_0000;    //OP_SYSTEM : ALU use x 
        endcase
    end
    
    //system instruction
    always_comb
    begin
        if(opcode == OP_SYSTEM) begin
            case(funct3)
                3'b000: begin   //privileged instruction
                    if(funct12 == ECALL || funct12 == EBREAK)
                        csr_controls = 7'b100_0000;
                    else if(funct12 == WFI)
                        csr_controls = 7'b010_0000;
                    else if(funct12 == MRET)
                        csr_controls = 7'b001_0000;
                    else
                        csr_controls = 7'b000_0000;
                end
                3'b001, 3'b101,
                3'b010, 3'b110,
                3'b011, 3'b111: //csr instruction
                        csr_controls = {4'b0001, funct3};
                default: csr_controls = 7'b000_0000;
            endcase
        end
        else begin
            csr_controls    = 7'b000_0000;
        end
    end
    
    always_comb
    begin
        case(c_csr_op_o)
            2'b01: begin    //RW
                c_writecsr_o    = 1'b1;
                
                if(instr_rdata_i[11:7] == 5'b0) //rd==x0 -> no csr read
                    c_readcsr_o = 1'b0;
                else
                    c_readcsr_o = 1'b1;
            end
            2'b10, 2'b11: begin //RS, RC
                c_readcsr_o     = 1'b1;
                
                if(instr_rdata_i[19:15] == 5'b0)    //rs1==x0 -> no csr write
                    c_writecsr_o    = 1'b0;
                else
                    c_writecsr_o    = 1'b1;
            end
            default: begin
                c_writecsr_o    = 1'b0;
                c_readcsr_o     = 1'b0;
            end
        endcase
    end

    //exception: illegal instruction
    always_comb
    begin
        case(opcode)
            OP_R: begin
                if(funct7 == 7'b000_0001 || funct7 == 7'b000_0000) begin
                    exc_illegal_instr_o     = 1'b0;
                end
                else if(funct7 == 7'b010_0000) begin
                    if(funct3 == 3'b000 || funct3 == 3'b101) begin
                        exc_illegal_instr_o = 1'b0;
                    end
                    else begin
                        exc_illegal_instr_o = 1'b1;
                    end
                end
                else begin
                    exc_illegal_instr_o     = 1'b1;
                end
            end
            OP_I: begin
                case(funct3)
                    3'b001: begin
                        if(funct7 == 7'b0) begin
                            exc_illegal_instr_o = 1'b0;
                        end
                        else begin
                            exc_illegal_instr_o = 1'b1;
                        end
                    end
                    3'b101: begin
                        if(funct7 == 7'b0 || funct7 == 7'b0100000) begin
                            exc_illegal_instr_o = 1'b0;
                        end
                        else begin
                            exc_illegal_instr_o = 1'b1;
                        end
                    end
                    default: begin
                        exc_illegal_instr_o = 1'b0;
                    end
                endcase
            end
            OP_B: begin
                if(funct3 == 3'b010 || funct3 == 3'b011) begin
                    exc_illegal_instr_o = 1'b1;
                end
                else begin
                    exc_illegal_instr_o = 1'b0;
                end
            end
            OP_LOAD: begin
                if(funct3 == 3'b011 || funct3 == 3'b110 || funct3 == 3'b111) begin
                    exc_illegal_instr_o = 1'b1;
                end
                else begin
                    exc_illegal_instr_o = 1'b0;
                end
            end
            OP_STORE: begin
                if(funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010) begin
                    exc_illegal_instr_o = 1'b0;
                end
                else begin
                    exc_illegal_instr_o = 1'b1;
                end
            end
            OP_LUI: begin
                exc_illegal_instr_o = 1'b0;
            end
            OP_JAL: begin
                exc_illegal_instr_o = 1'b0;
            end
            OP_JALR: begin
                if(funct3 == 3'b000) begin
                    exc_illegal_instr_o = 1'b0;
                end
                else begin
                    exc_illegal_instr_o = 1'b1;
                end
            end
            OP_AUIPC: begin
                exc_illegal_instr_o = 1'b0;
            end
            OP_SYSTEM: begin
                if(funct3 == 3'b000) begin
                    if(instr_rdata_i[19:15] == 5'b0 && instr_rdata_i[11:7] == 5'b0) begin
                        exc_illegal_instr_o = 1'b0;
                    end
                    else begin
                        exc_illegal_instr_o = 1'b1;
                    end
                end
                else if(funct3 == 3'b100) begin
                    exc_illegal_instr_o = 1'b1;
                end
                else begin
                    if(funct12 == MSTATUS || funct12 == MISA || funct12 == MTVEC || funct12 == MEPC || funct12 == MCAUSE) begin
                        exc_illegal_instr_o = 1'b0;
                    end
                    else begin
                        exc_illegal_instr_o = 1'b1;
                    end
                end
            end
            default: begin
                exc_illegal_instr_o = 1'b1;
            end
        endcase
    end

endmodule

module datapath (
    input logic         clk_i,
    input logic         rst_ni,
    input logic         fetch_en_i,
    input logic [31:0]  boot_addr_i,
    
    input logic         c_auipc_i,
    input logic         c_lui_i,
    input logic         c_branch_i,
    input logic         c_jal_i,
    input logic         c_jalr_i,
    input logic         c_load_i,
    input logic         c_store_i,
    input logic         c_regwrite_i,
    input logic         c_alusrc_i,
    input logic [5:0]   c_alucont_i,
    
    input logic [1:0]   c_csr_op_i,
    input logic         c_csr_imm_i,
    input logic         c_readcsr_i,
    input logic         c_writecsr_i,
    input logic         c_regwrite_by_csr_i,
    
    input logic         c_ecall_i,
    input logic         c_wfi_i,
    input logic         c_mret_i,
    
    output logic [31:0] instr_addr_o,
    input logic         instr_gnt_i,
    input logic         instr_rvalid_i,
    input logic [31:0]  instr_rdata_i,
    
    output logic        data_req_o,
    output logic [31:0] data_addr_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    output logic [31:0] data_wdata_o,
    input logic         data_gnt_i,
    input logic         data_rvalid_i,
    input logic [31:0]  data_rdata_i,
    
    output logic        stall_o,
    output logic        flush_o,
    
    input logic         irq_i,
    input logic [4:0]   irq_id_i,
    output logic        irq_ack_o,
    output logic [4:0]  irq_id_o,
    output logic        irq_taken_o,
    
    input logic         exc_illegal_instr_i,
    
    output logic        clk_en_o,
    output logic        sleep_o,
    
    output logic        first_fetch_o,
    output logic        id_ready_o,
    input logic [31:0]  pc_IF_i,
    input logic         illegal_c_instr_i,
    input logic         is_c_instr_i,
    input logic         fetch_ready_i       
);

    logic [4:0]     rs1;
    logic [4:0]     rs2;
    logic [4:0]     rd;
    logic [2:0]     funct3;
    logic [31:0]    rs1_rdata;
    logic [31:0]    rs2_rdata;
    logic [31:0]    rd_data;
    logic           c_regwrite;
    
    logic [11:0]    csr_address;
    logic [31:0]    csr_wdata, csr_rdata;
    logic [31:0]    mtvec, mepc;
    logic [5:0]     mcause;
    
    logic [31:0]    imm_jal;
    logic [31:0]    imm_b;
    logic [31:0]    imm_i;
    logic [31:0]    imm_s;
    logic [31:0]    imm_u;
    logic [31:0]    imm_csr;
    
    logic [31:0]    branch_dest;
    logic           branch_taken;
    logic [31:0]    jump_dest;
    
    logic [31:0]    alusrc1;
    logic [31:0]    alusrc2;
    logic [31:0]    aluout;
    logic           Nflag, Zflag, Cflag, Vflag;
    logic           div_ready;
    
    logic [3:0]     data_be;
    logic [1:0]     data_byte_offset;
    logic [31:0]    data_rdata_valid;   //valid rdata
    logic [31:0]    data_rdata_se;      //sign-extended rdata
    logic [31:0]    data_wdata_aligned; //byte aligned wdata
    
    logic [31:0]    pc_next, pcplus4, pc_ID;
    logic [31:0]    irq_addr;           //jump to irq vector
    enum logic [2:0] {RESET, BOOT, RUN, STALLED, IRQ_TAKEN, IRQ_DONE, SLEEP}  pc_stat_n, pc_stat_c;
    
    enum logic [1:0] {IDLE, WAIT_DATA_GNT, WAIT_DATA_RVALID}    data_stat_n, data_stat_c;
    
    logic           stall_waiting_data, stall_waiting_instr;
    
    logic           irq_enable;   
    logic           irq_done;
    
    logic           exc_misaligned_instr;
    logic           exc_taken;
    logic [4:0]     exc_id;
    logic [31:0]    exception_pc;
    
    logic           id_ready;
        
    assign rs1  = instr_rdata_i[19:15];
    assign rs2  = instr_rdata_i[24:20];
    assign rd   = instr_rdata_i[11:7];
    assign funct3   = instr_rdata_i[14:12];
    assign csr_address  = instr_rdata_i[31:20];
    
    assign imm_jal  = {{11{instr_rdata_i[31]}}, instr_rdata_i[31], instr_rdata_i[19:12], instr_rdata_i[20], instr_rdata_i[30:21], 1'b0};
    assign imm_b    = {{19{instr_rdata_i[31]}}, instr_rdata_i[31], instr_rdata_i[7], instr_rdata_i[30:25], instr_rdata_i[11:8], 1'b0};
    assign imm_i    = {{20{instr_rdata_i[31]}}, instr_rdata_i[31:20]};
    assign imm_s    = {{20{instr_rdata_i[31]}}, instr_rdata_i[31:25], instr_rdata_i[11:7]};
    assign imm_u    = {instr_rdata_i[31:12], 12'b0};
    assign imm_csr  = {27'b0, instr_rdata_i[19:15]};
    
    assign branch_dest  = pc_ID + imm_b;
    assign jump_dest    = pc_ID + imm_jal;
    assign irq_addr     = (irq_taken_o == 1'b1) ? {mtvec[31:8], 1'b0, irq_id_i, 2'b00} : (exc_taken == 1'b1) ? {mtvec[31:8], 8'b0} : '0;
    
    
    //Instruction logic
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni)     pc_stat_c   <= RESET;
        else            pc_stat_c   <= pc_stat_n;
    end
        
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni)             pcplus4 <= '0;
        else if(instr_gnt_i)    pcplus4 <= pc_next + 4;
    end
        
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni)     pc_ID   <= '0;
        else if(~stall_o && ~flush_o && ~sleep_o && fetch_ready_i)   pc_ID   <= pc_IF_i;
    end
    
    always_comb
    begin
        unique case(pc_stat_c)
            RESET: begin
                if(fetch_en_i)
                    pc_stat_n   = BOOT;
                else
                    pc_stat_n   = RESET;
            end
            BOOT: begin 
                if(instr_gnt_i)
                    pc_stat_n   = RUN;
                else
                    pc_stat_n   = BOOT;
            end
            RUN: begin
                if(irq_taken_o || exc_taken)
                    pc_stat_n   = IRQ_TAKEN;
                else if(c_mret_i)
                    pc_stat_n   = IRQ_DONE;
                else if(c_wfi_i)
                    pc_stat_n   = SLEEP;
                else if(stall_o)
                    pc_stat_n   = STALLED;
                else begin
                        pc_stat_n   = RUN;
                end
            end
            STALLED: begin
                if(irq_taken_o)
                    pc_stat_n   = IRQ_TAKEN;
                else if(~stall_o) begin
                        pc_stat_n   = RUN;
                end
                else
                    pc_stat_n   = STALLED; 
            end
            IRQ_TAKEN: begin
                if(fetch_ready_i) begin
                    pc_stat_n   = RUN;
                end
                else begin
                    pc_stat_n   = IRQ_TAKEN;
                end
            end
            IRQ_DONE: begin
                if(fetch_ready_i) begin
                    pc_stat_n   = RUN;
                end
                else begin
                    pc_stat_n   = IRQ_DONE;
                end
            end
            SLEEP: begin
                if(irq_taken_o)   
                    pc_stat_n   = IRQ_TAKEN;
                else if(irq_i)
                    pc_stat_n   = RUN;
                else
                    pc_stat_n   = SLEEP;
            end
            default: begin
                pc_stat_n   = pc_stat_c;
            end
        endcase
    end
    
    assign first_fetch_o    = pc_stat_c == BOOT ? 1'b1 : 1'b0;
    
    assign id_ready_o   = id_ready;

    always_comb
    begin
        unique case(pc_stat_c)
            RESET: begin
                pc_next     = '0;
                id_ready = 1'b0;
            end
            BOOT: begin
                pc_next     = boot_addr_i;
                id_ready = 1'b1;
            end
            RUN: begin
                if(irq_taken_o || exc_taken)  pc_next = irq_addr;
                else if(branch_taken)       pc_next = branch_dest;
                else if(c_jal_i)            pc_next = jump_dest;
                else if(c_jalr_i)           pc_next = aluout;
                else if(c_mret_i)           pc_next = mepc;
                else                        pc_next = pcplus4;
                
                id_ready = 1'b1;
            end
            STALLED: begin
                if(irq_taken_o)     pc_next = irq_addr;
                else                pc_next = pcplus4;
                
                id_ready    = 1'b1;
            end
            IRQ_TAKEN: begin
                pc_next     = pcplus4;
                id_ready    = 1'b1;
            end
            IRQ_DONE: begin
                pc_next     = pcplus4;
                id_ready    = 1'b1;
            end
            SLEEP: begin
                if(irq_taken_o) begin
                    pc_next     = irq_addr;
                    id_ready    = 1'b1;
                end
                else if(irq_i) begin
                    pc_next     = pcplus4;
                    id_ready    = 1'b1;
                end
                else begin
                    pc_next     = pc_IF_i;
                    id_ready    = 1'b0;
                end
            end
            default: begin
                pc_next     = pc_IF_i;
                id_ready    = 1'b0;
            end
        endcase
    end
    
    assign instr_addr_o = pc_next;
    
    //Data logic
    
    //byte enable logic
    assign data_byte_offset     = aluout[1:0];  //mem address alignment
    
    always_comb
    begin
        case(funct3[1:0])
            2'b00: begin    //byte
                case(data_byte_offset)
                    2'b00:      data_be = 4'b0001;
                    2'b01:      data_be = 4'b0010;
                    2'b10:      data_be = 4'b0100;
                    2'b11:      data_be = 4'b1000;
                endcase
            end
            2'b01: begin    //half-word
                case(data_byte_offset)
                    2'b00:      data_be = 4'b0011;
                    2'b10:      data_be = 4'b1100;
                    default:    data_be = 4'b0000;
                endcase
            end
            2'b10: begin    //word
                        data_be = 4'b1111;
            end
            default:    data_be    = 4'b0000;
        endcase
    end
    
    //data alignment logic
    always_comb
    begin
        case(funct3[1:0])
            2'b00: begin    //sb
                case(data_byte_offset)
                    2'b00:  data_wdata_aligned  = {24'b0, rs2_rdata[7:0]};
                    2'b01:  data_wdata_aligned  = {16'b0, rs2_rdata[7:0], 8'b0};
                    2'b10: data_wdata_aligned   = {8'b0, rs2_rdata[7:0], 16'b0};
                    2'B11: data_wdata_aligned   = {rs2_rdata[7:0], 24'b0};
                endcase
            end
            2'b01: begin    //sh
                case(data_byte_offset)
                    2'b00: data_wdata_aligned   = {16'b0, rs2_rdata[15:0]};
                    2'b10: data_wdata_aligned   = {rs2_rdata[15:0], 16'b0};
                endcase
            end
            2'b10: begin    //sw
                        data_wdata_aligned      = rs2_rdata;
            end
            default:    data_wdata_aligned = '0;
        endcase
    end
    
    //data sign-extension
    assign data_rdata_valid = data_rvalid_i ? data_rdata_i : '0;
    
    always_comb
    begin
        case(funct3)
            3'b000: begin   //signed byte
                case(data_byte_offset)
                    2'b00:      data_rdata_se   = {{24{data_rdata_valid[7]}}, data_rdata_valid[7:0]};
                    2'b01:      data_rdata_se   = {{24{data_rdata_valid[15]}}, data_rdata_valid[15:8]};
                    2'b10:      data_rdata_se   = {{24{data_rdata_valid[23]}}, data_rdata_valid[23:16]};
                    2'b11:      data_rdata_se   = {{24{data_rdata_valid[31]}}, data_rdata_valid[31:24]};
                endcase
            end
            3'b100: begin   //unsigned byte
                case(data_byte_offset)
                    2'b00:      data_rdata_se   = {24'b0, data_rdata_valid[7:0]};
                    2'b01:      data_rdata_se   = {24'b0, data_rdata_valid[15:8]};
                    2'b10:      data_rdata_se   = {24'b0, data_rdata_valid[23:16]};
                    2'b11:      data_rdata_se   = {24'b0, data_rdata_valid[31:24]};
                endcase
            end
            3'b001: begin   //signed half-word
                case(data_byte_offset)
                    2'b00:      data_rdata_se   = {{24{data_rdata_valid[15]}}, data_rdata_valid[15:0]};
                    2'b10:      data_rdata_se   = {{24{data_rdata_valid[31]}}, data_rdata_valid[31:16]};
                    default:    data_rdata_se   = {{24{data_rdata_valid[15]}}, data_rdata_valid[15:0]};
                endcase
            end
            3'b101: begin   //unsigned half-word
                case(data_byte_offset)
                    2'b00:      data_rdata_se   = {24'b0, data_rdata_valid[15:0]};
                    2'b10:      data_rdata_se   = {24'b0, data_rdata_valid[31:16]};
                    default:    data_rdata_se   = {24'b0, data_rdata_valid[15:0]};
                endcase
            end
            3'b010:         data_rdata_se   = data_rdata_valid;     //word
            default:        data_rdata_se   = data_rdata_valid;
        endcase
    end
    
    always_ff @(posedge clk_i or negedge rst_ni)
    begin
        if(~rst_ni)     data_stat_c <= IDLE;
        else            data_stat_c <= data_stat_n;
    end
    
    always_comb
    begin
        unique case(data_stat_c)
            IDLE: begin
                if(c_store_i) begin
                    if(data_gnt_i)
                        data_stat_n = IDLE;
                    else
                        data_stat_n = WAIT_DATA_GNT;
                end
                else if(c_load_i) begin
                    if(data_gnt_i)
                        data_stat_n = WAIT_DATA_RVALID;
                    else
                        data_stat_n = WAIT_DATA_GNT;
                end
                else    data_stat_n = IDLE;
            end
            WAIT_DATA_GNT: begin
                if(irq_taken_o)
                    data_stat_n = IDLE;
                else if(data_gnt_i) begin   
                    if(c_store_i)
                        data_stat_n = IDLE;
                    else
                        data_stat_n = WAIT_DATA_RVALID;
                end
                else
                    data_stat_n = WAIT_DATA_GNT;
            end
            WAIT_DATA_RVALID: begin
                if(irq_taken_o)
                    data_stat_n = IDLE;
                else if(data_rvalid_i)
                    data_stat_n = IDLE;
                else
                    data_stat_n = WAIT_DATA_RVALID;
            end
            default: begin
                data_stat_n = data_stat_c;
            end
        endcase
    end
    
    always_comb
    begin
        unique case(data_stat_c)
            IDLE: begin
                if(c_store_i) begin
                    data_req_o      = 1'b1;
                    data_addr_o     = aluout;
                    data_we_o       = 1'b1;
                    data_be_o       = data_be;
                    data_wdata_o    = data_wdata_aligned;
                end
                else if(c_load_i) begin
                    data_req_o      = 1'b1;
                    data_addr_o     = aluout;
                    data_we_o       = 1'b0;
                    data_be_o       = data_be;
                    data_wdata_o    = '0;
                end
                else begin
                    data_req_o      = 1'b0;
                    data_addr_o     = '0;
                    data_we_o       = 1'b0;
                    data_be_o       = '0;
                    data_wdata_o    = '0;
                end
            end
            WAIT_DATA_GNT: begin
                if(c_store_i) begin
                    data_req_o      = 1'b1;
                    data_addr_o     = aluout;
                    data_we_o       = 1'b1;
                    data_be_o       = data_be;
                    data_wdata_o    = data_wdata_aligned;
                end
                else begin
                    data_req_o      = 1'b1;
                    data_addr_o     = aluout;
                    data_we_o       = 1'b0;
                    data_be_o       = data_be;
                    data_wdata_o    = '0;
                end
            end
            WAIT_DATA_RVALID: begin
                data_req_o      = 1'b0;
                data_addr_o     = aluout;
                data_we_o       = 1'b0;
                data_be_o       = data_be;
                data_wdata_o    = '0;
            end
            default: begin
                data_req_o      = 1'b0;
                data_addr_o     = '0;
                data_we_o       = 1'b0;
                data_be_o       = '0;
                data_wdata_o    = '0;
            end
        endcase
    end
    
    //IRQ
    assign irq_taken_o  = (irq_i & irq_enable);
    assign irq_done     = (pc_stat_c == IRQ_DONE);
    
    always_comb
    begin
        if(pc_stat_c == IRQ_TAKEN) begin
            irq_ack_o   = 1'b1;
            irq_id_o    = irq_id_i;
        end
        else begin
            irq_ack_o   = 1'b0;
            irq_id_o    = '0;
        end
    end
    
    assign exc_misaligned_instr = (c_jal_i && jump_dest[0] != 1'b0) || (c_jalr_i && aluout[0] != 1'b0) || (branch_taken && branch_dest[0] != 1'b0)
                                    || (c_mret_i && mepc[0] != 1'b0) || (irq_taken_o && irq_addr[0] != 1'b0);
    assign exc_taken    = (pc_stat_c == RUN) && (exc_misaligned_instr || exc_illegal_instr_i || c_ecall_i || illegal_c_instr_i);
    
    always_comb
    begin
        if(exc_illegal_instr_i || illegal_c_instr_i)
            exc_id  = EXC_ILLEGAL_INSTR;
        else if(exc_misaligned_instr)
            exc_id  = EXC_MISALIGNED_INSTR;
        else if(c_ecall_i)
            exc_id  = EXC_ECALL_FROM_M;
        else
            exc_id  = '0;
    end
    
    //Control signals
    
    assign stall_waiting_data   = (data_stat_n == WAIT_DATA_GNT || data_stat_n == WAIT_DATA_RVALID);
    assign stall_o  = (stall_waiting_data | ~div_ready) & ~irq_taken_o & ~exc_taken;
    
    assign clk_en_o = (pc_stat_n == SLEEP && pc_stat_c == SLEEP) ? 1'b0 : 1'b1;
    assign sleep_o  = (pc_stat_n == SLEEP);
    
    assign flush_o  = (c_jal_i | c_jalr_i | branch_taken | irq_taken_o | c_mret_i | exc_taken);
    
    //CSR
    assign csr_wdata    = (c_csr_imm_i) ? imm_csr : rs1_rdata;
    assign exception_pc = (pc_stat_c == SLEEP) ? pc_IF_i : pc_ID;
    
    my_priv_module i_priv_module (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .fetch_ready_i  (fetch_ready_i),
        
        .csr_addr_i     (csr_address),
        .c_csr_op_i     (c_csr_op_i),
        .c_csr_imm_i    (c_csr_imm_i),
        .c_readcsr_i    (c_readcsr_i),
        .c_writecsr_i   (c_writecsr_i),
        
        .c_mret_i       (c_mret_i),
        
        .csr_wdata_i    (csr_wdata),
        .csr_rdata_o    (csr_rdata),
        
        .mstatus_mie_o  (irq_enable),
        .mtvec_o        (mtvec),
        .mepc_o         (mepc),
        .mcause_o       (mcause),
        
        .irq_taken_i    (irq_taken_o),
        .irq_i          (irq_i),
        .irq_id_i       (irq_id_i),
        .exc_taken_i    (exc_taken),
        .exc_id_i       (exc_id),
        .exc_pc_i       (exception_pc),
        
        .irq_done_i     (irq_done)
    );
    
    always_comb
    begin
        if(c_branch_i) begin
            case(funct3)
                3'b000: branch_taken = Zflag;               //beq
                3'b001: branch_taken = !Zflag;              //bne
                3'b100: branch_taken = (Nflag != Vflag);    //blt
                3'b101: branch_taken = (Nflag == Vflag);    //bge
                3'b110: branch_taken = !Cflag;              //bltu
                3'b111: branch_taken = Cflag;               //bgeu
                default: branch_taken = 1'b0;
            endcase
        end
        else    branch_taken    = 1'b0;
    end
    
    assign c_regwrite   = (c_regwrite_i | c_regwrite_by_csr_i);
    regfile i_regfile (
        .clk            (clk_i),
        .rst_n          (rst_ni),
        .stall_i        (stall_o),
        .sleep_i        (sleep_o),
        .rs1_i          (rs1),
        .rs2_i          (rs2),
        .rd_i           (rd),
        .we_i           (c_regwrite),
        .wdata_i        (rd_data),
        .rs1_rdata_o    (rs1_rdata),
        .rs2_rdata_o    (rs2_rdata)
    );
    
    always_comb
    begin
        if(c_auipc_i)       alusrc1 = pc_ID;
        else if(c_lui_i)    alusrc1 = 32'b0;
        else                alusrc1 = rs1_rdata;
    end
    
    always_comb
    begin
        if(c_auipc_i | c_lui_i) alusrc2 = imm_u;
        else if(c_store_i)      alusrc2 = imm_s;
        else if(c_alusrc_i)     alusrc2 = imm_i;
        else                    alusrc2 = rs2_rdata;
    end
    
    alu i_alu (
        .clk        (clk_i),
        .rst_ni     (rst_ni),
        .a          (alusrc1),
        .b          (alusrc2),
        .alucont    (c_alucont_i),
        .result_o     (aluout),
        .N          (Nflag),
        .Z          (Zflag),
        .C          (Cflag),
        .V          (Vflag),
        .div_ready  (div_ready),
        .irq_taken_i    (irq_taken_o)
    );
    
    always_comb
    begin
        if(c_jal_i || c_jalr_i)         rd_data = is_c_instr_i ? pc_ID + 2 : pc_ID + 4;
        else if(c_load_i)               rd_data = data_rdata_se;
        else if(c_regwrite_by_csr_i)    rd_data = csr_rdata;
        else                            rd_data = aluout;
    end
    
    `ifndef VERILATOR
    `ifdef TRACE_EXECUTION
    
    logic tracer_clk;
    logic is_running;
    
    assign tracer_clk = clk_i;
    assign is_running = (pc_stat_c == RUN);
    
    my_core_trace my_core_trace_i
    (
        .clk            (tracer_clk), // always-running clock for tracing
        .rst_n          (rst_ni),
        
        .fetch_enable   (fetch_en_i),
        
        .pc             (pc_ID),
        .instr          (instr_rdata_i),
        
        .is_running     (is_running),
        
        .rs1_value      (rs1_rdata),
        .rs2_value      (rs2_rdata),
        .rd_value       (rd_data),
        
        .mem_addr       (data_addr_o),
        .mem_wdata      (data_wdata_o),
        
        .imm_u_type     (imm_u),
        .imm_j_type     (imm_jal),
        .imm_i_type     (imm_i),
        .imm_csr_type   (imm_csr),
        .imm_s_type     (imm_s),
        .imm_b_type     (imm_b)
    );
    `endif
    `endif
    
endmodule