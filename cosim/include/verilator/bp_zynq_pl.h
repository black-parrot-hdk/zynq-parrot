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

#define BP_ZYNQ_PL_DEBUG 0

struct axil {
	unsigned int  *awaddr;
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
	unsigned int  *araddr;
	unsigned char *arprot;
	unsigned char *arvalid;
	unsigned char *arready;
	unsigned int  *rdata;
	unsigned char *rresp;
	unsigned char *rvalid;
	unsigned char *rready;
};

class bp_zynq_pl {

  int period = PERIOD; // ps
  TOP_MODULE *tb;
	axil axi_int[2];
  
  // reset is low true
  void reset(void) {
    this->tick(period);
    tb->s00_axi_aresetn = 0;
    tb->s01_axi_aresetn = 0;
    this->tick(period);
    tb->s00_axi_aresetn = 1;
    tb->s01_axi_aresetn = 1;
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
    tb->s00_axi_aclk = 0;
    tb->s01_axi_aclk = 0;
    tb->eval();
    Verilated::timeInc(time_period>>1);
    tb->s00_axi_aclk = 1;
    tb->s01_axi_aclk = 1;
    tb->eval();
  }

	void axi_assign() {
		axi_int[0].awaddr  = &(tb->s00_axi_awaddr);
		axi_int[0].awprot  = &(tb->s00_axi_awprot);
		axi_int[0].awvalid = &(tb->s00_axi_awvalid);
		axi_int[0].awready = &(tb->s00_axi_awready);
		axi_int[0].wdata   = &(tb->s00_axi_wdata);
		axi_int[0].wstrb   = &(tb->s00_axi_wstrb);
		axi_int[0].wvalid  = &(tb->s00_axi_wvalid);
		axi_int[0].wready  = &(tb->s00_axi_wready);
		axi_int[0].bresp   = &(tb->s00_axi_bresp);
		axi_int[0].bvalid  = &(tb->s00_axi_bvalid);
		axi_int[0].bready  = &(tb->s00_axi_bready);
		axi_int[0].araddr  = &(tb->s00_axi_araddr);
		axi_int[0].arprot  = &(tb->s00_axi_arprot);
		axi_int[0].arvalid = &(tb->s00_axi_arvalid);
		axi_int[0].arready = &(tb->s00_axi_arready);
		axi_int[0].rdata   = &(tb->s00_axi_rdata);
		axi_int[0].rresp   = &(tb->s00_axi_rresp);
		axi_int[0].rvalid  = &(tb->s00_axi_rvalid);
		axi_int[0].rready  = &(tb->s00_axi_rready);

		axi_int[1].awaddr  = &(tb->s01_axi_awaddr);
		axi_int[1].awprot  = &(tb->s01_axi_awprot);
		axi_int[1].awvalid = &(tb->s01_axi_awvalid);
		axi_int[1].awready = &(tb->s01_axi_awready);
		axi_int[1].wdata   = &(tb->s01_axi_wdata);
		axi_int[1].wstrb   = &(tb->s01_axi_wstrb);
		axi_int[1].wvalid  = &(tb->s01_axi_wvalid);
		axi_int[1].wready  = &(tb->s01_axi_wready);
		axi_int[1].bresp   = &(tb->s01_axi_bresp);
		axi_int[1].bvalid  = &(tb->s01_axi_bvalid);
		axi_int[1].bready  = &(tb->s01_axi_bready);
		axi_int[1].araddr  = &(tb->s01_axi_araddr);
		axi_int[1].arprot  = &(tb->s01_axi_arprot);
		axi_int[1].arvalid = &(tb->s01_axi_arvalid);
		axi_int[1].arready = &(tb->s01_axi_arready);
		axi_int[1].rdata   = &(tb->s01_axi_rdata);
		axi_int[1].rresp   = &(tb->s01_axi_rresp);
		axi_int[1].rvalid  = &(tb->s01_axi_rvalid);
		axi_int[1].rready  = &(tb->s01_axi_rready);
	}

 public:
  
  bp_zynq_pl(int argc, char *argv[]) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    
    // turn on tracing
    Verilated::traceEverOn(true);

    tb = new TOP_MODULE;
		printf("About to assign values\n");
		axi_assign();

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
		if (address >=0x40000000 && address <= 0x7fffffff)
			axil_write_helper(0, address, data, wstrb);
		else if (address >= 80000000 && address <= 0xbfffffff)
			axil_write_helper(1, address, data, wstrb);
		else
			assert(0);
	}

  void axil_write_helper(int index, unsigned int address, int data, int wstrb)
  {
    if (BP_ZYNQ_PL_DEBUG)
       printf("bp_zynq: AXI writing [%x]=%8.8x mask %x\n", address, data, wstrb);

    assert(wstrb==0xf); // we only support full int writes right now

		if (index == 0)
    	assert(address - GP0_ADDR_BASE < GP0_ADDR_SIZE_BYTES); // "address is not in the correct range?"
		else
			assert(address - GP1_ADDR_BASE < GP1_ADDR_SIZE_BYTES);
    
		*(axi_int[index].awvalid) = 1;
		*(axi_int[index].wvalid)  = 1;
		*(axi_int[index].awaddr)  = address;
		*(axi_int[index].wdata)   = data;
		*(axi_int[index].wstrb)   = wstrb;

    while ((*(axi_int[index].awready) == 0) && (*(axi_int[index].wready) == 0)) {
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
      this->tick(period);
    }

    // now, we will drop bready low with ready on the next cycle
    this->tick(period);
    *(axi_int[index].bready)  = 0;
    return;
  }

	int axil_read(unsigned int address) {
		if (address >=0x40000000 && address <= 0x7fffffff)
			return axil_read_helper(0, address);
		else if (address >= 80000000 && address <= 0xbfffffff)
			return axil_read_helper(1, address);
		else
			assert(0);
	}

  int axil_read_helper(int index, unsigned int address) {
    int data;

		if (index == 0)
    	assert(address - GP0_ADDR_BASE < GP0_ADDR_SIZE_BYTES); // "address is not in the correct range?"
		else
			assert(address - GP1_ADDR_BASE < GP1_ADDR_SIZE_BYTES);
    
    // assert these signals "late in the cycle"
    *(axi_int[index].arvalid) = 1;
    *(axi_int[index].araddr)  = address;

    // stall while ready is not asserted    
    while  (*(axi_int[index].arready) == 0)
      this->tick(period);

    // ready was asserted, transaction will be accepted!
    this->tick(period);

    // assert these signals "late in the cycle"
    
    // arvalid must drop the request
    *(axi_int[index].arvalid) = 0;

    // setup to receive the reply
    *(axi_int[index].rready)  = 1;
    
    // stall while valid is not asserted
    while(*(axi_int[index].rvalid) == 0)
      this->tick(period);

    // if valid was asserted, latch the incoming data
    data = *(axi_int[index].rdata);
    this->tick(period);

    // drop the ready signal on the following cycle
    *(axi_int[index].rready)  = 0;

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
		long unsigned int address;
		int data;
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
					axil_write(address, data, 0xf);
					address = address + 4;
					data = nbf[2];
					axil_write(address, data, 0xf);
				}
				else {
					address = nbf[1];
					address = address + 0x80000000;
					data = nbf[2];
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
