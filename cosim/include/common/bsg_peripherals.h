
#ifndef BSG_PERIPHERALS_H
#define BSG_PERIPHERALS_H

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
