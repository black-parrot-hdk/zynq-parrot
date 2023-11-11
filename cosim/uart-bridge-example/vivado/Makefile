include ../Makefile.design

#############################
# Modify base flist
#############################
BASE_FLIST   ?= $(abspath ../flist.vcs)
TOP_FLIST    ?= $(abspath flist.vcs)
FLIST        ?= $(TOP_FLIST)

# Export to TCL
export UART_BAUD

$(TOP_FLIST): $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

