export TEST_DIR ?= .
export TOP  ?= top
export HOST-PROGRAM ?= ps.cpp
export AXI_NAME ?= s00_axi

INCLUDES=-I../../include/verilator -I../../../include/verilator
VERILOG-INCLUDES= -I../../import/basejump_stl/bsg_misc -I../../../import/basejump_stl/bsg_misc -I../../import/basejump_stl/bsg_dataflow -I../../../import/basejump_stl/bsg_dataflow  -I../../import/basejump_stl/bsg_mem -I../../../import/basejump_stl/bsg_mem
VPATH=../ .

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!

THE_FLAGS = -DNAME=s00_axi -DCLOCK=_aclk -DRESETN=_aresetn -DADDR_BASE=0x43C00000 -DADDR_SIZE_BYTES=4096 $(INCLUDES)

top: all

verilate: $(HOST-PROGRAM)
	verilator -Wno-fatal -timescale 1ns/1ps -sv $(VERILOG-INCLUDES) -CFLAGS  "$(THE_FLAGS)" -Wno-UNUSED $(TRACE) -y ../../import/basejump_stl/ -cc $(TOP).v  -exe $<

recursive: verilate
	make -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

all: recursive
	obj_dir/V$(TOP) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst

view:
	gtkwave -f trace.fst
