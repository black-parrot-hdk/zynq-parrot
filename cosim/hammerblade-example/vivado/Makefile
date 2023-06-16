include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
MC_FLIST   ?= $(abspath flist.manycore.vcs)
BP_FLIST   ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(abspath flist.vcs)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(CURR_SRC_DIR)/bp_common_pkg.sv" $@

$(MC_FLIST): $(BSG_MANYCORE_DIR)/machines/arch_filelist.mk
	cp $^ $@
	sed -i "s/(/{/g" $@
	sed -i "s/)/}/g" $@
	sed -i "s/VINCLUDES += /+incdir+/g" $@
	sed -i "s/VHEADERS += //g" $@
	sed -i "s/VSOURCES += //g" $@

$(FLIST): $(BP_FLIST) $(MC_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

open:
	$(VIVADO) &

