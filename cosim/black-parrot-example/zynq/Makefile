include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DDRAM_TEST
#CFLAGS += -DFREE_DRAM=1
#CFLAGS += -DZERO_DRAM=1
ifneq ($(COV_EN),0)
CFLAGS += -lpynq_api
endif

SIM_ARGS += $(NBF_FILE)

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += GP1_ADDR_SIZE_BYTES=0x30000000
ifeq ($(BOARDNAME),pynqz2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=80
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=200
endif

include $(TOP)/cosim/mk/Makefile.zynq

