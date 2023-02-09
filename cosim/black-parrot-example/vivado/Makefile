include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
BP_FLIST   ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(abspath flist.vcs)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	# Replace with the vivado version
	sed -i "s/.*bsg_launch_sync_sync.v/\$$BASEJUMP_STL_DIR\/hard\/xilinx\/common\/bsg_async\/bsg_launch_sync_sync.v/g" $@
	sed -i "s/.*bsg_mux.v/\$$BASEJUMP_STL_DIR\/hard\/xilinx\/7_series\/bsg_misc\/bsg_mux.v/g" $@

$(FLIST): $(BP_FLIST) $(BASE_FLIST)
	# Replace with the vivado version
	sed -i "s/.*bsg_launch_sync_sync.v/\$$BASEJUMP_STL_DIR\/hard\/xilinx\/common\/bsg_async\/bsg_launch_sync_sync.v/g" $(BASE_FLIST)
	sed -i "s/.*bsg_mux.v/\$$BASEJUMP_STL_DIR\/hard\/xilinx\/7_series\/bsg_misc\/bsg_mux.v/g" $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

