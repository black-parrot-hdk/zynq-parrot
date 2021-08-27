TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)

#############################
# Project Settings
#############################
export PART       ?= xc7z020clg400-1
export TOP_MODULE ?= top
export BASENAME   ?= blackparrot

#############################
# Accelerator Software Settings
#############################
export NBF_FILE     ?= $(abspath ../prog.nbf)
export HOST_PROGRAM ?= $(abspath ../ps.cpp)
export BASE_FLIST   ?= $(abspath ../flist.vcs)
export FLIST        ?= $(abspath flist.vcs)
export SIM_ARGS     += $(NBF_FILE)
export SIM_DEFINES  += -DFPGA

#SIM_DEFINES  +=-DSKIP_DRAM_TESTING

CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_WIDTH=6
CFLAGS += -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=30
CFLAGS += -DGP1_ADDR_SIZE_BYTES=0x30000000 -DGP1_DATA_WIDTH=32

include $(TOP)/cosim/mk/Makefile.fpga

#############################
# Modify base flist
#############################
$(FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | envsubst > $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@

