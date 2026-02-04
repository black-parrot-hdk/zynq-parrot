
#ifndef BSG_HOST
#define BSG_HOST

#include <termios.h>
#include <queue>
#include <pthread.h>

#include "bsg_zynq_pl.h"

#define TICKS_PER_UPDATE 100

typedef struct __attribute__((packed)) {
    uint8_t  data      : 8;
    uint32_t address   : 23;
    uint8_t  wr_not_rd : 1;
} bsg_spack_t;

class bsg_host {
    bsg_zynq_pl *zpl;
    uintptr_t ctr_addr;
    uintptr_t data_addr;
    struct termios init_termios, nb_termios;
    bool finished;

  public:
    // Construct a host
    bsg_host(bsg_zynq_pl *zpl, uintptr_t ctr_addr, uintptr_t data_addr) : zpl(zpl), ctr_addr(ctr_addr), data_addr(data_addr), finished(false) {
        bsg_pr_info("Creating host: %p %" PRIxPTR " %d %d\n", zpl, ctr_addr, data_addr);

        bsg_pr_info("Setting non-blocking terminal mode\n");
        tcgetattr(STDIN_FILENO, &init_termios);
        nb_termios = init_termios;
        nb_termios.c_lflag &= ~(ICANON | ECHO); // Disable canonical mode and echo
        nb_termios.c_cc[VMIN] = 0; // Minimum characters to read
        nb_termios.c_cc[VTIME] = 0; // Timeout in tenths of a second
        tcsetattr(STDIN_FILENO, TCSANOW, &nb_termios);
    }

    ~bsg_host(void) {
        bsg_pr_info("Restoring terminal settings\n");
        tcsetattr(STDIN_FILENO, TCSANOW, &init_termios);
    }

    bool get_next_packet(bsg_spack_t *packet) {
        if (zpl->shell_read(ctr_addr) != 0) {
            int32_t data = zpl->shell_read(data_addr);
            memcpy(packet, &data, sizeof(int32_t));
            return true;
        }
        return false;
    }

    bool is_finished(void) {
        return finished;
    }

    void process_spack(bsg_spack_t *packet) {

        bool is_write = packet->wr_not_rd;
        bool is_read  = !packet->wr_not_rd;

        bool getc   = packet->address >= 0x100000 && packet->address < 0x101000;
        bool putc   = packet->address >= 0x101000 && packet->address < 0x102000;
        bool fini   = packet->address >= 0x102000 && packet->address < 0x103000;
        bool putch  = packet->address >= 0x103000 && packet->address < 0x104000;
        bool sig    = packet->address >= 0x104000 && packet->address < 0x105000;
        bool putint = packet->address >= 0x105000 && packet->address < 0x106000;
        bool brom   = packet->address >= 0x110000 && packet->address < 0x120000;
        bool prom   = packet->address >= 0x120000 && packet->address < 0x130000;
        bool drom   = packet->address >= 0x130000 && packet->address < 0x141000;

        // write functions
        if (!is_write) {
        } else if (putc || putch) {
            printf("%c", packet->data);
            //fflush(stdout);
        } else if (fini) {
            if (packet->data) {
              bsg_pr_info("CORE FAIL\n");
            } else {
              bsg_pr_info("CORE PASS\n");
            }
            finished = true;
        } else if (putint) {
            printf("%x", packet->data);
        } else {
            bsg_pr_err("ps.cpp: Errant write to %lx\n", packet->address);
            finished = true;
        }

        // read functions
        if (!is_read) {
        } else if (getc) {
            int32_t c = getchar();
            zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA, c, 0xf);
        } else if (brom) {
            // bootrom only partially implemented
            bsg_pr_dbg_ps("ps.cpp: bootrom read from (%lx)\n", packet->address);
            int bootrom_addr = (packet->address >> 2) & 0xfff;
            zpl->shell_write(GP0_WR_CSR_BOOTROM_ADDR, bootrom_addr, 0xf);
            int bootrom_data = zpl->shell_read(GP0_RD_BOOTROM_DATA);
            zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA, bootrom_data, 0xf);
        } else if (prom) {
			int offset = packet->address - 0x120000;
			if (offset == 0x0) { // CC_X_DIM, return number of cores
				zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA, BP_NCPUS, 0xf);
			} else if (offset == 0x4) { // CC_Y_DIM, just return 1 so X*Y == number of cores
				zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA, 1, 0xf);
			}
        } else {
            bsg_pr_err("ps.cpp: Errant read from %lx\n", packet->address);
            finished = true;
        }
    }
};

#endif
