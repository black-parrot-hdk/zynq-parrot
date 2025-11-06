#ifndef BSG_AXIS_H
#define BSG_AXIS_H

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
#include "bsg_axi.h"
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

class s_axis_device {
  public:
    virtual bool can_write() = 0;
    virtual void write(long data, bool last) = 0;
};

class m_axis_device {
  public:
    virtual bool pending_write(long *data, bool *last) = 0;
};

template <unsigned int D>
class axis : public axi_defaults<0, D> {
  protected:
    using addr_t = typename axi_defaults<0, D>::addr_t;
    using data_t = typename axi_defaults<0, D>::data_t;
  protected:
    pin<1> p_aclk;
    pin<1> p_aresetn;

    pin<1> p_tready;
    pin<1> p_tvalid;
    pin<D> p_tdata;
    pin<1> p_tlast; 

    // We use a boolean instead of true mutex so that we can check it
    bool mutex = 0;

    bool try_lock() {
        return !mutex;
    }

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

    axis(const std::string &base)
        : p_aclk(std::string(base) + std::string(".aclk_gpio")),
          p_aresetn(std::string(base) + std::string(".aresetn_gpio")),
          p_tready(std::string(base) + std::string(".tready_gpio")),
          p_tvalid(std::string(base) + std::string(".tvalid_gpio")),
          p_tdata(std::string(base) + std::string(".tdata_gpio")),
          p_tlast(std::string(base) + std::string(".tlast_gpio")) {
        std::cout << "Instantiating SAXIS at " << base;
    }

  public:
    // Wait for (low true) reset to be asserted by the testbench
    void reset(yield_t &yield) {
        printf("bsg_zynq_pl: Entering reset\n");
        this->lock(yield);
        while (this->p_aresetn == 0) {
            yield();
        }
        this->unlock(yield);
        printf("bsg_zynq_pl: Exiting reset\n");
    }
};

// D = axis data width
template <unsigned int D>
class saxis : public axis<D> {
  protected:
    using addr_t = typename axi_defaults<0, D>::addr_t;
    using data_t = typename axi_defaults<0, D>::data_t;
  public:
    saxis(const std::string &base) : axis<D>(base) {
      std::cout << " as a client AXIS port" << std::endl;
    }

    bool axis_has_write(uint8_t *last) {
        bool tv = this->p_tvalid;
        *last = this->p_tlast;

        return tv && this->try_lock();
    }

    void axis_write_helper(s_axis_device *p, yield_t &yield) {
        this->lock(yield);
        int timeout_counter = 0;

        bool t_done = false;
        int tdata;
        bool tlast;

        this->p_tready = 1;
        do {
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: SAXIS read request timeout\n");
                timeout_counter = 0;
            }

            if (this->p_tvalid == 1) {
                tdata = this->p_tdata;
                tlast = this->p_tlast;
                p->write(tdata, tlast);
                t_done = true;
            }

            // Tick the clock one cycle
            yield();

            if (t_done) {
                this->p_tready = 0;
            }
        } while (!t_done);

        this->unlock(yield);
        return;
    }
};

// D = axis data width
template <unsigned int D>
class maxis : public axis<D> {
  protected:
    using addr_t = typename axi_defaults<0, D>::addr_t;
    using data_t = typename axi_defaults<0, D>::data_t;
  public:
    maxis(const std::string &base) : axis<D>(base) {
      std::cout << " as a master AXIM port" << std::endl;
    }

    void axis_write_helper(data_t tdata, bool tlast, yield_t &yield) {
        this->lock(yield);
        int timeout_counter = 0;

        bool t_done = false;
        this->p_tvalid = 1;
        this->p_tdata = tdata;
        this->p_tlast = tlast;
        do {
            // check timeout
            if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                bsg_pr_err("bsg_zynq_pl: MAXIS write timeout\n");
            }

            if (this->p_tready) {
                t_done = true;
            }

            // tick the clock one cycle
            yield();

            if (t_done) {
                this->p_tvalid = 0;
            }
        } while (!t_done);

        this->unlock(yield);
        return;
    }
};

#endif
