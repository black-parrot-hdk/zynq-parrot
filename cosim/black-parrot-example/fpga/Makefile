.PHONY: fpga_build
.PHONY: load_bitstream

# update this with a pointer to your vivado install
XILINX_ENV=source /tools/Xilinx/Vivado/2019.1/settings64.sh

# need to set the shell so that source works
SHELL := /bin/bash

PS_FILE=../ps.cpp
BASENAME=black_parrot
NBF_FILE?=../prog.nbf

SKIP_DRAM=-DSKIP_DRAM_TESTING

# you must set these for the accelerator to work

CFLAGS=-DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_SIZE_BYTES=0x30000000 -DFPGA=1

all:
	@echo See the makefile for the fun things you can do in this directory

# you do this on the zynq board itself

control-program: $(PS_FILE) Makefile
	g++ -I../../include/fpga/ $(CFLAGS) -O2 $(PS_FILE) $(SKIP_DRAM) -lcma -lpthread -o $@

run:	control-program load_bitstream
	sudo ./control-program $(NBF_FILE)

fpga_build:
	$(MAKE) fpga_build_ip
	$(MAKE) fpga_build_block

# do this on a server that has vivado 2019.X
# package BP IP, and then synthesize, pnr and bitfile generate
fpga_build_block:
	$(XILINX_ENV) && vivado -source vivado-create-block.tcl -mode tcl
	-@grep --color "CRITICAL WARNING" vivado.log
	-@grep --color "ERROR" vivado.log
	-@tail -n5 vivado.log

# this packages the BP IP, but does not continue to synthesis, pnr and bitfile generation
fpga_build_ip: clean_fpga_build flist.vcs
	mkdir fpga_build
	$(XILINX_ENV) && vivado -source vivado-build-ip.tcl -mode tcl
	-@grep --color "CRITICAL WARNING" vivado.log
	-@grep --color "ERROR" vivado.log
	-@tail -n5 vivado.log

# create the flist file incorporating zynq parrot source with the bp source
flist.vcs: ../../import/black-parrot/bp_top/syn/flist.vcs Makefile
	cp $< $@
	echo "../bp_unicore_axi_sim.sv" >> flist.vcs
	echo "../bp_to_axi_decoder.sv" >> flist.vcs
	echo "\$$BSG_ZYNQ_PL_SHELL_DIR/bsg_zynq_pl_shell.v" >> flist.vcs
	echo "../top_zynq.sv" >> flist.vcs
	echo "top.v" >> flist.vcs

# packup up bitstream for shipping to the Zynq board (.b64)
pack_bitstream:
	cp $(BASENAME)_bd_proj.srcs/sources_1/bd/$(BASENAME)_bd_1/hw_handoff/$(BASENAME)_bd_1* .
	cp $(BASENAME)_bd_proj.runs/impl_1/$(BASENAME)_bd_1_wrapper.bit $(BASENAME)_bd_1.bit
#	tar -Jc $(BASENAME)_bd_1* | base64 > $(BASENAME)_bd_1.tar.xz.b64
	tar -Jc $(BASENAME)_bd_1.bit $(BASENAME)_bd_1_bd.tcl $(BASENAME)_bd_1.hwh | base64 > $(BASENAME)_bd_1.tar.xz.b64

# unpackage the bitstream on the Zynq board (copy the .b64 file into this dir first)
unpack_bitstream:
	base64 -d $(BASENAME)_bd_1.tar.xz.b64 | tar xvJ

load_bitstream:
	 echo 'from pynq import Overlay; overlay=Overlay("$(BASENAME)_bd_1.bit");' | sudo python3


clean: clean_fpga_build
	-rm control-program

clean_fpga_build:
	-rm *.log
	#-rm *.jou
	-rm -rf $(BASENAME)_ip_proj*
	-rm -rf fpga_build
	-rm -rf $(BASENAME)_bd_proj*
	-rm $(BASENAME)_bd_1.bit $(BASENAME)_bd_1.hwh $(BASENAME)_bd_1_bd.tcl
	-rm -rf sds_trace_data.dat flist.vcs


