TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
VPATH := $(CURR)/.. $(CURR)

include 

# you must set these for the accelerator to work
HOST_PROGRAM=../ps.cpp
BASENAME=blackparrot
NBF_FILE ?=../prog.nbf
SIM_ARGS ?= $(NBF_FILE)
SKIP_DRAM=-DSKIP_DRAM_TESTING

CFLAGS+= -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_WIDTH=6  -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_DATA_WIDTH=32
CFLAGS+= -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=30 -DGP1_ADDR_SIZE_BYTES=0x30000000 -DGP1_DATA_WIDTH=32
CFLAGS+= -DFPGA=1

# create the flist file incorporating zynq parrot source with the bp source
# on the x86 server
flist.vcs: ../../import/black-parrot/bp_top/syn/flist.vcs
	cp $< $@
	echo "../v/bp_unicore_axi_sim.sv" >> flist.vcs
	echo "../v/bp_to_axi_decoder.sv" >> flist.vcs
	echo "../../import/black-parrot/bp_me/src/v/network/bp_lite_to_axi_lite_master.sv" >> flist.vcs
	echo "../../import/black-parrot/bp_me/src/v/network/axi_lite_to_bp_lite_client.sv" >> flist.vcs
	echo "../../import/black-parrot/external/basejump_stl/bsg_cache/bsg_cache_to_axi.v" >> flist.vcs
	echo "../../import/black-parrot/external/basejump_stl/bsg_cache/bsg_cache_to_axi_rx.v" >> flist.vcs
	echo "../../import/black-parrot/external/basejump_stl/bsg_cache/bsg_cache_to_axi_tx.v" >> flist.vcs
	echo "\$$BSG_ZYNQ_PL_SHELL_DIR/bsg_zynq_pl_shell.v" >> flist.vcs
	echo "../v/top_zynq.sv" >> flist.vcs
	echo "../v/top.v" >> flist.vcs

include $(TOP)/cosim//mk/Makefile.fpga

