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

// Expose both the axil and uart methods which are protected in the base class
// TODO: Reduce duplication
class bsg_zynq_pl_dual : public bsg_zynq_pl {
    public:
        using bsg_zynq_pl::bsg_zynq_pl;

        int32_t shell_read(uintptr_t addr, bool uart_not_axi) {
            bool done = false;
            int32_t rdata;
            auto f_call = [&](int32_t x) {
                rdata = x;
                done = true;
            };
            if (uart_not_axi) {
                uart_read(0, addr, f_call);
            } else {
                axil_read(0, addr, f_call);
            }
            do {
                next();
            } while (!done);

            return rdata;
        }

        void shell_write(uintptr_t addr, int32_t data, uint8_t wstrb, bool uart_not_axi) {
            bool done = false;
            auto f_call = [&]() { done = true; };
            if (uart_not_axi) {
                uart_write(0, addr, data, wstrb, f_call);
            } else {
                axil_write(0, addr, data, wstrb, f_call);
            }
            do {
                next();
            } while (!done);
        }
};

int ps_main(int argc, char **argv) {
    bsg_zynq_pl_dual *zpl = new bsg_zynq_pl_dual(argc, argv);

    bool SHELL_AXI = false;
    bool SHELL_UART = true;

    zpl->start();

    // Take UART bridge out of reset
    zpl->shell_write(AXI_GP0_WR_CSR_RESET, 1, 0xf, SHELL_AXI);

    zpl->shell_write(UART_GP0_WR_CSR_LOOP_REG, 0xdead, 0xf, SHELL_UART);
    zpl->shell_read(UART_GP0_RD_CSR_LOOP_REG, SHELL_UART);
    assert(zpl->shell_read(UART_GP0_RD_CSR_LOOP_REG, SHELL_UART) == 0xdead);
    assert(zpl->shell_read(UART_GP0_RD_CSR_LOOP_IN, SHELL_UART) == 0xdead);

    // This takes too long in sim
#ifndef SIMULATION
    clock_t t;
    bsg_pr_info("Write bandwidth test (32 kB)...\n");
    t = clock();
    for (int j = 1; j <= 32; j++) {
        printf("\r[%d/%d] kB", j, 32);
        for (int k = 0; k < 1024; k++) {
            zpl->shell_write(UART_GP0_WR_CSR_LOOP_REG, 0x0000, 0xf);
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
            zpl->shell_read(UART_GP0_RD_CSR_LOOP_REG);
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
}

