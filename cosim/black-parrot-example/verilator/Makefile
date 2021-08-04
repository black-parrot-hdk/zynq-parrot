TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
VPATH := $(CURR)/.. $(CURR)

export HOST_PROGRAM ?= ps.cpp
export SIM_ARGS=$(NBF_FILE)

# You need to configure these parameters for your particular accelerator!

NBF_FILE  ?=../prog.nbf
SKIP_DRAM ?= -DSKIP_DRAM_TESTING

CINCLUDES += -I$(BASEJUMP_STL_DIR)/bsg_test

CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000U -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000U -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=TOP.top.axil1
CFLAGS += $(INCLUDES) $(SKIP_DRAM)

VV_OPTS += -f flist.vcs
flist.vcs:
	cp $(BP_TOP_DIR)/syn/flist.vcs $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> flist.vcs
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> flist.vcs
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> flist.vcs
	echo "$(BP_ME_DIR)/src/v/network/bp_lite_to_axi_lite_master.sv" >> flist.vcs
	echo "$(BP_ME_DIR)/src/v/network/axi_lite_to_bp_lite_client.sv" >> flist.vcs
	echo "$(COSIM_SRC_DIR)/bsg_zynq_pl_shell.v" >> flist.vcs
	echo "$(CURR_SRC_DIR)/bp_unicore_axi_sim.sv" >> flist.vcs
	echo "$(CURR_SRC_DIR)/bp_to_axi_decoder.sv" >> flist.vcs
	echo "$(CURR_SRC_DIR)/top_zynq.sv" >> flist.vcs
	echo "$(CURR_SRC_DIR)/top.v" >> flist.vcs

include $(TOP)/cosim/mk/Makefile.verilator

