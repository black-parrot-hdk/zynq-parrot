//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <stdlib.h>
#include <stdio.h>
#include "bsg_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#include <sys/time.h>

#include "ps.hpp"


#error "This example currently does not work, will be moved into shell example"

int ps_main(int argc, char **argv) {
        bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);

        bsg_pr_info("Smoke test\n");
        zpl->shell_write(GP0_WR_CSR_NONE, 0xdead, 0xf);
        assert(zpl->shell_read(GP0_RD_CSR_NONE) == 0xdead);

        assert(zpl->shell_read(GP0_RD_CSR_LAST_ADDR) == GP0_WR_CSR_NONE);
        zpl->shell_write(GP0_WR_CSR_NONE, 0xbeef, 0xf);
        assert(zpl->shell_read(GP0_RD_CSR_NONE) == 0xbeef);
        assert(zpl->shell_read(GP0_RD_CSR_LAST_ADDR) == GP0_WR_CSR_NONE);

        // This takes too long in sim
#ifndef SIMULATION
        clock_t t;
        bsg_pr_info("Write bandwidth test (32 kB)...\n");
        t = clock();
        for (int j = 1; j <= 32; j++) {
            printf("\r[%d/%d] kB", j, 32);
            for (int k = 0; k < 1024; k++) {
                zpl->shell_write(GP0_WR_CSR_NONE, 0x0000, 0xf);
            }
            fflush(stdout);
        }
        printf("\n");
        t = clock() - t;
        double write_bandwidth = CLOCKS_PER_SEC/((double)t)*1024*8;
        bsg_pr_info("Write bandwidth: %.0f kbps\n", write_bandwidth);

        bsg_pr_info("Read bandwidth test (16 kB)...\n");
        t = clock();
        for (int j = 1; j <= 16; j++) {
            printf("\r[%d/%d] kB", j, 16);
            for (int k = 0; k < 1024; k++) {
                zpl->shell_read(GP0_RD_CSR_NONE);
            }
            fflush(stdout);
        }
        printf("\n");
        t = clock() - t;
        double read_bandwidth = CLOCKS_PER_SEC/((double)t)*16*8;
        bsg_pr_info("Read bandwidth: %.0f kbps\n", read_bandwidth);
#endif

        printf("## everything passed; at end of test\n");

        zpl->done();
        delete zpl;
        return 0;
        delete zpl;
    }
