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


   // the read memory map is essentially
   //
   // 0,4,8,C: registers
   // 10, 14: output fifo heads
   // 18, 1C: output fifo counts
   // 20,24,28,2C: input fifo counts 

   // the write memory map is essentially
   //
   // 0,4,8,C: registers
   // 10,14,18,1C: input fifo 
	
	int val1 = 0xDEADBEEF;
	int val2 = 0xCAFEBABE;
	int val3 = 0x0000CADE;
	int val4 = 0xC0DE0000;
	int mask1 = 0xf;
	int mask2 = 0xf;
	int data;
	bool done = false;

	// write to two registers
	zpl->axil_write(0x0 + GP0_ADDR_BASE, val1, mask1);
	zpl->axil_write(0x4 + GP0_ADDR_BASE, val2, mask2);

	assert( (zpl->axil_read(0x0 + GP0_ADDR_BASE) == (val1)));
	assert( (zpl->axil_read(0x4 + GP0_ADDR_BASE) == (val2)));

	zpl->nbf_load();
	//assert( (zpl->axil_read(0x20000000 + GP1_ADDR_BASE) == 0x1197));
	
	while(!done) {
		data = zpl->axil_read(0x10 + GP0_ADDR_BASE);
		if (data != 0) {
			data = zpl->axil_read(0xC + GP0_ADDR_BASE);
			done = zpl->decode_bp_output(data);
		}
	}

	zpl->done();

	delete zpl;
	exit(EXIT_SUCCESS);
}

