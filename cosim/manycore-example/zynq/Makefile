include ../Makefile.design

#############################
# Accelerator Software Settings
#############################

#CFLAGS += -DZYNQ_PL_DEBUG
#CFLAGS += -DZYNQ_PS_DEBUG
#CFLAGS += -DVERIFY_NBF
CFLAGS += -DNUM_FINISH=1
CFLAGS += -D_BSD_SOURCE -D_DEFAULT_SOURCE
CFLAGS += -I$(BSG_REPLICANT_DIR)/libraries

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += GP1_ADDR_SIZE_BYTES=0x30000000
ifeq ($(BOARDNAME),pynqz2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=80
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=200
endif

SIM_ARGS += $(NBF_FILE)

include $(COSIM_MK_DIR)/Makefile.zynq

