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
#include <string.h>
#include <bitset>
#include <cstdint>
#include <iostream>
#include <iomanip>

#include "ps.hpp"

#include "bsg_tag_bitbang.h"
#include "bsg_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#ifdef PK
#include "htif.h"
#ifndef HTIF_INTERVAL
#define HTIF_INTERVAL 1
#endif
#endif

#ifndef FREE_DRAM
#define FREE_DRAM 0
#endif

#ifndef ZERO_DRAM
#define ZERO_DRAM 0
#endif

#ifndef DRAM_ALLOCATE_SIZE_MB
#define DRAM_ALLOCATE_SIZE_MB 241
#endif
#define DRAM_ALLOCATE_SIZE (DRAM_ALLOCATE_SIZE_MB * 1024 * 1024)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef BP_NCPUS
#define BP_NCPUS 1
#endif

#ifndef SAMPLE_INTERVAL
#error "SAMPLE_INTERVAL not defined!"
#endif

#ifndef DRAM_LATENCY
#error "DRAM_LATENCY not defined!"
#endif

// Helper functions
void nbf_load(bsg_zynq_pl *zpl, char *filename);
bool decode_bp_output(bsg_zynq_pl *zpl, long data);
void report(bsg_zynq_pl *zpl, char *);

const char* metrics[] = {
  "cycle", "mcycle", "minstret",
  "ic_miss",
  "br_ovr", "ret_ovr", "jal_ovr", "fe_cmd", "fe_cmd_fence",
  "mispredict", "control_haz", "long_haz", "data_haz",
  "catchup_dep", "aux_dep", "load_dep", "mul_dep", "fma_dep", "sb_iraw_dep",
  "sb_fraw_dep", "sb_iwaw_dep", "sb_fwaw_dep",
  "struct_haz", "idiv_haz", "fdiv_haz",
  "ptw_busy", "special", "exception", "_interrupt",
  "itlb_miss", "dtlb_miss",
  "dc_miss", "dc_fail", "unknown",
/*
  "e_ic_req_cnt", "e_ic_miss_cnt", "e_ic_miss",
  "e_dc_req_cnt", "e_dc_miss_cnt", "e_dc_miss",

  "e_ic_miss_l2_ic", "e_ic_miss_l2_dfetch", "e_ic_miss_l2_devict",
  "e_dc_miss_l2_ic", "e_dc_miss_l2_dfetch", "e_dc_miss_l2_devict",

  "e_dc_is_miss", "e_dc_is_late", "e_dc_is_resume", "e_dc_is_busy_cnt", "e_dc_is_busy",

  "e_l2_ic_cnt", "e_l2_dfetch_cnt", "e_l2_devict_cnt",
  "e_l2_ic", "e_l2_dfetch", "e_l2_devict",

  "e_l2_ic_miss_cnt", "e_l2_dfetch_miss_cnt", "e_l2_devict_miss_cnt",
  "e_l2_ic_miss", "e_l2_dfetch_miss", "e_l2_devict_miss",

  "e_l2_ic_dma", "e_l2_dfetch_dma", "e_l2_devict_dma",

  "e_wdma_ic_cnt", "e_rdma_ic_cnt", "e_wdma_ic", "e_rdma_ic", "e_dma_ic",
  "e_wdma_dfetch_cnt", "e_rdma_dfetch_cnt", "e_wdma_dfetch", "e_rdma_dfetch", "e_dma_dfetch",
  "e_wdma_devict_cnt", "e_wdma_devict",
*/
};

const char* samples[] = {
  "mcycle", "minstret"
};

// Globals
std::queue<int> getchar_queue;
std::bitset<BP_NCPUS> done_vec;
bool run = true;
#ifdef FPGA
volatile int32_t *buf;
#endif

inline uint64_t get_counter_64(bsg_zynq_pl *zpl, uint64_t addr) {
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

void *monitor(void *vargp) {
  char c;
  while(run) {
    c = getchar();
    if(c != -1)
      getchar_queue.push(c);
  }
  bsg_pr_info("Exiting from pthread\n");

  return NULL;
}

struct threadArgs {
    bsg_zynq_pl* zpl;
    char* nbf_filename;
};

void *device_poll(void *vargp) {
  bsg_zynq_pl *zpl = ((struct threadArgs*)vargp)->zpl;
  char* nbf_filename = ((struct threadArgs*)vargp)->nbf_filename;

#ifdef PK
  printf("Running with HTIF\n");
#ifdef FPGA
  void* dram = (void*) buf;
#else
  bsg_mem_dma::Memory* mem = bsg_mem_dma::bsg_mem_dma_get_memory(0);
  void* dram = (void*) mem;
#endif
  htif_t* htif = new htif_t(zpl, dram);
  int htif_cntr = 0;
#endif

  //open binary file for dumping samples
  char filename[100];
  if(strrchr(nbf_filename, '/') != NULL)
    strcpy(filename, 1 + strrchr(nbf_filename, '/'));
  else
    strcpy(filename, nbf_filename);
  *strrchr(filename, '.') = '\0';
  strcat(filename, ".stall");
  ofstream file(filename, ios::binary);

  uint32_t pc;
  uint8_t stall;
  while (1) {
    //zpl->axil_poll();

#ifdef PK
    htif_cntr++;
    if(htif_cntr % HTIF_INTERVAL == 0) {
      if(htif->step()) {
        break;
      }
    }
#endif

    // keep reading as long as there is data
    if (zpl->axil_read(GP0_RD_PL2PS_FIFO_0_CTRS) != 0) {
      decode_bp_output(zpl, zpl->axil_read(GP0_RD_PL2PS_FIFO_0_DATA));
    }
    // break loop when all cores done
    if (done_vec.all()) {
      break;
    }

    // drain sample data from FIFOs
    int cnt = zpl->axil_read(GP0_RD_PL2PS_FIFO_1_CTRS);
    if(cnt != 0) {
      for(int i = 0; i < cnt; i++) {
/*
        uint32x2_t data = zpl->axil_2read(GP0_RD_PL2PS_FIFO_1_DATA);
        pc = data[0];
        stall = ((data[1] & 0x1) << 7) | (data[1] >> 1);
*/
        pc = zpl->axil_read(GP0_RD_PL2PS_FIFO_1_DATA);
        uint32_t data = zpl->axil_read(GP0_RD_PL2PS_FIFO_2_DATA);
        stall = ((data & 0x1) << 7) | (data >> 1);

        file.write((char*)&pc, sizeof(pc));
        file.write((char*)&stall, sizeof(stall));
      }
    }
  }
  run = false;
  file.close();
  bsg_pr_info("Exiting from pthread\n");

  return NULL;
}

void *sample(void *vargp) {
  bsg_zynq_pl *zpl = ((struct threadArgs*)vargp)->zpl;
  char* nbf_filename = ((struct threadArgs*)vargp)->nbf_filename;;

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

  struct timespec tim;
  tim.tv_sec = 0;
  tim.tv_nsec = 100000000L;
  if(file.is_open()) {
    while(run) {
      nanosleep(&tim, NULL);
      for(int i=0; i<sizeof(samples)/sizeof(samples[0]); i++) {
        unsigned long long sample = get_counter_64(zpl,GP0_RD_COUNTERS + 8*sampleIdx[i]);
        file.write((char*)&sample, sizeof(sample));
      }
    }
    file.close();
  }
  else printf("Cannot open sample file: %s\n", filename);

  bsg_pr_info("Exiting from pthread\n");
  return NULL;
}

#ifdef VERILATOR
int main(int argc, char **argv) {
#elif FPGA
int main(int argc, char **argv) {
#else
extern "C" int cosim_main(char *argstr) {
  int argc = get_argc(argstr);
  char *argv[argc];
  get_argv(argstr, argc, argv);
#endif
  // this ensures that even with tee, the output is line buffered
  // so that we can see what is happening in real time

  setvbuf(stdout, NULL, _IOLBF, 0);

  bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);

  long allocated_dram = DRAM_ALLOCATE_SIZE;

  int32_t val;
  bsg_pr_info("ps.cpp: reading four base registers\n");
  bsg_pr_info("ps.cpp: reset(lo)=%d, bitbang=%d, dram_init=%d, dram_base=%d\n",
              zpl->axil_read(GP0_RD_CSR_SYS_RESETN),
              zpl->axil_read(GP0_RD_CSR_TAG_BITBANG),
              zpl->axil_read(GP0_RD_CSR_DRAM_INITED),
              val = zpl->axil_read(GP0_RD_CSR_DRAM_BASE));

  bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, 0xDEADBEEF, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == (0xDEADBEEF)));
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, val, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == (val)));

  bsg_pr_info("ps.cpp: successfully wrote and read registers in bsg_zynq_shell "
              "(verified ARM GP0 connection)\n");

  bsg_tag_bitbang *btb = new bsg_tag_bitbang(zpl, GP0_WR_CSR_TAG_BITBANG, TAG_NUM_CLIENTS, TAG_MAX_LEN);
  bsg_tag_client *pl_reset_client = new bsg_tag_client(TAG_CLIENT_PL_RESET_ID, TAG_CLIENT_PL_RESET_WIDTH);
  bsg_tag_client *pl_cnten_client = new bsg_tag_client(TAG_CLIENT_PL_CNTEN_ID, TAG_CLIENT_PL_CNTEN_WIDTH);
  bsg_tag_client *wd_reset_client = new bsg_tag_client(TAG_CLIENT_WD_RESET_ID, TAG_CLIENT_WD_RESET_WIDTH);

  // Reset the bsg tag master
  btb->reset_master();
  // Reset bsg client0
  btb->reset_client(pl_reset_client);
  // Reset bsg client1
  btb->reset_client(wd_reset_client);
  // Set bsg client0 to 1 (assert BP reset)
  btb->set_client(pl_reset_client, 0x1);
  // Set bsg client1 to 1 (assert BP counter en)
  btb->set_client(pl_cnten_client, 0x1);
  // Set bsg client2 to 1 (assert WD reset)
  btb->set_client(wd_reset_client, 0x1);
  // Set bsg client0 to 0 (deassert BP reset)
  btb->set_client(pl_reset_client, 0x0);

  // We need some additional toggles for data to propagate through
  btb->idle(50);
  // Deassert the active-low system reset as we finish initializing the whole system
  zpl->axil_write(GP0_RD_CSR_SYS_RESETN, 0x1, 0xF);

#ifdef FPGA
  unsigned long phys_ptr;
  if (zpl->axil_read(GP0_RD_CSR_DRAM_INITED) == 0) {
    bsg_pr_info(
        "ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate "
        "dram with size %ld\n",
        allocated_dram);
    buf = (volatile int32_t *)zpl->allocate_dram(allocated_dram, &phys_ptr);
    bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
    zpl->axil_write(GP0_WR_CSR_DRAM_BASE, phys_ptr, 0xf);
    assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == (phys_ptr)));
    bsg_pr_info("ps.cpp: wrote and verified base register\n");
    zpl->axil_write(GP0_WR_CSR_DRAM_INITED, 0x1, 0xf);
    assert(zpl->axil_read(GP0_RD_CSR_DRAM_INITED) == 1);
  } else
    bsg_pr_info("ps.cpp: reusing dram base pointer %x\n",
                zpl->axil_read(GP0_RD_CSR_DRAM_BASE));

  int outer = 1024 / 4;
  long num_times = allocated_dram / 32768;
#else
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, 0x0, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == 0x0));
  bsg_pr_info("ps.cpp: wrote and verified base register\n");

  int outer = 64 / 4;
  long num_times = 64;
#endif

  if (argc == 1) {
    bsg_pr_warn(
        "No nbf file specified, sleeping for 2^31 seconds (this will hold "
        "onto allocated DRAM)\n");
    sleep(1U << 31);
    delete zpl;
    return -1;
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
  zpl->axil_write(GP1_CSR_BASE_ADDR + 0x304000, y + 1, 0xf);

  bsg_pr_info("ps.cpp: reading mtimecmp\n");
  assert(zpl->axil_read(GP1_CSR_BASE_ADDR + 0x304000) == y + 1);

#ifdef DRAM_TEST

  bsg_pr_info(
      "ps.cpp: attempting to write L2 %ld times over %ld MB (testing ARM GP1 "
      "and HP0 connections)\n",
      num_times * outer, (allocated_dram) >> 20);
  zpl->axil_write(GP1_DRAM_BASE_ADDR, 0x12345678, 0xf);

  for (int s = 0; s < outer; s++)
    for (int t = 0; t < num_times; t++) {
      zpl->axil_write(GP1_DRAM_BASE_ADDR + 32768 * t + s * 4, 0x1ADACACA + t + s,
                      0xf);
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

#ifdef FPGA
  // Must zero DRAM for FPGA Linux boot, because opensbi payload mode
  //   obliterates the section names of the payload (Linux)
  if (ZERO_DRAM) {
    bsg_pr_info("ps.cpp: Zero-ing DRAM (%d bytes)\n", DRAM_ALLOCATE_SIZE);
    for (int i = 0; i < DRAM_ALLOCATE_SIZE; i+=4) {
      if (i % (1024*1024) == 0) bsg_pr_info("ps.cpp: zero-d %d MB\n", i/(1024*1024));
      zpl->axil_write(gp1_addr_base + i, 0x0, 0xf);
    }
  }
#endif

  bsg_pr_info("ps.cpp: clearing pl to ps fifo\n");
  while(zpl->axil_read(GP0_RD_PL2PS_FIFO_0_CTRS) != 0) {
    zpl->axil_read(GP0_RD_PL2PS_FIFO_0_DATA);
  }

  bsg_pr_info("ps.cpp: beginning nbf load\n");
  nbf_load(zpl, argv[1]);
  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
  unsigned long long mtime_start = get_counter_64(zpl, GP1_CSR_BASE_ADDR + 0x30bff8);
  bsg_pr_dbg_ps("ps.cpp: finished nbf load\n");

  // Set bsg client2 to 0 (deassert WD reset)
  btb->set_client(wd_reset_client, 0x0);
  bsg_pr_info("ps.cpp: starting watchdog\n");
  // We need some additional toggles for data to propagate through
  btb->idle(50);

  bsg_pr_info("ps.cpp: Setting DRAM latency\n");
  zpl->axil_write(GP0_WR_CSR_DRAM_LATENCY, DRAM_LATENCY, 0xf);

  bsg_pr_info("ps.cpp: Setting sampling interval\n");
  zpl->axil_write(GP0_WR_CSR_SAMPLE_INTRVL, (SAMPLE_INTERVAL - 1), 0xf);

  bsg_pr_info("ps.cpp: Asserting clock gate enable\n");
  zpl->axil_write(GP0_WR_CSR_GATE_EN, 0x1, 0xf);

  bsg_pr_info("ps.cpp: Unfreezing BlackParrot\n");
  zpl->axil_write(GP1_CSR_BASE_ADDR + 0x200008, 0x0, 0xf);

  pthread_t monitor_id, poll_id;

  //bsg_pr_info("ps.cpp: Starting scan thread\n");
  //pthread_create(&monitor_id, NULL, monitor, NULL);

  struct threadArgs* args = (struct threadArgs*)malloc(sizeof(struct threadArgs));
  args->zpl = zpl;
  args->nbf_filename = argv[1];

  bsg_pr_info("ps.cpp: Starting i/o polling thread\n");
  pthread_create(&poll_id, NULL, device_poll, (void *)args);

  bsg_pr_info("ps.cpp: waiting for i/o packet\n");
  pthread_join(poll_id, NULL);
  bsg_pr_info("ps.cpp: end polling i/o\n");

  bsg_pr_info("ps.cpp: Deasserting clock gate enable\n");
  zpl->axil_write(GP0_WR_CSR_GATE_EN, 0x0, 0xf);

  // Set bsg client1 to 0 (deassert BP counter en)
  btb->set_client(pl_cnten_client, 0x0);
  // Set bsg client2 to 1 (assert WD reset)
  btb->set_client(wd_reset_client, 0x1);
  bsg_pr_info("ps.cpp: stopping watchdog\n");
  // We need some additional toggles for data to propagate through
  btb->idle(50);

  unsigned long long mcycle_stop = get_counter_64(zpl, GP0_RD_MCYCLE);
  unsigned long long minstret_stop = get_counter_64(zpl, GP0_RD_MINSTRET);
  unsigned long long mtime_stop = get_counter_64(zpl, GP1_CSR_BASE_ADDR + 0x30bff8);
  unsigned long long mtime_delta = mtime_stop - mtime_start;

  clock_gettime(CLOCK_MONOTONIC, &end);
  setlocale(LC_NUMERIC, "");
  bsg_pr_info("ps.cpp: mcycle (instructions retired): %'16llu (%16llx)\n",
              mcycle_stop, mcycle_stop);
  bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
              minstret_stop, minstret_stop);
  bsg_pr_info("ps.cpp: MTIME start:                     %'16llu (%16llx)\n",
              mtime_start, mtime_start);
  bsg_pr_info("ps.cpp: MTIME stop:                      %'16llu (%16llx)\n",
              mtime_stop, mtime_stop);
  bsg_pr_info("ps.cpp: MTIME delta (=1/8 BP cycles):    %'16llu (%16llx)\n",
              mtime_delta, mtime_delta);
  bsg_pr_info("ps.cpp: IPC        :                     %'16f\n",
              ((double)minstret_stop) / ((double)(mcycle_stop)));
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
              "%-8.8d%-8.8d%-8.8d%-8.8d\n",
              zpl->axil_read(GP0_RD_MEM_PROF_3),
              zpl->axil_read(GP0_RD_MEM_PROF_2),
              zpl->axil_read(GP0_RD_MEM_PROF_1),
              zpl->axil_read(GP0_RD_MEM_PROF_0));

  report(zpl, argv[1]);
  btb->idle(500000);
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
    zpl->axil_write(GP0_WR_CSR_DRAM_INITED, 0x0, 0xf);
  }
#endif

  zpl->done();
  delete zpl;
  return 0;
}

std::uint32_t rotl(std::uint32_t v, std::int32_t shift) {
  std::int32_t s =  shift>=0? shift%32 : -((-shift)%32);
  return (v<<s) | (v>>(32-s));
}

void nbf_load(bsg_zynq_pl *zpl, char *nbf_filename) {
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
    return;
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

bool decode_bp_output(bsg_zynq_pl *zpl, long data) {
  long rd_wr = data >> 31;
  long address = (data >> 8) & 0x7FFFFF;
  char print_data = data & 0xFF;
  char core = (address-0x102000) >> 3;
  // write from BP
  if (rd_wr) {
    if (address == 0x101000) {
      printf("%c", print_data);
      fflush(stdout);
    } else if (address == 0x101004) {
      return false;
    } else if (address >= 0x102000 && address < 0x103000) {
      done_vec[core] = true;
      if (print_data == 0) {
        bsg_pr_info("CORE[%d] PASS\n", core);
      } else {
        bsg_pr_info("CORE[%d] FAIL\n", core);
      }
    } else if (address == 0x103000) {
      bsg_pr_dbg_ps("ps.cpp: Watchdog tick\n");
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
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA, -1, 0xf);
      } else {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA, getchar_queue.front(), 0xf);
        getchar_queue.pop();
      }
    }
    // parameter ROM, only partially implemented
    else if (address >= 0x120000 && address <= 0x120128) {
      bsg_pr_dbg_ps("ps.cpp: PARAM ROM read from (%lx)\n", address);
      int offset = address - 0x120000;
      // CC_X_DIM, return number of cores
      if (offset == 0x0) {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA, BP_NCPUS, 0xf);
      }
      // CC_Y_DIM, just return 1 so X*Y == number of cores
      else if (offset == 0x4) {
        zpl->axil_write(GP0_WR_PS2PL_FIFO_DATA, 1, 0xf);
      }
    }
    // if not implemented, print error
    else {
      bsg_pr_err("ps.cpp: Errant read from (%lx)\n", address);
      sleep(60);
      return false;
    }
  }

  return true;
}

void report(bsg_zynq_pl *zpl, char* nbf_filename) {

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
      file << get_counter_64(zpl, GP0_RD_COUNTERS + i*8) << "\n";
    }
    file.close();
  }
  else printf("Cannot open report file: %s\n", filename);
}
