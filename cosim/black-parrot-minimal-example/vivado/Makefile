include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
TOP_FLIST  ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(TOP_FLIST)

$(TOP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | envsubst > $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Harden synchronizers and clock muxes
	sed -i "s#.*bsg_launch_sync_sync.v#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_async/bsg_launch_sync_sync.v#g" $@
	sed -i "s#.*bsg_mux.v#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_mux.v#g" $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "s#.*bsg_mem_1rw_sync_mask_write_bit.v#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v#g" $@

include $(TOP)/cosim/mk/Makefile.vivado

