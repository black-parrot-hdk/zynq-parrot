.PHONY: fpga_build

PS_FILE=../ps.cpp

# you must set these for the accelerator to work

CFLAGS=-DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x83C00000 -DGP1_ADDR_SIZE_BYTES=4096

all:
	g++ -I../../include/fpga/ $(CFLAGS) -O2 $(PS_FILE)
	sudo ./a.out

clean: clean_fpga_build
	-rm a.out

clean_fpga_build:
	-rm *.log
	#-rm *.jou
	-rm -rf fartcloud*
	-rm -rf fpga_build
	-rm -rf poopcloud*

fpga_build: clean_fpga_build
	mkdir fpga_build
	vivado -source vivado-build-ip.tcl -mode tcl
	vivado -source vivado-create-block.tcl -mode tcl
