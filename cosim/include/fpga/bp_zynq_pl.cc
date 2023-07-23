#include "bp_zynq_pl.h"

extern "C" {
#include "/usr/include/libxlnk_cma.h"
void _xlnk_reset();
};

bp_zynq_pl::bp_zynq_pl(int argc, char *argv[]) {
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

bp_zynq_pl::~bp_zynq_pl(void) {}

// returns virtual pointer, writes physical parameter into arguments
void* bp_zynq_pl::allocate_dram(uint32_t len_in_bytes, unsigned long *physical_ptr) {

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

void bp_zynq_pl::free_dram(void *virtual_ptr) {
  printf("bp_zynq_pl: free_dram() called on virtual ptr=%p\n", virtual_ptr);
  cma_free(virtual_ptr);
}

bool bp_zynq_pl::done(void) { printf("bp_zynq_pl: done() called, exiting\n"); }
