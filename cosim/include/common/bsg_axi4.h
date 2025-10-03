
#ifndef BSG_AXI4_H
#define BSG_AXI4_H

#include <cassert>
#include <fstream>
#include <functional>
#include <iostream>
#include <memory>
#include <mutex>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <svdpi.h>
#include <unistd.h>

#include <boost/coroutine2/all.hpp>

#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_pin.h"
#include "bsg_printing.h"

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 1000
#endif

extern "C" {
int bsg_dpi_time();
}

typedef boost::coroutines2::coroutine<void>::pull_type coro_t;
typedef boost::coroutines2::coroutine<void>::push_type yield_t;

class s_axi4_device {
  public:
    virtual bool is_read(uintptr_t address) = 0;
    virtual bool can_read(uintptr_t address) = 0;
    virtual int32_t read(uintptr_t address) = 0;

    virtual bool is_write(uintptr_t address) = 0;
    virtual bool can_write(uintptr_t address) = 0;
    virtual void write(uintptr_t address, int32_t data) = 0;
};

class m_axi4_device {
  public:
    virtual bool pending_read(uintptr_t *address) = 0;
    virtual void return_read(int32_t data) = 0;

    virtual bool pending_write(uintptr_t *address, int32_t *data,
                               uint8_t *wmask) = 0;
    virtual void return_write() = 0;
};

// A = axi4 address width
// D = axi4 data width
template <unsigned int A, unsigned int D> class maxi4 {
  private:
    std::string base;

    pin<1> p_aclk;
    pin<1> p_aresetn;

    pin<A> p_awaddr;
    pin<2> p_awburst;
    pin<8> p_awlen;
    pin<1> p_awvalid;
    pin<1> p_awready;
    pin<1> p_awid;

    pin<D> p_wdata;
    pin<D / 8> p_wstrb;
    pin<1> p_wlast;
    pin<1> p_wvalid;
    pin<1> p_wready;
    pin<1> p_wid;

    pin<1> p_bvalid;
    pin<1> p_bready;
    pin<1> p_bid;
    pin<2> p_bresp;

    pin<A> p_araddr;
    pin<2> p_arburst;
    pin<8> p_arlen;
    pin<1> p_arvalid;
    pin<1> p_arready;
    pin<1> p_arid;

    pin<D> p_rdata;
    pin<1> p_rlast;
    pin<1> p_rvalid;
    pin<1> p_rready;
    pin<1> p_rid;
    pin<2> p_rresp;

    // We use a boolean instead of true mutex so that we can check it
    bool mutex = 0;

    void lock(yield_t &yield) {
        do {
            yield();
        } while (mutex);
        mutex = 1;
    }

    void unlock(yield_t &yield) {
        yield();
        mutex = 0;
    }

  public:
    maxi4(const std::string &base)
        : base(base), p_aclk(string(base) + std::string(".aclk_gpio")),
          p_aresetn(string(base) + std::string(".aresetn_gpio")),

          p_awaddr(string(base) + std::string(".awaddr_gpio")),
          p_awburst(string(base) + std::string(".awburst_gpio")),
          p_awlen(string(base) + std::string(".awlen_gpio")),
          p_awvalid(string(base) + std::string(".awvalid_gpio")),
          p_awready(string(base) + std::string(".awready_gpio")),
          p_awid(string(base) + std::string(".awid_gpio")),

          p_wdata(string(base) + std::string(".wdata_gpio")),
          p_wstrb(string(base) + std::string(".wstrb_gpio")),
          p_wvalid(string(base) + std::string(".wvalid_gpio")),
          p_wlast(string(base) + std::string(".wlast_gpio")),
          p_wready(string(base) + std::string(".wready_gpio")),
          p_wid(string(base) + std::string(".wid_gpio")),

          p_bresp(string(base) + std::string(".bresp_gpio")),
          p_bvalid(string(base) + std::string(".bvalid_gpio")),
          p_bready(string(base) + std::string(".bready_gpio")),
          p_bid(string(base) + std::string(".bid_gpio")),
          p_bresp(string(base) + std::string(".bresp_gpio")),

          p_araddr(string(base) + std::string(".araddr_gpio")),
          p_arburst(string(base) + std::string(".arburst_gpio")),
          p_arlen(string(base) + std::string(".arlen_gpio")),
          p_arvalid(string(base) + std::string(".arvalid_gpio")),
          p_arready(string(base) + std::string(".arready_gpio")),
          p_arid(string(base) + std::string(".arid_gpio")),

          p_rdata(string(base) + std::string(".rdata_gpio")),
          p_rlast(string(base) + std::string(".rlast_gpio")),
          p_rvalid(string(base) + std::string(".rvalid_gpio")),
          p_rready(string(base) + std::string(".rready_gpio")),
          p_rid(string(base) + std::string(".rid_gpio")),
          p_rresp(string(base) + std::string(".rresp_gpio")), mutex(0) {
        std::cout << "AXI4M not implemented yet!" << std::endl;
        exit(-1);
    }

    // Wait for (low true) reset to be asserted by the testbench
    void reset(yield_t &yield);

    int32_t axi4_read_helper(uintptr_t address, yield_t &yield) { return -1; }

    void axi4_write_helper(uintptr_t address, int32_t data, uint8_t wstrb,
                           yield_t &yield);
};

// A = axi4 address width
// D = axi4 data width
template <unsigned int A, unsigned int D> class saxi4 {
  private:
    pin<1> p_aclk;
    pin<1> p_aresetn;

    pin<A> p_awaddr;
    pin<2> p_awburst;
    pin<8> p_awlen;
    pin<1> p_awvalid;
    pin<1> p_awready;
    pin<1> p_awid;

    pin<D> p_wdata;
    pin<D / 8> p_wstrb;
    pin<1> p_wlast;
    pin<1> p_wvalid;
    pin<1> p_wready;
    pin<1> p_wid;

    pin<1> p_bvalid;
    pin<1> p_bready;
    pin<1> p_bid;
    pin<2> p_bresp;

    pin<A> p_araddr;
    pin<2> p_arburst;
    pin<8> p_arlen;
    pin<1> p_arvalid;
    pin<1> p_arready;
    pin<1> p_arid;

    pin<D> p_rdata;
    pin<1> p_rlast;
    pin<1> p_rvalid;
    pin<1> p_rready;
    pin<1> p_rid;
    pin<2> p_rresp;

    // We use a boolean instead of true mutex so that we can check it
    bool mutex = 0;

    void lock(yield_t &yield) {
        do {
            yield();
        } while (mutex);
        mutex = 1;
    }

    void unlock(yield_t &yield) {
        yield();
        mutex = 0;
    }

  public:
    saxi4(const std::string &base)
        : base(base), p_aclk(string(base) + std::string(".aclk_gpio")),
          p_aresetn(string(base) + std::string(".aresetn_gpio")),

          p_awaddr(string(base) + std::string(".awaddr_gpio")),
          p_awburst(string(base) + std::string(".awburst_gpio")),
          p_awlen(string(base) + std::string(".awlen_gpio")),
          p_awvalid(string(base) + std::string(".awvalid_gpio")),
          p_awready(string(base) + std::string(".awready_gpio")),
          p_awid(string(base) + std::string(".awid_gpio")),

          p_wdata(string(base) + std::string(".wdata_gpio")),
          p_wstrb(string(base) + std::string(".wstrb_gpio")),
          p_wvalid(string(base) + std::string(".wvalid_gpio")),
          p_wlast(string(base) + std::string(".wlast_gpio")),
          p_wready(string(base) + std::string(".wready_gpio")),
          p_wid(string(base) + std::string(".wid_gpio")),

          p_bresp(string(base) + std::string(".bresp_gpio")),
          p_bvalid(string(base) + std::string(".bvalid_gpio")),
          p_bready(string(base) + std::string(".bready_gpio")),
          p_bid(string(base) + std::string(".bid_gpio")),
          p_bresp(string(base) + std::string(".bresp_gpio")),

          p_araddr(string(base) + std::string(".araddr_gpio")),
          p_arburst(string(base) + std::string(".arburst_gpio")),
          p_arlen(string(base) + std::string(".arlen_gpio")),
          p_arvalid(string(base) + std::string(".arvalid_gpio")),
          p_arready(string(base) + std::string(".arready_gpio")),
          p_arid(string(base) + std::string(".arid_gpio")),

          p_rdata(string(base) + std::string(".rdata_gpio")),
          p_rlast(string(base) + std::string(".rlast_gpio")),
          p_rvalid(string(base) + std::string(".rvalid_gpio")),
          p_rready(string(base) + std::string(".rready_gpio")),
          p_rid(string(base) + std::string(".rid_gpio")),
          p_rresp(string(base) + std::string(".rresp_gpio")), mutex(0) {
        std::cout << "Instantiating AXI4 at " << base << std::endl;
    }

    // Wait for (low true) reset to be asserted by the testbench
    void reset(yield_t &yield) {
        printf("bsg_zynq_pl: Entering reset\n");
        lock(yield);
        while (this->p_aresetn == 0) {
            yield();
        }
        unlock(yield);
        printf("bsg_zynq_pl: Exiting reset\n");
    }

    bool axi4_has_write(uintptr_t *address) {
	    bool awv = this->p_awvalid;
        bool wv = this->p_wvalid;
        *address = this->p_awaddr;
        return awv && wv && !mutex;
    }

    bool axi4_has_read(uintptr_t *address) {
        bool arv = this->p_arvalid;
        *address = this->p_araddr;
        return arv && !mutex;
    }

    void axi4_read_helper(s_axi4_device *p, yield_t &yield) {
		printf("AXI4 read helper not implemented yet!\n");
		exit(-1);
	}

    void axi4_write_helper(s_axi4_device *p, yield_t &yield) {
		printf("AXI4 write helper not implemented yet!\n");
	e	exit(-1);
	}
};

#endif
