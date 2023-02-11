include ../Makefile.design

export TCL_DIR  ?= ./tcl
export AXI_DIR  ?= $(BLACKPARROT_SUB_DIR)/axi
export PLIC_DIR ?= $(BLACKPARROT_SUB_DIR)/rv_plic
export ETH_DIR  ?= $(BLACKPARROT_SUB_DIR)/ethernet_controller
#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath $(CURR_FLIST_DIR)/base_flist.vcs)
BP_FLIST   ?= $(abspath flist.blackparrot.vcs)

# Flist filename must have the following format: *_flist.vcs. '*' will become the IP name.
# Flist for Zynq-Parrot core
ZYNQ_CORE_FLIST  ?= $(abspath top_flist.vcs)
# Flists for all Zynq-Parrot Peripherals
ZYNQ_PERI_FLISTS ?=

FLIST := $(ZYNQ_CORE_FLIST) $(ZYNQ_PERI_FLISTS)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@

$(ZYNQ_CORE_FLIST): $(BP_FLIST) $(BASE_FLIST)
	# Use vivado version instead
	cat $^ > $@.merged
	sed -i "s/.*bsg_launch_sync_sync.v/\$$BASEJUMP_STL_DIR\/hard\/xilinx\/common\/bsg_async\/bsg_launch_sync_sync.v/g" $@.merged
	sed -i "s/.*bsg_mux.v/\$$BASEJUMP_STL_DIR\/hard\/xilinx\/7_series\/bsg_misc\/bsg_mux.v/g" $@.merged
	cat $@.merged | envsubst > $@
	rm -f $@.merged
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

