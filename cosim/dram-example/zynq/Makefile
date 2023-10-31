include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += GP0_ENABLE
DEFINES += GP0_ADDR_BASE=0x40000000 GP0_ADDR_SIZE_BYTES=65536 GP0_ADDR_WIDTH=6 GP0_DATA_WIDTH=32
DEFINES += GP1_ENABLE
DEFINES += GP1_ADDR_BASE=0x80000000 GP1_ADDR_SIZE_BYTES=65536 GP1_ADDR_WIDTH=6 GP1_DATA_WIDTH=32

include $(TOP)/cosim/mk/Makefile.zynq

