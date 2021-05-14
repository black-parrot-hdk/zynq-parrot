PS_FILE=../ps.cpp

# you must set these for the accelerator to work

CFLAGS=-DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_SIZE_BYTES=4096 -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_SIZE_BYTES=0x40000000

all:
	g++ -g -L/usr/lib/ -I../../include/fpga $(CFLAGS) -O2 $(PS_FILE)  -lcma -lpthread
	sudo ./a.out

clean:
	-rm -f *~ ./a.out sds_trace_data.dat


