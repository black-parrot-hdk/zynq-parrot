
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

#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "zynq_headers.h"
#include <assert.h>
#include <cstdint>
#include <errno.h>
#include <fcntl.h>
#include <fstream>
#include <inttypes.h>
#include <iostream>
#include <memory>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <xrt.h>
#include <xrt/xrt_device.h>
#include <xrt/xrt_bo.h>

#include "bsg_zynq_pl_hardware.h"

class bsg_zynq_pl : public bsg_zynq_pl_hardware {
  private:
    std::unique_ptr<xrt::device> xrt_device;
    std::unique_ptr<xrt::bo> xrt_dram;

  public:
    bsg_zynq_pl(int argc, char *argv[]) {
        printf("// bsg_zynq_pl: be sure to run as root\n");
        xrt_device = std::make_unique<xrt::device>(0);
        init();
    }

    ~bsg_zynq_pl(void) { deinit(); }

    void tick(void) override { /* Does nothing on PS */
    }

    void start(void) override { printf("bsg_zynq_pl: start() called\n"); }

    void stop(void) override { printf("bsg_zynq_pl: stop() called\n"); }

    void done(void) override {
        printf("bsg_zynq_pl: done() called, exiting\n");
    }

    // returns virtual pointer, writes physical parameter into arguments
    void *allocate_dram(unsigned long len_in_bytes,
                        unsigned long *physical_ptr) override {

        // for now, we do uncacheable to keep things simple, memory accesses go
        // straight to DRAM and
        // thus would be coherent with the PL

        // resets all CMA buffers across system (eek!)
        xrt_dram = std::make_unique<xrt::bo>(xrt_device.get(), len_in_bytes, xrt::bo::flags::normal, 0);
        void *virtual_ptr = xrt_dram->map<void*>();
        *physical_ptr = xrt_dram->address();

        printf("bsg_zynq_pl: allocate_dram() called with size %ld bytes --> "
               "virtual "
               "ptr=%p, physical ptr=0x%8.8lx\n",
               len_in_bytes, virtual_ptr, *physical_ptr);
        return virtual_ptr;
    }

    void free_dram(void *virtual_ptr) override {
        printf("bsg_zynq_pl: free_dram() called on virtual ptr=%p\n",
               virtual_ptr);
        xrt_dram.reset(nullptr);
        //cma_free(virtual_ptr);
    }

    int32_t shell_read(uintptr_t addr) override { return axil_read(addr); }

    void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) override {
        axil_write(addr, data, wmask);
    }

#ifdef NEON
    // typedef uint32_t uint32x4_t[4];
    void shell_write4(uintptr_t addr, int32_t data0, int32_t data1,
                      int32_t data2, int32_t data3) override {
        volatile uint32x4_t *ptr = (volatile uint32x4_t *)addr;
        int32_t sarray[4] = {data0, data1, data2, data3};
        uint32_t *array{reinterpret_cast<uint32_t *>(sarray)};
        uint32x4_t val = vld1q_u32(array);

        *ptr = val;
    }

    void shell_read4(uintptr_t addr, int32_t *data0, int32_t *data1,
                     int32_t *data2, int32_t *data3) override {
        volatile uint32x4_t *ptr = (volatile uint32x4_t *)addr;
        uint32x4_t val = *ptr;

        *data0 = val[0];
        *data1 = val[1];
        *data2 = val[2];
        *data3 = val[3];
    }
#endif
};

#endif
