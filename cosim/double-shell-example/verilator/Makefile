export TEST_DIR ?= .
export TOP  ?= top
export HOST-PROGRAM ?= ps.cpp
export AXI_NAME ?= s00_axi

BASEJUMP_STL := $(abspath ../../import/basejump_stl)

INCLUDES=-I../../include/verilator -I../../../include/verilator
VERILOG-INCLUDES= -I$(BASEJUMP_STL)/bsg_misc -I../$(BASEJUMP_STL)/bsg_misc -I$(BASEJUMP_STL)/bsg_dataflow -I../$(BASEJUMP_STL)/bsg_dataflow  -I$(BASEJUMP_STL)/bsg_mem -I../$(BASEJUMP_STL)/bsg_mem
VPATH=../ .  ../../../common/v ../../../../common/v

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!

THE_FLAGS = -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_SIZE_BYTES=4096 $(INCLUDES)

top: all

verilate: $(HOST-PROGRAM)
	verilator -Wno-fatal -timescale 1ns/1ps -sv $(VERILOG-INCLUDES) -CFLAGS  "$(THE_FLAGS)" -Wno-UNUSED $(TRACE) -y $(BASEJUMP_STL)/ -y ../../common/v/ -cc $(TOP).v  -exe $<

recursive: verilate
	make -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

all: recursive
	obj_dir/V$(TOP) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst

view:
	gtkwave -f trace.fst
