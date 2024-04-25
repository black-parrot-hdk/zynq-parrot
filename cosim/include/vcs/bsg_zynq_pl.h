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
extern "C" { int bsg_dpi_time(); }

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

        void *allocate_dram(unsigned long len_in_bytes, unsigned long *physical_ptr) override {
            bsg_pr_info("  bsg_zynq_pl: Allocated dummy DRAM\n");
            return (void *)(physical_ptr = (unsigned long *)0xdeadbeef);
        }

        void free_dram(void *virtual_ptr) override {
            printf("bsg_zynq_pl: Freeing dummy DRAM\n");
        }
};

#endif

