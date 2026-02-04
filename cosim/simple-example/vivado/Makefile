
#############################
# Accelerator Software Settings
#############################

VIVADO_MODE := gui

all: ip_package

simple_bd_1.map:
ifeq ($(BOARDNAME),pynqz2)
	@$(ECHO) "-DGP0_ADDR_BASE=0x40000000" > $@
else
	@$(ECHO) "-DGP0_ADDR_BASE=0xA0000000" > $@
endif

include ../Makefile.design

