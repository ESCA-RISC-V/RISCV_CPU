`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2021 06:09:31 PM
// Design Name: 
// Module Name: my_modules
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

module regfile
(
    input logic     clk,
    input logic     rst_n,
    input logic     stall_i,
    input logic     sleep_i,
    
    input logic [4:0]   rs1_i, rs2_i, rd_i,
    input logic         we_i,
    input logic [31:0]  wdata_i,
    output logic [31:0] rs1_rdata_o, rs2_rdata_o

);

    logic [31:0][31:0]  register_file;
    
    assign rs1_rdata_o = (rs1_i == 0) ? 0 : register_file[rs1_i];
    assign rs2_rdata_o = (rs2_i == 0) ? 0 : register_file[rs2_i];
    
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if(~rst_n) begin
            for(integer i=0; i<32; i++)
                register_file[i] <= 32'b0;
        end
        else if(rd_i !=0 && we_i && ~stall_i && ~sleep_i) register_file[rd_i] <= wdata_i;
    end

endmodule

module alu (
    input logic clk,
    input logic rst_ni,
    input logic     [31:0] a, b, 
    input logic     [5:0]  alucont, 
    
    output logic    [31:0] result_o,
    output logic           N,
    output logic           Z,
    output logic           C,
    output logic           V,
    output logic        div_ready
);

  logic [31:0]  result, mul_result, div_result;
  logic [31:0] b2, sum ;
  logic        slt, sltu;
  
  logic     div_done;
  logic     div_en;
  
  logic [31:0]  test_div_out;
  logic         test_div_done;
  
  assign    div_en      = (~alucont[5]) & alucont[2];
  assign    div_ready   = div_en ? div_done : 1'b1;
  
  assign b2 = alucont[4] ? ~b:b; 
  assign result_o   = (alucont[5]) ? result : (alucont[2]) ? div_result : mul_result;

   
//    adder_RCLA_8bit i_RCLA8 (
//        .a (a),
//        .b (b2),
//        .cin (alucont[4]),
//        .sum (sum),
//        .N (N),
//        .Z (Z),
//        .C (C),
//        .V (V)
//    );
    
    mult i_mult (
        .a  (a),
        .b  (b),
        .m_select   (alucont[1:0]),
        .m_out  (mul_result)
    );
    
    div i_div (
        .clk    (clk),
        .rst_ni (rst_ni),
        .div_en (div_en),
        .a      (a),
        .b      (b),
        .div_select (alucont[1:0]),
        .div_out    (div_result),
        .div_done   (div_done)
    );
    
    adder_KS i_KS (
        .a (a),
        .b (b2),
        .cin (alucont[4]),
        .sum (sum),
        .N (N),
        .Z (Z),
        .C (C),
        .V (V)
    );
    
  // signed less than condition
  assign slt  = N ^ V ; 

  // unsigned lower (C clear) condition
  assign sltu = ~C ;   

  always_comb
    case(alucont[3:0])
      4'b0000: result <= sum;    // A + B, A - B
      4'b0001: result <= a & b;
      4'b0010: result <= a | b;
      4'b0011: result <= a ^ b;
      4'b0100: result <= a << b[4:0]; // shift logical left (sll)
      4'b0101: result <= a >> b[4:0]; //srl
      4'b0110: result <= $signed(a) >>> b[4:0];
      4'b0111: result <= {31'b0, slt};    // slt
      4'b1000: result <= {31'b0,sltu};
      default: result <= 32'b0;
    endcase

endmodule

module div (
    input logic     clk,
    input logic     rst_ni,
    input logic     div_en,
    input logic [31:0]  a, b,
    input logic [1:0]   div_select,
    output logic [31:0] div_out,
    output logic        div_done
);

    enum logic [1:0] {IDLE, DIV, DONE}   div_n, div_c;
    
    logic [31:0]    quot_n, quot_c;
    logic [31:0]    quot_mask_n, quot_mask_c;
    logic [31:0]    dividend_n, dividend_c;
    logic [31:0]    divisor, rem_n, rem_c;
    
    logic           output_invert;  //a[31] != b[31]
    
    assign output_invert    = (div_select == 2'b00 && (a[31] != b[31]) && |b) || (div_select == 2'b10 && a[31] == 1'b1);
    assign divisor  = div_select[0] == 1'b0 && b[31] ? -$signed(b) : b;
    
    always_ff @(posedge clk or negedge rst_ni)
    begin
        if(~rst_ni) begin
            div_c   <= IDLE;
            quot_c  <= '0;
            dividend_c  <= '0;
            rem_c       <= '0;
            quot_mask_c = '0;
        end
        else begin
            div_c   <= div_n;
            quot_c  <= quot_n << 1;
            dividend_c  <= dividend_n << 1;
            rem_c       <= {rem_n[30:0], dividend_n[31]};
            quot_mask_c <= quot_mask_n;
        end
    end
    
    always_comb
    begin
        case(div_c)
            IDLE: begin
                if(div_en)  div_n   = DIV;
                else        div_n   = IDLE;
            end
            DIV: begin
                if(quot_mask_n[31])    div_n   = DONE;
                else                div_n   = DIV;
            end
            DONE: begin
                div_n   = IDLE;
            end
            default: begin
                div_n   = IDLE;
            end
        endcase
    end
    

    always_comb
    begin
        case(div_c)
            IDLE: begin
                div_done    = 1'b0;
                
                if(div_en) begin
                    rem_n       = '0;
                    dividend_n  = div_select[0] == 1'b0 && a[31] ? -$signed(a) : a;
                    quot_n      = '0;
                    quot_mask_n = 1;
                end
                else begin
                    rem_n       = '0;
                    dividend_n  = '0;
                    quot_n      = '0;
                    quot_mask_n = '0;
                end
            end
            DIV: begin
                div_done    = 1'b0;
                
                if(divisor <= rem_c) begin
                    rem_n   = rem_c - divisor;
                    quot_n  = quot_c + 1;
                end
                else begin
                    rem_n   = rem_c;
                    quot_n  = quot_c;
                end
                
                dividend_n  = dividend_c;
                quot_mask_n = quot_mask_c << 1;
            end
            DONE: begin
                div_done    = 1'b1;
                
                if(divisor <= rem_c) begin
                    rem_n   = rem_c - divisor;
                    quot_n  = quot_c + 1;
                end
                else begin
                    rem_n   = rem_c;
                    quot_n  = quot_c;
                end
            end
            default: begin
                quot_n  = '0;
                dividend_n  = '0;
                rem_n       = '0;
            end
        endcase
    end    
     
    always_comb
    begin
        if(div_done) begin
            if(div_select[1] == 1'b0) begin
                div_out = output_invert ? -$signed(quot_n) : quot_n;    
            end 
            else begin
                div_out = output_invert ? -$signed(rem_n) : rem_n;
            end
        end
        else begin
            div_out = '0;
        end
    end

endmodule

//module div (
//    input logic     clk,
//    input logic     rst_ni,
//    input logic     div_en,
//    input logic [31:0]  a, b,
//    input logic [1:0]   div_select,
//    output logic [31:0] div_out,
//    output logic        div_done
//);

//    enum logic [1:0] {IDLE, DIV, DONE}   div_n, div_c;
    
//    logic [31:0]    quot_n, quot_c;
//    logic [62:0]    divisor_n, divisor_c;
//    logic [31:0]    dividend_n, dividend_c;
//    logic [31:0]    quot_mask_n, quot_mask_c;
    
//    logic           output_invert;  //a[31] != b[31]
    
//    assign output_invert    = (div_select == 2'b00 && (a[31] != b[31]) && |b) || (div_select == 2'b10 && a[31] == 1'b1);
    
//    always_ff@(posedge clk or negedge rst_ni) begin
//        if(~rst_ni) begin
//            div_c   <= IDLE;
//            divisor_c   <= '0;
//            dividend_c  <= '0;
//            quot_mask_c <= '0;
//            quot_c  <= '0;
//        end
//        else if(div_en) begin
//            div_c   <= div_n;
//            divisor_c   <= divisor_n;
//            dividend_c  <= dividend_n;
//            quot_mask_c <= quot_mask_n;
//            quot_c  <= quot_n;
//        end
//    end
    
//    always_comb
//    begin
//        case(div_c)
//            IDLE: begin
//                if(div_en) begin
//                    div_n   = DIV;
//                end
//                else begin
//                    div_n   = IDLE;
//                end
//            end
//            DIV: begin
//                if(~|(quot_mask_n)) begin
//                    div_n   = DONE;
//                end
//                else begin
//                    div_n   = DIV;
//                end
//            end
//            DONE: begin
//                div_n   = IDLE;
//            end
//            default: begin
//                div_n   = div_c;
//            end
//        endcase
//    end
    
//    always_comb
//    begin
//        case(div_c)
//            IDLE: begin
//                div_done    = 1'b0;
            
//                if(div_en) begin
//                    divisor_n   = (div_select[0] == 1'b0 && b[31] ? -$signed(b) : b) << 31;
//                    dividend_n  = div_select[0] == 1'b0 && a[31] ? -$signed(a) : a;
//                    quot_n  = '0;
//                    quot_mask_n = 1 << 31;
//                end
//                else begin
//                    divisor_n   = '0;
//                    dividend_n  = '0;
//                    quot_n      = '0;
//                    quot_mask_n = '0;
//                end
//            end
//            DIV: begin
//                if(divisor_c <= dividend_c) begin
//                    dividend_n  = dividend_c - divisor_c;
//                    quot_n  = quot_c | quot_mask_c;
//                end
//                else begin
//                    dividend_n  = dividend_c;
//                    quot_n  = quot_c;
//                end
                
//                div_done    = 1'b0;
//                divisor_n   = divisor_c >> 1;
//                quot_mask_n = quot_mask_c >> 1;
//            end
//            DONE: begin
//                div_done    = 1'b1;
//            end
//            default: begin
//                div_done    = 1'b0;
//            end
//        endcase
//    end
    
//    always_comb
//    begin
//        if(div_done) begin
//            if(div_select[1] == 1'b0) begin
//                div_out = output_invert ? -$signed(quot_c) : quot_c;    
//            end 
//            else begin
//                div_out = output_invert ? -$signed(dividend_c) : dividend_c;
//            end
//        end
//        else begin
//            div_out = '0;
//        end
//    end

//endmodule


module mult (
    input logic [31:0]  a, b,
    input logic [1:0]   m_select,
    output logic [31:0] m_out
);

    logic [32:0]    rs1_exp, rs2_exp;
    logic [63:0]    res;
    
    always_comb
    begin
        if(m_select == 2'b11) begin
            rs1_exp = {1'b0, a};
        end
        else begin
            rs1_exp = {a[31], a};
        end
    end
    
    always_comb
    begin
        if(m_select[1]) begin
            rs2_exp = {1'b0, b};
        end
        else begin
            rs2_exp = {b[31], b};
        end
    end
    
    assign res = $signed(rs1_exp)*$signed(rs2_exp);
    
    assign m_out    = (m_select == 2'b00) ? res[31:0] : res[63:32];

endmodule


// Ripple-carry adder 
module adder_32bit (input  [31:0] a, b, 
                    input         cin,
                    output [31:0] sum,
                    output        N,Z,C,V);

	logic [31:0]  ctmp;

	assign N = sum[31];
	assign Z = (sum == 32'b0);
	assign C = ctmp[31];
	assign V = ctmp[31] ^ ctmp[30];

	adder_1bit bit31 (.a(a[31]), .b(b[31]), .cin(ctmp[30]), .sum(sum[31]), .cout(ctmp[31]));
	adder_1bit bit30 (.a(a[30]), .b(b[30]), .cin(ctmp[29]), .sum(sum[30]), .cout(ctmp[30]));
	adder_1bit bit29 (.a(a[29]), .b(b[29]), .cin(ctmp[28]), .sum(sum[29]), .cout(ctmp[29]));
	adder_1bit bit28 (.a(a[28]), .b(b[28]), .cin(ctmp[27]), .sum(sum[28]), .cout(ctmp[28]));
	adder_1bit bit27 (.a(a[27]), .b(b[27]), .cin(ctmp[26]), .sum(sum[27]), .cout(ctmp[27]));
	adder_1bit bit26 (.a(a[26]), .b(b[26]), .cin(ctmp[25]), .sum(sum[26]), .cout(ctmp[26]));
	adder_1bit bit25 (.a(a[25]), .b(b[25]), .cin(ctmp[24]), .sum(sum[25]), .cout(ctmp[25]));
	adder_1bit bit24 (.a(a[24]), .b(b[24]), .cin(ctmp[23]), .sum(sum[24]), .cout(ctmp[24]));
	adder_1bit bit23 (.a(a[23]), .b(b[23]), .cin(ctmp[22]), .sum(sum[23]), .cout(ctmp[23]));
	adder_1bit bit22 (.a(a[22]), .b(b[22]), .cin(ctmp[21]), .sum(sum[22]), .cout(ctmp[22]));
	adder_1bit bit21 (.a(a[21]), .b(b[21]), .cin(ctmp[20]), .sum(sum[21]), .cout(ctmp[21]));
	adder_1bit bit20 (.a(a[20]), .b(b[20]), .cin(ctmp[19]), .sum(sum[20]), .cout(ctmp[20]));
	adder_1bit bit19 (.a(a[19]), .b(b[19]), .cin(ctmp[18]), .sum(sum[19]), .cout(ctmp[19]));
	adder_1bit bit18 (.a(a[18]), .b(b[18]), .cin(ctmp[17]), .sum(sum[18]), .cout(ctmp[18]));
	adder_1bit bit17 (.a(a[17]), .b(b[17]), .cin(ctmp[16]), .sum(sum[17]), .cout(ctmp[17]));
	adder_1bit bit16 (.a(a[16]), .b(b[16]), .cin(ctmp[15]), .sum(sum[16]), .cout(ctmp[16]));
	adder_1bit bit15 (.a(a[15]), .b(b[15]), .cin(ctmp[14]), .sum(sum[15]), .cout(ctmp[15]));
	adder_1bit bit14 (.a(a[14]), .b(b[14]), .cin(ctmp[13]), .sum(sum[14]), .cout(ctmp[14]));
	adder_1bit bit13 (.a(a[13]), .b(b[13]), .cin(ctmp[12]), .sum(sum[13]), .cout(ctmp[13]));
	adder_1bit bit12 (.a(a[12]), .b(b[12]), .cin(ctmp[11]), .sum(sum[12]), .cout(ctmp[12]));
	adder_1bit bit11 (.a(a[11]), .b(b[11]), .cin(ctmp[10]), .sum(sum[11]), .cout(ctmp[11]));
	adder_1bit bit10 (.a(a[10]), .b(b[10]), .cin(ctmp[9]),  .sum(sum[10]), .cout(ctmp[10]));
	adder_1bit bit9  (.a(a[9]),  .b(b[9]),  .cin(ctmp[8]),  .sum(sum[9]),  .cout(ctmp[9]));
	adder_1bit bit8  (.a(a[8]),  .b(b[8]),  .cin(ctmp[7]),  .sum(sum[8]),  .cout(ctmp[8]));
	adder_1bit bit7  (.a(a[7]),  .b(b[7]),  .cin(ctmp[6]),  .sum(sum[7]),  .cout(ctmp[7]));
	adder_1bit bit6  (.a(a[6]),  .b(b[6]),  .cin(ctmp[5]),  .sum(sum[6]),  .cout(ctmp[6]));
	adder_1bit bit5  (.a(a[5]),  .b(b[5]),  .cin(ctmp[4]),  .sum(sum[5]),  .cout(ctmp[5]));
	adder_1bit bit4  (.a(a[4]),  .b(b[4]),  .cin(ctmp[3]),  .sum(sum[4]),  .cout(ctmp[4]));
	adder_1bit bit3  (.a(a[3]),  .b(b[3]),  .cin(ctmp[2]),  .sum(sum[3]),  .cout(ctmp[3]));
	adder_1bit bit2  (.a(a[2]),  .b(b[2]),  .cin(ctmp[1]),  .sum(sum[2]),  .cout(ctmp[2]));
	adder_1bit bit1  (.a(a[1]),  .b(b[1]),  .cin(ctmp[0]),  .sum(sum[1]),  .cout(ctmp[1]));
	adder_1bit bit0  (.a(a[0]),  .b(b[0]),  .cin(cin),      .sum(sum[0]),  .cout(ctmp[0]));

endmodule


module adder_1bit (input a, b, cin,
                   output sum, cout);

  assign sum  = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);

endmodule

module pg_module (
    input logic a, b,
    output logic p, g
);

    assign p = a ^ b;
    assign g = a & b;

endmodule

//adder examination
//RCLA (Ripple-block Carry Lookahead Adder)
module CLA_4bit (
    input logic [3:0] a, b,
    input logic cin,
    output logic [3:0] sum,
    output logic cout,
    output logic v
);

    logic [3:0] g, p;
    logic [3:0] c;
    
    assign c[0] = cin;
    
    pg_module bit0 (.a(a[0]), .b(b[0]), .p(p[0]), .g(g[0]));
    pg_module bit1 (.a(a[1]), .b(b[1]), .p(p[1]), .g(g[1]));
    pg_module bit2 (.a(a[2]), .b(b[2]), .p(p[2]), .g(g[2]));
    pg_module bit3 (.a(a[3]), .b(b[3]), .p(p[3]), .g(g[3]));
    
    assign c[1] = (cin & p[0]) | g[0];
    assign c[2] = (cin & p[1] & p[0]) | (p[1] & g[0]) | g[1];
    assign c[3] = (cin & p[2] & p[1] & p[0]) | (p[2] & p[1] & g[0]) | (p[2] & g[1]) | g[2];
    assign cout = (cin & p[3] & p[2] & p[1] & p[0]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & g[1]) | (p[3] & g[2]) | g[3];
    
    assign sum = c ^ a ^ b;
    assign v = cout ^ c[3];
    
endmodule

module CLA_8bit (
    input logic [7:0] a, b,
    input logic cin,
    output logic [7:0] sum,
    output logic cout,
    output logic v
);

    logic [7:0] g, p;
    logic [7:0] c;
    
    assign c[0] = cin;
    
    pg_module bit0 (.a(a[0]), .b(b[0]), .p(p[0]), .g(g[0]));
    pg_module bit1 (.a(a[1]), .b(b[1]), .p(p[1]), .g(g[1]));
    pg_module bit2 (.a(a[2]), .b(b[2]), .p(p[2]), .g(g[2]));
    pg_module bit3 (.a(a[3]), .b(b[3]), .p(p[3]), .g(g[3]));
    pg_module bit4 (.a(a[4]), .b(b[4]), .p(p[4]), .g(g[4]));
    pg_module bit5 (.a(a[5]), .b(b[5]), .p(p[5]), .g(g[5]));
    pg_module bit6 (.a(a[6]), .b(b[6]), .p(p[6]), .g(g[6]));
    pg_module bit7 (.a(a[7]), .b(b[7]), .p(p[7]), .g(g[7]));
    
    assign c[1] = (cin & p[0]) | g[0];
    assign c[2] = (cin & p[1] & p[0]) | (p[1] & g[0]) | g[1];
    assign c[3] = (cin & p[2] & p[1] & p[0]) | (p[2] & p[1] & g[0]) | (p[2] & g[1]) | g[2];
    assign c[4] = (cin & p[3] & p[2] & p[1] & p[0]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & g[1]) | (p[3] & g[2]) | g[3];
    assign c[5] = (cin & p[4] & p[3] & p[2] & p[1] & p[0]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & g[2]) | (p[4] & g[3]) | g[4];
    assign c[6] = (cin & p[5] & p[4] & p[3] & p[2] & p[1] & p[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & g[3]) | (p[5] & g[4]) | g[5];
    assign c[7] = (cin & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & g[4]) | (p[6] & g[5]) | g[6];
    assign cout = (cin & p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & g[5]) | (p[7] & g[6]) | g[7];

    assign sum = c ^ a ^ b;
    assign v = cout ^ c[7];

endmodule

module adder_RCLA_4bit (
    input logic [31:0]  a,
    input logic [31:0]  b,
    input logic     cin,
    
    output logic [31:0] sum,
    output logic    N, Z, C, V
);
    logic [7:0] ctmp;
    
    CLA_4bit g0 (.a(a[3:0]), .b(b[3:0]), .cin(cin), .sum(sum[3:0]), .cout(ctmp[0]));
    CLA_4bit g1 (.a(a[7:4]), .b(b[7:4]), .cin(ctmp[0]), .sum(sum[7:4]), .cout(ctmp[1]));
    CLA_4bit g2 (.a(a[11:8]), .b(b[11:8]), .cin(ctmp[1]), .sum(sum[11:8]), .cout(ctmp[2]));
    CLA_4bit g3 (.a(a[15:12]), .b(b[15:12]), .cin(ctmp[2]), .sum(sum[15:12]), .cout(ctmp[3]));
    CLA_4bit g4 (.a(a[19:16]), .b(b[19:16]), .cin(ctmp[3]), .sum(sum[19:16]), .cout(ctmp[4]));
    CLA_4bit g5 (.a(a[23:20]), .b(b[23:20]), .cin(ctmp[4]), .sum(sum[23:20]), .cout(ctmp[5]));
    CLA_4bit g6 (.a(a[27:24]), .b(b[27:24]), .cin(ctmp[5]), .sum(sum[27:24]), .cout(ctmp[6]));
    CLA_4bit g7 (.a(a[31:28]), .b(b[31:28]), .cin(ctmp[6]), .sum(sum[31:28]), .cout(ctmp[7]), .v(V));
    
    assign N = sum[31];
	assign Z = (sum == 32'b0);
	assign C = ctmp[7];
    
endmodule

module adder_RCLA_8bit (
    input logic [31:0]  a, b,
    input logic cin,
    
    output logic [31:0] sum,
    output logic    N, Z, C, V
);

    logic [3:0] ctmp;
    CLA_8bit g0 (.a(a[7:0]), .b(b[7:0]), .cin(cin), .sum(sum[7:0]), .cout(ctmp[0]), .v());
    CLA_8bit g1 (.a(a[15:8]), .b(b[15:8]), .cin(ctmp[0]), .sum(sum[15:8]), .cout(ctmp[1]), .v());
    CLA_8bit g2 (.a(a[23:16]), .b(b[23:16]), .cin(ctmp[1]), .sum(sum[23:16]), .cout(ctmp[2]), .v());
    CLA_8bit g3 (.a(a[31:24]), .b(b[31:24]), .cin(ctmp[2]), .sum(sum[31:24]), .cout(ctmp[3]), .v(V));
    
    assign N = sum[31];
    assign Z = (sum == 32'b0);
    assign C = ctmp[3];

endmodule

module black (
    input pi, gi,
    input pj, gj,
    output op, og
);

    assign op = pi & pj;
    assign og = gi | (pi & gj);

endmodule

module gray (
    input pi, gi,
    input gj,
    output og
);

    assign og = gi | (pi & gj);

endmodule

module adder_KS (
    input logic [31:0] a, b,
    input logic cin,
    
    output logic [31:0] sum,
    output logic N, Z, C, V
);

    logic [31:0] p0, g0;
    logic [31:0] c;
    logic cout;

    assign c[0] = cin;

    pg_module i_pg[31:0](a[31:0], b[31:0], p0[31:0], g0[31:0]);
    
    logic [31:1] p1, g1;
    
    gray s1_g(p0[0], g0[0], c[0], c[1]);
    black s1_b[31:1](p0[31:1], g0[31:1], p0[30:0], g0[30:0], p1[31:1], g1[31:1]);
    
    logic [31:3] p2, g2;
    
    gray s2_g[2:1](p1[2:1], g1[2:1], c[1:0], c[3:2]);
    black s2_b[31:3](p1[31:3], g1[31:3], p1[29:1], g1[29:1], p2[31:3], g2[31:3]);
    
    logic [31:7] p3, g3;
    
    gray s3_g[6:3](p2[6:3], g2[6:3], c[3:0], c[7:4]);
    black s3_b[31:7](p2[31:7], g2[31:7], p2[27:3], g2[27:3], p3[31:7], g3[31:7]);
    
    logic [31:15] p4, g4;
    
    gray s4_g[14:7](p3[14:7], g3[14:7], c[7:0], c[15:8]);
    black s4_b[31:15](p3[31:15], g3[31:15], p3[23:7], g3[23:7], p4[31:15], g4[31:15]);
    
    logic       p5, g5;
    
    gray s5_g[30:15](p4[30:15], g4[30:15], c[15:0], c[31:16]);
    black s5_b(p4[31], g4[31], p4[15], g4[15], p5, g5);
    
    gray s6_g(p5, g5, c[31], cout);
    
    assign sum[31:0] = p0[31:0] ^ c[31:0];
    
    assign N = sum[31];
    assign Z = (sum == 32'b0);
    assign C = cout;
    assign V = cout ^ c[31];
    
endmodule