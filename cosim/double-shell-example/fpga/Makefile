TOP   := $(shell git rev-parse --show-toplevel)
CURR  := $(shell pwd)
VPATH := $(CURR)/.. $(CURR)

# you must set these for the accelerator to work
HOST_PROGRAM ?= ps.cpp
BASENAME     ?= double_shell

CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x83C00000 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32

include $(TOP)/cosim/mk/Makefile.fpga

