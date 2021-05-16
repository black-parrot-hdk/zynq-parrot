## Set environment variables
TOPLEVEL ?= $(shell git rev-parse --show-toplevel)

#export BLACKPARROT_DIR  = /home/svijay97/black-parrot
export BLACKPARROT_DIR:= $(abspath ../../import/black-parrot)
export BSG_ZYNQ_PL_SHELL_DIR:= $(abspath ../../common/v)
export BP_FE_DIR        = $(BLACKPARROT_DIR)/bp_fe
export BP_COMMON_DIR    = $(BLACKPARROT_DIR)/bp_common
export BP_BE_DIR        = $(BLACKPARROT_DIR)/bp_be
export BP_ME_DIR        = $(BLACKPARROT_DIR)/bp_me
export BP_TOP_DIR       = $(BLACKPARROT_DIR)/bp_top
export BP_EXTERNAL_DIR  = $(BLACKPARROT_DIR)/external
export BASEJUMP_STL_DIR = $(BP_EXTERNAL_DIR)/basejump_stl
export HARDFLOAT_DIR    = $(BP_EXTERNAL_DIR)/HardFloat
export BP_TOOLS_DIR     = $(BLACKPARROT_DIR)/tools
export BP_SDK_DIR       = $(BLACKPARROT_DIR)/sdk
export BP_HDK_DIR       = $(BLACKPARROT_DIR)/hdk

export TEST_DIR ?= .
export TOP  ?= top
export HOST-PROGRAM ?= ps.cpp

$(warning Using BSG_ZYNQ_PL_SHELL_DIR=$(BSG_ZYNQ_PL_SHELL_DIR))
$(warning Using BLACKPARROT_DIR=$(BLACKPARROT_DIR))

VV_OPTS  = --cc
VV_OPTS += -O1
VV_OPTS += --x-assign fast --x-initial fast
VV_OPTS += --threads 1
VV_OPTS += -top-module $(TOP)
VV_OPTS += -f flist.vcs
VV_OPTS += --build
VV_OPTS += -Wno-timescalemod
VV_OPTS += --Wno-fatal --Wno-lint --Wno-unoptflat --Wno-widthconcat --Wno-style
VV_OPTS += -I$(BP_SDK_DIR)/install/include
VV_OPTS += -I$(BP_TOOLS_DIR)/install/share/verilator/include/vltstd/

INCLUDES=-I../../include/verilator -I../../../include/verilator
#VERILOG-INCLUDES= -I../../import/basejump_stl/bsg_misc -I../../../import/basejump_stl/bsg_misc -I../../import/basejump_stl/bsg_cache -I../../import/basejump_stl/bsg_dataflow -I../../../import/basejump_stl/bsg_dataflow  -I../../import/basejump_stl/bsg_mem -I../../../import/basejump_stl/bsg_mem -I$(BP_FE_DIR)/src/include -I$(BP_COMMON_DIR)/src/include -I$(BP_TOP_DIR)/src/include -I$(BP_BE_DIR)/src/include -I$(BP_ME_DIR)/include
VPATH=../ . 

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!

THE_FLAGS = -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_SIZE_BYTES=0x40000000 $(INCLUDES) -DBSG_ENABLE_S01

top: all

verilate: $(HOST-PROGRAM)
	verilator $(VV_OPTS) -sv -CFLAGS "$(THE_FLAGS)" $(TRACE)  -exe $< 2>&1 | tee build.log

recursive: verilate
	make -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

all: recursive
	obj_dir/V$(TOP) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst

view:
	gtkwave -f trace.fst
