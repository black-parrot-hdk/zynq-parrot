
#ifndef BSG_ZYNQ_PL_HARDWARE_H
#define BSG_ZYNQ_PL_HARDWARE_H

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <string>
#include <fstream>
#include <iostream>
#include <cstdint>
#include <inttypes.h>
#include <memory>
#define termios asmtermios
#include <asm/termios.h>
#undef termios
#undef winsize
#include <termios.h>
#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "zynq_headers.h"
using namespace std;

class bsg_zynq_pl_hardware {
    protected:
        bool debug = ZYNQ_PL_DEBUG;
        int serial_port;
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

    public:
        void init(void) {
            // open memory device
            int fd = open("/dev/mem", O_RDWR | O_SYNC);
            assert(fd != 0);
#ifdef GP0_ENABLE
            // map in first PLAXI region of physical addresses to virtual addresses
            volatile uintptr_t ptr0 =
                (uintptr_t)mmap((void *)gp0_addr_base, gp0_addr_size_bytes, PROT_READ | PROT_WRITE,
                        MAP_SHARED, fd, gp0_addr_base);
            assert(ptr0 == (uintptr_t)gp0_addr_base);

            printf("// bsg_zynq_pl: mmap returned %" PRIxPTR " (offset %" PRIxPTR ") errno=%x\n", ptr0,
                    gp0_base_offset, errno);
#endif

#ifdef GP1_ENABLE
            // map in second PLAXI region of physical addresses to virtual addresses
            volatile uintptr_t ptr1 =
                (uintptr_t)mmap((void *)gp1_addr_base, gp1_addr_size_bytes, PROT_READ | PROT_WRITE,
                        MAP_SHARED, fd, gp1_addr_base);
            assert(ptr1 == (uintptr_t)gp1_addr_base);

            printf("// bsg_zynq_pl: mmap returned %" PRIxPTR " (offset %" PRIxPTR ") errno=%x\n", ptr1,
                    gp1_base_offset, errno);
#endif
            close(fd);
        }

#ifdef AXI_ENABLE
        inline int32_t axil_read(uintptr_t address) {
            // Only aligned 32B reads are currently supported
            assert (alignof(address) >= 4);

            // We use unsigned here because the data is sign extended from the AXI bus
            volatile int32_t *ptr32 = axil_get_ptr32(address);
            int32_t data = *ptr32;

            if (debug)
                printf("  bsg_zynq_pl: AXI reading [%" PRIxPTR "]->%8.8x\n", address, data);

            return data;
        }

        inline void axil_write(uintptr_t address, int32_t data, uint8_t wstrb) {
            if (debug)
                printf("  bsg_zynq_pl: AXI writing [%" PRIxPTR "]=%8.8x mask %" PRIu8 "\n", address, data,
                        wstrb);

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
