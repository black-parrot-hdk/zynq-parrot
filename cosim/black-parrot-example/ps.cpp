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
#include <cstdint>
#include <iostream>
#ifdef FPGA
#include <fstream>
#include <thread>
#endif

#include "bp_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#ifdef PK
#include "htif.h"
#endif

#define FREE_DRAM 0
#define DRAM_ALLOCATE_SIZE 241 * 1024 * 1024

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef BP_NCPUS
#define BP_NCPUS 1
#endif

void nbf_load(bp_zynq_pl *zpl, char *);
bool decode_bp_output(bp_zynq_pl *zpl, int data, int* core);
void report(bp_zynq_pl *zpl, char *);
#ifdef FPGA
void sample(bp_zynq_pl *zpl, char *);
bool run = true;
#endif

const char* metrics[] = {
  "mcycle", "minstret",
  "ic_miss",
  "branch_override", "ret_override", "fe_cmd", "fe_cmd_fence",
  "mispredict", "control_haz", "long_haz", "data_haz",
  "aux_dep", "load_dep", "mul_dep", "fma_dep", "sb_iraw_dep",
  "sb_fraw_dep", "sb_iwaw_dep", "sb_fwaw_dep",
  "struct_haz", "idiv_haz", "fdiv_haz",
  "ptw_busy", "special", "replay", "exception", "_interrupt",
  "itlb_miss", "dtlb_miss",
  "dc_miss", "dc_fail", "unknown",

  "e_ic_req_cnt", "e_ic_miss_cnt", "e_ic_miss",
  "e_dc_req_cnt", "e_dc_miss_cnt", "e_dc_miss",

  "e_ic_miss_l2_ic", "e_ic_miss_l2_dc_fetch", "e_ic_miss_l2_dc_evict",
  "e_dc_miss_l2_ic", "e_dc_miss_l2_dc_fetch", "e_dc_miss_l2_dc_evict",

  "e_dc_is_miss", "e_dc_is_late", "e_dc_is_resume", "e_dc_is_busy_cnt", "e_dc_is_busy",

  "e_l2_ic_cnt", "e_l2_dc_fetch_cnt", "e_l2_dc_evict_cnt",
  "e_l2_ic", "e_l2_dc_fetch", "e_l2_dc_evict",

  "e_l2_ic_miss_cnt", "e_l2_dc_fetch_miss_cnt", "e_l2_dc_evict_miss_cnt",
  "e_l2_ic_miss", "e_l2_dc_fetch_miss", "e_l2_dc_evict_miss",

  "e_l2_ic_dma", "e_l2_dc_fetch_dma", "e_l2_dc_evict_dma",

/*
  "e_wdma_cnt", "e_rdma_cnt", "e_wdma_wait", "e_rdma_wait", "e_dma_wait",
  "e_wdma_ic", "e_rdma_ic", "e_dma_ic",
  "e_wdma_dc_fetch", "e_rdma_dc_fetch", "e_dma_dc_fetch",
  "e_dma_dc_evict",
*/

  "e_wdma_ic_cnt", "e_rdma_ic_cnt", "e_wdma_ic", "e_rdma_ic", "e_dma_ic",
  "e_wdma_dc_fetch_cnt", "e_rdma_dc_fetch_cnt", "e_wdma_dc_fetch", "e_rdma_dc_fetch", "e_dma_dc_fetch",
  "e_wdma_dc_evict_cnt", "e_wdma_dc_evict",

/*
  "e_br_cnt", "e_br_miss", "e_jalr_cnt", "e_jalr_miss", "e_ret_cnt", "e_ret_miss",
  "e_fpu_flong_cnt", "e_fpu_flong_miss", "e_div_cnt", "e_div_wait"
*/
};

const char* samples[] = {
  "mcycle", "minstret"
};

std::queue<int> getchar_queue;

void *monitor(void *vargp) {
  int c = -1;
  while(1) {
    c = getchar();
    if(c != -1)
      getchar_queue.push(c);
  }
}

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

#ifdef PK
  printf("Running with HTIF\n");
  htif_t* htif = new htif_t(zpl);
  int htif_cntr = 0;
#endif

  // the read memory map is essentially
  //
  // 0,4,8,C: reset, dram allocated, dram base address, counter enable
  // 10: pl to ps fifo
  // 14: pl to ps fifo count
  // 18: ps to pl fifo count

  // the write memory map is essentially
  //
  // 0,4,8,C: registers
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
              zpl->axil_read(0x0 + GP0_ADDR_BASE),
              zpl->axil_read(0x4 + GP0_ADDR_BASE),
              val = zpl->axil_read(0x8 + GP0_ADDR_BASE));

  bsg_pr_info("ps.cpp: putting BP into reset\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1); // BP reset

  bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

  zpl->axil_write(0x8 + GP0_ADDR_BASE, 0xDEADBEEF, mask1); // BP reset
  assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (0xDEADBEEF)));
  zpl->axil_write(0x8 + GP0_ADDR_BASE, val, mask1); // BP reset
  assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (val)));

  bsg_pr_info("ps.cpp: successfully wrote and read registers in bsg_zynq_shell "
              "(verified ARM GP0 connection)\n");
#ifdef FPGA
  data = zpl->axil_read(0x4 + GP0_ADDR_BASE);
  if (data == 0) {
    bsg_pr_info(
        "ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate "
        "dram with size %d\n",
        allocated_dram);
    buf = (volatile int *)zpl->allocate_dram(allocated_dram, &phys_ptr);
    bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
    zpl->axil_write(0x8 + GP0_ADDR_BASE, phys_ptr, mask1);
    assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (phys_ptr)));
    bsg_pr_info("ps.cpp: wrote and verified base register\n");
    zpl->axil_write(0x4 + GP0_ADDR_BASE, 0x1, mask2);
    assert(zpl->axil_read(0x4 + GP0_ADDR_BASE) == 1);
  } else
    bsg_pr_info("ps.cpp: reusing dram base pointer %x\n",
                zpl->axil_read(0x8 + GP0_ADDR_BASE));

  int outer = 1024 / 4;
#else
  zpl->axil_write(0x8 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (0x0)));
  bsg_pr_info("ps.cpp: wrote and verified base register\n");

  int outer = 8 / 4;
#endif

  if (argc == 1) {
    bsg_pr_warn(
        "No nbf file specified, sleeping for 2^31 seconds (this will hold "
        "onto allocated DRAM)\n");
    sleep(1 << 31);
    delete zpl;
    exit(0);
  }

  bsg_pr_info("ps.cpp: asserting reset to BP\n");

  // Assert reset
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));

  // Deassert reset
  bsg_pr_info("ps.cpp: deasserting reset to BP\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);

  bsg_pr_info("Reset asserted and deasserted\n");

  bsg_pr_info("ps.cpp: attempting to read mtime reg in BP CFG space, should "
              "increase monotonically  (testing ARM GP1 connections)\n");

  for (int q = 0; q < 10; q++) {
    int z = zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x30bff8);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z,(q % 8) == 7 ? '\n' : ' ');
    // read second 32-bits
    int z2 = zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x30bff8 + 4);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z2,(q % 8) == 7 ? '\n' : ' ');
  }

  bsg_pr_info("ps.cpp: attempting to read and write mtime reg in BP CFG space "
              "(testing ARM GP1 connections)\n");

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  int y = zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x304000);

  bsg_pr_info("ps.cpp: writing mtimecmp\n");
  zpl->axil_write(GP1_ADDR_BASE + 0x20000000U + 0x304000, y + 1, mask1);

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  assert(zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x304000) == y + 1);

#ifdef DRAM_TEST

  int num_times = allocated_dram / 32768;
  bsg_pr_info(
      "ps.cpp: attempting to write L2 %d times over %d MB (testing ARM GP1 "
      "and HP0 connections)\n",
      num_times * outer, (allocated_dram) >> 20);
  zpl->axil_write(GP1_ADDR_BASE, 0x12345678, mask1);

  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++) {
      zpl->axil_write(GP1_ADDR_BASE + 32768 * t + s * 4, 0x1ADACACA + t + s,
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
      if (zpl->axil_read(GP1_ADDR_BASE + 32768 * t + s * 4) == 0x1ADACACA + t + s)
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

  bsg_pr_info("ps.cpp: clearing pl to ps fifo\n");
  while(zpl->axil_read(0x14 + GP0_ADDR_BASE) != 0) {
    zpl->axil_read(0x10 + GP0_ADDR_BASE);
  }

  bsg_pr_info("ps.cpp: asserting counter enable\n");
  zpl->axil_write(0xC + GP0_ADDR_BASE, 0x1, mask1);

  bsg_pr_info("ps.cpp: beginning nbf load\n");
  nbf_load(zpl, argv[1]);
  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
  unsigned long long mtime_start = get_counter_64(zpl, 0x20000000 + 0x30bff8 + GP1_ADDR_BASE);
  unsigned long long mcycle_start = get_counter_64(zpl, 0x2C + GP0_ADDR_BASE);
  unsigned long long minstret_start = get_counter_64(zpl, 0x34 + GP0_ADDR_BASE);
  bsg_pr_dbg_ps("ps.cpp: finished nbf load\n");

  bsg_pr_info("ps.cpp: polling i/o\n");

#ifdef FPGA
  std::thread t(sample, zpl, argv[1]);
#endif
  while (1) {
#ifdef PK
    htif_cntr++;
    if(htif_cntr % 1000 == 0)
      if(htif->step()) {
        // deasserting counter enable
        zpl->axil_write(0xC + GP0_ADDR_BASE, 0x0, mask1);
        break;
      }
#endif

#ifdef HP0_ENABLE
    zpl->axil_poll();
#endif
#ifdef SIM_BACKPRESSURE_ENABLE
    if (!(rand() % SIM_BACKPRESSURE_CHANCE)) {
      for (int i = 0; i < SIM_BACKPRESSURE_LENGTH; i++) {
        zpl->tick();
      }
    }
#endif
    // keep reading as long as there is data
    data = zpl->axil_read(0x14 + GP0_ADDR_BASE);
    if (data != 0) {
      data = zpl->axil_read(0x10 + GP0_ADDR_BASE);
      int core = 0;
      core_done = decode_bp_output(zpl, data, &core);
      if (core_done) {
        done_vec[core] = true;
      }
    }
    // break loop when all cores done
    if (done_vec.all()) {
      // deasserting counter enable
      zpl->axil_write(0xC + GP0_ADDR_BASE, 0x0, mask1);
      break;
    }
  }
#ifdef FPGA
  run = false;
  t.join();
#endif

  unsigned long long mtime_stop = get_counter_64(zpl, 0x20000000 + 0x30bff8 + GP1_ADDR_BASE);
  unsigned long long mcycle_stop = get_counter_64(zpl, 0x2C + GP0_ADDR_BASE);
  unsigned long long minstret_stop = get_counter_64(zpl, 0x34 + GP0_ADDR_BASE);
  clock_gettime(CLOCK_MONOTONIC, &end);
  setlocale(LC_NUMERIC, "");
  bsg_pr_info("ps.cpp: end polling i/o\n");
  bsg_pr_info("ps.cpp: mcycle start:                    %'16llu (%16llx)\n",
              mcycle_start, mcycle_start);
  bsg_pr_info("ps.cpp: mcycle stop:                     %'16llu (%16llx)\n",
              mcycle_stop, mcycle_stop);
  unsigned long long mcycle_delta = mcycle_stop - mcycle_start;
  bsg_pr_info("ps.cpp: mcycle delta:                    %'16llu (%16llx)\n",
              mcycle_delta, mcycle_delta);
  bsg_pr_info("ps.cpp: minstret start:                  %'16llu (%16llx)\n",
              minstret_start, minstret_start);
  bsg_pr_info("ps.cpp: minstret stop:                   %'16llu (%16llx)\n",
              minstret_stop, minstret_stop);
  unsigned long long minstret_delta = minstret_stop - minstret_start;
  bsg_pr_info("ps.cpp: minstret delta:                  %'16llu (%16llx)\n",
              minstret_delta, minstret_delta);
  bsg_pr_info("ps.cpp: MTIME start:                     %'16llu (%16llx)\n",
              mtime_start, mtime_start);
  bsg_pr_info("ps.cpp: MTIME stop:                      %'16llu (%16llx)\n",
              mtime_stop, mtime_stop);
  unsigned long long mtime_delta = mtime_stop - mtime_start;
  bsg_pr_info("ps.cpp: MTIME delta (=1/8 BP cycles):    %'16llu (%16llx)\n",
              mtime_delta, mtime_delta);
  bsg_pr_info("ps.cpp: IPC        :                     %'16f\n",
              ((double)minstret_delta) / ((double)(mcycle_delta)));
  unsigned long long diff_ns =
      1000LL * 1000LL * 1000LL *
          ((unsigned long long)(end.tv_sec - start.tv_sec)) +
      (end.tv_nsec - start.tv_nsec);
  bsg_pr_info("ps.cpp: wall clock time                : %'16llu (%16llx) ns\n",
              diff_ns, diff_ns);
  bsg_pr_info(
      "ps.cpp: sim/emul speed                         : %'16.2f BP cycles per minute\n",
      mtime_delta * 8 /
          ((double)(diff_ns) / (60.0 * 1000.0 * 1000.0 * 1000.0)));

  bsg_pr_info("ps.cpp: BP DRAM USAGE MASK (each bit is 8 MB): "
              "%-8.8x%-8.8x%-8.8x%-8.8x\n",
              zpl->axil_read(0x28 + GP0_ADDR_BASE),
              zpl->axil_read(0x24 + GP0_ADDR_BASE),
              zpl->axil_read(0x20 + GP0_ADDR_BASE),
              zpl->axil_read(0x1C + GP0_ADDR_BASE));

  report(zpl, argv[1]);
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
    zpl->axil_write(0x4 + GP0_ADDR_BASE, 0x0, mask2);
  }
#endif

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
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
    bsg_pr_err("ps.cpp: error opening nbf file.\n");
    delete zpl;
    exit(-1);
  }

  int line_count=0;
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
        int shift = 8 * offset;
        data = zpl->axil_read(base_addr + nbf[1] - offset);
        data = data & rotl((uint32_t)0xffff0000,shift) + ((nbf[2] & ((uint32_t)0x0000ffff)) << shift);
        zpl->axil_write(base_addr + nbf[1] - offset, data, 0xf);
      }
      else {
        int offset = nbf[1] % 4;
        int shift = 8 * offset;
        data = zpl->axil_read(base_addr + nbf[1] - offset);
        data = data & rotl((uint32_t)0xffffff00,shift) + ((nbf[2] & ((uint32_t)0x000000ff)) << shift);
        zpl->axil_write(base_addr + nbf[1] - offset, data, 0xf);
      }
    }
    else if (nbf[0] == 0xfe) {
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
    }
    else if (address == 0x101004)
      return false;
    else if (address >= 0x102000 && address < 0x103000) {
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
        zpl->axil_write(0x10 + GP0_ADDR_BASE, -1, 0xf);
      } else {
        zpl->axil_write(0x10 + GP0_ADDR_BASE, getchar_queue.front(), 0xf);
        getchar_queue.pop();
      }
    }
    // parameter ROM, only partially implemented
    else if (address >= 0x120000 && address <= 0x120128) {
      bsg_pr_dbg_ps("ps.cpp: PARAM ROM read from (%x)\n", address);
      int offset = address - 0x120000;
      // CC_X_DIM, return number of cores
      if (offset == 0x0) {
        zpl->axil_write(0xC + GP0_ADDR_BASE, BP_NCPUS, 0xf);
      }
      // CC_Y_DIM, just return 1 so X*Y == number of cores
      else if (offset == 0x4) {
        zpl->axil_write(0xC + GP0_ADDR_BASE, 1, 0xf);
      }
    }
    // if not implemented, print error
    else {
      bsg_pr_err("ps.cpp: Errant read from (%x)\n", address);
    }
    return false;
  }
}

void report(bp_zynq_pl *zpl, char* nbf_filename) {

  char filename[100];
  if(strrchr(nbf_filename, '/') != NULL)
    strcpy(filename, 1 + strrchr(nbf_filename, '/'));
  else
    strcpy(filename, nbf_filename);
  *strrchr(filename, '.') = '\0';
  strcat(filename, ".rep");
  ofstream file(filename);

  if(file.is_open()) {
    file << nbf_filename << endl;
    for(int i=0; i<sizeof(metrics)/sizeof(metrics[0]); i++) {
      file << metrics[i] << "\t";
      file << get_counter_64(zpl, GP0_ADDR_BASE + 0x2C + i*8) << "\n";
    }
    file.close();
  }
  else printf("Cannot open report file: %s\n", filename);
}

#ifdef FPGA
void sample(bp_zynq_pl *zpl, char* nbf_filename) {

  char filename[100];
  if(strrchr(nbf_filename, '/') != NULL)
    strcpy(filename, 1 + strrchr(nbf_filename, '/'));
  else
    strcpy(filename, nbf_filename);
  *strrchr(filename, '.') = '\0';
  strcat(filename, ".sample");
  ofstream file(filename, ios::binary);

  int sampleIdx[sizeof(samples)/sizeof(samples[0])];
  for(int i=0; i<sizeof(samples)/sizeof(samples[0]); i++) {
    bool found = false;
    for(int j=0; j<sizeof(metrics)/sizeof(metrics[0]); j++) {
      if(!strcmp(samples[i], metrics[j])) {
        sampleIdx[i] = j;
        found = true;
        break;
      }
    }
    if(!found)
      printf("Cannot find sample %s index!", samples[i]);
  }

  if(file.is_open()) {
    while(run) {
      std::this_thread::sleep_for(100ms);
      for(int i=0; i<sizeof(samples)/sizeof(samples[0]); i++) {
        unsigned long long sample = get_counter_64(zpl,GP0_ADDR_BASE + 0x2C + 8*sampleIdx[i]);
        file.write((char*)&sample, sizeof(sample));
      }
    }
    file.close();
  }
  else printf("Cannot open sample file: %s\n", filename);
}
#endif
