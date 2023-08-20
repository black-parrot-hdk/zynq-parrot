include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
NBF_FILE     ?= $(abspath ../prog.nbf)
HOST_PROGRAM ?= $(abspath ../ps.cpp)
SIM_ARGS     += $(NBF_FILE)

#CFLAGS += -DZYNQ_PL_DEBUG
#CFLAGS += -DZYNQ_PS_DEBUG
#CFLAGS += -DVERIFY_NBF
CFLAGS += -DNUM_FINISH=1
CFLAGS += -D_BSD_SOURCE -D_DEFAULT_SOURCE
CFLAGS += -DGP0_DATA_WIDTH=32 -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_ADDR_WIDTH=10
CFLAGS += -I$(BSG_REPLICANT_DIR)/libraries

ifeq ($(BOARDNAME),pynqz2)
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000
CFLAGS += -DDRAM_ALLOCATE_SIZE_MB=80
else ifeq ($(BOARDNAME),ultra96v2)
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x400000000
CFLAGS += -DDRAM_ALLOCATE_SIZE_MB=200
endif

include $(TOP)/cosim/mk/Makefile.fpga

