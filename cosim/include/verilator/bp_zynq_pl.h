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

#ifndef PERIOD
#define PERIOD 25000
#endif

#define TOP_MODULE Vtop

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

#define BSG_move_bit(q,x,y) ((((q) >> (x)) & 1) << y)
#define BSG_expand_byte_mask(x) ((BSG_move_bit(x,0,0) | BSG_move_bit(x,1,8) | BSG_move_bit(x,2,16) | BSG_move_bit(x,3,24))*0xFF)

#define BP_ZYNQ_PL_DEBUG 1

struct axil {
        unsigned char *aresetn;
        unsigned char *aclk;

        unsigned char *awprot;
        unsigned char *awvalid;
        unsigned char *awready;
        unsigned int  *wdata;
        unsigned char *wstrb;
        unsigned char *wvalid;
        unsigned char *wready;
        unsigned char *bresp;
        unsigned char *bvalid;
        unsigned char *bready;

        unsigned char *arprot;
        unsigned char *arvalid;
        unsigned char *arready;
        unsigned int  *rdata;
        unsigned char *rresp;
        unsigned char *rvalid;
        unsigned char *rready;
        int address_size;

  private:
        void *awaddr;
        void *araddr;

public:

  void init(int interface, TOP_MODULE *tb) {
    if (interface == 0)
      {
        address_size = sizeof(tb->s00_axi_awaddr);
        aresetn = &(tb->s00_axi_aresetn);
        aclk    = &(tb->s00_axi_aclk);
        awaddr  = (void *) &(tb->s00_axi_awaddr);
        awprot  = &(tb->s00_axi_awprot);
        awvalid = &(tb->s00_axi_awvalid);
        awready = &(tb->s00_axi_awready);
        wdata   = &(tb->s00_axi_wdata);
        wstrb   = &(tb->s00_axi_wstrb);
        wvalid  = &(tb->s00_axi_wvalid);
        wready  = &(tb->s00_axi_wready);
        bresp   = &(tb->s00_axi_bresp);
        bvalid  = &(tb->s00_axi_bvalid);
        bready  = &(tb->s00_axi_bready);
        araddr  = (void *) &(tb->s00_axi_araddr);
        arprot  = &(tb->s00_axi_arprot);
        arvalid = &(tb->s00_axi_arvalid);
        arready = &(tb->s00_axi_arready);
        rdata   = &(tb->s00_axi_rdata);
        rresp   = &(tb->s00_axi_rresp);
        rvalid  = &(tb->s00_axi_rvalid);
        rready  = &(tb->s00_axi_rready);
      }
    else if (interface == 1)
      {
#ifdef BSG_ENABLE_S01
        address_size = sizeof(tb->s01_axi_awaddr);
        aresetn = &(tb->s01_axi_aresetn);
        aclk    = &(tb->s01_axi_aclk);
        awaddr  = (void *) &(tb->s01_axi_awaddr);
        awprot  = &(tb->s01_axi_awprot);
        awvalid = &(tb->s01_axi_awvalid);
        awready = &(tb->s01_axi_awready);
        wdata   = &(tb->s01_axi_wdata);
        wstrb   = &(tb->s01_axi_wstrb);
        wvalid  = &(tb->s01_axi_wvalid);
        wready  = &(tb->s01_axi_wready);
        bresp   = &(tb->s01_axi_bresp);
        bvalid  = &(tb->s01_axi_bvalid);
        bready  = &(tb->s01_axi_bready);
        araddr  = (void *) &(tb->s01_axi_araddr);
        arprot  = &(tb->s01_axi_arprot);
        arvalid = &(tb->s01_axi_arvalid);
        arready = &(tb->s01_axi_arready);
        rdata   = &(tb->s01_axi_rdata);
        rresp   = &(tb->s01_axi_rresp);
        rvalid  = &(tb->s01_axi_rvalid);
        rready  = &(tb->s01_axi_rready);
#else
        int *space = (int *)malloc(sizeof(int)*22);
        address_size = 4;
        aresetn = (unsigned char *) &space[20];
        aclk    = (unsigned char *) &space[19];
        awaddr  = (void *)  &space[0];
        awprot  = (unsigned char *) &space[1];
        awvalid = (unsigned char *) &space[2];
        awready = (unsigned char *) &space[3];
        wdata   = (unsigned int *)  &space[4];
        wstrb   = (unsigned char *) &space[5];
        wvalid  = (unsigned char *) &space[6];
        wready  = (unsigned char *) &space[7];
        bresp   = (unsigned char *) &space[8];
        bvalid  = (unsigned char *) &space[9];
        bready  = (unsigned char *) &space[10];
        araddr  = (void *)  &space[11];
        arprot  = (unsigned char *) &space[12];
        arvalid = (unsigned char *) &space[13];
        arready = (unsigned char *) &space[14];
        rdata   = (unsigned int *)  &space[15];
        rresp   = (unsigned char *) &space[16];
        rvalid  = (unsigned char *) &space[17];
        rready  = (unsigned char *) &space[18];
#endif
        }
    else assert(0);
  }

  // we truncate this address to the verilator simulation size
  // but presumably verilator is also internally truncating the
  // address to the actual Verilog correct size. This would be the primary
  // mechanism by which the base offset of the AXI slave ports
  // is "subtracted off".
  //
  // for the more general case of lots of AXI devices and AXI switches etc
  // more explicit modeling of the AXI switch would be necessary
  //

  void set_araddr(unsigned int value)
  {
    if (address_size == 1){
      unsigned char *cp = (unsigned char *) araddr;
      *cp = (unsigned char) value & 0xff;
    } else
      if (address_size == 2){
        unsigned short *cp = (unsigned short *) araddr;
        *cp = (unsigned short) value & 0xffff;
      } else
        if (address_size == 4){
          unsigned int *cp = (unsigned int *) araddr;
          *cp = value;
        }
        else
          assert(0); // unhandled size
  }

  // we truncate this address to the verilator simulation size
  // but presumably verilator is also internally truncating the
  // address to the actual Verilog correct size. This would be the primary
  // mechanism by which the base offset of the AXI slave ports
  // is "subtracted off".

  void set_awaddr(unsigned int value)
  {
    //    printf("%x address_size=%d\n",value, address_size);
    if (address_size == 1){
      unsigned char *cp = (unsigned char *) awaddr;
      *cp = (unsigned char) value & 0xff;
    } else
      if (address_size == 2){
        unsigned short *cp = (unsigned short *) awaddr;
        *cp = (unsigned short) value & 0xffff;
      } else
        if (address_size == 4){
          unsigned int *cp = (unsigned int *) awaddr;
          *cp = value;
        }
        else
          assert(0); // unhandled size
  }

};

class bp_zynq_pl {

  int period = PERIOD; // ps
  TOP_MODULE *tb;
  struct axil axi_int[2];

  // reset is low true
  void reset(void) {
    this->tick(period);
    *(axi_int[0].aresetn) = 0;
    *(axi_int[1].aresetn) = 0;
    this->tick(period);
    *(axi_int[0].aresetn) = 1;
    *(axi_int[1].aresetn) = 1;
  }

  // structure of a verilator clock cycle
  //
  //
  //
  //   my_inputs=X, CLK = 0, eval(): this triggers negedge clock events, and also absorbs combinational inputs. the assumption
  //                                 is that the DUT has no negedge events that are connected to combinational inputs. also "primes the pump"
  //                                 for the posedge of the clock
  //  (CLK = 1) eval():  this triggers posedge clock events, and also the combinational logic that happens as a result of those flops changing
  //
  //
  // so then you might have
  //
  //  t=0  reset=1
  //  t=5  negedge_calc()  // pass negedge, absorb inputs from reset
  //  t=10 posedge_calc()  // pass posedge, generate new outputs


  void tick(int time_period) {
    Verilated::timeInc(time_period>>1);
    *(axi_int[0].aclk) = 0;
    *(axi_int[1].aclk) = 0;
    tb->eval();
    Verilated::timeInc(time_period>>1);
    *(axi_int[0].aclk) = 1;
    *(axi_int[1].aclk) = 1;
    tb->eval();
  }


 public:

  bp_zynq_pl(int argc, char *argv[]) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);

    // turn on tracing
    Verilated::traceEverOn(true);

    tb = new TOP_MODULE;
    printf("About to assign values\n");
    axi_int[0].init(0,tb);
    axi_int[1].init(1,tb);

    printf("bp_zynq_pl: Entering reset\n");
    reset();
    printf("bp_zynq_pl: Exiting reset\n");
  }

  ~bp_zynq_pl(void) {
    delete tb;
    tb = NULL;
  }

  bool done(void) {
    printf("bp_zynq: done() called, exiting\n");
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

    if (BP_ZYNQ_PL_DEBUG)
      printf("bp_zynq: AXI writing [%x] -> port %d, [%x]<-%8.8x\n", address_orig, index, address, data);

    axil_write_helper(index,address,data,wstrb);
  }

#define AXI_TIMEOUT 8000

  void axil_write_helper(int index, unsigned int address, int data, int wstrb)
  {
    int timeout_counter=0;

    assert(wstrb==0xf); // we only support full int writes right now

    *(axi_int[index].awvalid) = 1;
    *(axi_int[index].wvalid)  = 1;
    axi_int[index].set_awaddr(address);
    //*(axi_int[index].awaddr)  = address;
    *(axi_int[index].wdata)   = data;
    *(axi_int[index].wstrb)   = wstrb;

    while ((*(axi_int[index].awready) == 0) && (*(axi_int[index].wready) == 0)) {

      if (timeout_counter++ > AXI_TIMEOUT) {
        printf("bp_zynq: AXI write timeout\n");
        done();
        delete tb;
        exit(0);
        assert(0);
      }

      this->tick(period);
    }

    this->tick(period);

    // must drop valid signals
    // let's get things ready with bready at the same time
    *(axi_int[index].awvalid) = 0;
    *(axi_int[index].wvalid)  = 0;
    *(axi_int[index].bready)  = 1;

    // wait for bvalid to go high
    while (*(axi_int[index].bvalid) == 0) {
      if (timeout_counter++ > AXI_TIMEOUT) {
        printf("bp_zynq: AXI bvalid timeout\n");
        done();
        delete tb;
        exit(0);
      }

      this->tick(period);
    }

    // now, we will drop bready low with ready on the next cycle
    this->tick(period);
    *(axi_int[index].bready)  = 0;
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

    if (BP_ZYNQ_PL_DEBUG)
      printf("bp_zynq: AXI reading [%x] -> port %d, [%x]->%8.8x\n", address_orig, index, address, data);

    return data;
  }

  int axil_read_helper(int index, unsigned int address) {
    int data;
    int timeout_counter = 0;

    // assert these signals "late in the cycle"
    *(axi_int[index].arvalid) = 1;
    axi_int[index].set_araddr(address);
    //*(axi_int[index].araddr)  = address;

    // stall while ready is not asserted
    while  (*(axi_int[index].arready) == 0)
      {
        if (timeout_counter++ > AXI_TIMEOUT) {
          printf("bp_zynq: AXI read arready timeout\n");
          done();
          delete tb;
          exit(0);
        }

        this->tick(period);
      }

    // ready was asserted, transaction will be accepted!
    this->tick(period);

    // assert these signals "late in the cycle"

    // arvalid must drop the request
    *(axi_int[index].arvalid) = 0;

    // setup to receive the reply
    *(axi_int[index].rready)  = 1;

    // stall while valid is not asserted
    while(*(axi_int[index].rvalid) == 0)
      {
        if (timeout_counter++ > AXI_TIMEOUT) {
          printf("bp_zynq: AXI read rvalid timeout\n");
          done();
          delete tb;
          exit(0);
        }

        this->tick(period);
      }

    // if valid was asserted, latch the incoming data
    data = *(axi_int[index].rdata);
    this->tick(period);

    // drop the ready signal on the following cycle
    *(axi_int[index].rready)  = 0;

    return data;
  }
};
