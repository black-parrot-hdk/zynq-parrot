export TEST_DIR ?= .
export TOP  ?= top
export TEST ?= ../ps
export AXI_NAME ?= s00_axi

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!

THE_FLAGS = -DNAME=s00_axi -DCLOCK=_aclk -DRESETN=_aresetn -DADDR_BASE=0x40000000 -DADDR_SIZE_BYTES=4096

top: all

verilate: $(TEST).cpp
	verilator -CFLAGS  "-I $(PWD) $(THE_FLAGS)" -Wall -Wno-UNUSED $(TRACE) -cc $(TOP).v -exe $(TEST).cpp

recursive: verilate
	make -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

all: recursive
	obj_dir/V$(TOP) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst

view:
	gtkwave -f trace.fst
