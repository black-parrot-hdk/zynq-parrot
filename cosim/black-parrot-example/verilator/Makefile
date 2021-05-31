
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
export BASEJUMP_STL_DIR = $(BP_EXTERNAL_DIR)/basejump_stl
export HARDFLOAT_DIR    = $(BP_EXTERNAL_DIR)/HardFloat


ifeq ($(shell /usr/bin/arch),armv7l)
export VERILATOR=/usr/local/bin/verilator
else
export VERILATOR_ROOT?=/gro/cad/verilator/v4.202/verilator/
export VERILATOR?=$(VERILATOR_ROOT)/bin/verilator
endif

ifeq ($(wildcard $(VERILATOR)),)
$(error "VERILATOR variable must be set!")
endif

export BP_TOOLS_DIR     = $(BLACKPARROT_DIR)/tools

export PATH := $(BP_TOOLS_DIR)/install/bin:$(PATH)

export TEST_DIR ?= .
export TOP  ?= top
export HOST-PROGRAM ?= ps.cpp
NBF_FILE=../prog.nbf

$(warning Using BSG_ZYNQ_PL_SHELL_DIR=$(BSG_ZYNQ_PL_SHELL_DIR))
$(warning Using BLACKPARROT_DIR=$(BLACKPARROT_DIR))

VV_OPTS  = --cc
VV_OPTS += -O1
VV_OPTS += --x-assign fast --x-initial fast
VV_OPTS += --threads 1
VV_OPTS += -top-module $(TOP)
VV_OPTS += -f flist.vcs
VV_OPTS += --build -j 4
VV_OPTS += -Wno-timescalemod
VV_OPTS += --Wno-fatal --Wno-unoptflat --Wno-widthconcat --Wno-width --Wno-pinmissing --Wno-style #--Wno-lint
VV_OPTS += -I$(BP_SDK_DIR)/install/include
VV_OPTS += -I$(BP_TOOLS_DIR)/install/share/verilator/include/vltstd/

INCLUDES=-I../../include/verilator -I../../../include/verilator
VPATH=../ . 

SKIP_DRAM=-DSKIP_DRAM_TESTING

TRACE=--trace-fst --trace-structs


# You need to configure these parameters for your particular accelerator!

THE_FLAGS = -DGP0_ADDR_BASE=0x40000000U -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x80000000U -DGP1_ADDR_SIZE_BYTES=0x30000000U $(INCLUDES) -DBSG_ENABLE_S01  $(SKIP_DRAM)

top: run

flist.vcs: ../../import/black-parrot/bp_top/syn/flist.vcs Makefile
	cp $< $@
	echo "../bp_unicore_axi_sim.sv" >> flist.vcs
	echo "../bp_to_axi_decoder.sv" >> flist.vcs
	echo "\$$BSG_ZYNQ_PL_SHELL_DIR/bsg_zynq_pl_shell.v" >> flist.vcs
	echo "../top_zynq.sv" >> flist.vcs
	echo "top.v" >> flist.vcs

obj_dir/V$(TOP):  $(HOST-PROGRAM) flist.vcs
	$(VERILATOR) $(VV_OPTS) -sv -CFLAGS "$(THE_FLAGS)" $(TRACE)  -exe $< 2>&1 | tee build.log
	$(MAKE) -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

# we do not log here, because we want this to be invokable by other directories, running in parallel

run: obj_dir/V$(TOP)
	$< $(NBF_FILE) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst build.log flist.vcs

view:
	gtkwave -f trace.fst
