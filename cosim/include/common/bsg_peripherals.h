
#ifndef BSG_PERIPHERALS_H
#define BSG_PERIPHERALS_H

#include <queue>
#include <vector>

#include "bsg_axil.h"
#include "bsg_axis.h"

// Scratchpad
#define SCRATCHPAD_BASE 0x1000000
#define SCRATCHPAD_SIZE 0x0100000
class zynq_scratchpad : public s_axil_device {
    std::vector<int32_t> mem;

  public:
    zynq_scratchpad() { mem.resize(SCRATCHPAD_SIZE, 0); }

    bool is_read(uintptr_t address) override {
        return (address >= SCRATCHPAD_BASE) &&
               (address < SCRATCHPAD_BASE + SCRATCHPAD_SIZE);
    }

    bool is_write(uintptr_t address) override {
        return (address >= SCRATCHPAD_BASE) &&
               (address < SCRATCHPAD_BASE + SCRATCHPAD_SIZE);
    }

    bool can_read(uintptr_t address) override { return true; }

    bool can_write(uintptr_t address) override { return true; }

    int32_t read(uintptr_t address) override {
        uintptr_t final_addr =
            ((address - SCRATCHPAD_BASE) + SCRATCHPAD_SIZE) % SCRATCHPAD_SIZE;
        bsg_pr_dbg_pl("  bsg_zynq_pl: scratchpad read [%" PRIxPTR "] == %x\n", final_addr,
                      mem.at(final_addr));
        return mem.at(final_addr);
    }

    void write(uintptr_t address, int32_t data) override {
        uintptr_t final_addr =
            ((address - SCRATCHPAD_BASE) + SCRATCHPAD_SIZE) % SCRATCHPAD_SIZE;
        bsg_pr_dbg_pl("  bsg_zynq_pl: scratchpad write [%" PRIxPTR "] <- %x\n",
                      final_addr, data);
        mem.at(final_addr) = data;
    }
};

// UART (loosely modelled off 16550)
#define UART_BASE 0x1100000
#define UART_SIZE 0x0001000
#define UART_REG_RX_FIFO 0x000
#define UART_REG_TX_FIFO 0x004
#define UART_REG_STAT 0x008
#define UART_REG_CTRL 0x00c
class zynq_uart : public s_axil_device {
    std::queue<uint8_t> rx_fifo;
    std::queue<uint8_t> tx_fifo;

  public:
    zynq_uart() {}

    bool is_read(uintptr_t address) override {
        return (address >= UART_BASE) && (address < UART_BASE + UART_SIZE);
    }

    bool is_write(uintptr_t address) override {

        return (address >= UART_BASE) && (address < UART_BASE + UART_SIZE);
    }

    bool can_read(uintptr_t address) override { return true; }

    bool can_write(uintptr_t address) override { return true; }

    int32_t read(uintptr_t address) override {
        uintptr_t final_addr = ((address - UART_BASE) + UART_SIZE) % UART_SIZE;
        int32_t retval = 0;
        if (final_addr == UART_REG_RX_FIFO) {
            if (!rx_fifo.empty()) {
                retval = rx_fifo.front();
                rx_fifo.pop();
            }
        } else if (final_addr == UART_REG_STAT) {
            retval = ((1 & tx_fifo.empty()) << 2)     // TX empty
                     | ((1 & !rx_fifo.empty()) << 0); // RX valid
        } else {
            bsg_pr_info("  bsg_zynq_pl: errant uart read: [%" PRIxPTR "]\n", final_addr);
        }

        bsg_pr_dbg_pl("  bsg_zynq_pl: uart read [%" PRIxPTR "] == %x\n", final_addr,
                      retval);
        return retval;
    }

    void write(uintptr_t address, int32_t data) override {
        int final_addr = ((address - UART_BASE) + UART_SIZE) % UART_SIZE;
        if (final_addr == UART_REG_TX_FIFO) {
            tx_fifo.push(data);
        } else if (final_addr == UART_REG_CTRL) {
            if (data & 0b00001) { // reset TX FIFO
                while (!tx_fifo.empty()) {
                    tx_fifo.pop();
                }
            } else if (data & 0xb00010) { // reset RX FIFO
                while (!rx_fifo.empty()) {
                    rx_fifo.pop();
                }
            } else {
                bsg_pr_info("  bsg_zynq_pl: errant uart write: %x\n",
                            final_addr);
            }
        } else {
            bsg_pr_info("  bsg_zynq_pl: errant uart write: %x\n", final_addr);
        }

        bsg_pr_dbg_pl("  bsg_zynq_pl: uart write [%x] <- %x\n", final_addr,
                      data);
    }

    // USER Functions
    bool tx_helper(uint8_t c) {
        rx_fifo.push(c);
        bsg_pr_dbg_pl("  bsg_zynq_pl: uart tx %x \n", c);

        return true;
    }

    bool rx_helper(uint8_t *c) {
        if (tx_fifo.empty()) {
            return false;
        };

        *c = tx_fifo.front();
        tx_fifo.pop();
        bsg_pr_dbg_pl("  bsg_zynq_pl: uart rx %x \n", *c);

        return true;
    }
};

#define WATCHDOG_ADDRESS 0x0F00000
#define WATCHDOG_PERIOD 0x1000
class zynq_watchdog : public m_axil_device {
    int count = 0;

  public:
    bool pending_write(uintptr_t *address, int32_t *data, uint8_t *wmask) {
        // Every time we check for pending, we increment the count
        if (count++ % WATCHDOG_PERIOD == 0) {
            *address = WATCHDOG_ADDRESS;
            *data = 'W'; // For 'woof'
            *wmask = 0xf;
            bsg_pr_dbg_pl("  bsg_zynq_pl: watchdog send\n");
            return true;
        }

        return false;
    }

    bool pending_read(uintptr_t *address) { return 0; }

    void return_write() { bsg_pr_dbg_pl("  bsg_zynq_pl: watchdog return\n"); }

    void return_read(int32_t data) { /* Unimp */
    }
};

// Buffer
class zynq_buffer : public s_axis_device, m_axis_device {
    bool buffer_full = false;
    std::queue<int32_t> buffer;

  public:
    zynq_buffer() {}

    bool can_write(uint8_t last) { return !buffer_full; }

    void write(int32_t data, uint8_t last) {
        bsg_pr_dbg_pl("  bsg_zynq_pl: fifo write <- %x\n", data);
        buffer.push(data);
        if (last) {
            buffer_full = true;
        }
    }

    bool pending_write(int32_t *data, uint8_t *last) {
        if (buffer_full) {
            *data = buffer.front();
            bsg_pr_dbg_pl("  bsg_zynq_pl: fifo read -> %x\n", *data);

            buffer.pop();
            data++;

            if (buffer.empty()) {
                *last = true;
                buffer_full = false;
            }

            return true;
        }

        return false;
    }

    // USER Functions
};

// Debug
// TODO:
#define DEBUG_BASE 0x0000000
#define DEBUG_SIZE 0x0100000
// Compile with DMI DPI
class zynq_debug : public s_axil_device, m_axil_device {
  public:
    zynq_debug() {
        bsg_pr_err("Debug unit co-simulation not yet implemented!");
    }

    // S AXI
    bool is_read(uintptr_t address) override {
        return (address >= DEBUG_BASE) && (address < DEBUG_BASE + DEBUG_SIZE);
    }

    bool is_write(uintptr_t address) override {
        return (address >= DEBUG_BASE) && (address < DEBUG_BASE + DEBUG_SIZE);
    }

    bool can_read(uintptr_t address) override { return true; }

    bool can_write(uintptr_t address) override { return true; }

    int32_t read(uintptr_t address) override {
        return 0; // Unimplemented
    }

    void write(uintptr_t address, int32_t data) override {
        return; // Unimplemented
    }

    // M AXI
    bool pending_write(uintptr_t *address, int32_t *data, uint8_t *wmask) {
        return false;
    }

    bool pending_read(uintptr_t *address) { return 0; }

    void return_write() { bsg_pr_dbg_pl("  bsg_zynq_pl: debug return\n"); }

    void return_read(int32_t data) { /* Unimp */
    }

    // USER Functions
};

// PLIC
// TODO:
#define PLIC_BASE 0x0000000
#define PLIC_SIZE 0x0100000
#define PLIC_INTERRUPT_ADDRESS 0x000000
// This is a super pared down PLIC that doesn't have a sense of priorities, just
// interrupts
class zynq_plic : public s_axil_device, m_axil_device {
    bool level = false;
    bool raised = false;

  public:
    zynq_plic() { bsg_pr_err("plic co-simulation not yet implemented!"); }

    // S AXI
    bool is_read(uintptr_t address) override {
        return (address >= PLIC_BASE) && (address < PLIC_BASE + PLIC_SIZE);
    }

    bool is_write(uintptr_t address) override {
        return (address >= PLIC_BASE) && (address < PLIC_BASE + PLIC_SIZE);
    }

    bool can_read(uintptr_t address) override { return true; }

    bool can_write(uintptr_t address) override { return true; }

    int32_t read(uintptr_t address) override {
        return 0; // Unimplemented
    }

    void write(uintptr_t address, int32_t data) override {
        return; // Unimplemented
    }

    // M AXI
    bool pending_write(uintptr_t *address, int32_t *data, uint8_t *wmask) {
        if (raised) {
            *address = PLIC_INTERRUPT_ADDRESS;
            *data = 1;
            *wmask = 0xf;
            bsg_pr_dbg_pl("  bsg_zynq_pl: plic_irq send\n");

            raised = false;

            return true;
        }

        return true;
    }

    bool pending_read(uintptr_t *address) { return 0; }

    void return_write() { bsg_pr_dbg_pl("  bsg_zynq_pl: plic return\n"); }

    void return_read(int32_t data) { /* Unimp */
    }

    // USER Functions

    // Returns previous irq state
    bool set_irq(bool val) {
        bool temp = level;

        level = val;
        raised = level ^ temp;

        return temp;
    }
};

// DMA
// TODO:
#define DMA_BASE 0x0000000
#define DMA_SIZE 0x0100000
#define DMA_INTERRUPT_ADDRESS 0x000000
// Compile with DMI DPI
class zynq_dma : public s_axil_device, m_axil_device {
  public:
    zynq_dma() { bsg_pr_err("dma co-simulation not yet implemented!"); }

    // S AXI
    bool is_read(uintptr_t address) override {
        return (address >= DMA_BASE) && (address < DMA_BASE + DMA_SIZE);
    }

    bool is_write(uintptr_t address) override {
        return (address >= DMA_BASE) && (address < DMA_BASE + DMA_SIZE);
    }

    bool can_read(uintptr_t address) override { return true; }

    bool can_write(uintptr_t address) override { return true; }

    int32_t read(uintptr_t address) override {
        return 0; // Unimplemented
    }

    void write(uintptr_t address, int32_t data) override {
        return; // Unimplemented
    }

    // M AXI
    bool pending_write(uintptr_t *address, int32_t *data, uint8_t *wmask) {
        return false;
    }

    bool pending_read(uintptr_t *address) { return 0; }

    void return_write() { bsg_pr_dbg_pl("  bsg_zynq_pl: debug return\n"); }

    void return_read(int32_t data) { /* Unimp */
    }

    // USER Functions
};

#endif
