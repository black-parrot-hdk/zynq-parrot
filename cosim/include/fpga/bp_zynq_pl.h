// This is an implementation of the standardized host bp_zynq_pl API
// that runs on the real Zynq chip.
//

#if !defined(__arm__) && !defined(__aarch64__)
#error this file intended only to be compiled on an ARM (Zynq) platform
#endif

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

#ifndef GP0_ENABLE
#define GP0_ADDR_WIDTH 0
#define GP0_DATA_WIDTH 0
#define GP0_ADDR_BASE 0
#define GP0_ADDR_SIZE_BYTES 0
#endif

#ifndef GP0_ADDR_WIDTH
#error GP0_ADDR_WIDTH must be defined
#endif

#ifndef GP0_ADDR_SIZE_BYTES
#error GP0_ADDR_SIZE_BYTES must be defined
#endif

#ifndef GP0_ADDR_BASE
#error GP0_ADDR_BASE must be defined
#endif

#ifndef GP0_DATA_WIDTH
#error GP0_DATA_WIDTH must be defined
#endif

#ifndef GP1_ENABLE
#define GP1_ADDR_WIDTH 0
#define GP1_DATA_WIDTH 0
#define GP1_ADDR_BASE 0
#define GP1_ADDR_SIZE_BYTES 0
#endif

#ifndef GP1_ADDR_WIDTH
#error GP1_ADDR_WIDTH must be defined
#endif

#ifndef GP1_ADDR_SIZE_BYTES
#error GP1_ADDR_SIZE_BYTES must be defined
#endif

#ifndef GP1_ADDR_BASE
#error GP1_ADDR_BASE must be defined
#endif

#ifndef GP1_DATA_WIDTH
#error GP1_DATA_WIDTH must be defined
#endif

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
#include "bsg_argparse.h"
#include "bsg_printing.h"

using namespace std;

class bp_zynq_pl {
public:
  unsigned int BP_ZYNQ_PL_DEBUG = 0;
  unsigned int gp0_base_offset = 0;
  unsigned int gp1_base_offset = 0;

  bp_zynq_pl(int argc, char *argv[]) {
    printf("// bp_zynq_pl: be sure to run as root\n");

    // open memory device
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    assert(fd != 0);

    uint64_t* addr0 = (uint64_t*)GP0_ADDR_BASE; // e.g. 0x43c00000;
    uint64_t* addr1 = (uint64_t*)GP1_ADDR_BASE; // e.g. 0x83c00000;


#ifdef GP0_ENABLE
    // map in first PLAXI region of physical addresses to virtual addresses

    volatile int *ptr0 =
        (int *)mmap(addr0, GP0_ADDR_SIZE_BYTES, PROT_READ | PROT_WRITE,
                    MAP_SHARED, fd, (intptr_t)addr0);
    assert(ptr0 == (int*)addr0);

    // assert(ptr0 != ((void *) -1));
    // if (ptr0 != addr0)
    //  gp0_base_offset = ( (unsigned int) ptr0 - GP0_ADDR_BASE);
    printf("// bp_zynq_pl: mmap returned %p (offset %x) errno=%x\n", ptr0,
           gp0_base_offset, errno);
#endif
    
#ifdef GP1_ENABLE
    // map in second PLAXI region of physical addresses to virtual addresses
    volatile int *ptr1 =
        (int *)mmap(addr1, GP1_ADDR_SIZE_BYTES, PROT_READ | PROT_WRITE,
                    MAP_SHARED, fd, (intptr_t)addr1);
    assert(ptr1 == (int*)addr1);

    // assert(ptr1 != ((void *) -1));
    // if (ptr1 != addr1)
    //  gp1_base_offset = ( (unsigned int) ptr1 - GP1_ADDR_BASE);

    printf("// bp_zynq_pl: mmap returned %p (offset %x) errno=%x\n", ptr1,
           gp1_base_offset, errno);

#endif
    
    close(fd);
  }

  ~bp_zynq_pl(void) {}

  // returns virtual pointer, writes physical parameter into arguments
  void *allocate_dram(uint32_t len_in_bytes, unsigned long *physical_ptr) {

    // resets all CMA buffers across system (eek!)
    _xlnk_reset();

    // for now, we do uncacheable to keep things simple, memory accesses go
    // straight to DRAM and
    // thus would be coherent with the PL

    void *virtual_ptr =
        cma_alloc(len_in_bytes, 0); // 1 = cacheable, 0 = uncacheable
    assert(virtual_ptr != NULL);
    *physical_ptr = cma_get_phy_addr(virtual_ptr);
    printf("bp_zynq_pl: allocate_dram() called with size %d bytes --> virtual "
           "ptr=%p, physical ptr=0x%8.8lx\n",
           len_in_bytes, virtual_ptr, *physical_ptr);
    return virtual_ptr;
  }

  void free_dram(void *virtual_ptr) {
    printf("bp_zynq_pl: free_dram() called on virtual ptr=%p\n", virtual_ptr);
    cma_free(virtual_ptr);
  }

  bool done(void) { printf("bp_zynq_pl: done() called, exiting\n"); }

  inline void axil_write(uint64_t address, uint32_t data, int wstrb=0xF) {
    if (BP_ZYNQ_PL_DEBUG)
      printf("  bp_zynq_pl: AXI writing [%lx]=%8.8x mask %x\n", address, data,
             wstrb);

    // assert(address >= ADDR_BASE && (address - ADDR_BASE < ADDR_SIZE_BYTES));
    // // "address is not in the correct range?"

    // for now we don't support alternate write strobes
    assert(wstrb == 0XF);
    volatile uint32_t* ptr;
    if (address >= GP1_ADDR_BASE)
      ptr = (uint32_t*)address + gp1_base_offset;
    else
      ptr = (uint32_t*)address + gp0_base_offset;
    ptr[0] = data;
  }

  inline uint32_t axil_read(uint64_t address) {
    volatile uint32_t* ptr;
    if (address >= GP1_ADDR_BASE)
      ptr = (uint32_t*)address + gp1_base_offset;
    else
      ptr = (uint32_t*)address + gp0_base_offset;

    uint32_t data = ptr[0];

    if (BP_ZYNQ_PL_DEBUG)
      printf("  bp_zynq_pl: AXI reading [%lx]->%8.8x\n", address, data);

    return data;
  }
};
