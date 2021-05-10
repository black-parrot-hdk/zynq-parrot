//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.


#include <stdlib.h>
#include <stdio.h>
#include "bp_zynq_pl.h"

int main(int argc, char **argv) {
        bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

	// this program just communicates with a "loopback accelerator"
	// that has 4 control registers that you can read and write
	
	int val1 = 0xDEADBEEF;
	int val2 = 0xCAFEBABE;
	int val3 = 0x0000CADE;
	int val4 = 0xC0DE0000;
	int mask1 = 0xf;
	int mask2 = 0xf;

	// write to two registers
	zpl->axil_write(0x0 + ADDR_BASE, val1, mask1);
	zpl->axil_write(0x4 + ADDR_BASE, val2, mask2);
	// 8,12

	// write to two fifos
	zpl->axil_write(0x10 + ADDR_BASE, val3, mask1);
	zpl->axil_write(0x14 + ADDR_BASE, val4, mask2);

	// write to two fifos
	zpl->axil_write(0x10 + ADDR_BASE, val1, mask1);
	zpl->axil_write(0x14 + ADDR_BASE, val2, mask2);

	// check register writes
	assert( (zpl->axil_read(0x0 + ADDR_BASE) == (val1)));
	assert( (zpl->axil_read(0x4 + ADDR_BASE) == (val2)));
	
	// check that the output fifo has the sum of the input fifos
	assert( (zpl->axil_read(0x10 + ADDR_BASE) == (val3+val4)));
	assert( (zpl->axil_read(0x10 + ADDR_BASE) == (val1+val2)));

	// try a different set of input and output fifos
	zpl->axil_write(0x18 + ADDR_BASE, val1, mask1);
	zpl->axil_write(0x1C + ADDR_BASE, val2, mask2);

	assert( (zpl->axil_read(0x14 + ADDR_BASE) == (val1+val2)));
	
	zpl->done();

	delete zpl;
	exit(EXIT_SUCCESS);
}

