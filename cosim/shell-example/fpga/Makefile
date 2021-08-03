.PHONY: fpga_build
.PHONY: load_bitstream

PS_FILE=../ps.cpp
BASENAME=shell

# you must set these for the accelerator to work

CFLAGS+= -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32
CFLAGS+= -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32

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
	@echo "reminder:  source /tools/Xilinx/Vivado/2019.1/settings64.sh to init xilinx tools"
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
