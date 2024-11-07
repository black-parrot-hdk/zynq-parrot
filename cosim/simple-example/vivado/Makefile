
all: simple_bd_1.map
	$(VIVADO) &

simple_bd_1.map:
ifeq ($(BOARDNAME),pynqz2)
	$(ECHO) "-DGP0_ADDR_BASE=0x40000000" >> simple_bd_1.map
else
	$(ECHO) "-DGP0_ADDR_BASE=0xA0000000" >> simple_bd_1.map
endif

include ../Makefile.design

