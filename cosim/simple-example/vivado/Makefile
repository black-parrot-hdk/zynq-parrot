
TOP ?= ../../..
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

all: simple_bd_1.map
	$(VIVADO) &

simple_bd_1.map:
ifeq ($(BOARDNAME),pynqz2)
	$(ECHO) "-DGP0_ADDR_BASE=0x40000000" >> simple_bd_1.map
else
	$(ECHO) "-DGP0_ADDR_BASE=0xA0000000" >> simple_bd_1.map
endif

#############################
# Accelerator Software Settings
#############################
include $(DESIGN_DIR)/Makefile.design
include $(COSIM_MK_DIR)/Makefile.vivado

