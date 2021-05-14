// This is an implementation of the standardized host bp_zynq_pl API
// that runs on the real Zynq chip.
//


#ifndef __arm__
#error this file intended only to be compiled on an ARM (Zynq) platform)
#endif

// memory management hooks (corresponds to allocate function in python)
//
// this is where all of the memory management functions are stored
// talks through /usr/lib/libcma.so

// look at this header file for cma_mmap, cma_alloc, cma_get_phy_addr, cma_free, cma_pages_available
// cma_flush_cache, cma_invalidate_cache
//
// see /usr/local/lib/python3.6/dist-packages/pynq for usage of _xlnk_reset()
//
// note: cat /proc/meminfo gives information about the CMA
//

extern "C" {
#include "/usr/include/libxlnk_cma.h"
    void _xlnk_reset();
};

#ifndef GP0_ADDR_BASE
#error GP0_ADDR_BASE must be defined
#endif

#ifndef GP0_ADDR_SIZE_BYTES
#error GP0_ADDR_SIZE_BYTES must be defined
#endif

#ifndef GP1_ADDR_BASE
#error GP1_ADDR_BASE must be defined
#endif

#ifndef GP1_ADDR_SIZE_BYTES
#error GP1_ADDR_SIZE_BYTES must be defined
#endif

#define BP_ZYNQ_PL_DEBUG 1 

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
using namespace std;

class bp_zynq_pl {
 public:
  
  bp_zynq_pl(int argc, char *argv[])
    {
      printf("// bp_zynq: be sure to run as root\n");

      // open memory device
      int fd = open("/dev/mem",O_RDWR | O_SYNC);
      assert(fd!=0);

      int *addr0 = (int *) GP0_ADDR_BASE; // e.g. 0x43c00000;
      int *addr1 = (int *) GP1_ADDR_BASE; // e.g. 0x43c00000;

      // map in first PLAXI region of physical addresses to virtual addresses
      volatile int *ptr0 = (int *) mmap(addr0,GP0_ADDR_SIZE_BYTES,PROT_READ | PROT_WRITE, MAP_SHARED, fd,(int) ptr0);
      printf("// bp_zynq: mmap returned %p errno=%x\n",ptr0,errno);
      assert(ptr0 == addr0);

      // map in second PLAXI region of physical addresses to virtual addresses
      volatile int *ptr1 = (int *) mmap(addr1,GP1_ADDR_SIZE_BYTES,PROT_READ | PROT_WRITE, MAP_SHARED, fd,(int) ptr1);
      printf("// bp_zynq: mmap returned %p errno=%x\n",ptr1,errno);
      //assert(ptr1 == addr1);

      close(fd);
    }

  ~bp_zynq_pl(void) {
  }

  // returns virtual pointer, writes physical parameter into arguments
  void *allocate_dram(uint32_t len_in_bytes, unsigned long *physical_ptr) {

    // resets all CMA buffers across system (eek!)
    _xlnk_reset();

    // for now, we do uncacheable to keep things simple, memory accesses go straight to DRAM and
    // thus would be coherent with the PL
    
    void *virtual_ptr = cma_alloc(len_in_bytes,0); // 1 = cacheable, 0 = uncacheable
    assert(virtual_ptr!=NULL);
    *physical_ptr = cma_get_phy_addr(virtual_ptr);
    printf("bp_zynq: allocate_dram() called with size %d bytes --> virtual ptr=%p, physical ptr=0x%8.8lx\n",len_in_bytes, virtual_ptr,*physical_ptr);
    return virtual_ptr;
  }

  void free_dram(void *virtual_ptr) {
    printf("bp_zynq: free_dram() called on virtual ptr=%p\n",virtual_ptr);
    cma_free(virtual_ptr);
  }
  
  bool done(void) {
    printf("bp_zynq: done() called, exiting\n");
  }

  void axil_write(unsigned int address, int data, int wstrb)
  {
    if (BP_ZYNQ_PL_DEBUG)
       printf("bp_zynq: AXI writing [%x]=%8.8x mask %x\n", address, data, wstrb);

    //assert(address >= ADDR_BASE && (address - ADDR_BASE < ADDR_SIZE_BYTES)); // "address is not in the correct range?"

    // for now we don't support alternate write strobes
    assert(wstrb == 0XF);
    volatile int *ptr = (int *) address;
    ptr[0] = data;
  }

  int axil_read(unsigned int address)
  {
    volatile int *ptr = (int *) address;
    int data = ptr[0];
    
    if (BP_ZYNQ_PL_DEBUG)    
      printf("bp_zynq: AXI reading [%x]->%8.8x\n", address, data);

    return data;
  }

void nbf_load() {
	string nbf_command;
	string tmp;
	string delimiter = "_";

	long long int nbf[3];
	int pos = 0;
	unsigned long int address;
	int data;
	int data_read;
	ifstream nbf_file("prog.nbf");

	while (getline(nbf_file, nbf_command)) {
		int i = 0;
		while ((pos = nbf_command.find(delimiter)) != std::string::npos) {
			tmp = nbf_command.substr(0, pos);
			nbf[i] = std::stoull(tmp, nullptr, 16);
			nbf_command.erase(0, pos + 1);
			i++;
		}
		nbf[i] = std::stoull(nbf_command, nullptr, 16);
		if (nbf[0] == 0x3) {
			if (nbf[1] >= 0x80000000) {
				address = nbf[1];
				address = address + 0x20000000;
				data = nbf[2];
				nbf[2] = nbf[2] >> 32;
				printf("Address: %lx, Data: %lx\n", address, data);
				axil_write(address, data, 0xf);
				data_read = axil_read(address);
				assert(data_read == data);
				address = address + 4;
				data = nbf[2];
				printf("Address: %lx, Data: %x\n", address, data);
				axil_write(address, data, 0xf);
				data_read = axil_read(address);
				assert(data_read == data);
			}
			else {
				address = nbf[1];
				address = address + 0x80000000;
				data = nbf[2];
				printf("Address: %lx, Data: %x\n", address, data);
				axil_write(address, data, 0xf);
			}
		}
		else if (nbf[0] == 0xfe) {
			continue;
		}
		else {
			return;
		}
	}
}

	bool decode_bp_output(int data) {
		int rd_wr = data >> 31;
		int address = (data >> 8) & 0x7FFFFF;
		int print_data = data & 0xFF;
		if (rd_wr) {
			if (address == 0x101000) {
				printf("%c", print_data);
				return false;
			}
			else if (address == 0x102000) {
				if (print_data == 0)
					printf("\nPASS\n");
				else
					printf("\nFAIL\n");
				return true;
			}
		}
		// TODO: Need to implement logic for bp io_read
		else return false;
	}
};
