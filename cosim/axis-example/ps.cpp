//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <stdlib.h>
#include <stdio.h>
#include "bsg_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#include <sys/time.h>

#include "ps.hpp"

int ps_main(int argc, char **argv) {
  bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);
  zpl->start();

  zpl->shell_write(GP0_WR_CSR_TINIT, 0, 0xf);
  assert(zpl->shell_read(GP0_RD_CSR_TINIT) == 0);

  for (int i = 0; i < 16; i++) {
    while (!zpl->shell_read(GP0_RD_PS2PL_FIFO_CTRS));
    zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA, i, 0xf);
  }

  // Make sure the fifo data is correct
  for (int i = 0; i < 16; i++) {
    while (!zpl->shell_read(GP0_RD_PL2PS_FIFO_CTRS));
    assert(zpl->shell_read(GP0_RD_PL2PS_FIFO_DATA) == i);
  }

  // Make sure TLAST was set correctly
  assert(zpl->shell_read(GP0_RD_CSR_TSTATUS) == 1);

  printf("## everything passed; at end of test\n");
  for (int i = 0; i < 50; i++) zpl->tick();
  zpl->stop();
  zpl->done();

  delete zpl;
  return 0;
}
