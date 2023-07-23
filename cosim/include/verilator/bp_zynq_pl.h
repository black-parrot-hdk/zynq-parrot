// This is an implementation of the standardized host bp_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BP_ZYNQ_PL_H
#define BP_ZYNQ_PL_H

#include <cassert>
#include <stdio.h>
#include <string>
#include <fstream>
#include <iostream>
#include "bsg_axil.h"
#include "bsg_printing.h"
#include "bsg_nonsynth_dpi_clock_gen.hpp"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "zynq_headers.h"

using namespace std;
using namespace bsg_nonsynth_dpi;

#include "Vtop.h"
#include "verilated.h"

// Scratchpad
#define SCRATCHPAD_BASE 0x1000000
#define SCRATCHPAD_SIZE 0x100000
class zynq_scratchpad : public axil_device {
  std::vector<int> mem;

public:
  zynq_scratchpad();

  int read(int address, void (*tick)()) override;
  void write(int address, int data, void (*tick)()) override;
};

class bp_zynq_pl {
  static Vtop *tb;

  static std::unique_ptr<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > axi_gp0;
  static std::unique_ptr<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > axi_gp1;
  static std::unique_ptr<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> > axi_hp0;

  static std::unique_ptr<zynq_scratchpad> scratchpad;

public:
  // Each bsg_timekeeper::next() moves to the next clock edge
  //   so we need 2 to perform one full clock cycle.
  // If your design does not evaluate things on negedge, you could omit
  //   the first eval, but BSG designs tend to do assertions on negedge
  //   at the least.
  static void tick(void) {
    tb->eval();
    bsg_timekeeper::next();
    tb->eval();
    bsg_timekeeper::next();
  }

  static void done(void) { printf("bp_zynq_pl: done() called, exiting\n"); }

  bp_zynq_pl(int argc, char *argv[]);
  ~bp_zynq_pl(void);

  void axil_write(uint64_t address, uint32_t data, int wstrb);
  uint32_t axil_read(uint64_t address);

  void axil_poll();
};

#endif
