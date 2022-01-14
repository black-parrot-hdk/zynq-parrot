
#ifndef BSG_AXIL_H
#define BSG_AXIL_H

#include <cassert>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <functional>
#include <fstream>
#include <iostream>
#include <memory>
#include <svdpi.h>
#include <unistd.h>
#include <string>
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_printing.h"

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 50000
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

  void set(const unsigned int val) {
    unsigned int bval = 0;
    for (int i = 0; i < W; i++) {
      bval = (val & (1 << i)) >> i;
      gpio->set(i, bval);
    }
  }

  void operator=(const unsigned int val) {
    set(val);
  }

  int get() const {
    unsigned int N = 0;
    for (int i = 0; i < W; i++) {
      N |= gpio->get(i) << i;
    }

    return N;
  }

  operator int() const {
    return get();
  }
};

class s_axil_device {
public:
  virtual bool is_read(uintptr_t address) = 0;
  virtual int32_t read(uintptr_t address) = 0;

  virtual bool is_write(uintptr_t address) = 0;
  virtual void write(uintptr_t address, int32_t data) = 0;
};

class m_axil_device {
public:
  virtual bool pending_read(uintptr_t *address) = 0;
  virtual void return_read(int32_t data) = 0;

  virtual bool pending_write(uintptr_t *address, int32_t *data, uint8_t *wmask) = 0;
  virtual void return_write() = 0;
};

// A = axil address width
// D = axil data width
template <unsigned int A, unsigned int D> class axilm {
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

  axilm(const string &base)
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
  void reset(std::function<void()> tick) {
    printf("bsg_zynq_pl: Entering reset\n");
    while (this->p_aresetn == 0) {
      tick();
    }
    printf("bsg_zynq_pl: Exiting reset\n");
  }

  int axil_read_helper(uintptr_t address, std::function<void()> tick) {
    int timeout_counter = 0;

    bool ar_done = false;
    bool r_done = false;

    int rdata;

    // assert these signals "late in the cycle"
    // stall while ready is not asserted
    this->p_arvalid = 1;
    this->p_araddr = address;
    while (!ar_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI M read arready timeout\n");
      }

      if (this->p_arready == 1) {
        ar_done = true;
      }

      tick();
    }
    this->p_arvalid = 0;

    // setup to receive the reply
    // stall while valid is not asserted
    while (!r_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI M read rvalid timeout\n");
      }

      if (this->p_rvalid == 1) {
        rdata = this->p_rdata;
        r_done = true;
      }

      tick();
    }

    // Do the read
    this->p_rready = 1;
    tick();
    this->p_rready = 0;

    return rdata;
  }

  void axil_write_helper(uintptr_t address, int32_t data, uint8_t wstrb,
                         std::function<void()> tick) {
    int timeout_counter = 0;

    assert(wstrb == 0xf); // we only support full int writes right now

    bool aw_done = false;
    bool w_done = false;
    bool b_done = false;

    // send data and address in same cycle
    this->p_awvalid = 1;
    this->p_wvalid = 1;
    this->p_awaddr = address;
    this->p_wdata = data;
    this->p_wstrb = wstrb;

    // loop until both address and data consumed
    // subordinate is allowed to consume one before the other, or both at once
    // this loop will run at least once (and tick the clock)
    while (!aw_done || !w_done) {
      // check timeout
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI S write timeout\n");
      }

      if (this->p_awready == 1) {
        aw_done = true;
      }

      if (this->p_wready == 1) {
        w_done = true;
      }

      // tick the clock one cycle
      tick();
    }
    this->p_awvalid = 0;
    this->p_wvalid = 0;

    // wait for response valid
    while (!b_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI M bvalid timeout\n");
      }

      if (this->p_bvalid == 1) {
        this->p_bready = 1;
        b_done = true;
      }

      tick();
    }
    // Drop bready
    this->p_bready = 0;
  }
};

// A = axil address width
// D = axil data width
template <unsigned int A, unsigned int D> class axils {
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

  axils(const string &base)
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
  void reset(std::function<void()> tick) {
    printf("bsg_zynq_pl: Entering reset\n");
    while (this->p_aresetn == 0) {
      tick();
    }
    printf("bsg_zynq_pl: Exiting reset\n");
  }

  void axil_read_helper(s_axil_device *p, std::function<void()> tick) {
    int timeout_counter = 0;
    int araddr;

    bool ar_done = false;
    bool r_done = false;

    while (!ar_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI S read request timeout\n");
      }

      if (this->p_arvalid == 1) {
        araddr = this->p_araddr;
        this->p_arready = 1;
        ar_done = true;
      }

      tick();
    }
    this->p_arready = 0;

    // Return read data
    this->p_rdata = p->read(araddr);
    this->p_rresp = 0;
    this->p_rvalid = 1;
    while (!r_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI S read data timeout\n");
      }

      if (this->p_rready == 1) {
        r_done = true;
      }

      tick();
    }
    this->p_rvalid = 0;
  }

  void axil_write_helper(s_axil_device *p, std::function<void ()> tick) {
    int timeout_counter = 0;

    bool aw_done = false;
    bool w_done = false;
    bool b_done = false;

    assert(this->p_wstrb == 0xf); // we only support full int writes right now

    int awaddr;
    int wdata;

    // loop until both address and data consumed
    // subordinate is allowed to consume one before the other, or both at once
    // this loop will run at least once (and tick the clock)
    while (!aw_done || !w_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI S write timeout\n");
      }

      if (this->p_awvalid) {
        awaddr = this->p_awaddr;
        this->p_awready = 1;
        aw_done = true;
      }

      if (this->p_wvalid) {
        wdata = this->p_wdata;
        this->p_wready = 1;
        w_done = true;
      }

      tick();
    }

    // Do the write
    p->write(awaddr, wdata);
    this->p_awready = 0;
    this->p_wready = 0;

    // raise bvalid for response
    // wait for response ready
    this->p_bvalid = 1;
    this->p_bresp  = 0;
    while (!b_done) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        bsg_pr_err("bsg_zynq_pl: AXI S bvalid timeout\n");
      }

      if (this->p_bready == 1) {
        b_done = true;
      }

      tick();
    }
    this->p_bvalid = 0;
  }
};

#endif

