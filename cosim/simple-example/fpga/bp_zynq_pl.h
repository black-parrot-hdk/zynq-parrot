// This is an implementation of the standardized host bp_zynq_pl API
// that runs on the real Zynq chip.
//


#ifndef __arm__
#error this file intended only to be compiled on an ARM (Zynq) platform)
#endif

//#define ADDR_BASE 0x4000_0000
//#define ADDR_SIZE_BYTES 0x1000

#ifndef ADDR_BASE
#error ADDR_BASE must be defined
#endif

#ifndef ADDR_SIZE_BYTES
#error ADDR_SIZE_BYTES must be defined
#endif


#define BP_ZYNQ_PL_DEBUG 1 

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>

class bp_zynq_pl {
 public:
  
  bp_zynq_pl(int argc, char *argv[])
    {
      printf("// bp_zynq: be sure to run as root\n");

      // open memory device
      int fd = open("/dev/mem",O_RDWR | O_SYNC);
      assert(fd!=0);

      int *addr = (int *) ADDR_BASE; // e.g. 0x43c00000;

      // map in first AXI region of physical addresses to virtual addresses
      volatile int *ptr = mmap(addr,ADDR_SIZE_BYTES,PROT_READ | PROT_WRITE, MAP_SHARED, fd,(int) ptr);
      printf("// bp_zynq: mmap returned %p errno=%x\n",ptr,errno);
      assert(ptr == addr);
      close(fd)
    }

  ~bp_zynq_pl(void) {
  }
    
  bool done(void) {
    printf("bp_zynq: done() called, exiting\n");
  }

  void axil_write(unsigned int address, int data, int wstrb)
  {
    if (BP_ZYNQ_PL_DEBUG)
       printf("bp_zynq: AXI writing [%x]=%8.8x mask %x\n", address, data, wstrb);

    assert(address >= ADDR_BASE && (address - ADDR_BASE < ADDR_SIZE_BYTES)); // "address is not in the correct range?"

    // for now we don't support alternate write strobes
    assert(wstrb == 0XF);
    volatile int *ptr = (int *) address;
    ptr[0] = data;
  }

  int axil_read(unsigned int address)
  {
    volatile int *ptr = (int *) address;
    int data = ptr[0];
    
    if (BP_ZYNQ_PL_DEBUG)    
      printf("bp_zynq: AXI reading [%x]->%8.8x\n", address, data);

    return data;
  }
};
