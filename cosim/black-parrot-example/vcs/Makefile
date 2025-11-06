TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

#############################
# Accelerator Software Settings
#############################

DEFINES += GP0_ADDR_BASE=0x40000000U
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ADDR_BASE=0x80000000U
DEFINES += GP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil1
DEFINES += GP2_ADDR_BASE=0x80000000U
DEFINES += GP2_HIER_BASE=bsg_nonsynth_zynq_testbench.axil2
DEFINES += WATCHDOG_ENABLE
DEFINES += HP0_ADDR_BASE=0x0000000U
DEFINES += AXI_MEM_ENABLE
DEFINES += HP1_ADDR_BASE=0x1000000U
DEFINES += HP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil4
DEFINES += SCRATCHPAD_ENABLE

include $(DESIGN_DIR)/Makefile.design
include $(COSIM_MK_DIR)/Makefile.vcs

