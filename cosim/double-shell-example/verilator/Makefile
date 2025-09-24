TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

#############################
# Accelerator Software Settings
#############################

DEFINES += GP0_ADDR_BASE=0x43C00000
DEFINES += GP0_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ADDR_BASE=0x80000000
DEFINES += GP1_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil1

include $(DESIGN_DIR)/Makefile.design
include $(COSIM_MK_DIR)/Makefile.verilator

