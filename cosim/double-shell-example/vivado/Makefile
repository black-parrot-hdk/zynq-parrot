include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST      ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

