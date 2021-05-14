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
   // 0,4,8: registers
   // C: output fifo
   // 10: output fifo count
   // 14: input fifo count

   // the write memory map is essentially
   //
   // 0,4,8: registers
   // 10: input fifo 
	
	int data;
	data = zpl->axil_read(0x10 + GP0_ADDR_BASE);
	int val1 = 0x80000000;
	int val2 = 0x20000000;
	int mask1 = 0xf;
	int mask2 = 0xf;
	bool done = false;
	unsigned long phys_ptr;
	volatile int *buf;

	// write to two registers
	zpl->axil_write(0x0 + GP0_ADDR_BASE, val1, mask1);
	zpl->axil_write(0x4 + GP0_ADDR_BASE, val2, mask2);
	buf = (volatile int*) zpl->allocate_dram(67108864, &phys_ptr);
	zpl->axil_write(0x8 + GP0_ADDR_BASE, phys_ptr, mask1);

	assert( (zpl->axil_read(0x0 + GP0_ADDR_BASE) == (val1)));
	assert( (zpl->axil_read(0x4 + GP0_ADDR_BASE) == (val2)));
	assert( (zpl->axil_read(0x8 + GP0_ADDR_BASE) == (phys_ptr)));

	zpl->nbf_load();
	
	//while(!done) {
	//	data = zpl->axil_read(0x10 + GP0_ADDR_BASE);
	//	if (data != 0) {
	//		data = zpl->axil_read(0xC + GP0_ADDR_BASE);
	//		done = zpl->decode_bp_output(data);
	//	}
	//}
	
	zpl->free_dram((void *)buf);
	
	//data = zpl->axil_read(0x10 + GP0_ADDR_BASE);
	zpl->done();

	delete zpl;
	exit(EXIT_SUCCESS);
}

