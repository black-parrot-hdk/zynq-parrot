include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += GP0_ENABLE GP0_DATA_WIDTH=32
ifeq ($(BOARDNAME),pynqz2)
DEFINES += GP0_ADDR_BASE=0x40000000 GP0_ADDR_WIDTH=6
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += GP0_ADDR_BASE=0xA0000000 GP0_ADDR_WIDTH=6
endif

include $(TOP)/cosim/mk/Makefile.zynq

