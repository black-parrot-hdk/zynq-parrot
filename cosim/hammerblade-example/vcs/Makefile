
#############################
# Accelerator Software Settings
#############################

NUM_MC_FINISH ?= 1
NUM_BP_FINISH ?= 1

DEFINES += GP0_ADDR_BASE=0x40000000U
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ADDR_BASE=0x80000000U
DEFINES += GP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil1
DEFINES += HP0_ADDR_BASE=0x00000000U
DEFINES += AXI_MEM_ENABLE
DEFINES += HP1_ADDR_BASE=0x1000000U
DEFINES += HP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil4
DEFINES += SCRATCHPAD_ENABLE

include ../Makefile.design

