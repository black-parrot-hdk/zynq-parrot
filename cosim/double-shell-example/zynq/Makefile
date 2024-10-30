include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += GP1_ADDR_SIZE_BYTES=4096

#############################
# Modify base flist
#############################
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@

include $(COSIM_MK_DIR)/Makefile.zynq

