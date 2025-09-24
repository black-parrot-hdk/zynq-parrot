TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

#############################
# Accelerator Software Settings
#############################

DEFINES += GP0_ADDR_BASE=0x43C00000
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += SP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axis6
DEFINES += MP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axis9
DEFINES += BUFFER_ENABLE

include $(DESIGN_DIR)/Makefile.design
include $(COSIM_MK_DIR)/Makefile.vcs

