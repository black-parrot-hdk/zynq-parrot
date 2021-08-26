TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
VPATH := $(CURR)/.. $(CURR)

# you must set these for the accelerator to work
HOST_PROGRAM ?= ps.cpp

CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS=-DADDR_BASE=0x43C00000 -DADDR_SIZE_BYTES=4096

include $(TOP)/cosim//mk/Makefile.fpga

