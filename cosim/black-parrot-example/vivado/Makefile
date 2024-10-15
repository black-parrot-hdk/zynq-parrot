include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
BP_FLIST ?= $(abspath flist.blackparrot.vcs)
FLIST ?= $(abspath flist.vcs)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | sed "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" | envsubst > $@
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(CURR_VSRC_DIR)/bp_common_pkg.sv" $@

$(FLIST): $(BP_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Harden synchronizers and clock muxes
	sed -i "s#.*bsg_launch_sync_sync.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_async/bsg_launch_sync_sync.sv#g" $@
	sed -i "s#.*bsg_mux.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_mux.sv#g" $@
	# Harden memories
	sed -i "s#.*bsg_mem_1r1w_sync.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1r1w_sync.sv#g" $@
	sed -i "s#.*bsg_mem_1rw_sync.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync.sv#g" $@
	sed -i "s#.*bsg_mem_1rw_sync_mask_write_byte.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_byte.sv#g" $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.sv/d" $@
	sed -i "s#.*bsg_mem_1rw_sync_mask_write_bit.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.sv#g" $@
	echo "$(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_from_1r1w.sv" >> $@
	sed -i "/bsg_decode_thermometer.v/d" $@
	sed -i "/bsg_icg_neg.sv/d" $@
	sed -i "/bsg_icg_pos.sv/d" $@
	sed -i "/test_bsg_clock_params.sv/d" $@
	# Fixing recursive instantiation bug in vivado 2022.2
	sed    "s/\`BSG_INV_PARAM(width_p)/width_p = 1/" $(BASEJUMP_STL_DIR)/bsg_misc/bsg_popcount.sv > $(CURR_VSRC_DIR)/bsg_popcount.sv
	sed -i "/bsg_popcount.sv/d" $@
	echo $(CURR_VSRC_DIR)/bsg_popcount.sv >> $@

include $(TOP)/cosim/mk/Makefile.vivado

