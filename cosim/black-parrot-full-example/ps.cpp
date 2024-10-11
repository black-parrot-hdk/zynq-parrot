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

#include "bsg_tag_bitbang.h"
#include "bp_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#ifndef FREE_DRAM
#define FREE_DRAM 0
#endif

#ifndef ZERO_DRAM
#define ZERO_DRAM 0
#endif

#ifndef DRAM_ALLOCATE_SIZE_MB
#define DRAM_ALLOCATE_SIZE_MB 128
#endif
#define DRAM_ALLOCATE_SIZE (DRAM_ALLOCATE_SIZE_MB * 1024 * 1024)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef BP_NCPUS
#define BP_NCPUS 1
#endif

// GP0 Read Memory Map
#define GP0_RD_CSR_BITBANG     0x0
#define GP0_RD_CSR_DRAM_INITED 0x4
#define GP0_RD_CSR_DRAM_BASE   0x8
#define GP0_RD_PL2PS_FIFO_DATA 0xC
#define GP0_RD_PL2PS_FIFO_CTRS 0x10
#define GP0_RD_PS2PL_FIFO_CTRS 0x14
#define GP0_RD_MINSTRET        0x18 // 64-bit
#define GP0_RD_MEM_PROF_0      0x20
#define GP0_RD_MEM_PROF_1      0x24
#define GP0_RD_MEM_PROF_2      0x28
#define GP0_RD_MEM_PROF_3      0x2C

// GP0 Write Memory Map
#define GP0_WR_CSR_BITBANG         GP0_RD_CSR_BITBANG
#define GP0_WR_CSR_DRAM_INITED     GP0_RD_CSR_DRAM_INITED
#define GP0_WR_CSR_DRAM_BASE       GP0_RD_CSR_DRAM_BASE
#define GP0_WR_PS2PL_FIFO_DATA 0xC

// DRAM
#define DRAM_BASE_ADDR  0x80000000U
#define DRAM_MAX_ALLOC_SIZE 0x20000000U
// GP1
#define GP1_DRAM_BASE_ADDR gp1_addr_base
#define GP1_CSR_BASE_ADDR (gp1_addr_base + DRAM_MAX_ALLOC_SIZE)

#define NUM_RESET 5

// Helper functions
void nbf_load(bp_zynq_pl *zpl, char *filename);
bool decode_bp_output(bp_zynq_pl *zpl, long data);

// Globals
std::queue<int> getchar_queue;
std::bitset<BP_NCPUS> done_vec;

void *monitor(void *vargp) {
  char c;
  while(1) {
    c = getchar();
    if(c != -1)
      getchar_queue.push(c);
  }
  bsg_pr_info("Exiting from pthread\n");

  return NULL;
}

void *device_poll(void *vargp) {
  bp_zynq_pl *zpl = (bp_zynq_pl *)vargp;
  while (1) {
#ifndef FPGA
    zpl->axil_poll();
#endif

    // keep reading as long as there is data
    if (zpl->axil_read(GP0_RD_PL2PS_FIFO_CTRS + gp0_addr_base) != 0) {
      decode_bp_output(zpl, zpl->axil_read(GP0_RD_PL2PS_FIFO_DATA + gp0_addr_base));
    }
    // break loop when all cores done
    if (done_vec.all()) {
      break;
    }
  }
  bsg_pr_info("Exiting from pthread\n");

  return NULL;
}

inline uint64_t get_counter_64(bp_zynq_pl *zpl, uint64_t addr) {
  uint64_t val;
  do {
    uint64_t val_hi = zpl->axil_read(addr + 4);
    uint64_t val_lo = zpl->axil_read(addr + 0);
    uint64_t val_hi2 = zpl->axil_read(addr + 4);
    if (val_hi == val_hi2) {
      val = val_hi << 32;
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

  long data;
  long val1 = 0x1;
  long val2 = 0x0;
  long mask1 = 0xf;
  long mask2 = 0xf;

  pthread_t thread_id;
  long allocated_dram = DRAM_ALLOCATE_SIZE;
#ifdef FPGA
  unsigned long phys_ptr;
  volatile int32_t *buf;
#endif

  long val;
  bsg_pr_info("ps.cpp: reading three base registers\n");
  bsg_pr_info("ps.cpp: reset(lo)=%d dram_init=%d, dram_base=%x\n",
              zpl->axil_read(GP0_RD_CSR_BITBANG + gp0_addr_base),
              zpl->axil_read(GP0_RD_CSR_DRAM_INITED + gp0_addr_base),
              val = zpl->axil_read(GP0_RD_CSR_DRAM_BASE + gp0_addr_base));
#ifdef BITBANG_ENABLE
  // Reset the bsg tag master
  zpl->tag->bsg_tag_reset(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base);
  // We need some additional toggles for data to propagate through
  for(int i = 0;i < 4;i++)
    zpl->tag->bsg_tag_bit_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, 0x0);

  // Reset bsg client0-4
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 0, 0, -1U);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 0, 1, -1U);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 0, 2, -1U);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 0, 3, -1U);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 0, 4, -1U);

  // Set bsg client2 to 1 (assert reset for the tx_clk downsampling logic)
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 2, 0x1);
  // Set bsg client2 to 0 (deassert reset for the tx_clk downsampling logic)
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 2, 0x0);

  // Set all bsg clients except client2 to 1 (assert resets)
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 0, 0x1);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 1, 0x1);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 3, 0x1);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 4, 0x1);
  // We need some additional toggles for data to propagate through
  for(int i = 0;i < 500;i++)
    zpl->tag->bsg_tag_bit_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, 0x0);

  // Set all bsg clients except client2 to 0 (deassert resets)
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 0, 0x0);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 1, 0x0);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 3, 0x0);
  zpl->tag->bsg_tag_packet_write(zpl, GP0_RD_CSR_BITBANG + gp0_addr_base, NUM_RESET, 1, 1, 4, 0x0);
#endif

  bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

  zpl->axil_write(GP0_WR_CSR_DRAM_BASE + gp0_addr_base, 0xDEADBEEF, mask1);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE + gp0_addr_base) == (0xDEADBEEF)));
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE + gp0_addr_base, val, mask1);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE + gp0_addr_base) == (val)));

  bsg_pr_info("ps.cpp: successfully wrote and read registers in bsg_zynq_shell "
              "(verified ARM GP0 connection)\n");
#ifdef FPGA
  data = zpl->axil_read(GP0_RD_CSR_DRAM_INITED + gp0_addr_base);
  if (data == 0) {
    bsg_pr_info(
        "ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate "
        "dram with size %ld\n",
        allocated_dram);
    buf = (volatile int32_t *)zpl->allocate_dram(allocated_dram, &phys_ptr);
    bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
    zpl->axil_write(GP0_WR_CSR_DRAM_BASE + gp0_addr_base, phys_ptr, mask1);
    assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE + gp0_addr_base) == (phys_ptr)));
    bsg_pr_info("ps.cpp: wrote and verified base register\n");
    zpl->axil_write(GP0_WR_CSR_DRAM_INITED + gp0_addr_base, 0x1, mask2);
    assert(zpl->axil_read(GP0_RD_CSR_DRAM_INITED + gp0_addr_base) == 1);
  } else
    bsg_pr_info("ps.cpp: reusing dram base pointer %lx\n",
                zpl->axil_read(GP0_RD_CSR_DRAM_BASE + gp0_addr_base));

  int outer = 1024 / 4;
#else
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE + gp0_addr_base, val1, mask1);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE + gp0_addr_base) == (val1)));
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

  bsg_pr_info("ps.cpp: attempting to read mtime reg in BP CFG space, should "
              "increase monotonically  (testing ARM GP1 connections)\n");

  for (int q = 0; q < 10; q++) {
    int z = zpl->axil_read(GP1_CSR_BASE_ADDR + 0x30bff8);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z,(q % 8) == 7 ? '\n' : ' ');
    // read second 32-bits
    int z2 = zpl->axil_read(GP1_CSR_BASE_ADDR + 0x30bff8 + 4);
    // bsg_pr_dbg_ps("ps.cpp: %d%c",z2,(q % 8) == 7 ? '\n' : ' ');
  }

  bsg_pr_info("ps.cpp: attempting to read and write mtime reg in BP CFG space "
              "(testing ARM GP1 connections)\n");

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  int y = zpl->axil_read(GP1_CSR_BASE_ADDR + 0x304000);

  bsg_pr_info("ps.cpp: writing mtimecmp\n");
  zpl->axil_write(GP1_CSR_BASE_ADDR + 0x304000, y + 1, mask1);

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  assert(zpl->axil_read(GP1_CSR_BASE_ADDR + 0x304000) == y + 1);

#ifdef FPGA
  // Must zero DRAM for FPGA Linux boot, because opensbi payload mode
  //   obliterates the section names of the payload (Linux)
  if (ZERO_DRAM) {
    bsg_pr_info("ps.cpp: Zero-ing DRAM (%d bytes)\n", DRAM_ALLOCATE_SIZE);
    for (int i = 0; i < DRAM_ALLOCATE_SIZE; i+=4) {
      if (i % (1024*1024) == 0) bsg_pr_info("ps.cpp: zero-d %d MB\n", i/(1024*1024));
      zpl->axil_write(gp1_addr_base + i, 0x0, mask1);
    }
  }
#endif

#ifdef DRAM_TEST

  long num_times = allocated_dram / 32768;
  bsg_pr_info(
      "ps.cpp: attempting to write L2 %ld times over %ld MB (testing ARM GP1 "
      "and HP0 connections)\n",
      num_times * outer, (allocated_dram) >> 20);
  zpl->axil_write(GP1_DRAM_BASE_ADDR, 0x12345678, mask1);

  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++) {
      zpl->axil_write(GP1_DRAM_BASE_ADDR + 32768 * t + s * 4, 0x1ADACACA + t + s,
                      mask1);
    }
  bsg_pr_info("ps.cpp: finished write L2 %ld times over %ld MB\n",
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
      "ps.cpp: attempting to read L2 %ld times over %ld MB (testing ARM GP1 "
      "and HP0 connections)\n",
      num_times * outer, (allocated_dram) >> 20);
  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++)
      if (zpl->axil_read(GP1_DRAM_BASE_ADDR + 32768 * t + s * 4) == 0x1ADACACA + t + s)
        matches++;
      else
        mismatches++;

  bsg_pr_info("ps.cpp: READ access through BP (some L1 coherence mismatch "
              "expected): %d matches, %d mismatches, %f\n",
              matches, mismatches,
              ((float)matches) / (float)(mismatches + matches));

#endif // DRAM_TEST

  bsg_pr_info("ps.cpp: beginning nbf load\n");
  nbf_load(zpl, argv[1]);
  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
  unsigned long long minstret_start = get_counter_64(zpl, GP0_RD_MINSTRET + gp0_addr_base);
  unsigned long long mtime_start = get_counter_64(zpl, GP1_CSR_BASE_ADDR + 0x30bff8);
  bsg_pr_dbg_ps("ps.cpp: finished nbf load\n");

  bsg_pr_info("ps.cpp: Starting scan thread\n");
  pthread_create(&thread_id, NULL, monitor, NULL);

  bsg_pr_info("ps.cpp: Starting i/o polling thread\n");
  pthread_create(&thread_id, NULL, device_poll, (void *)zpl);

  bsg_pr_info("ps.cpp: waiting for i/o packet\n");
  pthread_join(thread_id, NULL);

  unsigned long long mtime_stop = get_counter_64(zpl, GP1_CSR_BASE_ADDR + 0x30bff8);

  unsigned long long minstret_stop = get_counter_64(zpl, GP0_RD_MINSTRET + gp0_addr_base);
  // test delay for reading counter
  unsigned long long counter_data = get_counter_64(zpl, GP0_RD_MINSTRET + gp0_addr_base);
  clock_gettime(CLOCK_MONOTONIC, &end);
  setlocale(LC_NUMERIC, "");
  bsg_pr_info("ps.cpp: end polling i/o\n");
  bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
              minstret_start, minstret_start);
  bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
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
              ((double)minstret_delta) / ((double)(mtime_delta)) / 8.0);
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
              "%-8.8ld%-8.8ld%-8.8ld%-8.8ld\n",
              zpl->axil_read(GP0_RD_MEM_PROF_3 + gp0_addr_base),
              zpl->axil_read(GP0_RD_MEM_PROF_2 + gp0_addr_base),
              zpl->axil_read(GP0_RD_MEM_PROF_1 + gp0_addr_base),
              zpl->axil_read(GP0_RD_MEM_PROF_0 + gp0_addr_base));
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
    zpl->axil_write(GP0_WR_CSR_DRAM_INITED + gp0_addr_base, 0x0, mask2);
  }
#endif

  zpl->done();
  delete zpl;
#ifdef VCS
  return;
#else
  exit(EXIT_SUCCESS);
#endif
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
      // we map BP physical addresses for DRAM (0x8000_0000 - 0x9FFF_FFFF) (256MB)
      // to the same ARM physical addresses
      // see top_fpga.v for more details

      // we map BP physical address for CSRs etc (0x0000_0000 - 0x0FFF_FFFF)
      // to ARM address to 0xA0000_0000 - 0xAFFF_FFFF  (256MB)
      if (nbf[1] >= DRAM_BASE_ADDR)
        base_addr = gp1_addr_base - DRAM_BASE_ADDR;
      else
        base_addr = GP1_CSR_BASE_ADDR;

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
        int shift = 2 * offset;
        data = zpl->axil_read(base_addr + nbf[1] - offset);
        data = data & rotl((uint32_t)0xffffff00,shift) + nbf[2] & ((uint32_t)0x000000ff << shift);
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

bool decode_bp_output(bp_zynq_pl *zpl, long data) {
  long rd_wr = data >> 31;
  long address = (data >> 8) & 0x7FFFFF;
  char print_data = data & 0xFF;
  char core = (address-0x102000) >> 3;
  // write from BP
  if (rd_wr) {
    if (address == 0x101000) {
      printf("%c", print_data);
      fflush(stdout);
    } else if (address >= 0x102000 && address < 0x103000) {
      done_vec[core] = true;
      if (print_data == 0) {
        bsg_pr_info("CORE[%d] PASS\n", core);
      } else {
        bsg_pr_info("CORE[%d] FAIL\n", core);
      }
    } else {
      bsg_pr_err("ps.cpp: Errant write to %lx\n", address);
      return false;
    }
  }
  // read from BP
  else {
    // getchar
    if (address == 0x100000) {
      if (getchar_queue.empty()) {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA + gp0_addr_base, -1, 0xf);
      } else {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA + gp0_addr_base, getchar_queue.front(), 0xf);
        getchar_queue.pop();
      }
    }
    // parameter ROM, only partially implemented
    else if (address >= 0x120000 && address <= 0x120128) {
      bsg_pr_dbg_ps("ps.cpp: PARAM ROM read from (%lx)\n", address);
      int offset = address - 0x120000;
      // CC_X_DIM, return number of cores
      if (offset == 0x0) {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA + gp0_addr_base, BP_NCPUS, 0xf);
      }
      // CC_Y_DIM, just return 1 so X*Y == number of cores
      else if (offset == 0x4) {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA + gp0_addr_base, 1, 0xf);
      }
    }
    // if not implemented, print error
    else {
      bsg_pr_err("ps.cpp: Errant read from (%lx)\n", address);
      return false;
    }
  }

  return true;
}

