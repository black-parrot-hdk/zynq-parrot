.PHONY: fpga_build
.PHONY: load_bitstream

PS_FILE=../ps.cpp
BASENAME=decode

# you must set these for the accelerator to work

CFLAGS=-DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x83C00000 -DGP1_ADDR_SIZE_BYTES=4096

all: load_bitstream
	g++ -I../../include/fpga/ $(CFLAGS) -O2 $(PS_FILE)
	sudo ./a.out

clean: clean_fpga_build
	-rm a.out

clean_fpga_build:
	-rm *.log
	#-rm *.jou
	-rm -rf $(BASENAME)_ip_proj*
	-rm -rf fpga_build
	-rm -rf $(BASENAME)_bd_proj*
	-rm $(BASENAME)_bd_1.bit $(BASENAME)_bd_1.hwh $(BASENAME)_bd_1_bd.tcl
	-rm -rf sds_trace_data.dat

fpga_build_ip: clean_fpga_build
	mkdir fpga_build
	vivado -source vivado-build-ip.tcl -mode tcl	

fpga_build: fpga_build_ip
	vivado -source vivado-create-block.tcl -mode tcl

pack_bitstream:
	cp $(BASENAME)_bd_proj.srcs/sources_1/bd/$(BASENAME)_bd_1/hw_handoff/$(BASENAME)_bd_1* .
	cp $(BASENAME)_bd_proj.runs/impl_1/$(BASENAME)_bd_1_wrapper.bit $(BASENAME)_bd_1.bit
	tar -Jc $(BASENAME)_bd_1* | base64 > $(BASENAME)_bd_1.tar.xz.b64

unpack_bitstream:
	base64 -d $(BASENAME)_bd_1.tar.xz.b64 | tar xvJ

load_bitstream:
	 echo 'from pynq import Overlay; overlay=Overlay("$(BASENAME)_bd_1.bit");' | sudo python3
