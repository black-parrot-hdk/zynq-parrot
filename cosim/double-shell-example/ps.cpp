//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include "bsg_printing.h"
#include "bsg_zynq_pl.h"
#include <stdio.h>
#include <stdlib.h>

int ps_main(int argc, char **argv) {
    bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);

    // the read memory map is essentially
    //
    // 0,4: registers
    // 8, : pl_to_ps fifo data
    // C, : pl_to_ps fifo counts
    // 10: ps_to_pl fifo counts

    // the write memory map is essentially
    //
    // 0,4: registers
    // 8: ps_to_pl data

    int val1 = 0xDEADBEEF;
    int val2 = 0xCAFEBABE;
    int val3 = 0x0000CADE;
    int val4 = 0xC0DE0000;
    int val5 = 0xBEBEBEBE;
    int val6 = 0xDEFACADE;
    int mask1 = 0xf;
    int mask2 = 0xf;

    // write to two registers
    zpl->shell_write(0x0 + GP0_ADDR_BASE, val1, mask1);
    zpl->shell_write(0x4 + GP0_ADDR_BASE, val2, mask2);

    zpl->shell_write(0x0 + GP1_ADDR_BASE, val3, mask1);
    zpl->shell_write(0x4 + GP1_ADDR_BASE, val4, mask2);

    // verify the writes worked by reading
    // assert ( (zpl->shell_read(0x0 + GP0_ADDR_BASE) == val1) );
    (zpl->shell_read(0x0 + GP0_ADDR_BASE) == val1);
    assert((zpl->shell_read(0x4 + GP0_ADDR_BASE) == val2));
    assert((zpl->shell_read(0x0 + GP1_ADDR_BASE) == val3));
    assert((zpl->shell_read(0x4 + GP1_ADDR_BASE) == val4));

    // check pl_to_ps fifo counters are zero (no data)
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == 0));
    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == 0));

    // check ps_to_pl fifo credits (4 credits avail)

    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == 4));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == 4));

    // write to fifo
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val5, mask1);

    // check counters (rememder the FIFOs cross over)
    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == (1)));
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == (0)));

    // write to fifo
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val6, mask1);

    // check counters (rememder the FIFOs cross over)
    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == (1)));
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == (1)));
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == 4));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == 4));

    // read data coming from pl to ps
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val6)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val5)));

    bsg_pr_info("bsg_zynq: data communicated between two AXI slave regions.\n");

    zpl->shell_write(0x8 + GP0_ADDR_BASE, val1, mask1);
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val2, mask1);
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val3, mask1);
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val4, mask1);
    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == (0)));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == (4)));

    bsg_pr_info("bsg_zynq filled up fifo to GP1.\n");

    zpl->shell_write(0x8 + GP1_ADDR_BASE, val4, mask1);
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val3, mask1);
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val2, mask1);
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val1, mask1);

    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == (4)));

    bsg_pr_info("bsg_zynq filled up fifo to GP0.\n");

    zpl->shell_write(0x8 + GP1_ADDR_BASE, val5, mask1);
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val6, mask1);
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val6, mask1);
    zpl->shell_write(0x8 + GP1_ADDR_BASE, val1, mask1);

    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == (0)));
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == (4)));

    bsg_pr_info("bsg_zynq filled up sequential fifo pair successfully.\n");

    zpl->shell_write(0x8 + GP0_ADDR_BASE, val5, mask1);
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val6, mask1);
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val6, mask1);
    zpl->shell_write(0x8 + GP0_ADDR_BASE, val5, mask1);

    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == (4)));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == (0))); // no free space
    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == (0))); // no free space

    bsg_pr_info("bsg_zynq filled up all fifos successfully.\n");

    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val4)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val3)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val2)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val1)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val5)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val6)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val6)));
    assert((zpl->shell_read(0x8 + GP0_ADDR_BASE) == (val1)));

    bsg_pr_info("bsg_zynq read out sequential fifo pair successfully.\n");

    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val1)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val2)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val3)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val4)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val5)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val6)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val6)));
    assert((zpl->shell_read(0x8 + GP1_ADDR_BASE) == (val5)));

    bsg_pr_info(
        "bsg_zynq read out second sequential fifo pair successfully.\n");

    // check pl_to_ps fifo counters are zero (no data)
    assert((zpl->shell_read(0xC + GP0_ADDR_BASE) == 0));
    assert((zpl->shell_read(0xC + GP1_ADDR_BASE) == 0));

    // check ps_to_pl fifo credits (4 credits avail)

    assert((zpl->shell_read(0x10 + GP0_ADDR_BASE) == 4));
    assert((zpl->shell_read(0x10 + GP1_ADDR_BASE) == 4));

    zpl->done();

    delete zpl;
    return 0;
}
