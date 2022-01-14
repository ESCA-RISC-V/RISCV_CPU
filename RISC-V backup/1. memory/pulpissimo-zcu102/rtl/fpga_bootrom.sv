//-----------------------------------------------------------------------------
// Title         : FPGA Bootrom for PULPissimo
//-----------------------------------------------------------------------------
// File          : fpga_bootrom.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 29.05.2019
//-----------------------------------------------------------------------------
// Description :
// Mockup bootrom that keeps returning jal x0,0 to trap the core in an infinite
// loop until the debug module takes over control.
//-----------------------------------------------------------------------------
// Copyright (C) 2013-2019 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//-----------------------------------------------------------------------------


module fpga_bootrom
  #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
    )
  (
   input logic                   CLK,
   input logic                   CEN,
   input logic [ADDR_WIDTH-1:0]  A,
   output logic [DATA_WIDTH-1:0] Q
   );
   localparam NUM_WORDS = 2**ADDR_WIDTH;
   
   logic [DATA_WIDTH-1:0] MEM [NUM_WORDS-1:0];
   logic [ADDR_WIDTH-1:0] A_Q;
   
   //jump to 0x1c008080
   initial
   begin
        MEM[0] = 32'h1C008537;
        MEM[1] = 32'h08050513;
        MEM[2] = 32'h00050067;
   end
  
  always_ff @(posedge CLK)
  begin
    if(CEN==1'b0)
        A_Q <=A;
    end
    
    assign Q = MEM[A_Q];

endmodule : fpga_bootrom
