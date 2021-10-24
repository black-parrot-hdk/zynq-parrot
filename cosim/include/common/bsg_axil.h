
#ifndef BSG_AXIL_H
#define BSG_AXIL_H

#include <cassert>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <fstream>
#include <iostream>
#include <memory>
#include <svdpi.h>
#include <unistd.h>
#include <string>
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_printing.h"

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 8000
#endif

using namespace std;
using namespace bsg_nonsynth_dpi;

// W = width of pin
template <unsigned int W> class pin {
  std::unique_ptr<dpi_gpio<W> > gpio;

public:
  pin(const string &hierarchy) {
    gpio = std::make_unique<dpi_gpio<W> >(hierarchy);
  }

  void operator=(const unsigned int val) {
    unsigned int bval = 0;
    for (int i = 0; i < W; i++) {
      bval = (val & (1 << i)) >> i;
      gpio->set(i, bval);
    }
  }

  operator int() const {
    unsigned int N = 0;
    for (int i = 0; i < W; i++) {
      N |= gpio->get(i) << i;
    }

    return N;
  }
};

// A = axil address width
// D = axil data width
template <unsigned int A, unsigned int D> class axil {
public:
  pin<1> p_aclk;
  pin<1> p_aresetn;

  pin<A> p_awaddr;
  pin<3> p_awprot;
  pin<1> p_awvalid;
  pin<1> p_awready;
  pin<D> p_wdata;
  pin<D / 8> p_wstrb;
  pin<1> p_wvalid;
  pin<1> p_wready;
  pin<2> p_bresp;
  pin<1> p_bvalid;
  pin<1> p_bready;

  pin<A> p_araddr;
  pin<3> p_arprot;
  pin<1> p_arvalid;
  pin<1> p_arready;
  pin<D> p_rdata;
  pin<2> p_rresp;
  pin<1> p_rvalid;
  pin<1> p_rready;

  axil(const string &base)
      : p_aclk(string(base) + string(".aclk_gpio")),
        p_aresetn(string(base) + string(".aresetn_gpio")),
        p_awaddr(string(base) + string(".awaddr_gpio")),
        p_awprot(string(base) + string(".awprot_gpio")),
        p_awvalid(string(base) + string(".awvalid_gpio")),
        p_awready(string(base) + string(".awready_gpio")),
        p_wdata(string(base) + string(".wdata_gpio")),
        p_wstrb(string(base) + string(".wstrb_gpio")),
        p_wvalid(string(base) + string(".wvalid_gpio")),
        p_wready(string(base) + string(".wready_gpio")),
        p_bresp(string(base) + string(".bresp_gpio")),
        p_bvalid(string(base) + string(".bvalid_gpio")),
        p_bready(string(base) + string(".bready_gpio")),
        p_araddr(string(base) + string(".araddr_gpio")),
        p_arprot(string(base) + string(".arprot_gpio")),
        p_arvalid(string(base) + string(".arvalid_gpio")),
        p_arready(string(base) + string(".arready_gpio")),
        p_rdata(string(base) + string(".rdata_gpio")),
        p_rresp(string(base) + string(".rresp_gpio")),
        p_rvalid(string(base) + string(".rvalid_gpio")),
        p_rready(string(base) + string(".rready_gpio")) {
    std::cout << "Instantiating AXIL at " << base << std::endl;
  }

  // Wait for (low true) reset to be asserted by the testbench
  void reset(void (*tick)()) {
    printf("bp_zynq_pl: Entering reset\n");
    while (this->p_aresetn == 1) {
      tick();
    }
    printf("bp_zynq_pl: Exiting reset\n");
  }

  int axil_read_helper(unsigned int address, void (*tick)()) {
    int data;
    int timeout_counter = 0;

    // assert these signals "late in the cycle"
    this->p_arvalid = 1;
    this->p_araddr = address;

    // stall while ready is not asserted
    while (this->p_arready == 0) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bp_zynq_pl: AXI read arready timeout\n");
      }

      tick();
    }

    // ready was asserted, transaction will be accepted!
    tick();

    // arvalid must drop the request
    this->p_arvalid = 0;

    // setup to receive the reply
    this->p_rready = 1;

    // stall while valid is not asserted
    while (this->p_rvalid == 0) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bp_zynq_pl: AXI read rvalid timeout\n");
      }

      tick();
    }

    // if valid was asserted, latch the incoming data
    data = this->p_rdata;
    tick();

    // drop the ready signal on the following cycle
    this->p_rready = 0;

    return data;
  }

  void axil_write_helper(unsigned int address, int data, int wstrb,
                         void (*tick)()) {
    int timeout_counter = 0;

    assert(wstrb == 0xf); // we only support full int writes right now

    this->p_awvalid = 1;
    this->p_wvalid = 1;
    this->p_awaddr = address;
    this->p_wdata = data;
    this->p_wstrb = wstrb;

    while (this->p_awready == 0 && this->p_wready == 0) {

      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bp_zynq_pl: AXI write timeout\n");
      }

      tick();
    }

    tick();

    // must drop valid signals
    // let's get things ready with bready at the same time
    this->p_awvalid = 0;
    this->p_wvalid = 0;
    this->p_bready = 1;

    // wait for bvalid to go high
    while (this->p_bvalid == 0) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bp_zynq_pl: AXI bvalid timeout\n");
      }

      tick();
    }

    // now, we will drop bready low with ready on the next cycle
    tick();
    this->p_bready = 0;
    return;
  }
};

#endif
