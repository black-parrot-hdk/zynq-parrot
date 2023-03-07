include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_DATA_WIDTH=32
ifeq ($(BOARDNAME),pynqz2)
CFLAGS += -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_WIDTH=6
else ifeq ($(BOARDNAME),ultra96v2)
CFLAGS += -DGP0_ADDR_BASE=0xA0000000 -DGP0_ADDR_WIDTH=6
endif

include $(TOP)/cosim/mk/Makefile.fpga

