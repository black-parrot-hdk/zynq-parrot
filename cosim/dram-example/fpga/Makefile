TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
include $(TOP)/Makefile.common

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_SIZE_BYTES=65536 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_SIZE_BYTES=65536 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32

include $(TOP)/cosim/mk/Makefile.fpga

