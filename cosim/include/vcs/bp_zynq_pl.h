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
#include "zynq_headers.h"

extern "C" { void bsg_dpi_next(); }

using namespace std;
using namespace bsg_nonsynth_dpi;

// Scratchpad
#define SCRATCHPAD_BASE 0x1000000
#define SCRATCHPAD_SIZE 0x100000
class zynq_scratchpad : public axil_device {
  std::vector<int> mem;

public:
  zynq_scratchpad() {
    mem.resize(SCRATCHPAD_SIZE, 0);
  }

  int read(int address, void (*tick)()) override {
    int final_addr = ((address-SCRATCHPAD_BASE) + SCRATCHPAD_SIZE) % SCRATCHPAD_SIZE;
    bsg_pr_dbg_pl("  bp_zynq_pl: scratchpad read [%x] == %x\n", final_addr, mem.at(final_addr));
    return mem.at(final_addr);
  }

  void write(int address, int data, void (*tick)()) override {
    int final_addr = ((address-SCRATCHPAD_BASE) + SCRATCHPAD_SIZE) % SCRATCHPAD_SIZE;
    bsg_pr_dbg_pl("  bp_zynq_pl: scratchpad write [%x] <- %x\n", final_addr, data);
    mem.at(final_addr) = data;
  }
};

class bsg_tag_bitbang;

class bp_zynq_pl {

  std::unique_ptr<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > axi_gp0;
  std::unique_ptr<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > axi_gp1;
  std::unique_ptr<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> > axi_hp0;
public:
  std::unique_ptr<bsg_tag_bitbang> tag;
  std::unique_ptr<zynq_scratchpad> scratchpad;

  // Move the simulation forward to the next DPI event
  static void tick(void) { bsg_dpi_next(); }

  static void done(void) { bsg_pr_info("  bp_zynq_pl: done() called, exiting\n"); }

  bp_zynq_pl(int argc, char *argv[]) {
    tick();
#ifdef BITBANG_ENABLE
    tag = std::make_unique<bsg_tag_bitbang>();
#endif
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
#ifdef HP0_ENABLE
    axi_hp0 = std::make_unique<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> >(
        STRINGIFY(HP0_HIER_BASE));
    axi_hp0->reset(tick);
#endif
#ifdef SCRATCHPAD_ENABLE
    scratchpad = std::make_unique<zynq_scratchpad>();
#else
#endif
  }

  ~bp_zynq_pl(void) {}

  void axil_write(unsigned int address, int data, int wstrb=0xF) {
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
      bsg_pr_err("  bp_zynq: unsupported AXIL port %d\n", index);
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
    if (axi_hp0->p_awvalid && (axi_hp0->p_awaddr >= SCRATCHPAD_BASE) && (axi_hp0->p_awaddr < SCRATCHPAD_BASE+SCRATCHPAD_SIZE)) {
      axi_hp0->axil_write_helper((axil_device *)scratchpad.get(), tick);
    } else if (axi_hp0->p_arvalid && (axi_hp0->p_araddr >= SCRATCHPAD_BASE) && (axi_hp0->p_araddr < SCRATCHPAD_BASE+SCRATCHPAD_SIZE)) {
      axi_hp0->axil_read_helper((axil_device *)scratchpad.get(), tick);
    } else if (axi_hp0->p_awvalid) {
      int awaddr = axi_hp0->p_awaddr;
      bsg_pr_err("  bp_zynq_pl: Unsupported AXI device write at [%x]\n", awaddr);
    } else if (axi_hp0->p_arvalid) {
      int araddr = axi_hp0->p_awaddr;
      bsg_pr_err("  bp_zynq_pl: Unsupported AXI device read at [%x]\n", araddr);
    }
  }
};

#endif
