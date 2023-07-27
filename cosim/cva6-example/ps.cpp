#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
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

#define FREE_DRAM 0
#define DRAM_ALLOCATE_SIZE 241 * 1024 * 1024

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

void nbf_load(bp_zynq_pl *zpl, char *);
bool decode_bp_output(bp_zynq_pl *zpl, int data);
void report(bp_zynq_pl *zpl, char *);
#ifdef FPGA
void monitor(bp_zynq_pl *zpl, char *);
bool run = true;
#endif

const char* metrics[] = {
  "mcycle", "minstret",
  "iq_full", "ic_invl", "ic_miss", "ic_flush", "ic_atrans",
  "bp_haz", "ireplay", "realign", "sb_full",
  "waw_flu", "waw_lsu", "waw_fpu", "waw_reorder",
  "raw_flu", "raw_lsu", "raw_fpu",
  "br_haz", "br_miss", "mul_haz", "csr_buf",
  "div_busy", "fpu_busy",
  "ld_grant", "ld_pipe", "st_pipe", "sbuf_spec",
  "dc_pipe", "dc_miss_is_ld", "dc_miss_is_st",
  "dc_miss_ex_ld", "dc_miss_ex_st", "dc_miss_cmt",
  "amo_flush", "csr_flush", "fence", "exception",
  "unknown", "extra_cmt",

  "e_rdma_ic_cnt", "e_wdma_dc_cnt", "e_rdma_dc_cnt",
  "e_rdma_ic", "e_wdma_dc", "e_rdma_dc", "e_dma_dc",
  "e_wdma_ld", "e_rdma_ld", "e_wdma_st", "e_rdma_st",
  "e_ic_rdma", "e_ld_wdma", "e_ld_rdma", "e_st_wdma", "e_st_rdma",

  "e_ic_req_cnt", "e_ic_miss_cnt", "e_ic_miss",

  "e_dc_req_cnt", "e_ld_miss_cnt", "e_st_miss_cnt",
  "e_ld_miss", "e_ld_mshr_miss", "e_ld_st_wait_miss",
  "e_st_miss", "e_st_mshr_miss", "e_st_ld_wait_miss", "e_st_pgoff_miss",
  "e_lu_miss"
/*
  "e_br_cnt", "e_br_miss", "e_jalr_cnt", "e_jalr_miss", "e_ret_cnt", "e_ret_miss",
  "e_fpu_addmul_cnt", "e_fpu_divsqrt_cnt", "e_fpu_noncomp_cnt", "e_fpu_conv_cnt",
  "e_fpu_addmul_wait", "e_fpu_divsqrt_wait", "e_fpu_noncomp_wait", "e_fpu_conv_wait",
  "e_div_cnt", "e_div_wait"
*/
};

const char* samples[] = {
  "mcycle", "minstret"
};

inline uint64_t get_counter_64(bp_zynq_pl *zpl, uint64_t addr) {
  unsigned long long val;
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

  // the read memory map is essentially
  //
  // 0,4,8,C,10: main reset, dram allocated, dram base address, core reset, counter enable
  // 14: pl to ps fifo
  // 18: pl to ps fifo count
  // 1C: ps to pl fifo count

  // the write memory map is essentially
  //
  // 0,4,8: registers
  // 10: ps to pl fifo

  int data;
  int val1 = 0x1;
  int val2 = 0x0;
  int mask1 = 0xf;
  int mask2 = 0xf;
  bool done = false;

  int allocated_dram = DRAM_ALLOCATE_SIZE;
#ifdef FPGA
  unsigned long phys_ptr;
  volatile int *buf;
#endif

  int val;
  bsg_pr_info("ps.cpp: reading three base registers\n");
  bsg_pr_info("ps.cpp: main reset(lo)=%d dram_init=%d, dram_base=%x\n",
              zpl->axil_read(0x0 + GP0_ADDR_BASE),
              zpl->axil_read(0x4 + GP0_ADDR_BASE),
              val = zpl->axil_read(0x8 + GP0_ADDR_BASE));

  bsg_pr_info("ps.cpp: putting SoC and core into reset\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  zpl->axil_write(0xC + GP0_ADDR_BASE, 0x0, mask1);

  bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

  zpl->axil_write(0x8 + GP0_ADDR_BASE, 0xDEADBEEF, mask1);
  assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (0xDEADBEEF)));
  zpl->axil_write(0x8 + GP0_ADDR_BASE, val, mask1);
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
    exit(0);
  }

  bsg_pr_info("ps.cpp: asserting main and core reset\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(0xC + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0xC + GP0_ADDR_BASE) == (0)));

  bsg_pr_info("ps.cpp: deasserting main reset\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);

  bsg_pr_info("ps.cpp: asserting counter enable\n");
  zpl->axil_write(0x10 + GP0_ADDR_BASE, 0x1, mask1);

  bsg_pr_info("ps.cpp: attempting to read mtime reg, should "
              "increase monotonically  (testing ARM GP1 connections)\n");

  for (int q = 0; q < 10; q++) {
    int z = zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x200bff8);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z,(q % 8) == 7 ? '\n' : ' ');
    // read second 32-bits
    int z2 = zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x200bff8 + 4);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z2,(q % 8) == 7 ? '\n' : ' ');
  }

  bsg_pr_info("ps.cpp: attempting to read and write mtimecmp reg "
              "(testing ARM GP1 connections)\n");

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  int y = zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x2004000);

  bsg_pr_info("ps.cpp: writing mtimecmp\n");
  zpl->axil_write(GP1_ADDR_BASE + 0x20000000U + 0x2004000, y + 1, mask1);

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  assert(zpl->axil_read(GP1_ADDR_BASE + 0x20000000U + 0x2004000) == y + 1);

  printf("argc: %d\n", argc);
  bsg_pr_info("ps.cpp: beginning nbf load: %s\n", argv[1]);
  nbf_load(zpl, argv[1]);
  bsg_pr_info("ps.cpp: finished nbf load\n");

  bsg_pr_info("ps.cpp: clearing pl to ps fifo\n");
  while(zpl->axil_read(0x18 + GP0_ADDR_BASE) != 0) {
    zpl->axil_read(0x14 + GP0_ADDR_BASE);
  }

  bsg_pr_info("ps.cpp: deasserting core reset\n");
  zpl->axil_write(0xC + GP0_ADDR_BASE, 0x1, mask1);

  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);

  unsigned long long mcycle_start = get_counter_64(zpl,0x30 + GP0_ADDR_BASE);
  unsigned long long minstret_start = get_counter_64(zpl,0x38 + GP0_ADDR_BASE);
  unsigned long long mtime_start = get_counter_64(zpl, GP1_ADDR_BASE + 0x20000000U + 0x200bff8);
  bsg_pr_info("ps.cpp: polling i/o\n");

#ifdef FPGA
  std::thread t(monitor, zpl, argv[1]);
#endif
  while (1) {
    // keep reading as long as there is data
    data = zpl->axil_read(0x18 + GP0_ADDR_BASE);
    if (data != 0) {
      data = zpl->axil_read(0x14 + GP0_ADDR_BASE);
      done |= decode_bp_output(zpl, data);
      if (done) {
        // deasserting counter enable
        zpl->axil_write(0x10 + GP0_ADDR_BASE, 0x0, mask1);
        break;
      }
    }
  }
#ifdef FPGA
  run = false;
  t.join();
#endif

  unsigned long long mcycle_stop = get_counter_64(zpl,0x30 + GP0_ADDR_BASE);
  unsigned long long minstret_stop = get_counter_64(zpl,0x38 + GP0_ADDR_BASE);
  unsigned long long mtime_stop = get_counter_64(zpl, GP1_ADDR_BASE + 0x20000000U + 0x200bff8);
  unsigned long long mcycle_delta = mcycle_stop - mcycle_start;
  unsigned long long minstret_delta = minstret_stop - minstret_start;
  unsigned long long mtime_delta = mtime_stop - mtime_start;

  clock_gettime(CLOCK_MONOTONIC, &end);
  //setlocale(LC_NUMERIC, "");
  bsg_pr_info("ps.cpp: end polling i/o\n");
  bsg_pr_info("ps.cpp: mcycle start:                    %'16llu (%16llx)\n",
              mcycle_start, mcycle_start);
  bsg_pr_info("ps.cpp: mcycle stop:                     %'16llu (%16llx)\n",
              mcycle_stop, mcycle_stop);
  bsg_pr_info("ps.cpp: mcycle delta:                    %'16llu (%16llx)\n",
              mcycle_delta, mcycle_delta);
  bsg_pr_info("ps.cpp: minstret start:                  %'16llu (%16llx)\n",
              minstret_start, minstret_start);
  bsg_pr_info("ps.cpp: minstret stop:                   %'16llu (%16llx)\n",
              minstret_stop, minstret_stop);
  bsg_pr_info("ps.cpp: minstret delta:                  %'16llu (%16llx)\n",
              minstret_delta, minstret_delta);
  bsg_pr_info("ps.cpp: MTIME start:                     %'16llu (%16llx)\n",
              mtime_start, mtime_start);
  bsg_pr_info("ps.cpp: MTIME stop:                      %'16llu (%16llx)\n",
              mtime_stop, mtime_stop);
  bsg_pr_info("ps.cpp: MTIME delta:                     %'16llu (%16llx)\n",
              mtime_delta, mtime_delta);
  bsg_pr_info("ps.cpp: IPC        :                     %'16f\n",
              ((double)minstret_delta) / ((double)mcycle_delta));
  unsigned long long diff_ns =
      1000LL * 1000LL * 1000LL *
          ((unsigned long long)(end.tv_sec - start.tv_sec)) +
      (end.tv_nsec - start.tv_nsec);
  bsg_pr_info("ps.cpp: wall clock time                : %'16llu (%16llx) ns\n",
              diff_ns, diff_ns);

  bsg_pr_info("ps.cpp: DRAM USAGE MASK (each bit is 8 MB): "
              "%-8.8x%-8.8x%-8.8x%-8.8x\n",
              zpl->axil_read(0x2C + GP0_ADDR_BASE),
              zpl->axil_read(0x28 + GP0_ADDR_BASE),
              zpl->axil_read(0x24 + GP0_ADDR_BASE),
              zpl->axil_read(0x20 + GP0_ADDR_BASE));

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
  long unsigned int address;
  int data;
  ifstream nbf_file(nbf_filename);

  if (!nbf_file.is_open()) {
    bsg_pr_err("ps.cpp: error opening nbf file.\n");
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
    if (nbf[0] == 0x3 || nbf[0] == 0x2 || nbf[0] == 0x1 || nbf[0] == 0x0) {

      if (nbf[1] >= 0x80000000) {
        if (nbf[0] == 0x3) {
          zpl->axil_write(GP1_ADDR_BASE - 0x80000000 + nbf[1], nbf[2], 0xf);
          zpl->axil_write(GP1_ADDR_BASE - 0x80000000 + nbf[1] + 4, nbf[2] >> 32, 0xf);
        }
        else if (nbf[0] == 0x2) {
          zpl->axil_write(GP1_ADDR_BASE - 0x80000000 + nbf[1], nbf[2], 0xf);
        }
        else if (nbf[0] == 0x1) {
          int offset = nbf[1] % 4;
          int shift = 8 * offset;
          data = zpl->axil_read(GP1_ADDR_BASE - 0x80000000 + nbf[1] - offset);
          data = data & rotl((uint32_t)0xffff0000,shift) + ((nbf[2] & ((uint32_t)0x0000ffff)) << shift);
          zpl->axil_write(GP1_ADDR_BASE - 0x80000000 + nbf[1] - offset, data, 0xf);
        }
        else {
          int offset = nbf[1] % 4;
          int shift = 8 * offset;
          data = zpl->axil_read(GP1_ADDR_BASE - 0x80000000 + nbf[1] - offset);
          data = data & rotl((uint32_t)0xffffff00,shift) + ((nbf[2] & ((uint32_t)0x000000ff)) << shift);
          zpl->axil_write(GP1_ADDR_BASE - 0x80000000 + nbf[1] - offset, data, 0xf);
        }
      }
    } else if (nbf[0] == 0xfe) {
      continue;
    } else if (nbf[0] = 0xff) {
      bsg_pr_dbg_ps("ps.cpp: finished loading %d lines of nbf.\n", line_count);
      return;
    } else {
      bsg_pr_dbg_ps("ps.cpp: unrecognized nbf command, line %d : %x\n",
                    line_count, nbf[0]);
      return;
    }
  }
  bsg_pr_dbg_ps("ps.cpp: finished loading %d lines of nbf.\n", line_count);
}

bool decode_bp_output(bp_zynq_pl *zpl, int data) {
  int rd_wr = data >> 31;
  int address = (data >> 8) & 0x7FFFFF;
  int print_data = data & 0xFF;
  if (rd_wr) {
    if (address == 0x101000) {
      printf("%c", print_data);
      fflush(stdout);
      return false;
    } else if (address == 0x102000) {
      if (print_data == 0)
        bsg_pr_info("\nPASS\n");
      else
        bsg_pr_info("\nFAIL\n");
      return true;
    }

    bsg_pr_err("ps.cpp: Errant write to %x\n", address);
    return false;
  }
  else {
    bsg_pr_err("ps.cpp: Unsupported read (%x)\n", data);
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
      file << get_counter_64(zpl,GP0_ADDR_BASE + 0x30 + i*8) << "\n";
    }
    file.close();
  }
  else printf("Cannot open report file: %s\n", filename);
}

#ifdef FPGA
void monitor(bp_zynq_pl *zpl, char* nbf_filename) {

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
        unsigned long long sample = get_counter_64(zpl,GP0_ADDR_BASE + 0x30 + 8*sampleIdx[i]);
        file.write((char*)&sample, sizeof(sample));
      }
    }
    file.close();
  }
  else printf("Cannot open sample file: %s\n", filename);
}
#endif
