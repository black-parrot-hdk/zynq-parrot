PS_FILE=../ps.cpp

# you must set these for the accelerator to work

CFLAGS=-DADDR_BASE=0x43C00000 -DADDR_SIZE_BYTES=4096

all:
	g++ -I../../include/fpga/ $(CFLAGS) -O2 $(PS_FILE)
	sudo ./a.out

clean:
	-rm a.out

