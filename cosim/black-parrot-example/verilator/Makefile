
## Set environment variables
TOPLEVEL ?= $(shell git rev-parse --show-toplevel)

export BLACKPARROT_DIR := $(abspath ../../import/black-parrot)
export BP_SDK_DIR      := $(abspath ../../import/black-parrot-sdk)
export BSG_ZYNQ_PL_SHELL_DIR:= $(abspath ../../common/v)

# these defines are used by the flist.vcs file
export BP_FE_DIR        = $(BLACKPARROT_DIR)/bp_fe
export BP_COMMON_DIR    = $(BLACKPARROT_DIR)/bp_common
export BP_BE_DIR        = $(BLACKPARROT_DIR)/bp_be
export BP_ME_DIR        = $(BLACKPARROT_DIR)/bp_me
export BP_TOP_DIR       = $(BLACKPARROT_DIR)/bp_top
export BP_EXTERNAL_DIR  = $(BLACKPARROT_DIR)/external
#export BASEJUMP_STL_DIR = $(BP_EXTERNAL_DIR)/basejump_stl
export BASEJUMP_STL_DIR = ../../import/black-parrot/external/basejump_stl/
export HARDFLOAT_DIR    = $(BP_EXTERNAL_DIR)/HardFloat


ifeq ($(shell /usr/bin/arch),armv7l)
#export VERILATOR=/usr/local/bin/verilator
else
#export VERILATOR_ROOT?=/gro/cad/verilator/v4.202/verilator/
#export VERILATOR?=$(VERILATOR_ROOT)/bin/verilator
endif
VERILATOR ?= verilator

# FIXME: check verilator version

#ifeq ($(wildcard $(VERILATOR)),)
#$(error "VERILATOR variable must be set!")
#endif

export BP_TOOLS_DIR     = $(BLACKPARROT_DIR)/tools

export PATH := $(BP_TOOLS_DIR)/install/bin:$(PATH)

export TEST_DIR ?= .
export TOP  ?= top
export HOST-PROGRAM ?= ps.cpp
NBF_FILE=../prog.nbf

$(warning Using BSG_ZYNQ_PL_SHELL_DIR=$(BSG_ZYNQ_PL_SHELL_DIR))
$(warning Using BLACKPARROT_DIR=$(BLACKPARROT_DIR))

VV_OPTS  = --cc
VV_OPTS += -sv
VV_OPTS += -top-module $(TOP)
VV_OPTS += -f flist.vcs
VV_OPTS += -Wno-timescalemod
VV_OPTS += --Wno-fatal --Wno-unoptflat --Wno-widthconcat --Wno-width --Wno-pinmissing --Wno-style #--Wno-lint
#VV_OPTS += -I$(BP_SDK_DIR)/install/include
VV_OPTS += --build --exe

INCLUDES=-I$(BASEJUMP_STL_DIR)/bsg_misc -I$(BASEJUMP_STL_DIR)/bsg_dataflow -I$(BASEJUMP_STL_DIR)/bsg_mem -I$(BASEJUMP_STL_DIR)/bsg_test -I../../common/v/
VPATH=../ .
SKIP_DRAM=-DSKIP_DRAM_TESTING

TRACE=--trace-fst --trace-structs


# You need to configure these parameters for your particular accelerator!

THE_FLAGS += -DZYNQ_PL_DEBUG
THE_FLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000U -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
THE_FLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000U -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=TOP.top.axil1
THE_FLAGS += $(INCLUDES) $(SKIP_DRAM)
THE_FLAGS += -I../../include/verilator -I../../../include/verilator -I../$(BASEJUMP_STL_DIR)/bsg_test

top: run

flist.vcs: ../../import/black-parrot/bp_top/syn/flist.vcs Makefile
	cp $< $@
	echo "\$$BASEJUMP_STL_DIR/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> flist.vcs
	echo "\$$BASEJUMP_STL_DIR/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> flist.vcs
	echo "\$$BASEJUMP_STL_DIR/bsg_test/bsg_nonsynth_dpi_gpio.v " >> flist.vcs
	echo "../bp_unicore_axi_sim.sv" >> flist.vcs
	echo "../../import/black-parrot/bp_me/src/v/network/bp_lite_to_axi_lite_master.sv" >> flist.vcs
	echo "../../import/black-parrot/bp_me/src/v/network/axi_lite_to_bp_lite_client.sv" >> flist.vcs
	echo "\$$BSG_ZYNQ_PL_SHELL_DIR/bsg_zynq_pl_shell.v" >> flist.vcs
	echo "../bp_to_axi_decoder.sv" >> flist.vcs
	echo "../top_zynq.sv" >> flist.vcs
	echo "top.v" >> flist.vcs

obj_dir/V$(TOP): $(HOST-PROGRAM) flist.vcs
	$(VERILATOR) $(VV_OPTS) -CFLAGS "$(THE_FLAGS)" $(TRACE) $(INCLUDES) $<

# we do not log here, because we want this to be invokable by other directories, running in parallel

run: obj_dir/V$(TOP)
	$< $(NBF_FILE) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst build.log flist.vcs

view:
	gtkwave -f trace.fst
