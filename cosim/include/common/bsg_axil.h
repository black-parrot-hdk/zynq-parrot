
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
#include <mutex>
#include <svdpi.h>
#include <unistd.h>
#include <string>

#include <boost/coroutine2/all.hpp>

#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_printing.h"

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 1000
#endif

extern "C" { int bsg_dpi_time(); }
using namespace std;
using namespace bsg_nonsynth_dpi;
using namespace boost::coroutines2;
using namespace std::placeholders;

typedef coroutine<void>::pull_type coro_t;
typedef coroutine<void>::push_type yield_t;

// W = width of pin
template <unsigned int W>
class pin {
    std::unique_ptr<dpi_gpio<W>> gpio;

public:
    pin(const string &hierarchy) {
        gpio = std::make_unique<dpi_gpio<W>>(hierarchy);
    }

    void set(const unsigned int val) {
        unsigned int bval = 0;
        for (int i = 0; i < W; i++) {
            bval = (val & (1 << i)) >> i;
            gpio->set(i, bval);
        }
    }

    void operator=(const unsigned int val) { set(val); }

    int get() const {
        unsigned int N = 0;
        for (int i = 0; i < W; i++) {
            N |= gpio->get(i) << i;
        }

        return N;
    }

    operator int() const { return get(); }
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

    virtual bool pending_write(uintptr_t *address, int32_t *data,
                               uint8_t *wmask) = 0;
    virtual void return_write() = 0;
};

// A = axil address width
// D = axil data width
template <unsigned int A, unsigned int D>
class maxil {
private:
    string base;

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
    maxil(const string &base)
        : base(base),
          p_aclk(string(base) + string(".aclk_gpio")),
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
          p_rready(string(base) + string(".rready_gpio")),
          mutex(0) {
        std::cout << "Instantiating AXIL at " << base << std::endl;
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

    int32_t axil_read_helper(uintptr_t address, yield_t &yield) {
        lock(yield);
        int timeout_counter = 0;

        bool ar_done = false;
        bool r_done = false;

        int rdata;

        // assert these signals "late in the cycle"
        // stall while ready is not asserted
        this->p_arvalid = 1;
        this->p_araddr = address;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI M read arready timeout\n");
                timeout_counter = 0;
            }

            if (this->p_arready == 1) {
                ar_done = true;
            }
            yield();

            if (ar_done) {
                this->p_arvalid = 0;
            }
        } while (!ar_done);

        // setup to receive the reply
        // stall while valid is not asserted
        yield();
        this->p_rready = 1;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI M read rvalid timeout\n");
                timeout_counter = 0;
            }

            if (this->p_rvalid == 1) {
                rdata = this->p_rdata;
                r_done = true;
            }
            yield();

            if (r_done) {
                this->p_rready = 0;
            }
        } while (!r_done);

        unlock(yield);
        return rdata;
    }

    void axil_write_helper(uintptr_t address, int32_t data, uint8_t wstrb,
                           yield_t &yield) {
        lock(yield);
        int timeout_counter = 0;

        bool aw_done = false;
        bool w_done = false;
        bool b_done = false;

        // loop until both address and data consumed
        // subordinate is allowed to consume one before the other, or both at
        // once
        // this loop will run at least once (and tick the clock)
        // send data and address in same cycle
        this->p_awvalid = 1;
        this->p_wvalid = 1;
        this->p_awaddr = address;
        this->p_wdata = data;
        this->p_wstrb = wstrb;
        do {
            // check timeout
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI M write timeout\n");
            }

            if (this->p_awready == 1) {
                aw_done = true;
            }

            if (this->p_wready == 1) {
                w_done = true;
            }

            // tick the clock one cycle
            yield();

            if (aw_done) {
                this->p_awvalid = 0;
            }

            if (w_done) {
                this->p_wvalid = 0;
            }
        } while (!aw_done || !w_done);

        yield();
        this->p_bready = 1;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: %s, AXI M bvalid timeout at %lld\n,",
                           base.c_str(), bsg_dpi_time());
            }

            if (this->p_bvalid == 1) {
                b_done = true;
            }

            yield();

            if (b_done) {
                this->p_bready = 0;
            }
        } while (!b_done);

        unlock(yield);
        return;
    }
};

// A = axil address width
// D = axil data width
template <unsigned int A, unsigned int D>
class saxil {
private:
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
    saxil(const string &base)
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
    void reset(yield_t &yield) {
        printf("bsg_zynq_pl: Entering reset\n");
        lock(yield);
        while (this->p_aresetn == 0) {
            yield();
        }
        unlock(yield);
        printf("bsg_zynq_pl: Exiting reset\n");
    }

    bool axil_has_write(uintptr_t *address) {
        bool awv = this->p_awvalid;
        bool wv = this->p_wvalid;
        *address = this->p_awaddr;
        return awv && wv && !mutex;
    }

    bool axil_has_read(uintptr_t *address) {
        bool arv = this->p_arvalid;
        *address = this->p_araddr;
        return arv && !mutex;
    }

    void axil_read_helper(s_axil_device *p, yield_t &yield) {
        lock(yield);
        int timeout_counter = 0;
        int araddr;

        bool ar_done = false;
        bool r_done = false;

        this->p_arready = 1;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI S read request timeout\n");
                timeout_counter = 0;
            }

            if (this->p_arvalid == 1) {
                araddr = this->p_araddr;
                ar_done = true;
            }

            yield();

            if (ar_done) {
                this->p_arready = 0;
            }
        } while (!ar_done);

        // Return read data
        yield();
        this->p_rdata = p->read(araddr);
        this->p_rresp = 0;
        this->p_rvalid = 1;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI S read data timeout\n");
                timeout_counter = 0;
            }

            if (this->p_rready == 1) {
                r_done = true;
            }

            yield();

            if (r_done) {
                this->p_rvalid = 0;
            }
        } while (!r_done);
        unlock(yield);
        return;
    }

    void axil_write_helper(s_axil_device *p, yield_t &yield) {
        lock(yield);
        int timeout_counter = 0;

        bool aw_done = false;
        bool w_done = false;
        bool b_done = false;

        int awaddr;
        int wdata;

        // loop until both address and data consumed
        // subordinate is allowed to consume one before the other, or both at
        // once
        // this loop will run at least once (and tick the clock)
        this->p_awready = 1;
        this->p_wready = 1;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI S write timeout\n");
                timeout_counter = 0;
            }

            if (this->p_awvalid) {
                awaddr = this->p_awaddr;
                aw_done = true;
            }

            if (this->p_wvalid) {
                wdata = this->p_wdata;
                w_done = true;
            }

            yield();

            if (aw_done) {
                this->p_awready = 0;
            }

            if (w_done) {
                this->p_wready = 0;
            }

            if (aw_done && w_done) {
                // Do the write
                p->write(awaddr, wdata);
            }
        } while (!aw_done || !w_done);

        // raise bvalid for response
        // wait for response ready
        yield();
        this->p_bvalid = 1;
        this->p_bresp = 0;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: AXI S bvalid timeout\n");
                timeout_counter = 0;
            }

            if (this->p_bready == 1) {
                b_done = true;
            }

            yield();

            if (b_done) {
                this->p_bvalid = 0;
            }
        } while (!b_done);

        unlock(yield);
        return;
    }
};

#endif

