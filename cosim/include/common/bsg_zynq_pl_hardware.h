
#ifndef BSG_ZYNQ_PL_HARDWARE_H
#define BSG_ZYNQ_PL_HARDWARE_H

#include <assert.h>
#include <cstdint>
#include <errno.h>
#include <fcntl.h>
#include <fstream>
#include <inttypes.h>
#include <iostream>
#include <memory>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#ifdef UART_ENABLE
#define termios asmtermios
#include <asm/termios.h>
#undef termios
#undef winsize
#include <termios.h>
#endif
#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "bsg_zynq_pl_base.h"
#include "zynq_headers.h"

class bsg_zynq_pl_hardware : public bsg_zynq_pl_base {
  public:
    virtual void init(void) = 0;
    virtual void deinit(void) = 0;
    virtual void start(void) = 0;
    virtual void stop(void) = 0;
    virtual void tick(void) = 0;
    virtual int done(void) = 0;
    virtual void *allocate_dram(unsigned long len_in_bytes,
                                unsigned long *physical_ptr) = 0;
    virtual void free_dram(void *virtual_ptr) = 0;

  protected:
    uintptr_t gp0_base_offset = 0;
    uintptr_t gp1_base_offset = 0;

    inline volatile void *axil_get_ptr(uintptr_t address) {
        if (address >= gp1_addr_base)
            return (void *)(address + gp1_base_offset);
        else
            return (void *)(address + gp0_base_offset);
    }

    inline volatile int64_t *axil_get_ptr64(uintptr_t address) {
        return (int64_t *)axil_get_ptr(address);
    }

    inline volatile int32_t *axil_get_ptr32(uintptr_t address) {
        return (int32_t *)axil_get_ptr(address);
    }

    inline volatile int16_t *axil_get_ptr16(uintptr_t address) {
        return (int16_t *)axil_get_ptr(address);
    }

    inline volatile int8_t *axil_get_ptr8(uintptr_t address) {
        return (int8_t *)axil_get_ptr(address);
    }

#ifdef AXIL_ENABLE
    inline int32_t axil_read(uintptr_t address) {
        // Only aligned 32B reads are currently supported
        assert(alignof(address) >= 4);

        volatile int32_t *ptr32 = axil_get_ptr32(address);
        int32_t data = *ptr32;
        bsg_pr_dbg_pl("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n",
                      address, data);

        return data;
    }

    inline void axil_write(uintptr_t address, int32_t data, uint8_t wstrb) {
        bsg_pr_dbg_pl("  bsg_zynq_pl: AXI writing [%" PRIxPTR
                      "]=%8.8x mask %" PRIu8 "\n",
                      address, data, wstrb);

        // for now we don't support alternate write strobes
        assert(wstrb == 0XF || wstrb == 0x3 || wstrb == 0x1);

        if (wstrb == 0xF) {
            volatile int32_t *ptr32 = axil_get_ptr32(address);
            *ptr32 = data;
        } else if (wstrb == 0x3) {
            volatile int16_t *ptr16 = axil_get_ptr16(address);
            *ptr16 = data;
        } else if (wstrb == 0x1) {
            volatile int8_t *ptr8 = axil_get_ptr8(address);
            *ptr8 = data;
        } else {
            assert(false); // Illegal write strobe
        }
    }
#endif
};

#endif
