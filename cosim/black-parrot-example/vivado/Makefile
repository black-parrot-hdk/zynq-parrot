include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
WD_FLIST   ?= $(abspath flist.watchdog.vcs)
TOP_FLIST  ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(WD_FLIST) $(TOP_FLIST)

$(WD_FLIST):
	echo "+incdir+$(BASEJUMP_STL_DIR)/bsg_misc" >> $@
	echo "+incdir+$(BASEJUMP_STL_DIR)/bsg_tag" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux2_gatestack.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_async/bsg_launch_sync_sync.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_tag/bsg_tag_pkg.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_tag/bsg_tag_master_decentralized.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_tag/bsg_tag_client.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_axi/bsg_axi_pkg.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_counter_clear_up.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_one_fifo.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_reset.sv" >> $@
	echo "$(BLACKPARROT_SUB_DIR)/axi/v/bsg_axil_fifo_master.sv" >> $@
	echo "$(CURR_VSRC_DIR)/zynq_pkg.sv" >> $@
	echo "$(CURR_VSRC_DIR)/bsg_axil_watchdog.sv" >> $@
	echo "$(CURR_VSRC_DIR)/watchdog.v" >> $@
	# Harden synchronizers and clock muxes
	sed -i "s#.*bsg_launch_sync_sync.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_async/bsg_launch_sync_sync.sv#g" $@
	sed -i "s#.*bsg_mux.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_mux.sv#g" $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "s#.*bsg_mem_1rw_sync_mask_write_bit.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.sv#g" $@

$(TOP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | envsubst > $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(CURR_VSRC_DIR)/bp_common_pkg.sv" $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Harden synchronizers and clock muxes
	sed -i "s#.*bsg_launch_sync_sync.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_async/bsg_launch_sync_sync.sv#g" $@
	sed -i "s#.*bsg_mux.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_mux.sv#g" $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "s#.*bsg_mem_1rw_sync_mask_write_bit.sv#$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.sv#g" $@

include $(TOP)/cosim/mk/Makefile.vivado

