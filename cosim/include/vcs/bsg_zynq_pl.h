// This is an implementation of the standardized host bsg_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#include <cassert>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <fstream>
#include <iostream>
#include <memory>
#include <svdpi.h>
#include <unistd.h>
#include <memory>
#include <vector>
#include "bsg_argparse.h"
#include "bsg_axil.h"
#include "bsg_printing.h"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_peripherals.h"
#include "zynq_headers.h"

extern "C" { void bsg_dpi_next(); }

using namespace std;
using namespace bsg_nonsynth_dpi;

class bsg_zynq_pl {

  std::unique_ptr<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > axi_gp0;
  std::unique_ptr<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > axi_gp1;
  std::unique_ptr<axilm<GP2_ADDR_WIDTH, GP2_DATA_WIDTH> > axi_gp2;
  std::unique_ptr<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> > axi_hp0;

  std::unique_ptr<zynq_scratchpad> scratchpad;
  std::unique_ptr<zynq_watchdog> watchdog;

public:
  // Move the simulation forward to the next DPI event
  static void tick(void) {
    bsg_dpi_next();
  }

  static void done(void) { 
    bsg_pr_info("  bsg_zynq_pl: done() called, exiting\n");
  }

  bsg_zynq_pl(int argc, char *argv[]);
  ~bsg_zynq_pl(void);

  void axil_write(uintptr_t address, int32_t data, uint8_t wstrb);
  int32_t axil_read(uintptr_t address);

  void axil_poll();
};

#endif
