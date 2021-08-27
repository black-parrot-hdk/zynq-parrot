TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)

#############################
# Project Settings
#############################
export TOP_MODULE ?= top

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
BASE_FLIST   ?= $(abspath ../flist.vcs)
FLIST        ?= $(abspath flist.vcs)

CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=6
CFLAGS += -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=top.axil0

include $(TOP)/cosim/mk/Makefile.vcs

#############################
# Modify base flist
#############################
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@

