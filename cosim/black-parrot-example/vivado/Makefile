include ../Makefile.design

#############################
# Modify base flist
#############################
# AXI clock frequency
export AXI_FREQ ?= 160
# core clock frequency
export CORE_FREQ  ?= 40

# Coverage
COV_EN ?= 1
RAND_COV ?= 0
ifeq ($(RAND_COV),1)
COV_NUM ?= 36
else
COV_NUM ?= 11
endif

ifneq ($(COV_EN),0)
VDEFINES = COV_EN COV_NUM=$(COV_NUM)
ifeq ($(RAND_COV),1)
VDEFINES += RAND_COV
endif
endif

BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST ?= $(abspath flist.vcs)

$(FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | envsubst > $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(CURR_VSRC_DIR)/bp_common_pkg.sv" $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	if [ "$(COV_EN)" = "1" ]; then \
          if [ "$(RAND_COV)" = "0" ]; then \
            sed -i "/top_zynq.sv/d" $@ ;\
            echo "$(INSTRUMENTATION_DIR)/instrumented_top_zynq.sv" >> $@ ;\
          fi \
        fi
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

include ../Makefile.cov
include $(TOP)/cosim/mk/Makefile.vivado

