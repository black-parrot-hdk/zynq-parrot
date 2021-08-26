TOP   := $(shell git rev-parse --show-toplevel)
CURR  := $(shell pwd)

#############################
# Project Settings
#############################
export PART       ?= xc7z020clg400-1
export TOP_MODULE ?= top
export BASENAME   ?= shell

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
BASE_FLIST   ?= $(abspath ../flist.vcs)
FLIST        ?= $(abspath flist.vcs)

CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32

include $(TOP)/cosim/mk/Makefile.fpga

#############################
# Modify base flist
#############################
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@

