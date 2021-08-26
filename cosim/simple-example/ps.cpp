//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <cassert>
#include <stdlib.h>
#include <stdio.h>
#include "bp_zynq_pl.h"

#ifdef VERILATOR
int main(int argc, char **argv) {
#else
extern "C" void cosim_main(char *argstr) {
  int argc = get_argc(argstr);
  char *argv[argc];
  get_argv(argstr, argc, argv);
#endif
  bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

  // this program just communicates with a "loopback accelerator"
  // that has 4 control registers that you can read and write

  int val1 = 0xDEADBEEF;
  int val2 = 0xCAFEBABE;
  int mask1 = 0xf;
  int mask2 = 0xf;

  zpl->axil_write(0x0 + GP0_ADDR_BASE, val1, mask1);
  zpl->axil_write(0x4 + GP0_ADDR_BASE, val2, mask2);

  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (val1)));
  assert((zpl->axil_read(0x4 + GP0_ADDR_BASE) == (val2)));

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}
