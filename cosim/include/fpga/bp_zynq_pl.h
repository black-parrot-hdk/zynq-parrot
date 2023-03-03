
#ifndef BP_ZYNQ_PL_H
#define BP_ZYNQ_PL_H

#if !defined(__arm__) && !defined(__aarch64__)
#error this file intended only to be compiled on an ARM (Zynq) platform
#endif

// This is an implementation of the standardized host bp_zynq_pl API
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
using namespace std;

class bp_zynq_pl {
public:
  bool debug = ZYNQ_PL_DEBUG;
  uintptr_t gp0_base_offset = 0;
  uintptr_t gp1_base_offset = 0;

  bp_zynq_pl(int argc, char *argv[]) {
    printf("// bp_zynq_pl: be sure to run as root\n");
#ifdef SIM_BACKPRESSURE_ENABLE
    printf("// bp_zynq_pl: warning does not support SIM_BACKPRESSURE_ENABLE\n");
#endif

    // open memory device
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    assert(fd != 0);

#ifdef GP0_ENABLE
    // map in first PLAXI region of physical addresses to virtual addresses
    volatile uintptr_t ptr0 =
        (uintptr_t)mmap((void *)gp0_addr_base, gp0_addr_size_bytes, PROT_READ | PROT_WRITE,
                    MAP_SHARED, fd, gp0_addr_base);
    assert(ptr0 == (uintptr_t)gp0_addr_base);

    printf("// bp_zynq_pl: mmap returned %" PRIxPTR " (offset %" PRIxPTR ") errno=%x\n", ptr0,
           gp0_base_offset, errno);
#endif
    
#ifdef GP1_ENABLE
    // map in second PLAXI region of physical addresses to virtual addresses
    volatile uintptr_t ptr1 =
        (uintptr_t)mmap((void *)gp1_addr_base, gp1_addr_size_bytes, PROT_READ | PROT_WRITE,
                    MAP_SHARED, fd, gp1_addr_base);
    assert(ptr1 == (uintptr_t)gp1_addr_base);

    printf("// bp_zynq_pl: mmap returned %" PRIxPTR " (offset %" PRIxPTR ") errno=%x\n", ptr1,
           gp1_base_offset, errno);

#endif
    
    close(fd);
  }

  ~bp_zynq_pl(void) {}

  // returns virtual pointer, writes physical parameter into arguments
  void *allocate_dram(unsigned long len_in_bytes, unsigned long *physical_ptr) {

    // resets all CMA buffers across system (eek!)
    _xlnk_reset();

    // for now, we do uncacheable to keep things simple, memory accesses go
    // straight to DRAM and
    // thus would be coherent with the PL

    void *virtual_ptr =
        cma_alloc(len_in_bytes, 0); // 1 = cacheable, 0 = uncacheable
    assert(virtual_ptr != NULL);
    *physical_ptr = cma_get_phy_addr(virtual_ptr);
    printf("bp_zynq_pl: allocate_dram() called with size %ld bytes --> virtual "
           "ptr=%p, physical ptr=0x%8.8lx\n",
           len_in_bytes, virtual_ptr, *physical_ptr);
    return virtual_ptr;
  }

  void free_dram(void *virtual_ptr) {
    printf("bp_zynq_pl: free_dram() called on virtual ptr=%p\n", virtual_ptr);
    cma_free(virtual_ptr);
  }

  static void tick(void) { /* Does nothing on PS */ }

  static bool done(void) { printf("bp_zynq_pl: done() called, exiting\n"); return true; }

  inline volatile void *axil_get_ptr(uintptr_t address) {
    if (address >= gp1_addr_base)
      return (void *)(address + gp1_base_offset);
    else
      return (void *)(address + gp0_base_offset);
  }

  static void axil_poll() { /* Does nothing on PS */ }
  
  inline volatile uint64_t *axil_get_ptr64(uintptr_t address) {
    return (uint64_t *)axil_get_ptr(address);
  }

  inline volatile uint32_t *axil_get_ptr32(uintptr_t address) {
    return (uint32_t *)axil_get_ptr(address);
  }

  inline volatile uint16_t *axil_get_ptr16(uintptr_t address) {
    return (uint16_t *)axil_get_ptr(address);
  }

  inline volatile uint8_t *axil_get_ptr8(uintptr_t address) {
    return (uint8_t *)axil_get_ptr(address);
  }

  inline void axil_write(uintptr_t address, long data, uint8_t wstrb=0xF) {
    if (debug)
      printf("  bp_zynq_pl: AXI writing [%" PRIxPTR "]=%8.8ld mask %u\n", address, data,
             wstrb);

    // for now we don't support alternate write strobes
    assert(wstrb == 0XF || wstrb == 0x3 || wstrb == 0x1);

    if (wstrb == 0xFF) {
      volatile uint64_t *ptr64 = axil_get_ptr64(address);
      *ptr64 = data;
    } else if (wstrb == 0xF) {
      volatile uint32_t *ptr32 = axil_get_ptr32(address);
      *ptr32 = data;
    } else if (wstrb == 0x3) {
      volatile uint16_t *ptr16 = axil_get_ptr16(address);
      *ptr16 = data;
    } else if (wstrb == 0x1) {
      volatile uint8_t *ptr8 = axil_get_ptr8(address);
      *ptr8 = data;
    } else {
      assert(false); // Illegal write strobe
    }
  }

  inline long axil_read(uintptr_t address) {
    // Only aligned 32B reads are currently supported
    assert (alignof(address) >= 4);

    // We use unsigned here because the data is sign extended from the AXI bus
    volatile uint32_t *ptr32 = axil_get_ptr32(address);
    uint32_t data = *ptr32;

    if (debug)
      printf("  bp_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address, data);

    return data;
  }
};

#endif
