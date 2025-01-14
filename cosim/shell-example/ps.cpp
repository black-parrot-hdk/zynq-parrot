//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "bsg_zynq_pl.h"
#include <stdio.h>
#include <stdlib.h>

#include <sys/time.h>

#include "ps.hpp"

#define DRAM_ALLOC_SIZE_BYTES 16384

int ps_main(int argc, char **argv) {
    std::unique_ptr<bsg_zynq_pl> zpl = std::make_unique<bsg_zynq_pl>(argc, argv);

    // the read memory map is essentially
    //
    // 0,4,8,C: registers
    // 10, 14: output fifo heads
    // 18, 1C: output fifo counts
    // 20,24,28,2C: input fifo counts
    // 30: last address of write

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

    // write to two registers, checking our address snoop to see
    // actual address that was received over the AXI bus
    zpl->shell_write(0x0 + GP0_ADDR_BASE, val1, mask1);
    assert(zpl->shell_read(0x30 + GP0_ADDR_BASE) == 0x0);
    zpl->shell_write(0x4 + GP0_ADDR_BASE, val2, mask2);
    assert(zpl->shell_read(0x30 + GP0_ADDR_BASE) == 0x4);
    // 8,12

    // check output fifo counters
    assert((zpl->shell_read(0x18 + GP0_ADDR_BASE) == 0));
    assert((zpl->shell_read(0x1C + GP0_ADDR_BASE) == 0));

    // check input fifo counters
    bsg_pr_dbg_ps("%d\n", zpl->shell_read(0x20 + GP0_ADDR_BASE));
    assert((zpl->shell_read(0x20 + GP0_ADDR_BASE) == 4));
    assert((zpl->shell_read(0x24 + GP0_ADDR_BASE) == 4));
    assert((zpl->shell_read(0x28 + GP0_ADDR_BASE) == 4));
    assert((zpl->shell_read(0x2C + GP0_ADDR_BASE) == 4));

    // write to fifos
    zpl->shell_write(0x10 + GP0_ADDR_BASE, val3, mask1);

    // checker counters
    assert((zpl->shell_read(0x20 + GP0_ADDR_BASE) == (3)));
    assert((zpl->shell_read(0x24 + GP0_ADDR_BASE) == (4)));

    // write to fifo
    zpl->shell_write(0x10 + GP0_ADDR_BASE, val1, mask1);
    // checker counters
    assert((zpl->shell_read(0x20 + GP0_ADDR_BASE) == (2)));
    assert((zpl->shell_read(0x24 + GP0_ADDR_BASE) == (4)));

    zpl->shell_write(0x14 + GP0_ADDR_BASE, val4, mask2);
    zpl->shell_write(0x14 + GP0_ADDR_BASE, val2, mask2);

    // checker counters
    assert((zpl->shell_read(0x20 + GP0_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0x24 + GP0_ADDR_BASE) == (4)));

    // check register writes
    assert((zpl->shell_read(0x0 + GP0_ADDR_BASE) == (val1)));
    assert((zpl->shell_read(0x4 + GP0_ADDR_BASE) == (val2)));

    // checker output counters
    assert((zpl->shell_read(0x18 + GP0_ADDR_BASE) == (2)));
    assert((zpl->shell_read(0x1C + GP0_ADDR_BASE) == (0)));

    // check that the output fifo has the sum of the input fifos
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == (val3 + val4)));
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == (val1 + val2)));

    // checker output counters
    assert((zpl->shell_read(0x18 + GP0_ADDR_BASE) == (0)));
    assert((zpl->shell_read(0x1C + GP0_ADDR_BASE) == (0)));

    // try a different set of input and output fifos
    zpl->shell_write(0x18 + GP0_ADDR_BASE, val1, mask1);
    zpl->shell_write(0x1C + GP0_ADDR_BASE, val2, mask2);

    // checker output counters
    assert((zpl->shell_read(0x18 + GP0_ADDR_BASE) == (0)));
    assert((zpl->shell_read(0x1C + GP0_ADDR_BASE) == (1)));

    // read value out of fifo
    assert((zpl->shell_read(0x14 + GP0_ADDR_BASE) == (val1 + val2)));

    // checker output counters
    assert((zpl->shell_read(0x18 + GP0_ADDR_BASE) == (0)));
    assert((zpl->shell_read(0x1C + GP0_ADDR_BASE) == (0)));

    // DRAM test
    unsigned long phys_ptr;
    volatile int *buf;

    buf = (volatile int *)zpl->allocate_dram(DRAM_ALLOC_SIZE_BYTES, &phys_ptr);

    // write all of the dram
    for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES / 4; i++)
        buf[i] = i;

    // read all of the dram
    for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES / 4; i++)
        assert(buf[i] == i);

    printf("## everything passed; at end of test\n");
    zpl->done();

    return 0;
}
