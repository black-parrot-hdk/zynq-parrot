//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#ifdef FPGA
#include "arm_neon.h"
#endif
#include <stdlib.h>
#include <stdio.h>
#include "bp_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#include <sys/time.h>

// select between testing NEON and not testing NEON
#define TEST_BANDWIDTH_ENABLE_NEON

uint64_t get_microseconds()
{
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return tv.tv_sec*(uint64_t)1000000+tv.tv_usec;
}

#ifndef VCS
int main(int argc, char **argv) {
#else
extern "C" void cosim_main(char *argstr) {
  int argc = get_argc(argstr);
  char *argv[argc];
  get_argv(argstr, argc, argv);
#endif
  // this ensures that even with tee, the output is line buffered
  // so that we can see what is happening in real time

  setvbuf(stdout, NULL, _IOLBF, 0);

  bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

  // the read memory map is essentially
  //
  // 0,4,8,C: registers
  // 10, 14: output fifo heads
  // 18, 1C: output fifo counts
  // 20,24,28,2C: input fifo counts
  // 30: last address of write

  // the write memory map is essentially
  //
  // 0,4,8,C: registers
  // 10,14,18,1C: input fifo

  int val1 = 0xDEADBEEF;
  int val2 = 0xCAFEBABE;
  int val3 = 0x0000CADE;
  int val4 = 0xC0DE0000;
  int mask1 = 0xf;
  int mask2 = 0xf;

#ifdef FPGA

inline uint32x4_t set4(uint32_t a, uint32_t b, uint32_t c, uint32_t d) {
  uint32_t array[4] = {a, b, c, d};
  return vld1q_u32(array);
}

#define TEST_LOOP    \
  *p = val;          \
  /* this will show the last address written; a good test for whether NEON is working */ \
  printf("received %x\n",zpl->axil_read(0x30 + GP0_ADDR_BASE)); \
  uint64_t start=get_microseconds();                            \
  int limit = 100000; \
  for (int i = 0; i < limit; i++) \
    { \
      *p = val;      *p = val;      *p = val;      *p = val;      \
      *p = val;      *p = val;      *p = val;      *p = val;      \
      *p = val;      *p = val;      *p = val;      *p = val;      \
      *p = val;      *p = val;      *p = val;      *p = val;      \
    }\
  uint64_t net=get_microseconds()-start;\
  /* * 16 because of unroll factor */   \
  printf("%s: %llu microseconds for %d xfers: %f words per microsecond\n",label,net,limit*16,((double) (limit * 16 * words_per_xfer)) / ((double) net) ); 

  {
    volatile uint32x4_t *p =  (uint32x4_t *) zpl->axil_get_ptr(0x0+GP0_ADDR_BASE);
    uint32x4_t val = set4(23,12,1,43);
    uint32_t words_per_xfer = 4;
    const char *label="neon 4x32:";
    TEST_LOOP
  }
  {
    volatile int *p = zpl->axil_get_ptr(0x0+GP0_ADDR_BASE); 
    uint32_t val = 23;
    uint32_t words_per_xfer = 1;
    const char *label="int32    :";
    TEST_LOOP
  }

#endif

  // write to two registers, checking our address snoop to see
  // actual address that was received over the AXI bus
  zpl->axil_write(0x0 + GP0_ADDR_BASE, val1, mask1);
  assert(zpl->axil_read(0x30 + GP0_ADDR_BASE) == 0x0);
  zpl->axil_write(0x4 + GP0_ADDR_BASE, val2, mask2);
  assert(zpl->axil_read(0x30 + GP0_ADDR_BASE) == 0x4);
  // 8,12
  
  // check output fifo counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == 0));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == 0));

  // check input fifo counters
  bsg_pr_dbg_ps("%x\n", zpl->axil_read(0x20 + GP0_ADDR_BASE));
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == 4));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == 4));
  assert((zpl->axil_read(0x28 + GP0_ADDR_BASE) == 4));
  assert((zpl->axil_read(0x2C + GP0_ADDR_BASE) == 4));

  // write to fifos
  zpl->axil_write(0x10 + GP0_ADDR_BASE, val3, mask1);

  // checker counters
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == (3)));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == (4)));

  // write to fifo
  zpl->axil_write(0x10 + GP0_ADDR_BASE, val1, mask1);
  // checker counters
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == (2)));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == (4)));

  zpl->axil_write(0x14 + GP0_ADDR_BASE, val4, mask2);
  zpl->axil_write(0x14 + GP0_ADDR_BASE, val2, mask2);

  // checker counters
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == (4)));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == (4)));

  // check register writes
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (val1)));
  assert((zpl->axil_read(0x4 + GP0_ADDR_BASE) == (val2)));

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (2)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (0)));

  // check that the output fifo has the sum of the input fifos
  assert((zpl->axil_read(0x10 + GP0_ADDR_BASE) == (val3 + val4)));
  assert((zpl->axil_read(0x10 + GP0_ADDR_BASE) == (val1 + val2)));

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (0)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (0)));

  // try a different set of input and output fifos
  zpl->axil_write(0x18 + GP0_ADDR_BASE, val1, mask1);
  zpl->axil_write(0x1C + GP0_ADDR_BASE, val2, mask2);

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (0)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (1)));

  // read value out of fifo
  assert((zpl->axil_read(0x14 + GP0_ADDR_BASE) == (val1 + val2)));

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (0)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (0)));


  printf("## everything passed; at end of test\n");
  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}
