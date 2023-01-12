include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32 -DGP0_ADDR_SIZE_BYTES=4096
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32 -DGP1_ADDR_SIZE_BYTES=4096
CFLAGS += -mfpu=neon -DNEON

include $(TOP)/cosim/mk/Makefile.fpga

