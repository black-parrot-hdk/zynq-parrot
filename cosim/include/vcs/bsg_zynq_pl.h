// This is an implementation of the standardized host bsg_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#include <cassert>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <fstream>
#include <iostream>
#include <memory>
#include <svdpi.h>
#include <unistd.h>
#include <memory>
#include <vector>

#include "bsg_zynq_pl_simulation.h"

extern "C" { void bsg_dpi_next(); }

class bsg_zynq_pl : public bsg_zynq_pl_simulation {
    public:
        bsg_zynq_pl(int argc, char *argv[]) {
            tick();
            init();
        }

        ~bsg_zynq_pl(void) { }

#ifdef AXI_ENABLE
        int32_t axil_read(uintptr_t address) override {
            return bsg_zynq_pl_simulation::axil_read(address);
        }

        void axil_write(uintptr_t address, int32_t data, uint8_t wstrb) override {
            bsg_zynq_pl_simulation::axil_write(address, data, wstrb);
        }
#endif

        void tick(void) override {
            bsg_dpi_next();
        }

        void done(void) override {
            bsg_pr_info("  bsg_zynq_pl: done() called, exiting\n");
        }

        void next_tick() override {
            bsg_zynq_pl_simulation::next_tick();
        }

        void poll_tick() override {
            bsg_zynq_pl_simulation::poll_tick();
        }
};

#endif

