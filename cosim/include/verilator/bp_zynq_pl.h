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

  bp_zynq_pl(int argc, char *argv[]) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);

    // turn on tracing
    Verilated::traceEverOn(true);

    tb = new Vtop();

    // Tick once to register clock generators
    tb->eval();
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

  ~bp_zynq_pl(void) {
    // Causes segfault, double free?
    // delete tb;
  }

  void axil_write(uint64_t address, uint32_t data, int wstrb) {
    unsigned int offset;
    int index;

    // we subtract the bases to make it consistent with the Zynq AXI IPI
    // implementation

    if (address >= GP0_ADDR_BASE &&
        address <= GP0_ADDR_BASE + GP0_ADDR_SIZE_BYTES) {
      index = 0;
      offset = (unsigned int)(address - GP0_ADDR_BASE);
    } else if (address >= GP1_ADDR_BASE &&
               address <= GP1_ADDR_BASE + GP1_ADDR_SIZE_BYTES) {
      index = 1;
      offset = (unsigned int)(address - GP1_ADDR_BASE);
    } else
      bsg_pr_err("Invalid axi port: %d\n", index);

    bsg_pr_dbg_pl("  bp_zynq_pl: AXI writing [%lx] -> port %d, [%x]<-%8.8x\n",
                  address, index, offset, data);

    if (index == 0) {
      axi_gp0->axil_write_helper(offset, (int)data, wstrb, tick);
    } else if (index == 1) {
      axi_gp1->axil_write_helper(offset, (int)data, wstrb, tick);
    }
  }

  uint32_t axil_read(uint64_t address) {
    unsigned int offset;
    int index = 0;
    uint32_t data;

    // we subtract the bases to make it consistent with the Zynq AXI IPI
    // implementation

    if (address >= GP0_ADDR_BASE &&
        address <= GP0_ADDR_BASE + GP0_ADDR_SIZE_BYTES) {
      index = 0;
      offset = (unsigned int)(address - GP0_ADDR_BASE);
    } else if (address >= GP1_ADDR_BASE &&
               address <= GP1_ADDR_BASE + GP1_ADDR_SIZE_BYTES) {
      index = 1;
      offset = (unsigned int)(address - GP1_ADDR_BASE);
    } else
      bsg_pr_err("Invalid axi port: %d\n", index);

    if (index == 0) {
      data = (uint32_t)axi_gp0->axil_read_helper(address, tick);
    } else if (index == 1) {
      data = (uint32_t)axi_gp1->axil_read_helper(address, tick);
    }

    bsg_pr_dbg_pl("  bp_zynq_pl: AXI reading [%lx] -> port %d, [%x]->%8.8x\n",
                  address, index, offset, data);

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

Vtop *bp_zynq_pl::tb;
std::unique_ptr<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > bp_zynq_pl::axi_gp0;
std::unique_ptr<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > bp_zynq_pl::axi_gp1;
std::unique_ptr<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> > bp_zynq_pl::axi_hp0;

std::unique_ptr<zynq_scratchpad> bp_zynq_pl::scratchpad;

#endif
