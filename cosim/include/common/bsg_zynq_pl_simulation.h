// This is an implementation of the standardized host bsg_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BSG_ZYNQ_PL_SIMULATION_H
#define BSG_ZYNQ_PL_SIMULATION_H

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

#include <boost/coroutine2/all.hpp>

#include "bsg_argparse.h"
#include "bsg_axil.h"
#include "bsg_printing.h"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_peripherals.h"
#include "zynq_headers.h"

using namespace std;
using namespace bsg_nonsynth_dpi;
using namespace boost::coroutines2;
using namespace std::placeholders;

class bsg_zynq_pl_simulation {
    protected:

        std::unique_ptr<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> > axi_gp0;
        std::unique_ptr<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> > axi_gp1;
        std::unique_ptr<axilm<GP2_ADDR_WIDTH, GP2_DATA_WIDTH> > axi_gp2;
        std::unique_ptr<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> > axi_hp0;

        std::unique_ptr<zynq_scratchpad> scratchpad;
        std::unique_ptr<zynq_watchdog> watchdog;

        coroutine<void>::pull_type *co_next;
        coroutine<void>::pull_type *co_polls;
        coroutine<void>::pull_type *co_pollm;

        std::function<void ()> f_tick = std::bind(&bsg_zynq_pl_simulation::tick, this);
        std::function<void ()> f_next_tick = std::bind(&bsg_zynq_pl_simulation::next_tick, this);
        std::function<void ()> f_poll_tick = std::bind(&bsg_zynq_pl_simulation::poll_tick, this);

        void next(coroutine<void>::push_type &yield) {
            while (1) {
                tick();
                yield();
            }
        }

        void init() {
#ifdef SIM_BACKPRESSURE_ENABLE
            srand(SIM_BACKPRESSURE_SEED);
#endif
#ifdef SCRATCHPAD_ENABLE
            scratchpad = std::make_unique<zynq_scratchpad>();
#endif
#ifdef WATCHDOG_ENABLE
            watchdog = std::make_unique<zynq_watchdog>();
#endif
#ifdef GP0_ENABLE
            axi_gp0 = std::make_unique<axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> >(
                    STRINGIFY(GP0_HIER_BASE));
            axi_gp0->reset(f_tick);
#endif
#ifdef GP1_ENABLE
            axi_gp1 = std::make_unique<axilm<GP1_ADDR_WIDTH, GP1_DATA_WIDTH> >(
                    STRINGIFY(GP1_HIER_BASE));
            axi_gp1->reset(f_tick);
#endif
#ifdef GP2_ENABLE
            axi_gp2 = std::make_unique<axilm<GP2_ADDR_WIDTH, GP2_DATA_WIDTH> >(
                    STRINGIFY(GP2_HIER_BASE));
            axi_gp2->reset(f_tick);
            co_pollm = new coroutine<void>::pull_type{std::bind(&bsg_zynq_pl_simulation::axilm_poll, this, _1)};
            (*co_pollm)();
#endif
#ifdef HP0_ENABLE
            axi_hp0 = std::make_unique<axils<HP0_ADDR_WIDTH, HP0_DATA_WIDTH> >(
                    STRINGIFY(HP0_HIER_BASE));
            axi_hp0->reset(f_tick);
            co_polls = new coroutine<void>::pull_type{std::bind(&bsg_zynq_pl_simulation::axils_poll, this, _1)};
            (*co_polls)();
#endif
            // Start the main tick thread
            co_next = new coroutine<void>::pull_type{std::bind(&bsg_zynq_pl_simulation::next, this, _1)};
            (*co_next)();
        }

#ifdef HP0_ENABLE
        void axils_poll(coroutine<void>::push_type &yield) {
            while (1) {
#ifdef SIM_BACKPRESSURE_ENABLE
                if ((rand() % 100) < SIM_BACKPRESSURE_CHANCE) {
                    for (int i = 0; i < SIM_BACKPRESSURE_LENGTH; i++) {
                        yield();
                    }
                }
#endif
                int araddr = axi_hp0->p_araddr;
                if (!axi_hp0->p_arvalid) {
                    yield();
#ifdef SCRATCHPAD_ENABLE
                } else if (scratchpad->is_read(araddr)) {
                    axi_hp0->axil_read_helper((s_axil_device *)scratchpad.get(), f_next_tick);
#endif
                } else {
                    bsg_pr_err("  bsg_zynq_pl: Unsupported AXI device read at [%x]\n", araddr);
                }

                int awaddr = axi_hp0->p_awaddr;
                if (!axi_hp0->p_awvalid) {
                    yield();
#ifdef SCRATCHPAD_ENABLE
                } else if (scratchpad->is_write(awaddr)) {
                    axi_hp0->axil_write_helper((s_axil_device *)scratchpad.get(), f_next_tick);
#endif
                } else {
                    bsg_pr_err("  bsg_zynq_pl: Unsupported AXI device write at [%x]\n", awaddr);
                }
            }
        }
#endif

#ifdef GP2_ENABLE
        void axilm_poll(coroutine<void>::push_type &yield) {
            uintptr_t address;
            int32_t data, ret;
            uint8_t wmask;

            while (1) {
                if (0) {
#ifdef WATCHDOG_ENABLE
                } else if (watchdog->pending_write(&address, &data, &wmask)) {
                    axi_gp2->axil_write_helper(address, data, wmask, f_next_tick);
                    watchdog->return_write();
                } else if (watchdog->pending_read(&address)) {
                    ret = axi_gp2->axil_read_helper(address, f_next_tick);
                    watchdog->return_read(ret);
#endif
                } else {
                    yield();
                }
            }
        }
#endif

    public:

#ifdef AXI_ENABLE
        virtual int32_t axil_read(uintptr_t address) {
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
                bsg_pr_err("  bsg_zynq_pl: unsupported AXIL port %d\n", index);
                return -1;
            }

            if (index == 0) {
                data = axi_gp0->axil_read_helper(address, f_tick);
            } else if (index == 1) {
                data = axi_gp1->axil_read_helper(address, f_tick);
            }

            bsg_pr_dbg_pl("  bsg_zynq_pl: AXI reading [%x] -> port %d, [%x]->%8.8x\n",
                    address_orig, index, address, data);

            return data;
        }

        virtual void axil_write(uintptr_t address, int32_t data, uint8_t wstrb) {
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
                bsg_pr_err("  bsg_zynq_pl: unsupported AXIL port %d\n", index);
                return;
            }

            bsg_pr_dbg_pl("  bsg_zynq_pl: AXI writing [%x] -> port %d, [%x]<-%8.8x\n",
                    address_orig, index, address, data);

            if (index == 0) {
                axi_gp0->axil_write_helper(address, data, wstrb, f_tick);
            } else if (index == 1) {
                axi_gp1->axil_write_helper(address, data, wstrb, f_tick);
            }
        }
#endif

        virtual void tick(void) = 0;
        virtual void done(void) = 0;

        virtual void next_tick() {
            (*co_next)();
        }

        virtual void poll_tick() {
#ifdef HP0_ENABLE
            (*co_polls)();
#endif
#ifdef GP2_ENABLE
            (*co_pollm)();
#endif
            (*co_next)();
        }
};

#endif
