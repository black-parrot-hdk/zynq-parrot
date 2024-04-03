
#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

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

#include "bsg_zynq_pl_hardware.h"

#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "zynq_headers.h"
using namespace std;

class bsg_zynq_pl : public bsg_zynq_pl_hardware {
	public:
		bsg_zynq_pl(int argc, char *argv[]) {
			printf("// bsg_zynq_pl: be sure to run as root\n");
			init();
		}

		~bsg_zynq_pl(void) {
			deinit();
		}

		void tick(void) override {
			/* Does nothing on PS */
		}

		void done(void) override {
			printf("bsg_zynq_pl: done() called, exiting\n");
		}

		void *allocate_dram(unsigned long len_in_bytes, unsigned long *physical_ptr) override {
			bsg_pr_info("  bsg_zynq_pl: Allocated dummy DRAM\n");
			return (void *)(physical_ptr = (unsigned long *)0xdeadbeef);
		}

		void free_dram(void *virtual_ptr) override {
			printf("bsg_zynq_pl: Freeing dummy DRAM\n");
		}

		int32_t shell_read(uintptr_t addr) override {
			return uart_read(addr);
		}

		void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) override {
			uart_write(addr, data, wmask);
		}
};

#endif

