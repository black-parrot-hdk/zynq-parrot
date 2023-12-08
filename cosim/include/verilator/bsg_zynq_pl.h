// This is an implementation of the standardized host bsg_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#include <cassert>
#include <stdio.h>
#include <string>
#include <fstream>
#include <iostream>
#include "bsg_axil.h"
#include "bsg_printing.h"
#include "bsg_nonsynth_dpi_clock_gen.hpp"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_peripherals.h"
#include "zynq_headers.h"
#include "verilated_fst_c.h"
#include "verilated_cov.h"

#include "bsg_zynq_pl_simulation.h"
#include "Vbsg_nonsynth_zynq_testbench.h"
#include "verilated.h"

class bsg_zynq_pl : public bsg_zynq_pl_simulation {
    Vbsg_nonsynth_zynq_testbench *tb;
    VerilatedFstC *wf;

    public:
    bsg_zynq_pl(int argc, char *argv[]) {
        // Initialize Verilators variables
        Verilated::commandArgs(argc, argv);

        // turn on tracing
        Verilated::traceEverOn(true);

        tb = new Vbsg_nonsynth_zynq_testbench();

        wf = new VerilatedFstC;
        tb->trace(wf, 10);
        wf->open("trace.fst");

        tick();
        init();
    }

    ~bsg_zynq_pl(void) { }

    // Each bsg_timekeeper::next() moves to the next clock edge
    //   so we need 2 to perform one full clock cycle.
    // If your design does not evaluate things on negedge, you could omit
    //   the first eval, but BSG designs tend to do assertions on negedge
    //   at the least.
    void tick(void) override {
        tb->eval();
        wf->dump(sc_time_stamp());
        bsg_timekeeper::next();
        tb->eval();
        wf->dump(sc_time_stamp());
        bsg_timekeeper::next();
    }

    void done(void) override {
        printf("bsg_zynq_pl: done() called, exiting\n");
        wf->close();
    }

    void next_tick() override {
        bsg_zynq_pl_simulation::next_tick();
    }

    void poll_tick() override {
        bsg_zynq_pl_simulation::poll_tick();
    }

    void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) {
        axil_write(addr, data, wmask);
    }

    int32_t shell_read(uintptr_t addr) {
        return axil_read(addr);
    }
};

#endif
