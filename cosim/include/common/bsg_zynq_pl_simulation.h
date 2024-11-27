// This is an implementation of the standardized host bsg_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BSG_ZYNQ_PL_SIMULATION_H
#define BSG_ZYNQ_PL_SIMULATION_H

#include <cassert>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <svdpi.h>
#include <unistd.h>
#include <vector>

#include <boost/coroutine2/all.hpp>

#include "bsg_nonsynth_dpi_clock_gen.hpp"
#include "bsg_nonsynth_dpi_cycle_counter.hpp"
#include "bsg_nonsynth_dpi_errno.hpp"
#include "bsg_nonsynth_dpi_fifo.hpp"
#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_nonsynth_dpi_rom.hpp"

#include "bsg_argparse.h"
#include "bsg_axil.h"
#include "bsg_axis.h"

#include "bsg_peripherals.h"
#include "bsg_printing.h"
#include "zynq_headers.h"

using namespace std;
using namespace bsg_nonsynth_dpi;
using namespace boost::coroutines2;
using namespace std::placeholders;

// Copy this to C++14 so we don't have to upgrade
// https://stackoverflow.com/questions/3424962/where-is-erase-if
// for std::vector
namespace std {
template <class T, class A, class Predicate>
void erase_if(vector<T, A> &c, Predicate pred) {
    c.erase(remove_if(c.begin(), c.end(), pred), c.end());
}
} // namespace std

class bsg_zynq_pl_simulation {
  public:
    virtual void start(void) { create_peripherals(); }
    virtual void stop(void) { destroy_peripherals(); }
    virtual void tick(void) = 0;
    virtual void done(void) = 0;
    virtual void *allocate_dram(unsigned long len_in_bytes,
                                unsigned long *physical_ptr) = 0;
    virtual void free_dram(void *virtual_ptr) = 0;

  protected:
    std::unique_ptr<maxil<GP0_ADDR_WIDTH, GP0_DATA_WIDTH>> axi_gp0;
    std::unique_ptr<maxil<GP1_ADDR_WIDTH, GP1_DATA_WIDTH>> axi_gp1;
    std::unique_ptr<maxil<GP2_ADDR_WIDTH, GP2_DATA_WIDTH>> axi_gp2;
    std::unique_ptr<saxil<HP0_ADDR_WIDTH, HP0_DATA_WIDTH>> axi_hp0;
    std::unique_ptr<saxil<HP1_ADDR_WIDTH, HP1_DATA_WIDTH>> axi_hp1;
    std::unique_ptr<saxil<HP2_ADDR_WIDTH, HP2_DATA_WIDTH>> axi_hp2;
    std::unique_ptr<maxis<SP0_DATA_WIDTH>> axi_sp0;
    std::unique_ptr<maxis<SP1_DATA_WIDTH>> axi_sp1;
    std::unique_ptr<maxis<SP2_DATA_WIDTH>> axi_sp2;
    std::unique_ptr<saxis<MP0_DATA_WIDTH>> axi_mp0;
    std::unique_ptr<saxis<MP1_DATA_WIDTH>> axi_mp1;
    std::unique_ptr<saxis<MP2_DATA_WIDTH>> axi_mp2;

    std::unique_ptr<zynq_uart> uart;
    std::unique_ptr<zynq_scratchpad> scratchpad;
    std::unique_ptr<zynq_watchdog> watchdog;
    std::unique_ptr<zynq_buffer> buffer;
    std::unique_ptr<zynq_debug> debug;
    std::unique_ptr<zynq_plic> plic;
    std::unique_ptr<zynq_dma> dma;

    std::function<int32_t(uintptr_t)> shell_read_fn;
    std::function<void(uintptr_t, int32_t, uint8_t)> shell_write_fn;
    std::vector<std::unique_ptr<coro_t>> co_list;

    void init() {
#ifdef GP0_ENABLE
        axi_gp0 = std::make_unique<maxil<GP0_ADDR_WIDTH, GP0_DATA_WIDTH>>(
            STRINGIFY(GP0_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_gp0->reset(yield); }));
#endif
#ifdef GP1_ENABLE
        axi_gp1 = std::make_unique<maxil<GP1_ADDR_WIDTH, GP1_DATA_WIDTH>>(
            STRINGIFY(GP1_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_gp1->reset(yield); }));
#endif
#ifdef GP2_ENABLE
        axi_gp2 = std::make_unique<maxil<GP2_ADDR_WIDTH, GP2_DATA_WIDTH>>(
            STRINGIFY(GP2_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_gp2->reset(yield); }));
#endif
#ifdef HP0_ENABLE
// TODO: Make AXI MEM a peripheral
#ifndef AXI_MEM_ENABLE
        axi_hp0 = std::make_unique<saxil<HP0_ADDR_WIDTH, HP0_DATA_WIDTH>>(
            STRINGIFY(HP0_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_hp0->reset(yield); }));
#endif
#endif
#ifdef HP1_ENABLE
        axi_hp1 = std::make_unique<saxil<HP1_ADDR_WIDTH, HP1_DATA_WIDTH>>(
            STRINGIFY(HP1_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_hp1->reset(yield); }));
#endif
#ifdef HP2_ENABLE
        axi_hp2 = std::make_unique<saxil<HP2_ADDR_WIDTH, HP2_DATA_WIDTH>>(
            STRINGIFY(HP2_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_hp2->reset(yield); }));
#endif
#ifdef SP0_ENABLE
        axi_sp0 =
            std::make_unique<maxis<SP0_DATA_WIDTH>>(STRINGIFY(SP0_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_sp0->reset(yield); }));
#endif
#ifdef SP1_ENABLE
        axi_sp1 =
            std::make_unique<maxis<SP1_DATA_WIDTH>>(STRINGIFY(SP1_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_sp1->reset(yield); }));
#endif
#ifdef SP2_ENABLE
        axi_sp2 =
            std::make_unique<maxis<SP2_DATA_WIDTH>>(STRINGIFY(SP2_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_sp2->reset(yield); }));
#endif
#ifdef MP0_ENABLE
        axi_mp0 =
            std::make_unique<saxis<MP0_DATA_WIDTH>>(STRINGIFY(MP0_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_mp0->reset(yield); }));
#endif
#ifdef MP1_ENABLE
        axi_mp1 =
            std::make_unique<saxis<MP1_DATA_WIDTH>>(STRINGIFY(MP1_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_mp1->reset(yield); }));
#endif
#ifdef MP2_ENABLE
        axi_mp2 =
            std::make_unique<saxis<MP2_DATA_WIDTH>>(STRINGIFY(MP2_HIER_BASE));
        co_list.push_back(std::make_unique<coro_t>(
            [=](yield_t &yield) { axi_mp2->reset(yield); }));
#endif
#ifdef HOST_ZYNQ
        shell_read_fn = std::bind(&bsg_zynq_pl_simulation::shell_read_axil,
                                  this, std::placeholders::_1);
        shell_write_fn =
            std::bind(&bsg_zynq_pl_simulation::shell_write_axil, this,
                      std::placeholders::_1, std::placeholders::_2,
                      std::placeholders::_3);
#else
#error
#endif
        // Do the reset
        while (co_list.size() > 0) {
            next();
        }
    }

    void create_peripherals() {
#ifdef SCRATCHPAD_ENABLE
        scratchpad = std::make_unique<zynq_scratchpad>();
#endif
#ifdef WATCHDOG_ENABLE
        watchdog = std::make_unique<zynq_watchdog>();
#endif
#ifdef UART_ENABLE
        uart = std::make_unique<zynq_uart>();
#endif
#ifdef BUFFER_ENABLE
        buffer = std::make_unique<zynq_buffer>();
#endif
#ifdef DEBUG_ENABLE
        debug = std::make_unique<zynq_debug>();
#endif
#ifdef PLIC_ENABLE
        plic = std::make_unique<zynq_plic>();
#endif
#ifdef DMA_ENABLE
        dma = std::make_unique<zynq_dma>();
#endif
    }

    void destroy_peripherals() {
        scratchpad.reset();
        watchdog.reset();
        uart.reset();
        buffer.reset();
        debug.reset();
        plic.reset();
        dma.reset();
    }

    void next() {
        std::erase_if(co_list, [](auto &ptr) {
            (*ptr)();
            return !(*ptr);
        });

        pollm_helper();
        polls_helper();
        tick();
    }

    void polls_helper() {
        uintptr_t addr;
        int32_t data;
        uint8_t wstrb;
        uint8_t last;

        if (!axi_hp1.get() || !axi_hp1->axil_has_read(&addr)) {

        } else if (scratchpad.get() && scratchpad->is_read(addr)) {
            if (scratchpad->can_read(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_read_helper((s_axil_device *)scratchpad.get(),
                                              yield);
                }));
            }
        } else if (uart.get() && uart->is_read(addr)) {
            if (uart->can_read(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_read_helper((s_axil_device *)uart.get(),
                                              yield);
                }));
            }
        } else if (debug.get() && debug->is_read(addr)) {
            if (debug->can_read(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_read_helper((s_axil_device *)debug.get(),
                                              yield);
                }));
            }
        } else if (plic.get() && plic->is_read(addr)) {
            if (plic->can_read(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_read_helper((s_axil_device *)plic.get(),
                                              yield);
                }));
            }
        } else if (dma.get() && dma->is_read(addr)) {
            if (dma->can_read(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_read_helper((s_axil_device *)dma.get(),
                                              yield);
                }));
            }
        } else {
            bsg_pr_err("  bsg_zynq_pl: Unsupported AXI device read at [%" PRIxPTR "]\n",
                       addr);
        }

        if (!axi_hp1.get() || !axi_hp1->axil_has_write(&addr)) {

        } else if (scratchpad && scratchpad->is_write(addr)) {
            if (scratchpad->can_write(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_write_helper(
                        (s_axil_device *)scratchpad.get(), yield);
                }));
            }
        } else if (uart.get() && uart->is_write(addr)) {
            if (uart->can_write(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_write_helper((s_axil_device *)uart.get(),
                                               yield);
                }));
            }
        } else if (debug.get() && debug->is_write(addr)) {
            if (debug->can_write(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_write_helper((s_axil_device *)debug.get(),
                                               yield);
                }));
            }
        } else if (plic.get() && plic->is_write(addr)) {
            if (plic->can_write(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_write_helper((s_axil_device *)plic.get(),
                                               yield);
                }));
            }
        } else if (dma.get() && dma->is_write(addr)) {
            if (dma->can_write(addr)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_hp1->axil_write_helper((s_axil_device *)dma.get(),
                                               yield);
                }));
            }
        } else {
            bsg_pr_err("  bsg_zynq_pl: Unsupported AXI device write at [%" PRIxPTR "]\n",
                       addr);
        }

        if (!axi_mp0.get() || !axi_mp0->axis_has_write(&last)) {

        } else if (buffer.get()) {
            if (buffer->can_write(last)) {
                co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                    axi_mp0->axis_write_helper((s_axis_device *)buffer.get(),
                                               yield);
                }));
            }
        } else {
            bsg_pr_err("  bsg_zynq_pl: Unsupported AXI device write at [%" PRIxPTR "]\n",
                       addr);
        }
    }

    void pollm_helper() {
        uintptr_t addr;
        int32_t data;
        uint8_t wstrb;
        uint8_t last;
        if (!axi_gp2.get()) {
        } else if (watchdog.get() &&
                   watchdog->pending_write(&addr, &data, &wstrb)) {
            axil_write(2, addr, data, wstrb,
                       [=]() { watchdog->return_write(); });
        } else if (watchdog.get() && watchdog->pending_read(&addr)) {
            axil_read(2, addr,
                      [=](int32_t rdata) { watchdog->return_read(rdata); });
        } else if (debug.get() && debug->pending_write(&addr, &data, &wstrb)) {
            axil_write(2, addr, data, wstrb, [=]() { debug->return_write(); });
        } else if (debug.get() && debug->pending_read(&addr)) {
            axil_read(2, addr,
                      [=](int32_t rdata) { debug->return_read(rdata); });
        } else if (debug.get() && debug->pending_write(&addr, &data, &wstrb)) {
            axil_write(2, addr, data, wstrb, [=]() { debug->return_write(); });
        } else if (debug.get() && debug->pending_read(&addr)) {
            axil_read(2, addr,
                      [=](int32_t rdata) { debug->return_read(rdata); });
        }

        if (!axi_sp0.get()) {
        } else if (buffer.get() && buffer->pending_write(&data, &last)) {
            axis_write(0, data, last, [=]() {});
        }
    }

    void axil_read(int port, uintptr_t addr,
                   std::function<void(int32_t)> callback) {
        if (port == 2) {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                int32_t rdata = axi_gp2->axil_read_helper(addr, yield);
                callback(rdata);
            }));
        } else if (port == 1) {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                int32_t rdata = axi_gp1->axil_read_helper(addr, yield);
                callback(rdata);
            }));
        } else {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                int32_t rdata = axi_gp0->axil_read_helper(addr, yield);
                callback(rdata);
            }));
        }
    }

    void axil_write(int port, uintptr_t addr, int32_t data, uint8_t wstrb,
                    std::function<void()> callback) {
        if (port == 2) {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                axi_gp2->axil_write_helper(addr, data, wstrb, yield);
                callback();
            }));
        } else if (port == 1) {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                axi_gp1->axil_write_helper(addr, data, wstrb, yield);
                callback();
            }));
        } else {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                axi_gp0->axil_write_helper(addr, data, wstrb, yield);
                callback();
            }));
        }
    }

    void axis_write(int port, int32_t data, uint8_t last,
                    std::function<void()> callback) {
        if (port == 2) {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                axi_sp2->axis_write_helper(data, last, yield);
                callback();
            }));
        } else if (port == 1) {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                axi_sp1->axis_write_helper(data, last, yield);
                callback();
            }));
        } else {
            co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
                axi_sp0->axis_write_helper(data, last, yield);
                callback();
            }));
        }
    }

    // Must sync to verilog
    //     typedef struct packed
    //     {
    //       logic [31:0] data;
    //       logic [5:0]  addr7to2;
    //       logic        wr_not_rd;
    //       logic        port;
    //     } bsg_uart_pkt_s;
    void uart_write(int port, uintptr_t addr, int32_t data, uint8_t wstrb,
                    std::function<void()> callback) {
        uint64_t uart_pkt = 0;
        uintptr_t word = addr >> 2;
        int rdwr = 1;

        uart_pkt |= (data & 0xffffffff) << 8;
        uart_pkt |= (word & 0x0000003f) << 2;
        uart_pkt |= (rdwr & 0x00000001) << 1;
        uart_pkt |= (port & 0x00000001) << 0;

        co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
            for (int i = 0; i < 40; i += 8) {
                uint8_t b = (uart_pkt >> i) & 0xff;
                do {
                    yield();
                } while (!uart->tx_helper(b));
            }
            callback();
        }));
    }

    void uart_read(int port, uintptr_t addr,
                   std::function<void(int32_t)> callback) {
        uint64_t uart_pkt = 0;
        uintptr_t word = addr >> 2;
        int32_t data = 0;
        int rdwr = 0;

        uart_pkt |= (data & 0xffffffff) << 8;
        uart_pkt |= (word & 0x0000003f) << 2;
        uart_pkt |= (rdwr & 0x00000001) << 1;
        uart_pkt |= (port & 0x00000001) << 0;

        co_list.push_back(std::make_unique<coro_t>([=](yield_t &yield) {
            for (int i = 0; i < 40; i += 8) {
                uint8_t b = (uart_pkt >> i) & 0xff;
                do {
                    yield();
                } while (!uart->tx_helper(b));
            }

            int32_t data = 0;
            uint8_t d;
            for (int i = 0; i < 32; i += 8) {
                do {
                    yield();
                } while (!uart->rx_helper(&d));
                data |= (d << i);
            }
            callback(data);
        }));
    }

    int32_t shell_read_axil(uintptr_t addr) {
        int port = 0;
        bool done = false;
        int32_t rdata;
        auto f_call = [&](int32_t x) {
            rdata = x;
            done = true;
        };

        // we subtract the bases to make it consistent with the Zynq AXI IPI
        // implementation
        if (axi_gp0.get() && addr >= GP0_ADDR_BASE &&
            addr <= GP0_ADDR_BASE + GP0_ADDR_SIZE_BYTES) {
            port = 0;
            addr = addr - GP0_ADDR_BASE;
        } else if (axi_gp1.get() && addr >= GP1_ADDR_BASE &&
                   addr <= GP1_ADDR_BASE + GP1_ADDR_SIZE_BYTES) {
            port = 1;
            addr = addr - GP1_ADDR_BASE;
        } else {
            bsg_pr_err("  bsg_zynq_pl: unsupported AXIL address: [%" PRIxPTR "]\n", addr);
            return -1;
        }

        axil_read(port, addr, f_call);

        do {
            next();
        } while (!done);

        bsg_pr_dbg_pl("  bsg_zynq_pl: AXI reading port %d [%" PRIxPTR "] -> %8.8x\n",
                      port, addr, rdata);

        return rdata;
    }

    int32_t shell_read_uart(uintptr_t addr) {
        int port = 0;
        bool done = false;
        int32_t rdata;
        auto f_call = [&](int32_t x) {
            rdata = x;
            done = true;
        };

        uart_read(port, addr, f_call);
        do {
            next();
        } while (!done);

        bsg_pr_dbg_pl("  bsg_zynq_pl: UART reading port %d [%" PRIxPTR "] -> %8.8x\n",
                      port, addr, rdata);

        return rdata;
    }

    void shell_write_axil(uintptr_t addr, int32_t data, uint8_t wstrb) {
        int port = 0;
        bool done = false;
        auto f_call = [&]() { done = true; };

        // we subtract the bases to make it consistent with the Zynq AXI IPI
        // implementation
        if (axi_gp0.get() && addr >= GP0_ADDR_BASE &&
            addr <= GP0_ADDR_BASE + GP0_ADDR_SIZE_BYTES) {
            port = 0;
            addr = addr - GP0_ADDR_BASE;
        } else if (axi_gp1.get() && addr >= GP1_ADDR_BASE &&
                   addr <= GP1_ADDR_BASE + GP1_ADDR_SIZE_BYTES) {
            port = 1;
            addr = addr - GP1_ADDR_BASE;
        } else {
            bsg_pr_err("  bsg_zynq_pl: unsupported AXIL address: [%" PRIxPTR "]\n", addr);
            return;
        }

        axil_write(port, addr, data, wstrb, f_call);
        do {
            next();
        } while (!done);

        bsg_pr_dbg_pl("  bsg_zynq_pl: AXI writing port %d, [%" PRIxPTR "]<-%8.8x\n", port,
                      addr, data);

        return;
    }

    void shell_write_uart(uintptr_t addr, int32_t data, uint8_t wstrb) {
        int port = 0;
        bool done = false;
        auto f_call = [&]() { done = true; };

        uart_write(port, addr, data, wstrb, f_call);
        do {
            next();
        } while (!done);

        bsg_pr_dbg_pl("  bsg_zynq_pl: AXI writing port %d, [%" PRIxPTR "]<-%8.8x\n", port,
                      addr, data);

        return;
    }

  public:
    void shell_write(uintptr_t addr, int32_t data, uint8_t wstrb) {
        shell_write_fn(addr, data, wstrb);
    }

    int32_t shell_read(uintptr_t addr) { return shell_read_fn(addr); }

    void shell_read4(uintptr_t addr, int32_t *data0, int32_t *data1,
                     int32_t *data2, int32_t *data3) {
        *data0 = shell_read(addr + 0);
        *data1 = shell_read(addr + 4);
        *data2 = shell_read(addr + 8);
        *data3 = shell_read(addr + 12);
    }

    void shell_write4(uintptr_t addr, int32_t data0, int32_t data1,
                      int32_t data2, int32_t data3) {
        shell_write(addr + 0, data0, 0xf);
        shell_write(addr + 4, data1, 0xf);
        shell_write(addr + 8, data2, 0xf);
        shell_write(addr + 12, data3, 0xf);
    }
};

#endif
