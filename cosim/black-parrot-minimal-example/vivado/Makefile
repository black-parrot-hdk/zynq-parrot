include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
TOP_FLIST  ?= $(abspath flist.blackparrot.vcs)
UART_FLIST ?= $(abspath flist.uart.vcs)
FLIST      ?= $(UART_FLIST) $(TOP_FLIST)

$(UART_FLIST):
	echo "$(BASEJUMP_STL_DIR)/bsg_axi/bsg_axi_pkg.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_serial_in_parallel_out_full.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_parallel_in_serial_out.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_one_fifo.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_two_fifo.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_flow_counter.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_round_robin_1_to_n.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_counter_clear_up.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_counter_up_down.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode_with_v.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_reset.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_reset_en.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux_one_hot.sv" >> $@
	echo "$(BLACKPARROT_SUB_DIR)/axi/v/bsg_axil_fifo_master.sv" >> $@
	echo "$(BLACKPARROT_SUB_DIR)/axi/v/bsg_axil_fifo_client.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_zynq_uart_bridge.sv" >> $@
	echo "$(CURR_VSRC_DIR)/uart.v" >> $@
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

