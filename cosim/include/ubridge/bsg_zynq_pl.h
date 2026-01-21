
#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#if !defined(__arm__) && !defined(__aarch64__)
#error this file intended only to be compiled on an ARM (Zynq) platform
#endif

// This is an implementation of the standardized host bsg_zynq_pl API
// that runs on the real Zynq chip.
//

#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "bsg_zynq_uart.h"
#include "zynq_headers.h"
#include <assert.h>
#include <cstdint>
#include <errno.h>
#include <fcntl.h>
#include <fstream>
#include <inttypes.h>
#include <iostream>
#include <map>
#include <memory>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "bsg_zynq_pl_hardware.h"

#define BOARD_ID_artya7 "arty_a7_100t"

#define __GET_BOARD_STR(x) BOARD_ID_ ## x
#define GET_BOARD_STR(x) __GET_BOARD_STR(x)

#define BOARD_STRING     GET_BOARD_STR(BOARDNAME)
#define BITSTREAM_STRING STRINGIFY(BITSTREAM_FILE)

class bsg_zynq_pl : public bsg_zynq_pl_hardware {
  private:
    int serial_port;

    void load_bitstream(const char *bitstream) {
        // Call OpenFPGALoader
        std::string cmd = "openFPGALoader -b" BOARD_STRING " --bitstream " BITSTREAM_STRING;
        std::cout << "Programming board with command: " << cmd << std::endl;
        //system(cmd.c_str());
    }

  public:
    bsg_zynq_pl(int argc, char *argv[]) {
        load_bitstream(BITSTREAM_STRING);
        init();
    }

    ~bsg_zynq_pl(void) {
        deinit();
    }

    void init(void) override {
        serial_port = open(UART_DEV_STR, O_RDWR | O_NOCTTY);

        struct termios tty;
        assert(!tcgetattr(serial_port, &tty));

        tty.c_cflag &= ~PARENB;
        tty.c_cflag &= ~CSTOPB;
        tty.c_cflag &= ~CSIZE;
        tty.c_cflag |= CS8;
        tty.c_cflag &= ~CRTSCTS;
        tty.c_cflag |= (CREAD | CLOCAL);

        tty.c_lflag &= ~(ICANON | ECHO | ECHOE | ECHONL | ISIG);

        tty.c_iflag &= ~(IXON | IXOFF | IXANY);
        tty.c_iflag &=
            ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL);

        tty.c_oflag &= ~OPOST;
        tty.c_oflag &= ~ONLCR;

        tty.c_cc[VTIME] = 0;
        tty.c_cc[VMIN] = 4;

        cfsetspeed(&tty, UART_BAUD_ENUM);

        assert(!tcsetattr(serial_port, TCSANOW, &tty));
    }

    void deinit(void) override {
        close(serial_port);
    }

    void tick(void) override { /* Does nothing on PS */ }

    void start(void) override { printf("bsg_zynq_pl: start() called\n"); }

    void stop(void) override { printf("bsg_zynq_pl: stop() called\n"); }

    int done(void) override {
        printf("bsg_zynq_pl: done() called, exiting\n");
        return (status > 0);
    }

    // returns virtual pointer, writes physical parameter into arguments
    void *allocate_dram(unsigned long len_in_bytes,
                        unsigned long *physical_ptr) override {
        // Unsupported currently
        return NULL;
    }

    void free_dram(void *virtual_ptr) override {
        // Unsupported currently
    }

    int32_t shell_read(uintptr_t addr) override { return uart_read(addr); }

    void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) override {
        uart_write(addr, data, wmask);
    }

    // Must sync to verilog
    //     typedef struct packed
    //     {
    //       logic [31:0] data;
    //       logic [29:0] addr30to2;
    //       logic        wr_not_rd;
    //       logic        port;
    //     } bsg_uart_pkt_s;

    void smoke(char data) {
	bsg_zynq_uart_pkt_t pkt, buf;
	pkt.f.data = data;
	pkt.f.addr30to2 = (0x12345678) >> 2;
	pkt.f.wr_not_rd = 1;
	pkt.f.port = 1;

	printf("============\n");
	printf("Sending......\n");
	printf("raw: %llx\n", pkt.bits);
	printf("data: %x\n", pkt.f.data);
	printf("addr: %x\n", (pkt.f.addr30to2)<<2);
	printf("wr_not_rd: %x\n", pkt.f.wr_not_rd);
	printf("port: %x\n", pkt.f.port);
	printf("============\n");
        write(serial_port, &pkt, sizeof(pkt));
	printf("Done with send\n");
        read(serial_port, &buf, sizeof(pkt));
	printf("============\n");
	printf("Receiving......\n");
	printf("raw: %llx\n", buf.bits);
	printf("data: %x\n", buf.f.data);
	printf("addr: %x\n", (buf.f.addr30to2)<<2);
	printf("wr_not_rd: %x\n", buf.f.wr_not_rd);
	printf("port: %x\n", buf.f.port);
	printf("============\n");
    }

    void uart_write(uintptr_t addr, int32_t data, uint8_t wmask) {
        int count;

        uint64_t uart_pkt = 0;
        uintptr_t word = addr >> 2;
        int rdwr = 1;
        int port = 0; // TODO: Support GP1 as well

        uart_pkt |= ((uint64_t)data & 0xffffffff) << 32;
        uart_pkt |= (word & 0x3fffffff) << 2;
        uart_pkt |= (rdwr & 0x00000001) << 1;
        uart_pkt |= (port & 0x00000001) << 0;

        count = write(serial_port, &uart_pkt, 5);
        bsg_pr_dbg_ps("uart tx write: %x bytes\n", count);
    }

    int32_t uart_read(uintptr_t addr) {
        int count;
        uint64_t uart_pkt = 0;
        uintptr_t word = addr >> 2;
        int32_t data = 0;
        int rdwr = 0;
        int port = 0; // TODO: support GP1 as well

        uart_pkt |= ((uint64_t)data & 0xffffffff) << 32;
        uart_pkt |= (word & 0x3fffffff) << 2;
        uart_pkt |= (rdwr & 0x00000001) << 1;
        uart_pkt |= (port & 0x00000001) << 0;

        count = write(serial_port, &uart_pkt, 5);
        bsg_pr_dbg_ps("uart rx write: %x bytes\n", count);

        int32_t read_buf;
        count = read(serial_port, &read_buf, 4);
        bsg_pr_dbg_ps("uart rx read: %x\n", read_buf, count);

        return read_buf;
    }
};

#endif
