if ![info exists INCLUDE_DIRS] {
	set INCLUDE_DIRS ""
}

eval "set INCLUDE_DIRS {
    /home/sun/sun/esca_samsung/escaplp/fpga/myrtl	\
	/home/sun/sun/esca_samsung/escaplp/rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/common_cells/include \
    /home/sun/sun/esca_samsung/escaplp/ips/cluster_interconnect/rtl/low_latency_interco \
    /home/sun/sun/esca_samsung/escaplp/ips/cluster_interconnect/rtl/peripheral_interco \
    /home/sun/sun/esca_samsung/escaplp/ips/cluster_interconnect/../../rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/adv_dbg_if/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/apb/apb_adv_timer/./rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/axi/axi/include \
    /home/sun/sun/esca_samsung/escaplp/ips/axi/axi/../../common_cells/include \
    /home/sun/sun/esca_samsung/escaplp/ips/timer_unit/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/fpnew/../common_cells/include \
    /home/sun/sun/esca_samsung/escaplp/ips/jtag_pulp/../../rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/riscv/./rtl/include \
    /home/sun/sun/esca_samsung/escaplp/ips/riscv/../../rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/riscv/./rtl/include \
    /home/sun/sun/esca_samsung/escaplp/ips/ibex/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/ibex/shared/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/udma/udma_core/./rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/udma/udma_qspi/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/hwpe-ctrl/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/hwpe-stream/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/hwpe-mac-engine/rtl \
    /home/sun/sun/esca_samsung/escaplp/ips/register_interface/include \
    /home/sun/sun/esca_samsung/escaplp/ips/register_interface/../axi/axi/include \
    /home/sun/sun/esca_samsung/escaplp/ips/register_interface/../common_cells/include \
    /home/sun/sun/esca_samsung/escaplp/ips/register_interface/include \
    /home/sun/sun/esca_samsung/escaplp/ips/register_interface/../axi/axi/include \
    /home/sun/sun/esca_samsung/escaplp/ips/register_interface/../common_cells/include \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/../../rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/rtl/include \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/../axi/axi/include \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/../../rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/. \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/../../rtl/includes \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/. \
    /home/sun/sun/esca_samsung/escaplp/ips/pulp_soc/../../rtl/includes \
	${INCLUDE_DIRS} \
}"
