include ../Makefile.design

#############################
# Accelerator Software Settings
#############################

#CFLAGS += -DDRAM_TEST
#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DFREE_DRAM=1
CFLAGS += -DZERO_DRAM=0

DEFINES += GP0_ADDR_SIZE_BYTES=4096
ifeq ($(BOARDNAME),pynqz2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=64
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=200
endif

SIM_ARGS += $(NBF_FILE)

include $(COSIM_MK_DIR)/Makefile.zynq

