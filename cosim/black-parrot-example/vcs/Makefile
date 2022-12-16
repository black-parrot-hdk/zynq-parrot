TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)

#############################
# Project Settings
#############################
export TOP_MODULE ?= top

#############################
# Accelerator Software Settings
#############################
export NBF_FILE     ?= $(abspath ../hello.nbf)
export HOST_PROGRAM ?= $(abspath ../ps.cpp)
export BASE_FLIST   ?= $(abspath ../flist.vcs)
export FLIST        ?= $(abspath flist.vcs)
export SIM_ARGS     += +c_args=$(NBF_FILE)
export SIM_DEFINES  += -DVERILATOR

SKIP_DRAM ?= -DSKIP_DRAM_TESTING
BP_NCPUS ?= 1

#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000U \
					  -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000U \
            -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=top.axil1
CFLAGS += -DGP2_ENABLE -DGP2_ADDR_BASE=0x00000000U \
            -DGP2_ADDR_WIDTH=28 -DGP2_DATA_WIDTH=32 -DGP2_HIER_BASE=top.axil2
CFLAGS += -DHP0_ENABLE -DHP0_ADDR_BASE=0x1000000U -DHP0_ADDR_WIDTH=32 -DHP0_DATA_WIDTH=32 -DHP0_HIER_BASE=top.axil2
CFLAGS += -DSCRATCHPAD_ENABLE
CFLAGS += -DBP_NCPUS=$(BP_NCPUS)
# Enable backpressure
#CFLAGS += -DSIM_BACKPRESSURE_ENABLE
#CFLAGS += -DSIM_BACKPRESSURE_CHANCE=5
#CFLAGS += -DSIM_BACKPRESSURE_LENGTH=100
CFLAGS += $(INCLUDES) $(SKIP_DRAM)

include $(TOP)/cosim/mk/Makefile.vcs

#############################
# Modify base flist
#############################
$(FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	echo "+incdir+$(CURR_SRC_DIR)" > $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_axil_to_dpi.v" >> $@
	cat $^ | envsubst >> $@

