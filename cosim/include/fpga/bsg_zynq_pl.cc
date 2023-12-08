#include "bsg_zynq_pl.h"

extern "C" {
#include "/usr/include/libxlnk_cma.h"
void _xlnk_reset();
};

bsg_zynq_pl::bsg_zynq_pl(int argc, char *argv[]) {
  printf("// bsg_zynq_pl: be sure to run as root\n");
#ifdef SIM_BACKPRESSURE_ENABLE
  printf("// bsg_zynq_pl: warning does not support SIM_BACKPRESSURE_ENABLE\n");
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

  printf("// bsg_zynq_pl: mmap returned %" PRIxPTR " (offset %" PRIxPTR ") errno=%x\n", ptr0,
         gp0_base_offset, errno);
#endif
#ifdef GP1_ENABLE
  // map in second PLAXI region of physical addresses to virtual addresses
  volatile uintptr_t ptr1 =
      (uintptr_t)mmap((void *)gp1_addr_base, gp1_addr_size_bytes, PROT_READ | PROT_WRITE,
                  MAP_SHARED, fd, gp1_addr_base);
  assert(ptr1 == (uintptr_t)gp1_addr_base);

  printf("// bsg_zynq_pl: mmap returned %" PRIxPTR " (offset %" PRIxPTR ") errno=%x\n", ptr1,
         gp1_base_offset, errno);
#endif
  close(fd);
}

bsg_zynq_pl::~bsg_zynq_pl(void) {}

// returns virtual pointer, writes physical parameter into arguments
void* bsg_zynq_pl::allocate_dram(unsigned long len_in_bytes, unsigned long *physical_ptr) {

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

void bsg_zynq_pl::free_dram(void *virtual_ptr) {
  printf("bsg_zynq_pl: free_dram() called on virtual ptr=%p\n", virtual_ptr);
  cma_free(virtual_ptr);
}
