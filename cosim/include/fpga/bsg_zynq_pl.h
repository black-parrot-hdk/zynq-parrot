
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
#include "arm_neon.h"
using namespace std;

class bsg_zynq_pl {
public:
  bool debug = ZYNQ_PL_DEBUG;
  uintptr_t gp0_base_offset = 0;
  uintptr_t gp1_base_offset = 0;

  bsg_zynq_pl(int argc, char *argv[]);
  ~bsg_zynq_pl(void);

  // returns virtual pointer, writes physical parameter into arguments
  void *allocate_dram(unsigned long len_in_bytes, unsigned long *physical_ptr);

  void free_dram(void *virtual_ptr);

  static void tick(void) { /* Does nothing on PS */ }

  static bool done(void) { printf("bsg_zynq_pl: done() called, exiting\n"); return true; }

  inline volatile void *axil_get_ptr(uintptr_t address) {
    if (address >= gp1_addr_base)
      return (void *)(address + gp1_base_offset);
    else
      return (void *)(address + gp0_base_offset);
  }

  static void axil_poll() { /* Does nothing on PS */ }
  
  inline volatile int64_t *axil_get_ptr64(uintptr_t address) {
    return (int64_t *)axil_get_ptr(address);
  }

  inline volatile int32_t *axil_get_ptr32(uintptr_t address) {
    return (int32_t *)axil_get_ptr(address);
  }

  inline volatile int16_t *axil_get_ptr16(uintptr_t address) {
    return (int16_t *)axil_get_ptr(address);
  }

  inline volatile int8_t *axil_get_ptr8(uintptr_t address) {
    return (int8_t *)axil_get_ptr(address);
  }

  inline void axil_write(uintptr_t address, int32_t data, uint8_t wstrb) {
    if (debug)
      printf("  bsg_zynq_pl: AXI writing [%" PRIxPTR "]=%8.8x mask %" PRIu8 "\n", address, data,
             wstrb);

    // for now we don't support alternate write strobes
    assert(wstrb == 0XF || wstrb == 0x3 || wstrb == 0x1);

    if (wstrb == 0xF) {
      volatile int32_t *ptr32 = axil_get_ptr32(address);
      *ptr32 = data;
    } else if (wstrb == 0x3) {
      volatile int16_t *ptr16 = axil_get_ptr16(address);
      *ptr16 = data;
    } else if (wstrb == 0x1) {
      volatile int8_t *ptr8 = axil_get_ptr8(address);
      *ptr8 = data;
    } else {
      assert(false); // Illegal write strobe
    }
  }

  inline int32_t axil_read(uintptr_t address) {
    // Only aligned 32B reads are currently supported
    assert (alignof(address) >= 4);

    // We use unsigned here because the data is sign extended from the AXI bus
    volatile int32_t *ptr32 = axil_get_ptr32(address);
    int32_t data = *ptr32;

    if (debug)
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address, data);

    return data;
  }

  inline uint32x2_t axil_2read(uintptr_t address) {
    if (alignof(address) < 6)
      printf("[Error] Address misaligned\n");
    volatile uint32_t *ptr32x2 =  (uint32_t *)axil_get_ptr(address);
    uint32x2_t data = vld1_u32((const uint32_t *)ptr32x2);

    if (debug) {
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address, data[0]);
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address+4, data[1]);
    }
    return data;
  }

  inline uint32x4_t axil_4read(uintptr_t address) {
    if (alignof(address) < 8)
      printf("[Error] Address misaligned\n");
    volatile uint32_t *ptr32x4 =  (uint32_t *)axil_get_ptr(address);
    uint32x4_t data = vld1q_u32((const uint32_t *)ptr32x4);

    if (debug) {
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address, data[0]);
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address+4, data[1]);
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address+8, data[2]);
      printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address+12, data[3]);
    }
    return data;
  }
};

#endif
