//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include "bsg_assert.h"
#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "bsg_zynq_pl.h"
#include <stdio.h>
#include <stdlib.h>

#include <sys/time.h>

#include "ps.hpp"

int ps_main(bsg_zynq_pl *zpl, int argc, char **argv) {

    // This host code is abnormal since we are testing the bridge itself

    //std::unique_ptr<zynq_uart> uart;
    //
    for (int i = 0; i < 100; i++) zpl->tick();

    return zpl->done();
}
