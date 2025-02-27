
#############################
# Accelerator Software Settings
#############################
CFLAGS += -I$(BSG_REPLICANT_DIR)/libraries

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += GP1_ADDR_SIZE_BYTES=0x30000000
ifeq ($(BOARDNAME),pynqz2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=80
else ifeq ($(BOARDNAME),ultra96v2)
DEFINES += DRAM_ALLOCATE_SIZE_MB=200
endif

include ../Makefile.design

