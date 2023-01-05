TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
include $(TOP)/Makefile.common

#############################
# Project Settings
#############################
PART       ?= xc7z020clg400-1
TOP_MODULE ?= top
BASENAME   ?= blackparrot

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST      ?= $(abspath flist.vcs)
$(FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

