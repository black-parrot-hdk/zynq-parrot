TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)

#############################
# Project Settings
#############################
export TOP_MODULE ?= top

#############################
# Accelerator Software Settings
#############################
export NBF_FILE     ?= $(abspath ../prog.nbf)
export HOST_PROGRAM ?= $(abspath ../ps.cpp)
export BASE_FLIST   ?= $(abspath ../flist.vcs)
export FLIST        ?= $(abspath flist.vcs)
export SIM_ARGS     += $(NBF_FILE)
export SIM_DEFINES  += -DVERILATOR

SKIP_DRAM ?= -DSKIP_DRAM_TESTING

CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000U -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000U -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=TOP.top.axil1
CFLAGS += $(INCLUDES) $(SKIP_DRAM)

include $(TOP)/cosim/mk/Makefile.verilator

#############################
# Modify base flist
#############################
$(FLIST): $(BASE_FLIST)
	cat $(BP_TOP_DIR)/syn/flist.vcs > $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_axil_to_dpi.v" >> $@
	cat $< | envsubst >> $@

