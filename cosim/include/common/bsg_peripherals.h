
#ifndef BSG_PERIPHERALS_H
#define BSG_PERIPHERALS_H

#include <vector>
#include <queue>

// Scratchpad
#define SCRATCHPAD_BASE 0x1000000
#define SCRATCHPAD_SIZE 0x100000
class zynq_scratchpad : public s_axil_device {
  std::vector<int32_t> mem;

public:
  zynq_scratchpad() {
    mem.resize(SCRATCHPAD_SIZE, 0);
  }

  bool is_read(uintptr_t address) override {
    return (address >= SCRATCHPAD_BASE) && (address < SCRATCHPAD_BASE+SCRATCHPAD_SIZE);
  }

  bool is_write(uintptr_t address) override {
    return (address >= SCRATCHPAD_BASE) && (address < SCRATCHPAD_BASE+SCRATCHPAD_SIZE);
  }

  int32_t read(uintptr_t address) override {
    uintptr_t final_addr = ((address-SCRATCHPAD_BASE) + SCRATCHPAD_SIZE) % SCRATCHPAD_SIZE;
    bsg_pr_dbg_pl("  bsg_zynq_pl: scratchpad read [%x] == %x\n", final_addr, mem.at(final_addr));
    return mem.at(final_addr);
  }

  void write(uintptr_t address, int32_t data) override {
    int final_addr = ((address-SCRATCHPAD_BASE) + SCRATCHPAD_SIZE) % SCRATCHPAD_SIZE;
    bsg_pr_dbg_pl("  bsg_zynq_pl: scratchpad write [%x] <- %x\n", final_addr, data);
    mem.at(final_addr) = data;
  }
};

// UART (loosely modelled off 16550)
#define UART_BASE 0x1100000
#define UART_SIZE 0x1000
#define UART_REG_RX_FIFO 0x000
#define UART_REG_TX_FIFO 0x004
#define UART_REG_STAT    0x008
#define UART_REG_CTRL    0x00c
class zynq_uart : public s_axil_device {
  std::queue<uint8_t> rx_fifo;
  std::queue<uint8_t> tx_fifo;

public:
  zynq_uart() { }

  bool is_read(uintptr_t address) override {
    return (address >= UART_BASE) && (address < UART_BASE+UART_SIZE);
  }

  bool is_write(uintptr_t address) override {
    return (address >= UART_BASE) && (address < UART_BASE+UART_SIZE);
  }

  int32_t read(uintptr_t address) override {
    uintptr_t final_addr = ((address-UART_BASE) + UART_SIZE) % UART_SIZE;
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
      bsg_pr_info("  bsg_zynq_pl: errant uart read: %x\n", final_addr);
    }

    bsg_pr_dbg_pl("  bsg_zynq_pl: uart read [%x] == %x\n", final_addr, retval);
    return retval;
  }

  void write(uintptr_t address, int32_t data) override {
    int final_addr = ((address-UART_BASE) + UART_SIZE) % UART_SIZE;
    if (final_addr == UART_REG_TX_FIFO) {
      tx_fifo.push(data);
    } else if (final_addr == UART_REG_CTRL) {
      if (data & 0b00001) { // reset TX FIFO
        while (!tx_fifo.empty()) { tx_fifo.pop(); }
      } else if (data & 0xb00010) { // reset RX FIFO
        while (!rx_fifo.empty()) { rx_fifo.pop(); }
      } else {
        bsg_pr_info("  bsg_zynq_pl: errant uart write: %x\n", final_addr);
      }
    } else {
      bsg_pr_info("  bsg_zynq_pl: errant uart write: %x\n", final_addr);
    }

    bsg_pr_dbg_pl("  bsg_zynq_pl: uart write [%x] <- %x\n", final_addr, data);
  }

  // USER Functions
  void tx_helper(uint8_t c, std::function<void ()> tick) {
    bsg_pr_dbg_pl("  bsg_zynq_pl: uart tx %x \n", c);
    rx_fifo.push(c);
    tick();
  }

  uint8_t rx_helper(std::function<void ()> tick) {
    while (tx_fifo.empty()) { tick(); }

    uint8_t c = tx_fifo.front();
    tx_fifo.pop();
    bsg_pr_dbg_pl("  bsg_zynq_pl: uart rx %x \n", c);

    return c;
  }
};

#define WATCHDOG_ADDRESS 0x103000
#define WATCHDOG_PERIOD  0x1000
class zynq_watchdog : public m_axil_device {
  int count = 0;
public:
  bool pending_write(uintptr_t *address, int32_t *data, uint8_t *wmask) {
    // Every time we check for pending, we increment the count
    count++;
    if (count % WATCHDOG_PERIOD == 0) {
        *address = WATCHDOG_ADDRESS;
        *data = 'W'; // For 'woof'
        *wmask = 0xf;
        bsg_pr_dbg_pl("  bsg_zynq_pl: watchdog send\n");
        return true;
    }

    return false;
  }

  bool pending_read(uintptr_t *address) {
    return 0;
  }

  void return_write() {
    bsg_pr_dbg_pl("  bsg_zynq_pl: watchdog return\n");
  }

  void return_read(int32_t data) {
    /* Unimp */
  }
};

#endif
