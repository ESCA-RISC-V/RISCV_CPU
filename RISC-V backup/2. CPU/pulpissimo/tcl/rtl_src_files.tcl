if ![info exists PULP_FPGA_SIM] {
    set RTL /home/sun/sun/esca_samsung/escaplp/rtl
    set IPS /home/sun/sun/esca_samsung/escaplp/ips
    set FPGA_IPS ../ips
    set FPGA_RTL ../rtl
}



# pulpissimo
set SRC_PULPISSIMO " \
    $RTL/pulpissimo/jtag_tap_top.sv \
    $RTL/pulpissimo/pad_control.sv \
    $RTL/pulpissimo/pad_frame.sv \
    $RTL/pulpissimo/safe_domain.sv \
    $RTL/pulpissimo/soc_domain.sv \
    $RTL/pulpissimo/rtc_date.sv \
    $RTL/pulpissimo/rtc_clock.sv \
    $RTL/pulpissimo/pulpissimo.sv \
"
set INC_PULPISSIMO " \
    $RTL/pulpissimo/../includes \
"
