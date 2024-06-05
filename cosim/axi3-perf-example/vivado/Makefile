include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST   ?= $(abspath ../flist.vcs)
FLIST        ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@

ifneq ($(BOARDNAME),pynqz2)
$(error Only PynqZ2 currently supported)
endif

include $(TOP)/cosim/mk/Makefile.vivado

