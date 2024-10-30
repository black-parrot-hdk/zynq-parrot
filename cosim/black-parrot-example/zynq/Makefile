include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
ZYNQ_PL_DEBUG ?= 0
ZYNQ_PS_DEBUG ?= 1

CFLAGS += -DDRAM_TEST
CFLAGS += -DFREE_DRAM=1
CFLAGS += -DZERO_DRAM=1

SIM_ARGS += $(NBF_FILE)

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += GP1_ADDR_SIZE_BYTES=0x30000000
ifeq ($(BOARDNAME),pynqz2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=64
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=200
endif

include $(COSIM_MK_DIR)/Makefile.zynq

