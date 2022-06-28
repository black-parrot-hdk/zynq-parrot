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
export BASE_FLIST   ?= $(abspath ../Flist.ariane ../Flist.basejump ../flist.vcs)
export FLIST        ?= $(abspath flist.vcs)
export SIM_ARGS     += $(NBF_FILE)
export SIM_DEFINES  += -DVERILATOR

SKIP_DRAM ?= -DSKIP_DRAM_TESTING

VV_OPTS += -Wno-BLKANDNBLK

#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x400000000U -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_ADDR_WIDTH=9 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x500000000U -DGP1_ADDR_SIZE_BYTES=0x30000000 -DGP1_ADDR_WIDTH=32 -DGP1_DATA_WIDTH=64 -DGP1_HIER_BASE=TOP.top.axil1
CFLAGS += $(INCLUDES) $(SKIP_DRAM)

include $(TOP)/cosim/mk/Makefile.verilator

#############################
# Modify base flist
#############################
$(FLIST): $(BASE_FLIST)
	echo "+incdir+$$BASEJUMP_STL_DIR)/bsg_cache" > $@
	echo "+incdir+$$BASEJUMP_STL_DIR/bsg_test" >> $@
	echo "+incdir+$$BASEJUMP_STL_DIR/bsg_noc" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_axi_mem.v" >> $@
	cat $^ | envsubst >> $@

