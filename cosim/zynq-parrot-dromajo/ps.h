#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <time.h>
#include <queue>
#include <unistd.h>
#include <bitset>
#include <cstdint>
#include <iostream>

#include "bp_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"
#include "dromajo_cosim.h"

#include "stdlib.h"
#include <string>

// this is needed for peeking into dromajo_cosim_state to extract PC for precisely trapping exceptions
#include "riscv_machine.h"

#ifdef FPGA
#include <fstream>
#include <thread>
#endif

#define FREE_DRAM 0
#define DRAM_ALLOCATE_SIZE 241 * 1024 * 1024


// TODO change this to stop after this many insns (by Dromajo)
#define MAX_INSNS 0x7fffffff

/*
TODO change the memory map accordingly
the read memory map:
address:         what:                 number of regs:
0                ps to pl regs         N1 (reset, dram allocated, dram base address, gate_en_li)
N1*4             pl to ps fifo heads   N2
(N1+N2)*4        pl to ps fifo counts  N2
(N1+2*N2)*4      ps to pl fifo count   N3
(N1+2*N2+N3)*4   pl to ps regs

the write memory map:
0                ps to pl regs         N1
N1*4             ps to pl fifo         N3
*/
#define AXIL_DATA_WIDTH 4 // bytes

#define PS2PL_REGS  4
#define PS2PL_FIFOS 1
#define PL2PS_REGS  1
#define PL2PS_FIFOS 17

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

// address calculation for PL registers/FIFOs
int r_ps2pl_reg, r_pl2ps, r_pl2ps_cnt, r_ps2pl_cnt, r_pl2ps_reg, w_ps2pl_reg, w_ps2pl;
long long int get_addr(int type, int index=0) {
  static bool init;
  if(!init) {
    r_ps2pl_reg = 0;
    r_pl2ps     = r_ps2pl_reg + AXIL_DATA_WIDTH * PS2PL_REGS;
    r_pl2ps_cnt = r_pl2ps + AXIL_DATA_WIDTH * PL2PS_FIFOS;
    r_ps2pl_cnt = r_pl2ps_cnt + AXIL_DATA_WIDTH * PL2PS_FIFOS;
    r_pl2ps_reg = r_ps2pl_cnt + AXIL_DATA_WIDTH * PS2PL_FIFOS;
    w_ps2pl_reg = 0;
    w_ps2pl     = w_ps2pl_reg + AXIL_DATA_WIDTH * PS2PL_REGS;
  }
  return type + AXIL_DATA_WIDTH * index + GP0_ADDR_BASE;
}

// global variables for dromajo virtual machine
dromajo_cosim_state_t* dromajo_pointer;
std::vector<bool>*     finish;
char                   init = 0; // flag for dromajo init
double                 inception = 0; // start time of dromajo
int                    dromajo_instret = 0;
// ignores the first 14 (or more) insns while dromajo executes setup code
#ifdef FPGA
int                    ignore_dromajo_setup_insns = 0; 
#else
int                    ignore_dromajo_setup_insns = 14;
#endif
int                    max_insns = MAX_INSNS;

// other global variables
std::queue<int> getchar_queue;  

// dromajo ancillary function declarations
static inline double get_current_time_in_seconds(void);
void dromajo_init(int, int, int);
bool dromajo_step(int, uint64_t, uint32_t, uint64_t, uint64_t, bool);
void dromajo_trap(int, uint64_t);

// other helper function declations
bool decode_bp_output(bp_zynq_pl *, int);
inline uint64_t get_counter_64(bp_zynq_pl *, uint64_t);
void nbf_load(bp_zynq_pl *, char *);

// dromajo ancillary function definitions
static inline double get_current_time_in_seconds(void) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  return ts.tv_sec + ts.tv_nsec * 1e-9;
}

void dromajo_init(int hartid, int ncpus, int memory_size, char *prog_str) {
  if (!hartid) {
    if (!init) {
      init = 1;
      cout << "Running with Dromajo cosimulation" << endl;
      finish = new vector<bool>(ncpus, false);

      char dromajo_str[50];
      sprintf(dromajo_str, "dromajo");
      char ncpus_str[50];
      sprintf(ncpus_str, "--ncpus=%d", ncpus);
      char memsize_str[50];
      sprintf(memsize_str, "--memory_size=%d", memory_size);
      char mmio_str[50];
      sprintf(mmio_str, "--mmio_range=0x20000:0x80000000");
      //TODO: integrate this for easy checkpointing during fuzzing!
      //char load_str[50];
      //sprintf(load_str, "--load=prog");
      char amo_str[50];
      sprintf(amo_str, "--enable_amo");
      char mulh_str[50];
      sprintf(mulh_str, "--enable_mulh");
      char trace_str[50]; // reserved for later
      sprintf(trace_str, "--trace=0");

      char* argv[] = {dromajo_str, ncpus_str, memsize_str, mmio_str, amo_str, mulh_str, prog_str};
      dromajo_pointer = dromajo_cosim_init(sizeof(argv)/sizeof(char *), argv);
    }
  }
}

bool dromajo_step(int hartid, uint64_t pc, uint32_t insn,
    uint64_t wdata, uint64_t mstatus, bool verbose) {
  if(dromajo_instret == 0) {
    inception = get_current_time_in_seconds();
    bsg_pr_dbg_ps("Inception time: %lf\n", inception);
    while(ignore_dromajo_setup_insns-- > 0) {
      int exit_code = dromajo_cosim_step(dromajo_pointer, hartid, pc, insn, wdata, mstatus, true, verbose);
      if(exit_code)
        bsg_pr_dbg_ps("Dromajo VM out-of-sync!\n\n\n");
      else {
        bsg_pr_dbg_ps("Dromajo VM henceforth in-sync\n");
        dromajo_instret++;
        return false;
      }
      dromajo_instret++;
    }
  } 
  return dromajo_cosim_step(dromajo_pointer, hartid, pc, insn, wdata, mstatus, true, verbose);
}

uint64_t dromajo_get_pc() {
  return (uint64_t)(((RISCVMachine *)dromajo_pointer)->cpu_state[0]->pc);
}

void dromajo_trap(int hartid, uint64_t cause) {
  dromajo_cosim_raise_trap(dromajo_pointer, hartid, cause, true);
}

// other helper function definitions
inline uint64_t get_counter_64(bp_zynq_pl *zpl, uint64_t addr) {
  uint64_t val;
  do {
    uint32_t val_hi = zpl->axil_read(addr + 4);
    uint32_t val_lo = zpl->axil_read(addr + 0);
    uint32_t val_hi2 = zpl->axil_read(addr + 4);
    if (val_hi == val_hi2) {
      val = ((uint64_t)val_hi) << 32;
      val += val_lo;
      return val;
    } else
      bsg_pr_err("ps.h: timer wrapover addr: %x, h0: %x, h1: %x!\n", addr, val_hi2, val_hi);
  } while (1);
}

std::uint32_t rotl(std::uint32_t v, std::int32_t shift) {
  std::int32_t s =  shift>=0? shift%32 : -((-shift)%32);
  return (v<<s) | (v>>(32-s));
}

void nbf_load(bp_zynq_pl *zpl, char *nbf_filename) {
  string nbf_command;
  string tmp;
  string delimiter = "_";

  long long int nbf[3];
  int pos = 0;
  long unsigned int base_addr;
  int data;
  ifstream nbf_file(nbf_filename);

  if (!nbf_file.is_open()) {
    bsg_pr_err("ps.h: error opening nbf file.\n");
    delete zpl;
    exit(-1);
  }

  int line_count = 0;
  while (getline(nbf_file, nbf_command)) {
    line_count++;
    int i = 0;
    while ((pos = nbf_command.find(delimiter)) != std::string::npos) {
      tmp = nbf_command.substr(0, pos);
      nbf[i] = std::stoull(tmp, nullptr, 16);
      nbf_command.erase(0, pos + 1);
      i++;
    }
    nbf[i] = std::stoull(nbf_command, nullptr, 16);

    if(nbf[0] == 0x2 && nbf[1] == 0x200008 && nbf[2] == 0) {
      printf("[INFO] Ignoring the unfreeze instruction; will be manually handled in the code.\n");
      continue;
#ifdef FPGA
    }
#else
    } else if(nbf[2] == 0)
      continue;
#endif

    if (nbf[0] == 0x3 || nbf[0] == 0x2 || nbf[0] == 0x1 || nbf[0] == 0x0) {
      // we map BP physical addresses for DRAM (0x8000_0000 - 0x9FFF_FFFF) (256MB)
      // to the same ARM physical addresses
      // see top_fpga.v for more details

      // we map BP physical address for CSRs etc (0x0000_0000 - 0x0FFF_FFFF)
      // to ARM address to 0xA0000_0000 - 0xAFFF_FFFF  (256MB)
      if (nbf[1] >= 0x80000000)
        base_addr = GP1_ADDR_BASE - 0x80000000;
      else
        base_addr = GP1_ADDR_BASE + 0x20000000;

      if (nbf[0] == 0x3) {
        zpl->axil_write(base_addr + nbf[1], nbf[2], 0xf);
        zpl->axil_write(base_addr + nbf[1] + 4, nbf[2] >> 32, 0xf);
      }
      else if (nbf[0] == 0x2) {
        zpl->axil_write(base_addr + nbf[1], nbf[2], 0xf);
      }
      else if (nbf[0] == 0x1) {
        int offset = nbf[1] % 4;
        int shift = 2 * offset;
        data = zpl->axil_read(base_addr + nbf[1] - offset);
        data = data & rotl((uint32_t)0xffff0000,shift) + nbf[2] & ((uint32_t)0x0000ffff << shift);
        zpl->axil_write(base_addr + nbf[1] - offset, data, 0xf);
      }
      else {
        int offset = nbf[1] % 4;
        int shift = 2 * offset;                                                                                                                                                                                                                                                                                                     data = zpl->axil_read(base_addr + nbf[1] - offset);
        data = data & rotl((uint32_t)0xffffff00,shift) + nbf[2] & ((uint32_t)0x000000ff << shift);
        zpl->axil_write(base_addr + nbf[1] - offset, data, 0xf);
      }
    }
    else if (nbf[0] == 0xfe) {
      continue;
    } else if (nbf[0] == 0xff) {
      bsg_pr_dbg_ps("ps.h: nbf finish command, line %d\n", line_count);
      continue;
    } else {
      bsg_pr_dbg_ps("ps.h: unrecognized nbf command, line %d : %llx\n",
                    line_count, nbf[0]);
      return;
    }
  }
  bsg_pr_dbg_ps("ps.h: finished loading %d lines of nbf.\n", line_count);
}

bool decode_bp_output(bp_zynq_pl *zpl, int data) {
  int rd_wr = data >> 31;
  uint64_t address = (data >> 8) & 0x7FFFFF;
  int print_data = data & 0xFF;
  if (rd_wr) {
    if (address == 0x101000) {
      printf("%c", print_data);
      fflush(stdout);
      return false;
    } else if (address == 0x102000) {
      if (print_data == 0)
        bsg_pr_info("\n\t\t\tPASS\n");
      else
        bsg_pr_info("\n\t\t\tFAIL\n");
      return true;
    }

    bsg_pr_err("ps.h: Errant write to %x\n", address);
    return false;
  }
  else {
    if (address == 0x100000) {
      if (getchar_queue.empty()) {
        zpl->axil_write(get_addr(w_ps2pl), -1, 0xf);
      } else {
        zpl->axil_write(get_addr(w_ps2pl), getchar_queue.front(), 0xf);
        getchar_queue.pop();
      }
    } else {
      bsg_pr_err("ps.h: Errant read from (%x)\n", address);
    }
    return false;
  }
}


