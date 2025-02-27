include ../Makefile.design

#############################
# Accelerator Software Settings
#############################

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += GP1_ADDR_SIZE_BYTES=0x30000000
ifeq ($(BOARDNAME),pynqz2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=64
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=200
endif

include $(TOP)/cosim/mk/Makefile.zynq

