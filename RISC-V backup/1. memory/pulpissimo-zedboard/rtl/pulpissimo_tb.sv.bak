`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2021 03:52:21 PM
// Design Name: 
// Module Name: pulpissimo_tb
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


module pulpissimo_tb;

    localparam CORE_TYPE = 0; // 0 for RISCY, 1 for ZERORISCY, 2 for MICRORISCY
    localparam USE_FPU   = 0;
    localparam USE_HWPE = 0; 

    wire  ref_clk;

    wire  pad_uart_rx;
    wire  pad_uart_tx;
    wire  pad_uart_rts; //Mapped to spim_csn0
    wire  pad_uart_cts; //Mapped to spim_sck

    wire  led0_o; //Mapped to spim_csn1
    wire  led1_o; //Mapped to cam_pclk
    wire  led2_o; //Mapped to cam_hsync
    wire  led3_o; //Mapped to cam_data0

    wire  switch0_i; //Mapped to cam_data1
    wire  switch1_i; //Mapped to cam_data2
    wire  switch2_i; //Mapped to cam_data7
    wire  switch3_i; //Mapped to cam_vsync

    wire  btn0_i; //Mapped to cam_data3
    wire  btn1_i; //Mapped to cam_data4
    wire  btn2_i; //Mapped to cam_data5
    wire  btn3_i; //Mapped to cam_data6

    wire  pad_i2c0_sda;
    wire  pad_i2c0_scl;

    wire  pad_pmod0_4; //Mapped to spim_sdio0
    wire  pad_pmod0_5; //Mapped to spim_sdio1
    wire  pad_pmod0_6; //Mapped to spim_sdio2
    wire  pad_pmod0_7; //Mapped to spim_sdio3

    wire  pad_pmod1_0; //Mapped to sdio_data0
    wire  pad_pmod1_1; //Mapped to sdio_data1
    wire  pad_pmod1_2; //Mapped to sdio_data2
    wire  pad_pmod1_3; //Mapped to sdio_data3
    wire  pad_pmod1_4; //Mapped to i2s0_sck
    wire  pad_pmod1_5; //Mapped to i2s0_ws
    wire  pad_pmod1_6; //Mapped to i2s0_sdi
    wire  pad_pmod1_7; //Mapped to i2s1_sdi

    wire  pad_hdmi_scl; //Mapped to sdio_clk
    wire  pad_hdmi_sda; //Mapped to sdio_cmd

    wire  pad_reset;

    wire  pad_jtag_tck;
    wire  pad_jtag_tdi;
    wire  pad_jtag_tdo;
    wire  pad_jtag_tms;
    
    wire pad_jtag_trst;
    
    logic tmp_clk;
    logic tmp_reset;
    
    parameter CLK_PERIOD = 8;
    
    initial
    begin
        tmp_clk = 0;
        
        #(CLK_PERIOD);
        
        forever tmp_clk = #(CLK_PERIOD/2) ~tmp_clk;
    end 
    
    initial
    begin
        tmp_reset = 0;
        #50
        tmp_reset = 1;
        #50
        tmp_reset = 0;
    end
    
    assign ref_clk = tmp_clk;
    assign pad_reset = ~tmp_reset;
    assign pad_jtag_trst = 1'b1;
    
    pulpissimo
        #(.CORE_TYPE(CORE_TYPE),
          .USE_FPU(USE_FPU),
          .USE_HWPE(USE_HWPE)
      ) i_pulpissimo
      (
       .pad_spim_sdio0(pad_pmod0_4),
       .pad_spim_sdio1(pad_pmod0_5),
       .pad_spim_sdio2(pad_pmod0_6),
       .pad_spim_sdio3(pad_pmod0_7),
       .pad_spim_csn0(pad_uart_rts),
       .pad_spim_csn1(led0_o),
       .pad_spim_sck(pad_uart_cts),
       .pad_uart_rx(pad_uart_rx),
       .pad_uart_tx(pad_uart_tx),
       .pad_cam_pclk(led1_o),
       .pad_cam_hsync(led2_o),
       .pad_cam_data0(led3_o),
       .pad_cam_data1(switch0_i),
       .pad_cam_data2(switch1_i),
       .pad_cam_data3(btn0_i),
       .pad_cam_data4(btn1_i),
       .pad_cam_data5(btn2_i),
       .pad_cam_data6(btn3_i),
       .pad_cam_data7(switch2_i),
       .pad_cam_vsync(switch3_i),
       .pad_sdio_clk(pad_hdmi_scl),
       .pad_sdio_cmd(pad_hdmi_sda),
       .pad_sdio_data0(pad_pmod1_0),
       .pad_sdio_data1(pad_pmod1_1),
       .pad_sdio_data2(pad_pmod1_2),
       .pad_sdio_data3(pad_pmod1_3),
       .pad_i2c0_sda(pad_i2c0_sda),
       .pad_i2c0_scl(pad_i2c0_scl),
       .pad_i2s0_sck(pad_pmod1_4),
       .pad_i2s0_ws(pad_pmod1_5),
       .pad_i2s0_sdi(pad_pmod1_6),
       .pad_i2s1_sdi(pad_pmod1_7),
       .pad_reset_n(pad_reset),
       .pad_jtag_tck(pad_jtag_tck),
       .pad_jtag_tdi(pad_jtag_tdi),
       .pad_jtag_tdo(pad_jtag_tdo),
       .pad_jtag_tms(pad_jtag_tms),
       .pad_jtag_trst(pad_jtag_trst),
       .pad_xtal_in(ref_clk),
       .pad_bootsel()
       );

endmodule
