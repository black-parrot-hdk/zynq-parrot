export TEST_DIR ?= .
export TOP  ?= top
export TEST ?= ps
export AXI_NAME ?= s00_axi

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!

THE_FLAGS = -DNAME=s00_axi -DCLOCK=_aclk -DRESETN=_aresetn -DADDR_BASE=0x40000000 -DADDR_SIZE_BYTES=4096

top: all

#$(TEST)_tmp.cpp:
#	sed "s/Vtop/V$(TOP)/g" $(TEST).cpp > $@
#	sed -i "s/axil_func/axil_func_tmp/" $@

#axil_func_tmp.h:
#	sed "s/s00_axi/$(AXI_NAME)/" axil_func.h > $@

verilate: $(TEST).cpp bp_zynq_pl.h
	verilator -CFLAGS "$(THE_FLAGS)" -Wall -Wno-UNUSED $(TRACE) -cc $(TOP).v -exe $(TEST).cpp

recursive: verilate
	make -j -C obj_dir/ -f V$(TOP).mk V$(TOP)

all: recursive
	obj_dir/V$(TOP) +bsg_trace

clean:
	-rm -rf obj_dir/ *~ trace.fst
	-rm -f $(TEST)_tmp.cpp
	-rm -f axil_func_tmp.h

view:
	gtkwave -f trace.fst
