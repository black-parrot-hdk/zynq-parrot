// This is an implementation of the standardized host bsg_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#include <cassert>
#include <stdio.h>
#include <string>
#include <fstream>
#include <iostream>
#include "bsg_axil.h"
#include "bsg_printing.h"
#include "bsg_nonsynth_dpi_clock_gen.hpp"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_peripherals.h"
#include "zynq_headers.h"
#include "verilated_fst_c.h"
#include "verilated_cov.h"

using namespace std;
using namespace bsg_nonsynth_dpi;

#include "Vtop.h"
#include "verilated.h"

class bsg_zynq_pl {
  static Vtop *tb;
  static VerilatedFstC *wf;

  std::unique_ptr<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > axi_gp0;
  std::unique_ptr<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > axi_gp1;
  std::unique_ptr<axilm<GP2_ADDR_WIDTH, GP2_DATA_WIDTH> > axi_gp2;
  std::unique_ptr<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> > axi_hp0;
  std::unique_ptr<zynq_scratchpad> scratchpad;
  std::unique_ptr<zynq_watchdog> watchdog;

public:
  // Each bsg_timekeeper::next() moves to the next clock edge
  //   so we need 2 to perform one full clock cycle.
  // If your design does not evaluate things on negedge, you could omit
  //   the first eval, but BSG designs tend to do assertions on negedge
  //   at the least.
  static void tick(void) {
    tb->eval();
    wf->dump(sc_time_stamp());
    bsg_timekeeper::next();
    tb->eval();
    wf->dump(sc_time_stamp());
    bsg_timekeeper::next();
  }

  static void done(void) {
    printf("bsg_zynq_pl: done() called, exiting\n");
    wf->close();
  }

  bsg_zynq_pl(int argc, char *argv[]);
  ~bsg_zynq_pl(void);

  void axil_write(uintptr_t address, int32_t data, uint8_t wstrb);
  int32_t axil_read(uintptr_t address);

  void axil_poll();
};

#endif
