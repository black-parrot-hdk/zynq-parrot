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

 #ifdef HOST_ZYNQ
         void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) {
             axil_write(addr, data, wmask);
         }

         int32_t shell_read(uintptr_t addr) {
             return axil_read(addr);
         }
 #else
         void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) {
             uart_write(addr, data, wmask);
         }

         int32_t shell_read(uintptr_t addr) {
             return uart_read(addr);
         }
 #endif
};

#endif

