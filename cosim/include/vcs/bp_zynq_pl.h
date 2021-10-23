// This is an implementation of the standardized host bp_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BP_ZYNQ_PL_H
#define BP_ZYNQ_PL_H

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
#include "bsg_argparse.h"
#include "bsg_axil.h"
#include "bsg_printing.h"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "zynq_headers.h"

extern "C" { void bsg_dpi_next(); }

using namespace std;
using namespace bsg_nonsynth_dpi;

class bp_zynq_pl {

  static std::unique_ptr<axil<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > axi_gp0;
  static std::unique_ptr<axil<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > axi_gp1;

public:
  // Move the simulation forward to the next DPI event
  static void tick(void) { bsg_dpi_next(); }

  static void done(void) { bsg_pr_info("bp_zynq_pl: done() called, exiting\n"); }

  bp_zynq_pl(int argc, char *argv[]) {
    tick();

#ifdef GP0_ENABLE
    axi_gp0 = std::make_unique<axil<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> >(
        STRINGIFY(GP0_HIER_BASE));
    axi_gp0->reset(tick);
#endif
#ifdef GP1_ENABLE
    axi_gp1 = std::make_unique<axil<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> >(
        STRINGIFY(GP1_HIER_BASE));
    axi_gp1->reset(tick);
#endif
  }

  ~bp_zynq_pl(void) {}

  void axil_write(unsigned int address, int data, int wstrb) {
    int address_orig = address;
    int index;

    // we subtract the bases to make it consistent with the Zynq AXI IPI
    // implementation

    if (address >= GP0_ADDR_BASE &&
        address <= GP0_ADDR_BASE + GP0_ADDR_SIZE_BYTES) {
      index = 0;
      address = address - GP0_ADDR_BASE;
    } else if (address >= GP1_ADDR_BASE &&
               address <= GP1_ADDR_BASE + GP1_ADDR_SIZE_BYTES) {
      index = 1;
      address = address - GP1_ADDR_BASE;
    } else {
      bsg_pr_err("  bp_zynq: unsupported AXIL port %d", index);
    }

    bsg_pr_dbg_pl("  bp_zynq_pl: AXI writing [%x] -> port %d, [%x]<-%8.8x\n",
                  address_orig, index, address, data);

    if (index == 0) {
      axi_gp0->axil_write_helper(address, data, wstrb, tick);
    } else if (index == 1) {
      axi_gp1->axil_write_helper(address, data, wstrb, tick);
    }
  }

  int axil_read(unsigned int address) {
    int address_orig = address;
    int index = 0;
    int data;

    // we subtract the bases to make it consistent with the Zynq AXI IPI
    // implementation

    if (address >= GP0_ADDR_BASE &&
        address <= GP0_ADDR_BASE + GP0_ADDR_SIZE_BYTES) {
      index = 0;
      address = address - GP0_ADDR_BASE;
    } else if (address >= GP1_ADDR_BASE &&
               address <= GP1_ADDR_BASE + GP1_ADDR_SIZE_BYTES) {
      index = 1;
      address = address - GP1_ADDR_BASE;
    } else {
      bsg_pr_err("  bp_zynq: unsupported AXIL port %d", index);
    }

    if (index == 0) {
      data = axi_gp0->axil_read_helper(address, tick);
    } else if (index == 1) {
      data = axi_gp1->axil_read_helper(address, tick);
    }

    bsg_pr_dbg_pl("  bp_zynq_pl: AXI reading [%x] -> port %d, [%x]->%8.8x\n",
                  address_orig, index, address, data);

    return data;
  }
};

std::unique_ptr<axil<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > bp_zynq_pl::axi_gp0;
std::unique_ptr<axil<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > bp_zynq_pl::axi_gp1;

#endif
