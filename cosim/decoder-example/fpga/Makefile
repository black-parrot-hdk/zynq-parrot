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
	-rm -rf decode_ip_proj*
	-rm -rf fpga_build
	-rm -rf decode_bd_proj*

fpga_build: clean_fpga_build
	mkdir fpga_build
	vivado -source vivado-build-ip.tcl -mode tcl
	vivado -source vivado-create-block.tcl -mode tcl

pack_bitstream:
	cp decode_bd_proj.srcs/sources_1/bd/decode_bd_1/hw_handoff/decode_bd_1* .
	cp decode_bd_proj.runs/impl_1/decode_bd_1_wrapper.bit decode_bd_1.bit
	tar -Jc decode_bd_1* | base64 > decode_bd_1.tar.xz.b64
