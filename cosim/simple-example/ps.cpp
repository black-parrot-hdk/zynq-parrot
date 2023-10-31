//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <cassert>
#include <stdlib.h>
#include <stdio.h>
#include "bsg_zynq_pl.h"

int ps_main(int argc, char **argv) {
  bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);

  // this program just communicates with a "loopback accelerator"
  // that has 4 control registers that you can read and write

  int val1 = 0xDEADBEEF;
  int val2 = 0xCAFEBABE;
  int mask1 = 0xf;
  int mask2 = 0xf;

  zpl->shell_write(0x0 + GP0_ADDR_BASE, val1, mask1);
  zpl->shell_write(0x4 + GP0_ADDR_BASE, val2, mask2);

  assert((zpl->shell_read(0x0 + GP0_ADDR_BASE) == (val1)));
  assert((zpl->shell_read(0x4 + GP0_ADDR_BASE) == (val2)));

  zpl->done();

  delete zpl;
  return 0;
}

