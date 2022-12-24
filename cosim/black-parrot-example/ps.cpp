//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <pthread.h>
#include <time.h>
#include <queue>
#include <unistd.h>
#include <bitset>

#include "bp_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#define FREE_DRAM 0
#define DRAM_ALLOCATE_SIZE 120 * 1024 * 1024

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef BP_NCPUS
#define BP_NCPUS 1
#endif

// Offsets for GP0 (Check bsg_zynq_pl_shell in top_zynq)
#define GP0_CSR_RESET          0x0
#define GP0_CSR_DRAM_INITED    0x4
#define GP0_CSR_DRAM_BASE      0x8
#define GP0_PL_TO_PS_FIFO_DATA 0xC
#define GP0_PL_TO_PS_FIFO_CTRS 0x10
#define GP0_PS_TO_PL_FIFO_CTRS 0x14
#define GP0_MINSTRET           0x18 // 64-bit
#define GP0_MEM_PROFILER_0     0x20
#define GP0_MEM_PROFILER_1     0x24
#define GP0_MEM_PROFILER_2     0x28
#define GP0_MEM_PROFILER_3     0x2C

// BP Address in PS
#define BP_L2_ADDR  0x80000000U
#define BP_CSR_ADDR 0xA0000000U

void nbf_load(bp_zynq_pl *zpl, char *);
bool decode_bp_output(bp_zynq_pl *zpl, int data, int* core);

std::queue<int> getchar_queue;

void *monitor(void *vargp) {
  int c = -1;
  while(1) {
    c = getchar();
    if(c != -1)
      getchar_queue.push(c);
  }
}

inline unsigned long long get_counter_64(bp_zynq_pl *zpl, unsigned int addr) {
  unsigned long long val;
  do {
    unsigned int val_hi = zpl->axil_read(addr + 4);
    unsigned int val_lo = zpl->axil_read(addr + 0);
    unsigned int val_hi2 = zpl->axil_read(addr + 4);
    if (val_hi == val_hi2) {
      val = ((unsigned long long)val_hi) << 32;
      val += val_lo;
      return val;
    } else
      bsg_pr_err("ps.cpp: timer wrapover!\n");
  } while (1);
}

#ifndef VCS
int main(int argc, char **argv) {
#else
extern "C" void cosim_main(char *argstr) {
  int argc = get_argc(argstr);
  char *argv[argc];
  get_argv(argstr, argc, argv);
#endif
  // this ensures that even with tee, the output is line buffered
  // so that we can see what is happening in real time

  setvbuf(stdout, NULL, _IOLBF, 0);

  bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

  // the read memory map is essentially
  //
  // 0,4,8: reset, dram allocated, dram base address
  // C: pl to ps fifo
  // 10: pl to ps fifo count
  // 14: ps to pl fifo count

  // the write memory map is essentially
  //
  // 0,4,8: registers
  // 10: ps to pl fifo

  int data;
  int val1 = 0x1;
  int val2 = 0x0;
  int mask1 = 0xf;
  int mask2 = 0xf;
  std::bitset<BP_NCPUS> done_vec;
  bool core_done = false;

  int allocated_dram = DRAM_ALLOCATE_SIZE;
#ifdef FPGA
  unsigned long phys_ptr;
  volatile int *buf;
#endif

  int val;
  bsg_pr_info("ps.cpp: reading three base registers\n");
  bsg_pr_info("ps.cpp: reset(lo)=%d dram_init=%d, dram_base=%x\n",
              zpl->axil_read(GP0_CSR_RESET + GP0_ADDR_BASE),
              zpl->axil_read(GP0_CSR_DRAM_INITED + GP0_ADDR_BASE),
              val = zpl->axil_read(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE));

  bsg_pr_info("ps.cpp: putting BP into reset\n");
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x0, mask1); // BP reset

  bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

  zpl->axil_write(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE, 0xDEADBEEF, mask1);
  assert((zpl->axil_read(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE) == (0xDEADBEEF)));
  zpl->axil_write(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE, val, mask1);
  assert((zpl->axil_read(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE) == (val)));

  bsg_pr_info("ps.cpp: successfully wrote and read registers in bsg_zynq_shell "
              "(verified ARM GP0 connection)\n");
#ifdef FPGA
  data = zpl->axil_read(GP0_CSR_DRAM_INITED + GP0_ADDR_BASE);
  if (data == 0) {
    bsg_pr_info(
        "ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate "
        "dram with size %d\n",
        allocated_dram);
    buf = (volatile int *)zpl->allocate_dram(allocated_dram, &phys_ptr);
    bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
    zpl->axil_write(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE, phys_ptr, mask1);
    assert((zpl->axil_read(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE) == (phys_ptr)));
    bsg_pr_info("ps.cpp: wrote and verified base register\n");
    zpl->axil_write(GP0_CSR_DRAM_INITED + GP0_ADDR_BASE, 0x1, mask2);
    assert(zpl->axil_read(GP0_CSR_DRAM_INITED + GP0_ADDR_BASE) == 1);
  } else
    bsg_pr_info("ps.cpp: reusing dram base pointer %x\n",
                zpl->axil_read(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE));

  int outer = 1024 / 4;
#else
  zpl->axil_write(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE, val1, mask1);
  assert((zpl->axil_read(GP0_CSR_DRAM_BASE + GP0_ADDR_BASE) == (val1)));
  bsg_pr_info("ps.cpp: wrote and verified base register\n");

  int outer = 8 / 4;
#endif

  if (argc == 1) {
    bsg_pr_warn(
        "No nbf file specified, sleeping for 2^31 seconds (this will hold "
        "onto allocated DRAM)\n");
    sleep(1U << 31);
    delete zpl;
    exit(0);
  }

  bsg_pr_info("ps.cpp: asserting reset to BP\n");

  // Assert reset, we do it repeatedly just to make sure that enough cycles pass
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(GP0_CSR_RESET + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(GP0_CSR_RESET + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(GP0_CSR_RESET + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(GP0_CSR_RESET + GP0_ADDR_BASE) == (0)));

  // Deassert reset
  bsg_pr_info("ps.cpp: deasserting reset to BP\n");
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x1, mask1);
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x1, mask1);
  zpl->axil_write(GP0_CSR_RESET + GP0_ADDR_BASE, 0x1, mask1);

  bsg_pr_info("Reset asserted and deasserted\n");

  bsg_pr_info("ps.cpp: attempting to read mtime reg in BP CFG space, should "
              "increase monotonically  (testing ARM GP1 connections)\n");

  for (int q = 0; q < 10; q++) {
    int z = zpl->axil_read(BP_CSR_ADDR + 0x30bff8);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z,(q % 8) == 7 ? '\n' : ' ');
    // read second 32-bits
    int z2 = zpl->axil_read(BP_CSR_ADDR + 0x30bff8 + 4);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z2,(q % 8) == 7 ? '\n' : ' ');
  }

  bsg_pr_info("ps.cpp: attempting to read and write mtime reg in BP CFG space "
              "(testing ARM GP1 connections)\n");

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  int y = zpl->axil_read(BP_CSR_ADDR + 0x304000);

  bsg_pr_info("ps.cpp: writing mtimecmp\n");
  zpl->axil_write(BP_CSR_ADDR + 0x304000, y + 1, mask1);

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  assert(zpl->axil_read(BP_CSR_ADDR + 0x304000) == y + 1);

#ifdef DRAM_TEST

  int num_times = allocated_dram / 32768;
  bsg_pr_info(
      "ps.cpp: attempting to write L2 %d times over %d MB (testing ARM GP1 "
      "and HP0 connections)\n",
      num_times * outer, (allocated_dram) >> 20);
  zpl->axil_write(BP_L2_ADDR, 0x12345678, mask1);

  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++) {
      zpl->axil_write(BP_L2_ADDR + 32768 * t + s * 4, 0x1ADACACA + t + s,
                      mask1);
    }
  bsg_pr_info("ps.cpp: finished write L2 %d times over %d MB\n",
              num_times * outer, (allocated_dram) >> 20);

  int mismatches = 0;
  int matches = 0;

#ifdef FPGA
  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++)
      if (buf[(32768 * t + s * 4) / 4] == 0x1ADACACA + t + s)
        matches++;
      else
        mismatches++;

  bsg_pr_info("ps.cpp: DIRECT access from ARM to DDR (some L1/L2 coherence "
              "mismatches expected) %d matches, %d mismatches, %f\n",
              matches, mismatches,
              ((float)matches) / (float)(mismatches + matches));
#endif

  bsg_pr_info(
      "ps.cpp: attempting to read L2 %d times over %d MB (testing ARM GP1 "
      "and HP0 connections)\n",
      num_times * outer, (allocated_dram) >> 20);
  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++)
      if (zpl->axil_read(BP_L2_ADDR + 32768 * t + s * 4) == 0x1ADACACA + t + s)
        matches++;
      else
        mismatches++;

  bsg_pr_info("ps.cpp: READ access through BP (some L1 coherence mismatch "
              "expected): %d matches, %d mismatches, %f\n",
              matches, mismatches,
              ((float)matches) / (float)(mismatches + matches));

#endif // DRAM_TEST

  bsg_pr_info("ps.cpp: Starting scan thread\n");
  pthread_t thread_id;
  pthread_create(&thread_id, NULL, monitor, NULL);

  bsg_pr_info("ps.cpp: beginning nbf load\n");
  nbf_load(zpl, argv[1]);
  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
  unsigned long long minstrret_start =
      get_counter_64(zpl, GP0_MINSTRET + GP0_ADDR_BASE);
  unsigned long long mtime_start = get_counter_64(zpl, BP_CSR_ADDR + 0x30bff8);
  bsg_pr_dbg_ps("ps.cpp: finished nbf load\n");
  bsg_pr_info("ps.cpp: polling i/o\n");

  while (1) {
#ifndef FPGA
    zpl->peripherals_sim_poll();
#endif
#ifdef SIM_BACKPRESSURE_ENABLE
    if (!(rand() % SIM_BACKPRESSURE_CHANCE)) {
      for (int i = 0; i < SIM_BACKPRESSURE_LENGTH; i++) {
        zpl->tick();
      }
    }
#endif

    // keep reading as long as there is data
    data = zpl->axil_read(GP0_PL_TO_PS_FIFO_CTRS + GP0_ADDR_BASE);
    if (data != 0) {
      data = zpl->axil_read(GP0_PL_TO_PS_FIFO_DATA + GP0_ADDR_BASE);
      int core = 0;
      core_done = decode_bp_output(zpl, data, &core);
      if (core_done) {
        done_vec[core] = true;
      }
    }
    // break loop when all cores done
    if (done_vec.all()) {
      break;
    }
  }

  unsigned long long mtime_stop = get_counter_64(zpl, BP_CSR_ADDR + 0x30bff8);

  unsigned long long minstrret_stop = get_counter_64(zpl, GP0_MINSTRET + GP0_ADDR_BASE);
  // test delay for reading counter
  unsigned long long counter_data = get_counter_64(zpl, GP0_MINSTRET + GP0_ADDR_BASE);
  clock_gettime(CLOCK_MONOTONIC, &end);
  setlocale(LC_NUMERIC, "");
  bsg_pr_info("ps.cpp: end polling i/o\n");
  bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
              minstrret_start, minstrret_start);
  bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
              minstrret_stop, minstrret_stop);
  unsigned long long minstrret_delta = minstrret_stop - minstrret_start;
  bsg_pr_info("ps.cpp: minstret delta:                  %'16llu (%16llx)\n",
              minstrret_delta, minstrret_delta);
  bsg_pr_info("ps.cpp: MTIME start:                     %'16llu (%16llx)\n",
              mtime_start, mtime_start);
  bsg_pr_info("ps.cpp: MTIME stop:                      %'16llu (%16llx)\n",
              mtime_stop, mtime_stop);
  unsigned long long mtime_delta = mtime_stop - mtime_start;
  bsg_pr_info("ps.cpp: MTIME delta (=1/8 BP cycles):    %'16llu (%16llx)\n",
              mtime_delta, mtime_delta);
  bsg_pr_info("ps.cpp: IPC        :                     %'16f\n",
              ((double)minstrret_delta) / ((double)(mtime_delta)) / 8.0);
  bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
              counter_data, counter_data);
  unsigned long long diff_ns =
      1000LL * 1000LL * 1000LL *
          ((unsigned long long)(end.tv_sec - start.tv_sec)) +
      (end.tv_nsec - start.tv_nsec);
  bsg_pr_info("ps.cpp: wall clock time                : %'16llu (%16llx) ns\n",
              diff_ns, diff_ns);
  bsg_pr_info(
      "ps.cpp: sim/emul speed                 : %'16.2f BP cycles per minute\n",
      mtime_delta * 8 /
          ((double)(diff_ns) / (60.0 * 1000.0 * 1000.0 * 1000.0)));

  bsg_pr_info("ps.cpp: BP DRAM USAGE MASK (each bit is 8 MB): "
              "%-8.8x%-8.8x%-8.8x%-8.8x\n",
              zpl->axil_read(GP0_MEM_PROFILER_3 + GP0_ADDR_BASE),
              zpl->axil_read(GP0_MEM_PROFILER_2 + GP0_ADDR_BASE),
              zpl->axil_read(GP0_MEM_PROFILER_1 + GP0_ADDR_BASE),
              zpl->axil_read(GP0_MEM_PROFILER_0 + GP0_ADDR_BASE));
#ifdef FPGA
  // in general we do not want to free the dram; the Xilinx allocator has a
  // tendency to
  // fail after many allocate/fail cycle. instead we keep a pointer to the dram
  // in a CSR
  // in the accelerator, and if we reload the bitstream, we copy the pointer
  // back in.s

  if (FREE_DRAM) {
    bsg_pr_info("ps.cpp: freeing DRAM buffer\n");
    zpl->free_dram((void *)buf);
    zpl->axil_write(GP0_CSR_DRAM_INITED + GP0_ADDR_BASE, 0x0, mask2);
  }
#endif

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}

void nbf_load(bp_zynq_pl *zpl, char *nbf_filename) {
  string nbf_command;
  string tmp;
  string delimiter = "_";

  long long int nbf[3];
  int pos = 0;
  long unsigned int address;
  int data;
  ifstream nbf_file(nbf_filename);

  if (!nbf_file.is_open()) {
    bsg_pr_err("ps.cpp: error opening nbf file.\n");
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
    if (nbf[0] == 0x3) {
      // we map BP physical addresses for DRAM (0x8000_0000 - 0x9FFF_FFFF)
      // (256MB)
      // to the same ARM physical addresses
      // see top_fpga.v for more details

      if (nbf[1] >= BP_L2_ADDR) {
        address = nbf[1];
        address = address;
        data = nbf[2];
        nbf[2] = nbf[2] >> 32;
        zpl->axil_write(address, data, 0xf);
        address = address + 4;
        data = nbf[2];
        zpl->axil_write(address, data, 0xf);
      }
      // we map BP physical address for CSRs etc (0x0000_0000 - 0x0FFF_FFFF)
      // to ARM address to 0xA0000_0000 - 0xAFFF_FFFF  (256MB)
      else {
        address = nbf[1];
        address = address + BP_CSR_ADDR;
        data = nbf[2];
        zpl->axil_write(address, data, 0xf);
      }
    } else if (nbf[0] == 0xfe) {
      continue;
    } else if (nbf[0] == 0xff) {
      bsg_pr_dbg_ps("ps.cpp: nbf finish command, line %d\n", line_count);
      continue;
    } else {
      bsg_pr_dbg_ps("ps.cpp: unrecognized nbf command, line %d : %llx\n",
                    line_count, nbf[0]);
      return;
    }
  }
  bsg_pr_dbg_ps("ps.cpp: finished loading %d lines of nbf.\n", line_count);
}

bool decode_bp_output(bp_zynq_pl *zpl, int data, int* core) {
  int rd_wr = data >> 31;
  int address = (data >> 8) & 0x7FFFFF;
  int print_data = data & 0xFF;
  // write from BP
  if (rd_wr) {
    if (address == 0x101000) {
      printf("%c", print_data);
      fflush(stdout);
      return false;
    } else if (address >= 0x102000 && address < 0x103000) {
      *core = ((address-0x102000) >> 3);
      if (print_data == 0) {
        bsg_pr_info("CORE[%d] PASS\n", *core);
      } else {
        bsg_pr_info("CORE[%d] FAIL\n", *core);
      }
      return true;
    }

    bsg_pr_err("ps.cpp: Errant write to %x\n", address);
    return false;
  }
  // read from BP
  else {
    // getchar
    if (address == 0x100000) {
      if (getchar_queue.empty()) {
        zpl->axil_write(GP0_PL_TO_PS_FIFO_DATA + GP0_ADDR_BASE, -1, 0xf);
      } else {
        zpl->axil_write(GP0_PL_TO_PS_FIFO_DATA + GP0_ADDR_BASE, getchar_queue.front(), 0xf);
        getchar_queue.pop();
      }
    }
    // parameter ROM, only partially implemented
    else if (address >= 0x120000 && address <= 0x120128) {
      bsg_pr_dbg_ps("ps.cpp: PARAM ROM read from (%x)\n", address);
      int offset = address - 0x120000;
      // CC_X_DIM, return number of cores
      if (offset == 0x0) {
        zpl->axil_write(GP0_PL_TO_PS_FIFO_DATA + GP0_ADDR_BASE, BP_NCPUS, 0xf);
      }
      // CC_Y_DIM, just return 1 so X*Y == number of cores
      else if (offset == 0x4) {
        zpl->axil_write(GP0_PL_TO_PS_FIFO_DATA + GP0_ADDR_BASE, 1, 0xf);
      }
    }
    // if not implemented, print error
    else {
      bsg_pr_err("ps.cpp: Errant read from (%x)\n", address);
    }
    return false;
  }
}
