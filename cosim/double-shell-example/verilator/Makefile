TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
VPATH := $(CURR)/.. $(CURR)

# You need to configure these parameters for your particular accelerator!
HOST_PROGRAM ?= ps.cpp

CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=5 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=5 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=TOP.top.axil1

CINCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_test

VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp
VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small.v
VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v
VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.v
VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_flow_counter.v
VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.v
VSOURCES  += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.v
VSOURCES  += $(CURR_SRC_DIR)/top.v

VINCLUDES +=-I$(BASEJUMP_STL_DIR)/bsg_misc -I$(BASEJUMP_STL_DIR)/bsg_test

include $(TOP)/cosim/mk/Makefile.verilator

