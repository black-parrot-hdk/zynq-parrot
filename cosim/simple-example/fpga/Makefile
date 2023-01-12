include Makefile.design

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DADDR_BASE=0x43C00000 -DADDR_SIZE_BYTES=4096

include $(TOP)/cosim/mk/Makefile.fpga

