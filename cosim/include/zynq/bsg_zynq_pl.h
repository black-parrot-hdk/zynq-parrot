
#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#if !defined(__arm__) && !defined(__aarch64__)
#error this file intended only to be compiled on an ARM (Zynq) platform
#endif

// This is an implementation of the standardized host bsg_zynq_pl API
// that runs on the real Zynq chip.
//

// memory management hooks (corresponds to allocate function in python)
//
// this is where all of the memory management functions are stored
// talks through /usr/lib/libcma.so

// look at this header file for cma_mmap, cma_alloc, cma_get_phy_addr, cma_free,
// cma_pages_available
// cma_flush_cache, cma_invalidate_cache
//
// see /usr/local/lib/python3.6/dist-packages/pynq for usage of _xlnk_reset()
//
// note: cat /proc/meminfo gives information about the CMA
//

extern "C" {
#include "/usr/include/libxlnk_cma.h"
    void _xlnk_reset();
};

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <string>
#include <fstream>
#include <iostream>
#include <cstdint>
#include <inttypes.h>
#include <memory>
#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "zynq_headers.h"

#include "bsg_zynq_pl_hardware.h"

using namespace std;

class bsg_zynq_pl : public bsg_zynq_pl_hardware {
    public:
        bsg_zynq_pl(int argc, char *argv[]) {
            printf("// bsg_zynq_pl: be sure to run as root\n");
            init();
        }

        ~bsg_zynq_pl(void) {
            deinit();
        }

        void tick(void) override {
            /* Does nothing on PS */
        }

        void done(void) override {
            printf("bsg_zynq_pl: done() called, exiting\n");
        }

        // returns virtual pointer, writes physical parameter into arguments
        void *allocate_dram(unsigned long len_in_bytes, unsigned long *physical_ptr) override {

            // resets all CMA buffers across system (eek!)
            _xlnk_reset();

            // for now, we do uncacheable to keep things simple, memory accesses go
            // straight to DRAM and
            // thus would be coherent with the PL

            void *virtual_ptr =
                cma_alloc(len_in_bytes, 0); // 1 = cacheable, 0 = uncacheable
            assert(virtual_ptr != NULL);
            *physical_ptr = cma_get_phy_addr(virtual_ptr);
            printf("bsg_zynq_pl: allocate_dram() called with size %ld bytes --> virtual "
                    "ptr=%p, physical ptr=0x%8.8lx\n",
                    len_in_bytes, virtual_ptr, *physical_ptr);
            return virtual_ptr;
        }

        void free_dram(void *virtual_ptr) override {
            printf("bsg_zynq_pl: free_dram() called on virtual ptr=%p\n", virtual_ptr);
            cma_free(virtual_ptr);
        }
};

#endif

