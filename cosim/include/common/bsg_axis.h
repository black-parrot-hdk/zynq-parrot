#ifndef BSG_AXIS_H
#define BSG_AXIS_H

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
#include "bsg_pin.h"

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

class s_axis_device {
    public:
        virtual bool is_read(uintptr_t address) = 0;
        virtual int32_t read(uintptr_t address) = 0;

        virtual bool is_write(uintptr_t address) = 0;
        virtual void write(uintptr_t address, int32_t data) = 0;
};

class m_axis_device {
    public:
        virtual bool pending_read(uintptr_t *address) = 0;
        virtual void return_read(int32_t data) = 0;

        virtual bool pending_write(uintptr_t *address, int32_t *data,
                uint8_t *wmask) = 0;
        virtual void return_write() = 0;
};

// D = axis data width
template <unsigned int D>
class saxis {
    private:
        pin<1> p_aclk;
        pin<1> p_aresetn;

        pin<1> p_tready;
        pin<1> p_tvalid;
        pin<D> p_tdata;
        pin<D / 8> p_tkeep;
        pin<1> p_tlast;

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
        saxis(const string &base)
            : p_aclk(string(base) + string(".aclk_gpio")),
            p_aresetn(string(base) + string(".aresetn_gpio")),
            p_tready(string(base) + string(".tready_gpio")),
            p_tvalid(string(base) + string(".tvalid_gpio")),
            p_tdata(string(base) + string(".tdata_gpio")),
            p_tkeep(string(base) + string(".tkeep_gpio")),
            p_tlast(string(base) + string(".tlast_gpio")) {
                std::cout << "Instantiating SAXIS at " << base << std::endl;
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

        bool axis_has_write() {
            bool tv = this->p_tvalid;
            return tv && !mutex;
        }

        void axis_write_helper(s_axis_device *p, yield_t &yield) {
            lock(yield);
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
                }

                if (tlast) {
                    t_done = true;
                }

                yield();
            } while (!t_done);

            unlock(yield);
            return;
        }
};

// D = axis data width
template <unsigned int D>
class maxis {
    private:
        pin<1> p_aclk;
        pin<1> p_aresetn;

        pin<1> p_tready;
        pin<1> p_tvalid;
        pin<D> p_tdata;
        pin<D / 8> p_tkeep;
        pin<1> p_tlast;

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
        maxis(const string &base)
            : p_aclk(string(base) + string(".aclk_gpio")),
            p_aresetn(string(base) + string(".aresetn_gpio")),
            p_tready(string(base) + string(".tready_gpio")),
            p_tvalid(string(base) + string(".tvalid_gpio")),
            p_tdata(string(base) + string(".tdata_gpio")),
            p_tkeep(string(base) + string(".tkeep_gpio")),
            p_tlast(string(base) + string(".tlast_gpio")) {
                std::cout << "Instantiating MAXIS at " << base << std::endl;
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

        void axis_write_helper(int32_t *tdata, int32_t length, yield_t &yield) {
            lock(yield);
            int timeout_counter = 0;
            int count = 0;

            bool t_done = false;
            this->p_tkeep = 0xf; // Do not support tkeep for now
            do {
                // check timeout
                if (timeout_counter++ == ZYNQ_AXI_TIMEOUT) {
                    bsg_pr_err("bsg_zynq_pl: MAXIS write timeout\n");
                }

                this->p_tvalid = 1;
                this->p_tdata = tdata[count];
                this->p_tlast = (count == length-1);
                if (this->p_tready) {
                    if (count++ == length) {
                        t_done = true;
                    }
                }

                // tick the clock one cycle
                yield();
            } while (!t_done);

            unlock(yield);
            return;
        }
};

#endif

