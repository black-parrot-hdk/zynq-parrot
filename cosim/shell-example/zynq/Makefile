TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

#############################
# Accelerator Software Settings
#############################
CFLAGS += -mfpu=neon

DEFINES += GP0_ADDR_SIZE_BYTES=4096
DEFINES += NEON

include ../Makefile.design

