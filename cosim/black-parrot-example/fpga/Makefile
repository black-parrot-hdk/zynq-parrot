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
	@echo "## See the makefile for the fun things you can do in this directory"

# you do this on the zynq board itself
control-program: $(PS_FILE) Makefile
	g++ -I../../include/fpga/ $(CFLAGS) -O2 $(PS_FILE) $(SKIP_DRAM) -lcma -lpthread -o $@

run:	control-program
	sudo ./control-program $(NBF_FILE)

# do this on a x86 server that has vivado 2019.X
fpga_build:
	$(MAKE) fpga_build_ip
	$(MAKE) fpga_build_block

# combine BP IP with Zynq ARM core and then synthesize, pnr and bitfile generate
# on the x86 server

fpga_report_build_block:
	-@grep --color "CRITICAL WARNING" vivado.log
	-@grep --color "ERROR" vivado.log
	-@tail -n5 vivado.log
	-@grep --color "ERROR" `find . -iname "*.log"`
	-@grep -m 1 -A 3 WNS black_parrot_bd_proj.runs/impl_1/black_parrot_bd_1_wrapper_timing_summary_routed.rpt
	-@echo "## See black_parrot_bd_proj.runs/impl_1/black_parrot_bd_1_wrapper_timing_summary_routed.rpt for timing report."

fpga_build_block:
	-$(XILINX_ENV) && vivado -source vivado-create-block.tcl -mode tcl
	$(MAKE) fpga_report_build_block

# this packages the BP IP, but does not continue to synthesis, pnr and bitfile generation
# on the x86 server

fpga_build_ip: clean_fpga_build flist.vcs
	mkdir fpga_build
	$(XILINX_ENV) && vivado -source vivado-build-ip.tcl -mode tcl
	-@grep --color "CRITICAL WARNING" vivado.log
	-@grep --color "ERROR" vivado.log
	-@tail -n5 vivado.log

# create the flist file incorporating zynq parrot source with the bp source
# on the x86 server

flist.vcs: ../../import/black-parrot/bp_top/syn/flist.vcs Makefile
	cp $< $@
	echo "../bp_unicore_axi_sim.sv" >> flist.vcs
	echo "../bp_to_axi_decoder.sv" >> flist.vcs
	echo "\$$BSG_ZYNQ_PL_SHELL_DIR/bsg_zynq_pl_shell.v" >> flist.vcs
	echo "../top_zynq.sv" >> flist.vcs
	echo "top.v" >> flist.vcs

# packup up bitstream for shipping to the Zynq board (.b64)
# on the x86 server

pack_bitstream:
	cp $(BASENAME)_bd_proj.srcs/sources_1/bd/$(BASENAME)_bd_1/hw_handoff/$(BASENAME)_bd_1* .
	cp $(BASENAME)_bd_proj.runs/impl_1/$(BASENAME)_bd_1_wrapper.bit $(BASENAME)_bd_1.bit
#	tar -Jc $(BASENAME)_bd_1* | base64 > $(BASENAME)_bd_1.tar.xz.b64
	tar -Jc $(BASENAME)_bd_1.bit $(BASENAME)_bd_1_bd.tcl $(BASENAME)_bd_1.hwh | base64 > $(BASENAME)_bd_1.tar.xz.b64

# unpackage the bitstream on the Zynq board (copy the .b64 file into this dir first)
unpack_bitstream:
	base64 -d $(BASENAME)_bd_1.tar.xz.b64 | tar xvJ

# load the bitstream on the Zynq board (copy the .b64 file into this dir first)
# make sure to unpack it first

load_bitstream: control-program
	echo 'import pprint; from pynq import Overlay; overlay=Overlay("$(BASENAME)_bd_1.bit"); print (overlay.__doc__); pprint.pprint(overlay.ip_dict,width=1); pprint.pprint(overlay.clock_dict,width=1);' | sudo python3
	@echo 'allocating memory and sleeping...'
	sudo ./control-program &

print_clocks:
	echo 'from pynq import Clocks; print("PL Clock: ",Clocks.fclk0_mhz,"MHz"); print("PS Clock: ",Clocks.cpu_mhz,"MHz");' | sudo python3

%.set_clock:
	echo 'from pynq import Clocks;  Clocks.fclk0_mhz = $*; print("PL Clock Set To:: ",Clocks.fclk0_mhz,"MHz"); ' | sudo python3

# use this instead if you have already loaded the bitstream this will load the bitstream, but transfer
# over the physical memory pointer that was written into the accelerator before
# this way we do not need to reallocate dram
# on the zynq board

reload_bitstream_keep_dram:
	echo 'import pprint; from pynq import Overlay, MMIO; mmio=MMIO(0x40000000,0x1000); val4 = mmio.read(0x4); val8 = mmio.read(0x8);  overlay=Overlay("$(BASENAME)_bd_1.bit"); print("transferring over: ", hex(val4), hex(val8)); mmio.write(0x4,val4); mmio.write(0x8,val8);  print (overlay.__doc__); pprint.pprint(overlay.ip_dict,width=1); pprint.pprint(overlay.clock_dict,width=1)' | sudo python3

clean: clean_fpga_build
	-rm control-program

clean_fpga_build:
	-rm *.log *.b64
	#-rm *.jou
	-rm -rf $(BASENAME)_ip_proj*
	-rm -rf fpga_build
	-rm -rf $(BASENAME)_bd_proj*
	-rm $(BASENAME)_bd_1.bit $(BASENAME)_bd_1.hwh $(BASENAME)_bd_1_bd.tcl
	-rm -rf sds_trace_data.dat flist.vcs


