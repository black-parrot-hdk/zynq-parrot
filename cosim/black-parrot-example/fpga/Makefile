TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
include $(TOP)/Makefile.common

#############################
# Project Settings
#############################
BASENAME   ?= blackparrot

#############################
#############################
# Accelerator Software Settings
#############################
NBF_FILE     ?= $(abspath ../prog.nbf)
HOST_PROGRAM ?= $(abspath ../ps.cpp)
SIM_ARGS     += $(NBF_FILE)

#SIM_DEFINES  +=-DSKIP_DRAM_TESTING

CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_WIDTH=6
CFLAGS += -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=30
CFLAGS += -DGP1_ADDR_SIZE_BYTES=0x30000000 -DGP1_DATA_WIDTH=32
CFLAGS += -DFREE_DRAM=1
CFLAGS += -DZERO_DRAM=0
CFLAGS += -DDRAM_ALLOCATE_SIZE_MB=100

include $(TOP)/cosim/mk/Makefile.fpga

