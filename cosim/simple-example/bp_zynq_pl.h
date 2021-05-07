// This is an implementation of the standardized host bp_zynq_pl API
// that can be swapped out with a separate implementation to run on the PS
//

#include <stdio.h>
#include "Vtop.h"
#include "verilated.h"

//#define NAME s00_axi
//#define CLOCK _aclk
//#define RESETN _aresetn
//#define ADDR_BASE 0x4000_0000
//#define ADDR_SIZE_BYTES 0x1000

#define TOP_MODULE Vtop

#ifndef NAME
#ERROR NAME must be defined
#endif

#ifndef CLOCK
#ERROR CLOCK must be defined
#endif

#ifndef RESETN
#ERROR RESETN must be defined
#endif

#ifndef ADDR_BASE
#ERROR ADDR_BASE must be defined
#endif

#ifndef ADDR_SIZE_BYTES
#ERROR ADDR_SIZE_BYTES must be defined
#endif


#define CONCAT(a, b) CONCAT_(a, b)
#define CONCAT_(a, b) a ## b

#define BSG_move_bit(q,x,y) ((((q) >> (x)) & 1) << y)
#define BSG_expand_byte_mask(x) ((BSG_move_bit(x,0,0) | BSG_move_bit(x,1,8) | BSG_move_bit(x,2,16) | BSG_move_bit(x,3,24))*0xFF)

class bp_zynq_pl {

  int period = 1000; // ps
  TOP_MODULE *tb;
  
  
  // reset is low true
  void reset(void) {
    this->tick(period);
    tb->CONCAT(NAME, RESETN) = 0;
    this->tick(period);
    tb->CONCAT(NAME, RESETN) = 1;
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
    tb->CONCAT(NAME, CLOCK) = 0;
    tb->eval();
    Verilated::timeInc(time_period>>1);
    tb->CONCAT(NAME, CLOCK) = 1;
    tb->eval();
    /*
    while (i_period != 1) {
      Verilated::timeInc(1);
      i_period--;
      if (i_period == (time_period/2)) {
        tb->CONCAT(NAME, CLOCK) = 0;
      }
      tb->eval();
    }
    Verilated::timeInc(1);
    tb->CONCAT(NAME, CLOCK) = 1; 
    tb->eval(); */
  }
  
  
 public:

  
  bp_zynq_pl(int argc, char *argv[]) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    
    // turn on tracing
    Verilated::traceEverOn(true);

    tb = new TOP_MODULE;

    printf("bp_zynq_pl: Entering reset\n");
    reset();
    printf("bp_zynq_pl: Exiting reset\n");
  }
  
  ~bp_zynq_pl(void) {
    delete tb;
    tb = NULL;
  }

  
  bool done(void) {
    return Verilated::gotFinish();
  }

  void axil_write(unsigned int address, int data, int wstrb)
  {
    printf("AXI writing [%x]=%8.8x mask %x\n", address, data, wstrb);
    int done = 0;

    assert(address >= ADDR_BASE && (address - ADDR_BASE < ADDR_SIZE_BYTES)); // "address is not in the correct range?"
    
    tb->CONCAT(NAME, _awvalid) = 1;
    tb->CONCAT(NAME, _wvalid)  = 1;
    tb->CONCAT(NAME, _awaddr)  = address - ADDR_BASE;
    tb->CONCAT(NAME, _wdata)   = data;
    tb->CONCAT(NAME, _wstrb)   = wstrb;

    while ((tb->CONCAT(NAME, _awready) == 0) && (tb->CONCAT(NAME, _wready) == 0)) {
      this->tick(period);
    }

    this->tick(period);

    // must drop valid signals
    // let's get things ready with bready at the same time
    tb->CONCAT(NAME, _awvalid) = 0;
    tb->CONCAT(NAME, _wvalid)  = 0;
    tb->CONCAT(NAME, _bready)  = 1;

    // wait for bvalid to go high
    while (tb->CONCAT(NAME, _bvalid) == 0) {
      this->tick(period);
    }

    // now, we will drop bready low with ready on the next cycle
    this->tick(period);
    tb->CONCAT(NAME, _bready)  = 0;
    return;
  }

  int axil_read(unsigned int address) {
    int data;

    assert(address >= ADDR_BASE && (address - ADDR_BASE < ADDR_SIZE_BYTES)); // "address is not in the correct range?"
    
    // assert these signals "late in the cycle"
    tb->CONCAT(NAME, _arvalid) = 1;
    tb->CONCAT(NAME, _araddr)  = address - ADDR_BASE;

    // stall while ready is not asserted    
    while  (tb->CONCAT(NAME, _arready) == 0)
      this->tick(period);

    // ready was asserted, transaction will be accepted!
    this->tick(period);

    // assert these signals "late in the cycle"
    
    // arvalid must drop the request
    tb->CONCAT(NAME, _arvalid) = 0;

    // setup to receive the reply
    tb->CONCAT(NAME, _rready)  = 1;
    
    // stall while valid is not asserted
    while(tb->CONCAT(NAME, _rvalid) == 0)
      this->tick(period);

    // if valid was asserted, latch the incoming data
    data = tb->CONCAT(NAME, _rdata);
    this->tick(period);

    // drop the ready signal on the following cycle
    tb->CONCAT(NAME, _rready)  = 0;

    printf("AXI reading [%x]->%8.8x\n", address, data);
    
    return data;
  }
};
