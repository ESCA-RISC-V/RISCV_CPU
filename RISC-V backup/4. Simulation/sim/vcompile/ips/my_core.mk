#
# Copyright (C) 2016 ETH Zurich, University of Bologna
# All rights reserved.
#
# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.
#

IP=my_core
IP_PATH=$(IPS_PATH)/my_core
LIB_NAME=$(IP)_lib
MY_CORE_PATH=/home/sun/sun/esca_samsung/escaplp/fpga/myrtl

include vcompile/build.mk

.PHONY: vcompile-$(IP) vcompile-subip-my_core 

vcompile-$(IP): $(LIB_PATH)/_vmake

$(LIB_PATH)/_vmake : $(LIB_PATH)/my_core.vmake 
	@touch $(LIB_PATH)/_vmake


# my_core component
# INCDIR_ADV_DBG_IF=+incdir+$(IP_PATH)/rtl
INCDIR_MY_CORE=
SRC_SVLOG_MY_CORE=\
	$(MY_CORE_PATH)/my_riscv_defines.sv\
	$(MY_CORE_PATH)/my_modules.sv\
	$(MY_CORE_PATH)/my_core.sv\
	$(MY_CORE_PATH)/my_priv_module.sv\
	$(MY_CORE_PATH)/my_core_tracer_defines.sv\
	$(MY_CORE_PATH)/my_core_trace.sv
SRC_VHDL_MY_CORE=

vcompile-subip-my_core: $(LIB_PATH)/my_core.vmake

$(LIB_PATH)/my_core.vmake: $(SRC_SVLOG_MY_CORE) $(SRC_VHDL_MY_CORE)
	$(call subip_echo,my_core)
	$(SVLOG_CC) -work $(LIB_PATH)   -suppress 2583 -suppress 13314 $(INCDIR_MY_CORE) $(SRC_SVLOG_MY_CORE)

	@touch $(LIB_PATH)/my_core.vmake

