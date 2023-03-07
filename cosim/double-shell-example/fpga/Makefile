include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32 -DGP0_ADDR_SIZE_BYTES=4096
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x83C00000 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32 -DGP1_ADDR_SIZE_BYTES=4096

#############################
# Modify base flist
#############################
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/fpga" >> $@

include $(TOP)/cosim/mk/Makefile.fpga

