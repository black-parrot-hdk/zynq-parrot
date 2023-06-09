include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
MC_FLIST   ?= $(abspath flist.manycore.vcs)
FLIST      ?= $(abspath flist.vcs)

$(MC_FLIST): $(BSG_MANYCORE_DIR)/machines/arch_filelist.mk
	cp $^ $@
	sed -i "s/(/{/g" $@
	sed -i "s/)/}/g" $@
	sed -i "s/VINCLUDES += /+incdir+/g" $@
	sed -i "s/VHEADERS += //g" $@
	sed -i "s/VSOURCES += //g" $@

$(FLIST): $(MC_FLIST) $(BASE_FLIST)
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
