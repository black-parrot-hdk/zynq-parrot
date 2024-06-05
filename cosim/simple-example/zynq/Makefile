include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PS_DEBUG

ifeq ($(BOARDNAME),pynqz2)
DEFINES += GP0_ADDR_BASE=0x40000000
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += GP0_ADDR_BASE=0xA0000000
endif

include $(TOP)/cosim/mk/Makefile.zynq

