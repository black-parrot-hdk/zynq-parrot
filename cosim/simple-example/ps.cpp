//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include "bsg_zynq_pl.h"
#include <cassert>
#include <stdio.h>
#include <stdlib.h>

#include "ps.hpp"

int ps_main(int argc, char **argv) {
    bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);

    // this program just communicates with a "loopback accelerator"
    // that has 4 control registers that you can read and write

    int val1 = 0xDEADBEEF;
    int val2 = 0xCAFEBABE;
    int val3 = 0xAAAAAAAA;
    int val4 = 0xBBBBBBBB;
    int mask1 = 0xf;
    int mask2 = 0xf;
    int mask3 = 0xf;
    int mask4 = 0xf;

    zpl->shell_write(GP0_WR_CSR_0, val1, mask1);
    zpl->shell_write(GP0_WR_CSR_1, val2, mask2);
    zpl->shell_write(GP0_WR_CSR_2, val3, mask3);
    zpl->shell_write(GP0_WR_CSR_3, val4, mask4);

    assert(zpl->shell_read(GP0_RD_CSR_0) == val1);
    assert(zpl->shell_read(GP0_RD_CSR_1) == val2);
    assert(zpl->shell_read(GP0_RD_CSR_2) == val3);
    assert(zpl->shell_read(GP0_RD_CSR_3) == val4);

    zpl->done();

    delete zpl;
    return 0;
}
