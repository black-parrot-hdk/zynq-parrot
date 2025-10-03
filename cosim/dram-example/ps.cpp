//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

// This host code uses Linux to allocate some uncached DRAM that can be shared
// with
// DRAM.  We send the physical address to the PL so that it knows where to host
// its DRAM region.
//
// This test is incomplete, the PL does not actually currently access the DRAM.
//

#include "bsg_zynq_pl.h"
#include <stdio.h>
#include <stdlib.h>

#include "ps.hpp"

//#define DRAM_ALLOC_SIZE_BYTES 16384
#define DRAM_ALLOC_SIZE_BYTES 128

int ps_main(int argc, char **argv) {
    std::unique_ptr<bsg_zynq_pl> zpl = std::make_unique<bsg_zynq_pl>(argc, argv);

    volatile int *buf;
    unsigned long phys_ptr;
    buf = (volatile int *)zpl->allocate_dram(DRAM_ALLOC_SIZE_BYTES, &phys_ptr);

    //// backdoor write all of the dram
    //for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES / 4; i++)
    //    buf[i] = i;

    //// backdoor read all of the dram
    //for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES / 4; i++)
    //    assert(buf[i] == i);

    zpl->shell_write(GP0_WR_CSR_DRAM_BASE, phys_ptr);

    int write_not_read, addr, wdata, rdata;
    // frontdoor write all of the dram
    write_not_read = 1;
    for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES; i+=4) {
        addr = i;
        wdata = i/4;
		printf("Writing [%x] := %x\n", addr, wdata);
        while (!zpl->shell_read(GP0_RD_PS2PL_FIFO_CTR0));
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA0, write_not_read);
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA1, addr);
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA2, wdata);
        while (!zpl->shell_read(GP0_RD_PL2PS_FIFO_CTR0));
        rdata = zpl->shell_read(GP0_RD_PL2PS_FIFO_DATA0);
    }

    // frontdoor read all of the dram
	write_not_read = 0;
    for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES; i+=4) {
        addr = i;
        while (!zpl->shell_read(GP0_RD_PS2PL_FIFO_CTR0));
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA0, write_not_read);
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA1, addr);
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA2, wdata);
        while (!zpl->shell_read(GP0_RD_PL2PS_FIFO_CTR0));
        rdata = zpl->shell_read(GP0_RD_PL2PS_FIFO_DATA0);
		printf("Reading [%x] == %x\n", addr, rdata);
    }

    if (argc == 1)
        zpl->free_dram((void *)buf);

    printf("## everything passed; at end of test\n");
    zpl->done();

    return 0;
}
