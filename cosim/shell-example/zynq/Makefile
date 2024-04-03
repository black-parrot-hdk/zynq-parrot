include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -mfpu=neon

DEFINES += GP0_ENABLE
DEFINES += GP0_ADDR_BASE=0x40000000 GP0_ADDR_WIDTH=6 GP0_DATA_WIDTH=32 GP0_ADDR_SIZE_BYTES=4096
#DEFINES += NEON

include $(TOP)/cosim/mk/Makefile.zynq

