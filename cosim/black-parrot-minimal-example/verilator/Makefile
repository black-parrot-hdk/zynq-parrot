TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

#############################
# Accelerator Software Settings
#############################

DEFINES += GP0_ADDR_BASE=0x40000000U
DEFINES += GP0_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil0
DEFINES += HP0_ADDR_BASE=0x00000000U
DEFINES += AXI_MEM_ENABLE

include $(DESIGN_DIR)/Makefile.design
include $(COSIM_MK_DIR)/Makefile.verilator

