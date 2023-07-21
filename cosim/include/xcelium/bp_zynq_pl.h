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

class bp_zynq_pl {

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
    bsg_pr_info("  bp_zynq_pl: done() called, exiting\n");
  }

  bp_zynq_pl(int argc, char *argv[]) {
    // Initialize backpressure (if any)
#ifdef SIM_BACKPRESSURE_ENABLE
    srand(SIM_BACKPRESSURE_SEED);
#endif

    tick();
#ifdef GP0_ENABLE
    axi_gp0 = std::make_unique<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> >(
        STRINGIFY(GP0_HIER_BASE));
    axi_gp0->reset(tick);
#endif
#ifdef GP1_ENABLE
    axi_gp1 = std::make_unique<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> >(
        STRINGIFY(GP1_HIER_BASE));
    axi_gp1->reset(tick);
#endif
#ifdef GP2_ENABLE
    axi_gp2 = std::make_unique<axilm<GP2_ADDR_WIDTH, GP2_DATA_WIDTH> >(
        STRINGIFY(GP2_HIER_BASE));
    axi_gp2->reset(tick);
#endif
#ifdef HP0_ENABLE
    axi_hp0 = std::make_unique<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> >(
        STRINGIFY(HP0_HIER_BASE));
    axi_hp0->reset(tick);
#ifdef SCRATCHPAD_ENABLE
    scratchpad = std::make_unique<zynq_scratchpad>();
#endif
#ifdef WATCHDOG_ENABLE
    watchdog = std::make_unique<zynq_watchdog>();
#endif
#endif
  }

  ~bp_zynq_pl(void) {}

  void axil_write(uintptr_t address, int32_t data, uint8_t wstrb) {
    uintptr_t address_orig = address;
    int index = -1;

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
      bsg_pr_err("  bp_zynq_pl: unsupported AXIL port %d\n", index);
    }

    bsg_pr_dbg_pl("  bp_zynq_pl: AXI writing [%x] -> port %d, [%x]<-%8.8x\n",
                  address_orig, index, address, data);

    if (index == 0) {
      axi_gp0->axil_write_helper(address, data, wstrb, tick);
    } else if (index == 1) {
      axi_gp1->axil_write_helper(address, data, wstrb, tick);
    }
  }

  int32_t axil_read(uintptr_t address) {
    uintptr_t address_orig = address;
    int index = -1;
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
      bsg_pr_err("  bp_zynq_pl: unsupported AXIL port %d\n", index);
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

  void axil_poll() {
#ifdef SIM_BACKPRESSURE_ENABLE
    if ((rand() % 100) < SIM_BACKPRESSURE_CHANCE) {
      for (int i = 0; i < SIM_BACKPRESSURE_LENGTH; i++) {
        tick();
      }
    }
#endif

#ifdef HP0_ENABLE
    int araddr = axi_hp0->p_araddr;
    if (!axi_hp0->p_arvalid) {
#ifdef SCRATCHPAD_ENABLE
    } else if (scratchpad->is_read(araddr)) {
      axi_hp0->axil_read_helper((s_axil_device *)scratchpad.get(), tick);
#endif
    } else {
      bsg_pr_err("  bp_zynq_pl: Unsupported AXI device read at [%x]\n", araddr);
    }
#endif

#ifdef HP0_ENABLE
    int awaddr = axi_hp0->p_awaddr;
    if (!axi_hp0->p_awvalid) {
#ifdef SCRATCHPAD_ENABLE
    } else if (scratchpad->is_write(awaddr)) {
      axi_hp0->axil_write_helper((s_axil_device *)scratchpad.get(), tick);
#endif
    } else {
      bsg_pr_err("  bp_zynq_pl: Unsupported AXI device write at [%x]\n", awaddr);
    }
#endif

#ifdef GP2_ENABLE
#ifdef WATCHDOG_ENABLE
    uintptr_t address;
    int32_t data, ret;
    uint8_t wmask;
    if (watchdog->pending_write(&address, &data, &wmask)) {
      axi_gp2->axil_write_helper(address, data, wmask, tick);
      watchdog->return_write();
    } else if (watchdog->pending_read(&address)) {
      ret = axi_gp2->axil_read_helper(address, tick);
      watchdog->return_read(ret);
    }
#endif
#endif
  }
};

#endif
