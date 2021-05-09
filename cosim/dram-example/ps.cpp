//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

// This host code uses Linux to allocate some uncached DRAM that can be shared with
// DRAM.  We send the physical address to the PL so that it knows where to host its DRAM region.
//
// This test is incomplete, the PL does not actually currently access the DRAM.
//

#include <stdlib.h>
#include <stdio.h>
#include "bp_zynq_pl.h"

int main(int argc, char **argv) {
        bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

	int mask1 = 0xf;
	unsigned long phys_ptr;
	
	volatile int *buf;

	if (argc==1)
	  buf = (volatile int*) zpl->allocate_dram(16384,&phys_ptr);

	// write all of the dram
	for (int i = 0; i < 16384/4;i++)
	  buf[i] = i;

	// read all of the dram
	for (int i = 0; i < 16384/4;i++)
	  assert(buf[i]==i);
	
	zpl->axil_write(0x0 + ADDR_BASE, phys_ptr, mask1);

	assert( (zpl->axil_read(0x0 + ADDR_BASE) == (phys_ptr)));

	if (argc==1)
	  zpl->free_dram((void *)buf);

	zpl->done();

	delete zpl;
	exit(EXIT_SUCCESS);
}

