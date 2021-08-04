TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
VPATH := $(CURR)/.. $(CURR)

# You need to configure these parameters for your particular accelerator!
HOST_PROGRAM ?= ps.cpp

CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=4 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0

CINCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_test

VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp
VSOURCES  += $(CURR_SRC_DIR)/example_axi_v1_0_S00_AXI.v
VSOURCES  += $(CURR_SRC_DIR)/top.v

VINCLUDES +=-I$(BASEJUMP_STL_DIR)/bsg_misc -I$(BASEJUMP_STL_DIR)/bsg_test

include $(TOP)/cosim/mk/Makefile.verilator

