PS_FILE=../ps.cpp

# you must set these for the accelerator to work

CFLAGS=-DADDR_BASE=0x43C00000 -DADDR_SIZE_BYTES=4096

all:
	g++ -g -L/usr/lib/ -I../../include/fpga $(CFLAGS) -O2 $(PS_FILE)  -lcma -lpthread
	sudo ./a.out

clean:
	-rm -f *~ ./a.out sds_trace_data.dat


