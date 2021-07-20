// This is an implementation of the standardized host bp_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#include <stdio.h>
#include <string>
#include <fstream>
#include <iostream>
#include "Vtop.h"
#include "verilated.h"
using namespace std;
#include "bsg_nonsynth_dpi_clock_gen.hpp"
#include "bsg_nonsynth_dpi_gpio.hpp"
using namespace bsg_nonsynth_dpi;

#define TOP_MODULE Vtop

// TODO: Make define
#define GP0_ADDR_WIDTH 32

#define ZYNQ_PL_DEBUG 1

#ifndef GP0_ACLK_PERIOD
#define GP0_ACLK_PERIOD 1000
#endif

#ifndef GP0_ADDR_BASE
#ERROR GP0_ADDR_BASE must be defined
#endif

#ifndef GP0_ADDR_SIZE_BYTES
#ERROR GP0_ADDR_SIZE_BYTES must be defined
#endif

#ifndef GP1_ADDR_BASE
#ERROR GP1_ADDR_BASE must be defined
#endif

#ifndef GP1_ADDR_SIZE_BYTES
#ERROR GP1_ADDR_SIZE_BYTES must be defined
#endif

template <unsigned int W>
class pin {
  dpi_gpio<W> *gpio;

  public:
    pin(const string &hierarchy) {
      gpio = new dpi_gpio<W>(hierarchy);
    }

    void operator=(const unsigned int val) {
      for (int i = 0; i < W; i++) {
        gpio->set(i, (val & (1 << i)) >> i);
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

template <unsigned int A, unsigned int D>
struct axil {
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

public:

  //void init(int interface) {
  axil() :
    //int interface = 0;
    //if (interface == 0)
    //  {
        p_aclk    ("TOP.top.axi_aclk_gpio"),
        p_aresetn ("TOP.top.axi_aresetn_gpio"),
        p_awaddr  ("TOP.top.axi_awaddr_gpio"),
        p_awprot  ("TOP.top.axi_awprot_gpio"),
        p_awvalid ("TOP.top.axi_awvalid_gpio"),
        p_awready ("TOP.top.axi_awready_gpio"),
        p_wdata   ("TOP.top.axi_wdata_gpio"),
        p_wstrb   ("TOP.top.axi_wstrb_gpio"),
        p_wvalid  ("TOP.top.axi_wvalid_gpio"),
        p_wready  ("TOP.top.axi_wready_gpio"),
        p_bresp   ("TOP.top.axi_bresp_gpio"),
        p_bvalid  ("TOP.top.axi_bvalid_gpio"),
        p_bready  ("TOP.top.axi_bready_gpio"),
        p_araddr  ("TOP.top.axi_araddr_gpio"),
        p_arprot  ("TOP.top.axi_arprot_gpio"),
        p_arvalid ("TOP.top.axi_arvalid_gpio"),
        p_arready ("TOP.top.axi_arready_gpio"),
        p_rdata   ("TOP.top.axi_rdata_gpio"),
        p_rresp   ("TOP.top.axi_rresp_gpio"),
        p_rvalid  ("TOP.top.axi_rvalid_gpio"),
        p_rready  ("TOP.top.axi_rready_gpio") { }
//      }
//    else if (interface == 1)
//      {
//#ifdef BSG_ENABLE_S01
//        address_size = sizeof(tb->s01_axi_awaddr);
//        //aclk    = &(tb->s01_axi_aclk);
//        //aresetn = &(tb->s01_axi_aresetn);
//        p_awaddr  = (void *) &(tb->s01_axi_awaddr);
//        p_awprot  = &(tb->s01_axi_awprot);
//        p_awvalid = &(tb->s01_axi_awvalid);
//        p_awready = &(tb->s01_axi_awready);
//        p_wdata   = &(tb->s01_axi_wdata);
//        p_wstrb   = &(tb->s01_axi_wstrb);
//        p_wvalid  = &(tb->s01_axi_wvalid);
//        p_wready  = &(tb->s01_axi_wready);
//        p_bresp   = &(tb->s01_axi_bresp);
//        p_bvalid  = &(tb->s01_axi_bvalid);
//        p_bready  = &(tb->s01_axi_bready);
//        p_araddr  = (void *) &(tb->s01_axi_araddr);
//        p_arprot  = &(tb->s01_axi_arprot);
//        p_arvalid = &(tb->s01_axi_arvalid);
//        p_arready = &(tb->s01_axi_arready);
//        p_rdata   = &(tb->s01_axi_rdata);
//        p_rresp   = &(tb->s01_axi_rresp);
//        p_rvalid  = &(tb->s01_axi_rvalid);
//        p_rready  = &(tb->s01_axi_rready);
//#else
//        //int *space = (int *)malloc(sizeof(int)*22);
//        //address_size = 4;
//        //aclk    = (unsigned char *) &space[19];
//        //aresetn = (unsigned char *) &space[20];
//        //p_awaddr  = (void *)  &space[0];
//        //p_awprot  = (unsigned char *) &space[1];
//        //p_awvalid = (unsigned char *) &space[2];
//        //p_awready = (unsigned char *) &space[3];
//        //p_wdata   = (unsigned int *)  &space[4];
//        //p_wstrb   = (unsigned char *) &space[5];
//        //p_wvalid  = (unsigned char *) &space[6];
//        //p_wready  = (unsigned char *) &space[7];
//        //p_bresp   = (unsigned char *) &space[8];
//        //p_bvalid  = (unsigned char *) &space[9];
//        //p_bready  = (unsigned char *) &space[10];
//        //p_araddr  = (void *)  &space[11];
//        //p_arprot  = (unsigned char *) &space[12];
//        //p_arvalid = (unsigned char *) &space[13];
//        //p_arready = (unsigned char *) &space[14];
//        //p_rdata   = (unsigned int *)  &space[15];
//        //p_rresp   = (unsigned char *) &space[16];
//        //p_rvalid  = (unsigned char *) &space[17];
//        //p_rready  = (unsigned char *) &space[18];
//#endif
//        }
//    else assert(0);
//}

  // we truncate this address to the verilator simulation size
  // but presumably verilator is also internally truncating the
  // address to the actual Verilog correct size. This would be the primary
  // mechanism by which the base offset of the AXI slave ports
  // is "subtracted off".
  //
  // for the more general case of lots of AXI devices and AXI switches etc
  // more explicit modeling of the AXI switch would be necessary
  //

  //void set_araddr(unsigned int value)
  //{
  //  if (address_size == 1){
  //    unsigned char *cp = (unsigned char *) araddr;
  //    *cp = (unsigned char) value & 0xff;
  //  } else
  //    if (address_size == 2){
  //      unsigned short *cp = (unsigned short *) araddr;
  //      *cp = (unsigned short) value & 0xffff;
  //    } else
  //      if (address_size == 4){
  //        unsigned int *cp = (unsigned int *) araddr;
  //        *cp = value;
  //      }
  //      else
  //        assert(0); // unhandled size
  //}

  //// we truncate this address to the verilator simulation size
  //// but presumably verilator is also internally truncating the
  //// address to the actual Verilog correct size. This would be the primary
  //// mechanism by which the base offset of the AXI slave ports
  //// is "subtracted off".

  //void set_awaddr(unsigned int value)
  //{
  //  //    printf("%x address_size=%d\n",value, address_size);
  //  if (address_size == 1){
  //    unsigned char *cp = (unsigned char *) awaddr;
  //    *cp = (unsigned char) value & 0xff;
  //  } else
  //    if (address_size == 2){
  //      unsigned short *cp = (unsigned short *) awaddr;
  //      *cp = (unsigned short) value & 0xffff;
  //    } else
  //      if (address_size == 4){
  //        unsigned int *cp = (unsigned int *) awaddr;
  //        *cp = value;
  //      }
  //      else
  //        assert(0); // unhandled size
  //}

};

class bp_zynq_pl {

  TOP_MODULE *tb;
  struct axil<4,32> *axi_int[2];

  // Wait for (low true) reset to be asserted by the testbench
  void reset(void) { while (axi_int[0]->p_aresetn == 0); }

  // Each bsg_timekeeper::next() moves to the next clock edge
  //   so we need 2 to perform one full clock cycle.
  // If your design does not evaluate things on negedge, you could omit 
  //   the first eval, but BSG designs tend to do assertions on negedge
  //   at the least.
  void tick() {
    bsg_timekeeper::next();
    tb->eval();
    bsg_timekeeper::next();
    tb->eval();
  }

 public:
  
  bp_zynq_pl(int argc, char *argv[]) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);

    // turn on tracing
    Verilated::traceEverOn(true);

    tb = new TOP_MODULE;

    // Tick once to register clock generators
    tb->eval();

    printf("About to assign values\n");
    //axi_int[0].init(0,tb);
    axi_int[0] = new axil<4, 32>();
    printf("Init 0\n");
    //axi_int[1].init(1,tb);
    //axi_int[1] = new axil();
    printf("Init 1\n");

    printf("bp_zynq_pl: Entering reset\n");
    reset();
    printf("bp_zynq_pl: Exiting reset\n");
  }

  ~bp_zynq_pl(void) {
    delete tb;
    tb = NULL;
  }

  bool done(void) {
    printf("bp_zynq_pl: done() called, exiting\n");
    return Verilated::gotFinish();
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

    axil_write_helper(index,address,data,wstrb);
  }

#define AXI_TIMEOUT 8000

  void axil_write_helper(int index, unsigned int address, int data, int wstrb)
  {
    int timeout_counter=0;

    assert(wstrb==0xf); // we only support full int writes right now

    axi_int[index]->p_awvalid = 1;
    axi_int[index]->p_wvalid = 1;
    axi_int[index]->p_awaddr = address;
    axi_int[index]->p_wdata = data;
    axi_int[index]->p_wstrb = wstrb;

    while (axi_int[index]->p_awready == 0 && axi_int[index]->p_wready == 0) {

      if (timeout_counter++ > AXI_TIMEOUT) {
        printf("bp_zynq_pl: AXI write timeout\n");
        done();
        delete tb;
        exit(0);
        assert(0);
      }

      this->tick();
    }

    this->tick();

    // must drop valid signals
    // let's get things ready with bready at the same time
    axi_int[index]->p_awvalid = 0;
    axi_int[index]->p_wvalid = 0;
    axi_int[index]->p_bready = 1;

    // wait for bvalid to go high
    while (axi_int[index]->p_bvalid == 0) {
      if (timeout_counter++ > AXI_TIMEOUT) {
        printf("bp_zynq_pl: AXI bvalid timeout\n");
        done();
        delete tb;
        exit(0);
      }

      this->tick();
    }

    // now, we will drop bready low with ready on the next cycle
    this->tick();
    axi_int[index]->p_bready  = 0;
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

    data = axil_read_helper(index, address);

    if (ZYNQ_PL_DEBUG)
      printf("  bp_zynq_pl: AXI reading [%x] -> port %d, [%x]->%8.8x\n", address_orig, index, address, data);

    return data;
  }

  int axil_read_helper(int index, unsigned int address) {
    int data;
    int timeout_counter = 0;

    // assert these signals "late in the cycle"
    axi_int[index]->p_arvalid = 1;
    axi_int[index]->p_araddr = address;

    // stall while ready is not asserted
    while (axi_int[index]->p_arready == 0)
      {
        if (timeout_counter++ > AXI_TIMEOUT) {
          printf("bp_zynq_pl: AXI read arready timeout\n");
          done();
          delete tb;
          exit(0);
        }

        this->tick();
      }

    // ready was asserted, transaction will be accepted!
    this->tick();

    // assert these signals "late in the cycle"

    // arvalid must drop the request
    axi_int[index]->p_arvalid = 0;

    // setup to receive the reply
    axi_int[index]->p_rready  = 1;

    // stall while valid is not asserted
    while (axi_int[index]->p_rvalid == 0)
      {
        if (timeout_counter++ > AXI_TIMEOUT) {
          printf("bp_zynq_pl: AXI read rvalid timeout\n");
          done();
          delete tb;
          exit(0);
        }

        this->tick();
      }

    // if valid was asserted, latch the incoming data
    //data = *(axi_int[index].rdata);
    data = axi_int[index]->p_rdata;
    this->tick();

    // drop the ready signal on the following cycle
    axi_int[index]->p_rready  = 0;

    return data;
  }
};
