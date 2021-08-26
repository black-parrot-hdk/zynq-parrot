// This is an implementation of the standardized host bp_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#ifndef BP_ZYNQ_PL_H
#define BP_ZYNQ_PL_H

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <fstream>
#include <iostream>
#include <svdpi.h>
#include <unistd.h>
#include "bsg_nonsynth_dpi_gpio.hpp"

// Given a string, determine the number of space-separated arguments
static
int get_argc(char * args){
        char *cur = args, prev=' ';
        int count = 1;
        while(*cur != '\0'){
                if((prev == ' ') && (prev != *cur)){
                        count ++;
                }
                prev = *cur;
                ++cur;
        }
        return count;
}

static
void get_argv(char * args, int argc, char **argv){
        int count = 0;
        char *cur = args, prev=' ';

        // First parse the path name. This is not in the argument string because
        // VCS doesn't provide it to us. Instead, we "hack" around it by reading
        // the path from 'proc/self/exe'. The maximum path-name length is 1024,
        // with an extra null character for safety
        static char path[1025] = {'\0'};

        readlink("/proc/self/exe", path, sizeof(path) - 1);
        argv[0] = path;
        count ++;

        // Then we parse the remaining arguments. Arguments are separated by N
        // >= 1 spaces. We only register an argument when the previous character
        // was a space, and the current character is not (so that multiple
        // spaces don't count as multiple arguments). We replace spaces with
        // null characters (\0) so that each argument appears to be an
        // individual string and can be used later, by argparse (and other
        // libraries)
        while(*cur != '\0'){
                if((prev == ' ') && (prev != *cur)){
                        argv[count] = cur;
                        count++;
                }
                prev = *cur;
                if(*cur == ' ')
                        *cur = '\0';
                cur++;
        }
}

extern "C" {
    void bsg_dpi_next();
}

using namespace std;
using namespace bsg_nonsynth_dpi;

#define _STRINGIFY(x) #x
#define STRINGIFY(x) _STRINGIFY(x)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 8000
#endif

#ifndef GP0_ENABLE
#define GP0_ADDR_WIDTH 0
#define GP0_DATA_WIDTH 0
#define GP0_ADDR_BASE  0
#define GP0_HIER_BASE  ""
#endif

#ifndef GP0_ADDR_WIDTH
#error GP0_ADDR_WIDTH must be defined
#endif
#ifndef GP0_ADDR_SIZE_BYTES
#define GP0_ADDR_SIZE_BYTES (1 << GP0_ADDR_WIDTH)
#endif

#ifndef GP0_ADDR_BASE
#error GP0_ADDR_BASE must be defined
#endif

#ifndef GP0_DATA_WIDTH
#error GP0_DATA_WIDTH must be defined
#endif

#ifndef GP0_HIER_BASE
#error GP0_HIER_BASE must be defined
#endif

#ifndef GP1_ENABLE
#define GP1_ADDR_WIDTH 0
#define GP1_DATA_WIDTH 0
#define GP1_ADDR_BASE  0
#define GP1_HIER_BASE  ""
#endif

#ifndef GP1_ADDR_WIDTH
#error GP1_ADDR_WIDTH must be defined
#endif
#ifndef GP1_ADDR_SIZE_BYTES
#define GP1_ADDR_SIZE_BYTES (1 << GP1_ADDR_WIDTH)
#endif

#ifndef GP1_ADDR_BASE
#error GP1_ADDR_BASE must be defined
#endif

#ifndef GP1_DATA_WIDTH
#error GP1_DATA_WIDTH must be defined
#endif

#ifndef GP1_HIER_BASE
#error GP1_HIER_BASE must be defined
#endif

// W = width of pin
template <unsigned int W>
class pin {
  dpi_gpio<W> *gpio;

  public:
    pin(const string &hierarchy) {
      gpio = new dpi_gpio<W>(hierarchy);
    }

    void operator=(const unsigned int val) {
      unsigned int bval = 0;
      for (int i = 0; i < W; i++) {
        bval = (val & (1 << i)) >> i;
        gpio->set(i, bval);
      }
    }

    operator int() const {
      unsigned int N = 0;
      for (int i = 0; i < W; i++) {
        N |= gpio->get(i) << i;
      }

      return N;
    }
};

// A = axil address width
// D = axil data width
template <unsigned int A, unsigned int D>
class axil {
  public:
        pin<1>   p_aclk;
        pin<1>   p_aresetn;

        pin<A>   p_awaddr;
        pin<3>   p_awprot;
        pin<1>   p_awvalid;
        pin<1>   p_awready;
        pin<D>   p_wdata;
        pin<D/8> p_wstrb;
        pin<1>   p_wvalid;
        pin<1>   p_wready;
        pin<2>   p_bresp;
        pin<1>   p_bvalid;
        pin<1>   p_bready;

        pin<A>   p_araddr;
        pin<3>   p_arprot;
        pin<1>   p_arvalid;
        pin<1>   p_arready;
        pin<D>   p_rdata;
        pin<2>   p_rresp;
        pin<1>   p_rvalid;
        pin<1>   p_rready;

  axil(const string &base) :
        p_aclk    (string(base) + string(".aclk_gpio")),
        p_aresetn (string(base) + string(".aresetn_gpio")),
        p_awaddr  (string(base) + string(".awaddr_gpio")),
        p_awprot  (string(base) + string(".awprot_gpio")),
        p_awvalid (string(base) + string(".awvalid_gpio")),
        p_awready (string(base) + string(".awready_gpio")),
        p_wdata   (string(base) + string(".wdata_gpio")),
        p_wstrb   (string(base) + string(".wstrb_gpio")),
        p_wvalid  (string(base) + string(".wvalid_gpio")),
        p_wready  (string(base) + string(".wready_gpio")),
        p_bresp   (string(base) + string(".bresp_gpio")),
        p_bvalid  (string(base) + string(".bvalid_gpio")),
        p_bready  (string(base) + string(".bready_gpio")),
        p_araddr  (string(base) + string(".araddr_gpio")),
        p_arprot  (string(base) + string(".arprot_gpio")),
        p_arvalid (string(base) + string(".arvalid_gpio")),
        p_arready (string(base) + string(".arready_gpio")),
        p_rdata   (string(base) + string(".rdata_gpio")),
        p_rresp   (string(base) + string(".rresp_gpio")),
        p_rvalid  (string(base) + string(".rvalid_gpio")),
        p_rready  (string(base) + string(".rready_gpio")) {
            std::cout << base << std::endl;
        }
};

class bp_zynq_pl {

    axil<GP0_ADDR_WIDTH,GP0_DATA_WIDTH> *axi_gp0;
    axil<GP1_ADDR_WIDTH,GP1_DATA_WIDTH> *axi_gp1;

    // Wait for (low true) reset to be asserted by the testbench
    template <unsigned int A, unsigned int D>
    void reset(axil<A, D> *axil) {
      printf("bp_zynq_pl: Entering reset\n");
      while (axil->p_aresetn == 1) {
        tick();
      }
      printf("bp_zynq_pl: Exiting reset\n");
    }

    // Move the simulation forward to the next DPI event
    void tick() {
       bsg_dpi_next();
    }

  public:

  bp_zynq_pl(int argc, char *argv[]) {
    tick();

#ifdef GP0_ENABLE
    axi_gp0 = new axil<GP0_ADDR_WIDTH, GP0_DATA_WIDTH>(STRINGIFY(GP0_HIER_BASE));
    reset(axi_gp0);
#endif
#ifdef GP1_ENABLE
    axi_gp1 = new axil<GP1_ADDR_WIDTH, GP1_DATA_WIDTH>(STRINGIFY(GP1_HIER_BASE));
    reset(axi_gp1);
#endif
  }

  void done(void) {
    printf("bp_zynq_pl: done() called, exiting\n");
  }

  ~bp_zynq_pl(void) {
  }

  void axil_write(unsigned int address, int data, int wstrb) {
    int address_orig = address;
    int index;

    // we subtract the bases to make it consistent with the Zynq AXI IPI implementation

    if (address >=GP0_ADDR_BASE && address <= GP0_ADDR_BASE+GP0_ADDR_SIZE_BYTES)
    {
      index = 0;
      address = address - GP0_ADDR_BASE;
    }
    else if (address >= GP1_ADDR_BASE && address <= GP1_ADDR_BASE+GP1_ADDR_SIZE_BYTES)
    {
      index = 1;
      address = address - GP1_ADDR_BASE;
    }
    else
      assert(0);

    if (ZYNQ_PL_DEBUG)
      printf("  bp_zynq_pl: AXI writing [%x] -> port %d, [%x]<-%8.8x\n", address_orig, index, address, data);

    if (index == 0) {
      axil_write_helper(axi_gp0, address, data, wstrb);
    } else if (index == 1) {
      axil_write_helper(axi_gp1, address, data, wstrb);
    }
  }

  template <typename T>
  void axil_write_helper(T *axil, unsigned int address, int data, int wstrb)
  {
    int timeout_counter=0;

    assert(wstrb==0xf); // we only support full int writes right now

    axil->p_awvalid = 1;
    axil->p_wvalid = 1;
    axil->p_awaddr = address;
    axil->p_wdata = data;
    axil->p_wstrb = wstrb;

    while (axil->p_awready == 0 && axil->p_wready == 0) {

      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        printf("bp_zynq_pl: AXI write timeout\n");
        assert(0);
      }

      tick();
    }

    tick();

    // must drop valid signals
    // let's get things ready with bready at the same time
    axil->p_awvalid = 0;
    axil->p_wvalid = 0;
    axil->p_bready = 1;

    // wait for bvalid to go high
    while (axil->p_bvalid == 0) {
      if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
        printf("bp_zynq_pl: AXI bvalid timeout\n");
        assert(0);
      }

      tick();
    }

    // now, we will drop bready low with ready on the next cycle
    tick();
    axil->p_bready  = 0;
    return;
  }


  int axil_read(unsigned int address) {
    int address_orig = address;
    int index = 0;
    int data;

    // we subtract the bases to make it consistent with the Zynq AXI IPI implementation

    if (address >=GP0_ADDR_BASE && address <= GP0_ADDR_BASE+GP0_ADDR_SIZE_BYTES)
    {
      index = 0;
      address = address - GP0_ADDR_BASE;
    }
    else if (address >= GP1_ADDR_BASE && address <= GP1_ADDR_BASE+GP1_ADDR_SIZE_BYTES)
    {
      index = 1;
      address = address - GP1_ADDR_BASE;
    }
    else
      assert(0);

    if (index == 0) {
      data = axil_read_helper(axi_gp0, address);
    } else if (index == 1) {
      data = axil_read_helper(axi_gp1, address);
    }

    if (ZYNQ_PL_DEBUG)
      printf("  bp_zynq_pl: AXI reading [%x] -> port %d, [%x]->%8.8x\n", address_orig, index, address, data);

    return data;
  }

  template <typename T>
  int axil_read_helper(T *axil, unsigned int address) {
    int data;
    int timeout_counter = 0;

    // assert these signals "late in the cycle"
    axil->p_arvalid = 1;
    axil->p_araddr = address;

    // stall while ready is not asserted
    while (axil->p_arready == 0)
      {
        if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
          printf("bp_zynq_pl: AXI read arready timeout\n");
          assert(0);
        }

        tick();
      }

    // ready was asserted, transaction will be accepted!
    tick();

    // arvalid must drop the request
    axil->p_arvalid = 0;

    // setup to receive the reply
    axil->p_rready  = 1;

    // stall while valid is not asserted
    while (axil->p_rvalid == 0)
      {
        if (timeout_counter++ > ZYNQ_AXI_TIMEOUT) {
          printf("bp_zynq_pl: AXI read rvalid timeout\n");
          assert(0);
        }

        tick();
      }

    // if valid was asserted, latch the incoming data
    data = axil->p_rdata;
    tick();

    // drop the ready signal on the following cycle
    axil->p_rready  = 0;

    return data;
  }
};

#endif

