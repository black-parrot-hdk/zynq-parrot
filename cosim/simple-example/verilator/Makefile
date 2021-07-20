export TEST_DIR ?= .
export TOP  ?= top
export HOST-PROGRAM ?= ps.cpp
export AXI_NAME ?= s00_axi

VERILATOR ?= verilator

VPATH=../ .

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!
BASEJUMP_STL = ../../import/black-parrot/external/basejump_stl/

THE_FLAGS = -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_SIZE_BYTES=4096
THE_FLAGS += -I../../include/verilator -I../../include/verilator -I../../../include/verilator -I../$(BASEJUMP_STL)/bsg_test

top: all

INCLUDES=-I$(BASEJUMP_STL)/bsg_misc -I$(BASEJUMP_STL)/bsg_dataflow -I$(BASEJUMP_STL)/bsg_mem -I$(BASEJUMP_STL)/bsg_test ../../import/black-parrot/external/basejump_stl/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp

VV_OPTS = -Wno-timescalemod -Wno-DECLFILENAME -Wno-fatal

verilate: $(HOST-PROGRAM)
	$(VERILATOR) $(VV_OPTS) -CFLAGS "$(THE_FLAGS)" -Wall -Wno-UNUSED $(TRACE) -cc $(INCLUDES) $(TOP).v -exe $<

recursive: verilate
	make -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

all: recursive
	obj_dir/V$(TOP) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst

view:
	gtkwave -f trace.fst
