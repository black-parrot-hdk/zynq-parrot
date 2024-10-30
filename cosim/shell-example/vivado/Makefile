include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST   ?= $(abspath ../flist.vcs)
FLIST        ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@
	sed -i "/bsg_decode_thermometer.v/d" $@
	sed -i "/bsg_icg_neg.sv/d" $@
	sed -i "/bsg_icg_pos.sv/d" $@
	sed -i "/test_bsg_clock_params.sv/d" $@

include $(COSIM_DIR)/mk/Makefile.vivado

