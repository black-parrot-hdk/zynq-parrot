PS_FILE=../ps.cpp

# you must set these for the accelerator to work

CFLAGS+= -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=6 -DGP0_DATA_WIDTH=32
CFLAGS+= -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=6 -DGP1_DATA_WIDTH=32

all:
	g++ -g -L/usr/lib/ -I../../include/fpga $(CFLAGS) -O2 $(PS_FILE)  -lcma -lpthread
	sudo ./a.out

clean:
	-rm -f *~ ./a.out sds_trace_data.dat


