include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -mfpu=neon

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += NEON

include $(TOP)/cosim/mk/Makefile.zynq

