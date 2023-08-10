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
#include <cmath>

#include "bsg_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_tag_bitbang.h"
#include "bsg_argparse.h"

#include "bsg_manycore_machine.h"

#ifndef DRAM_ALLOCATE_SIZE_MB
#define DRAM_ALLOCATE_SIZE_MB 128
#endif
#define DRAM_ALLOCATE_SIZE (DRAM_ALLOCATE_SIZE_MB * 1024 * 1024)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

// GP0 Read Memory Map
#define GP0_RD_CSR_SYS_RESETN    (GP0_ADDR_BASE                   )
#define GP0_RD_CSR_TAG_BITBANG   (GP0_RD_CSR_SYS_RESETN    + 0x4  )
#define GP0_RD_CSR_DRAM_INITED   (GP0_RD_CSR_TAG_BITBANG   + 0x4  )
#define GP0_RD_CSR_DRAM_BASE     (GP0_RD_CSR_DRAM_INITED   + 0x4  )
#define GP0_RD_CSR_ROM_ADDR      (GP0_RD_CSR_DRAM_BASE     + 0x4  )
#define GP0_RD_MC_REQ_FIFO_DATA  (GP0_RD_CSR_ROM_ADDR      + 0x4  )
#define GP0_RD_MC_RSP_FIFO_DATA  (GP0_RD_MC_REQ_FIFO_DATA  + 0x4  )
#define GP0_RD_MC_REQ_FIFO_CTR   (GP0_RD_MC_RSP_FIFO_DATA  + 0x4  )
#define GP0_RD_MC_RSP_FIFO_CTR   (GP0_RD_MC_REQ_FIFO_CTR   + 0x4  )
#define GP0_RD_EP_REQ_FIFO_CTR   (GP0_RD_MC_RSP_FIFO_CTR   + 0x4  )
#define GP0_RD_EP_RSP_FIFO_CTR   (GP0_RD_EP_REQ_FIFO_CTR   + 0x4  )
#define GP0_RD_CREDIT_COUNT      (GP0_RD_EP_RSP_FIFO_CTR   + 0x4  )
#define GP0_RD_ROM_DATA          (GP0_RD_CREDIT_COUNT      + 0x4  )

// GP0 Write Memory Map
#define GP0_WR_CSR_SYS_RESETN     GP0_RD_CSR_SYS_RESETN
#define GP0_WR_CSR_TAG_BITBANG    GP0_RD_CSR_TAG_BITBANG
#define GP0_WR_CSR_DRAM_INITED    GP0_RD_CSR_DRAM_INITED
#define GP0_WR_CSR_DRAM_BASE      GP0_RD_CSR_DRAM_BASE
#define GP0_WR_CSR_ROM_ADDR       GP0_RD_CSR_ROM_ADDR
#define GP0_WR_EP_REQ_FIFO_DATA  (GP0_WR_CSR_ROM_ADDR + 0x4)
#define GP0_WR_EP_RSP_FIFO_DATA  (GP0_WR_EP_REQ_FIFO_DATA + 0x4)

#define TAG_NUM_CLIENTS 16
#define TAG_MAX_LEN 1
#define TAG_CLIENT_MC_RESET_ID 0
#define TAG_CLIENT_MC_RESET_WIDTH 1

#include "bsg_manycore_packet.h"

void configure_blackparrot(bsg_zynq_pl *zpl);

void nbf_load(bsg_zynq_pl *zpl, char *filename);

inline void send_mc_request_packet(bsg_zynq_pl *zpl, hb_mc_request_packet_t *packet) {
  int axil_len = sizeof(hb_mc_request_packet_t) / 4;

  uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
  for (int i = 0; i < axil_len; i++) {
    while (!zpl->axil_read(GP0_RD_EP_REQ_FIFO_CTR));
    zpl->axil_write(GP0_WR_EP_REQ_FIFO_DATA, pkt_data[i], 0xf);
  }
}

inline void recv_mc_response_packet(bsg_zynq_pl *zpl, hb_mc_response_packet_t *packet) {
  int axil_len = sizeof(hb_mc_response_packet_t) / 4;

  uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
  for (int i = 0; i < axil_len; i++) {
    while (!zpl->axil_read(GP0_RD_MC_RSP_FIFO_CTR));
    pkt_data[i] = zpl->axil_read(GP0_RD_MC_RSP_FIFO_DATA);
  }
}

inline void recv_mc_request_packet(bsg_zynq_pl *zpl, hb_mc_request_packet_t *packet) {
  int axil_len = sizeof(hb_mc_request_packet_t) / 4;

  uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
  for (int i = 0; i < axil_len; i++) {
    while (!zpl->axil_read(GP0_RD_MC_REQ_FIFO_CTR));
    pkt_data[i] = zpl->axil_read(GP0_RD_MC_REQ_FIFO_DATA);
  }
}

inline void send_mc_response_packet(bsg_zynq_pl *zpl, hb_mc_response_packet_t *packet) {
  int axil_len = sizeof(hb_mc_response_packet_t) / 4;

  uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
  for (int i = 0; i < axil_len; i++) {
    while (!zpl->axil_read(GP0_RD_EP_RSP_FIFO_CTR));
    zpl->axil_write(GP0_WR_EP_RSP_FIFO_DATA, pkt_data[i], 0xf);
  }
}

inline void send_mc_write(bsg_zynq_pl *zpl, uint8_t x, uint8_t y, uint32_t epa, int32_t data) {
  hb_mc_request_packet_t req_pkt;

  req_pkt.op_v2   = 2; // SW
  req_pkt.reg_id  = 0xff; // unused
  req_pkt.payload = data;
  req_pkt.x_src   = BSG_MANYCORE_MACHINE_LOADER_COORD_X;
  req_pkt.y_src   = BSG_MANYCORE_MACHINE_LOADER_COORD_Y;
  req_pkt.x_dst   = x;
  req_pkt.y_dst   = y;
  req_pkt.addr    = epa >> 2;

  bsg_pr_dbg_ps("Writing: [%x]<-%x\n", req_pkt.addr, req_pkt.payload);
  send_mc_request_packet(zpl, &req_pkt);
}

inline int32_t send_mc_read(bsg_zynq_pl *zpl, uint8_t x, uint8_t y, uint32_t epa) {
  hb_mc_request_packet_t req_pkt;

  req_pkt.op_v2   = 0; // LD
  req_pkt.reg_id  = 0xff; // unused
  req_pkt.payload = 0; // Ignore payload
  req_pkt.x_src   = BSG_MANYCORE_MACHINE_LOADER_COORD_X;
  req_pkt.y_src   = BSG_MANYCORE_MACHINE_LOADER_COORD_Y;
  req_pkt.x_dst   = x;
  req_pkt.y_dst   = y;
  req_pkt.addr    = epa >> 2;

  send_mc_request_packet(zpl, &req_pkt);

  hb_mc_response_packet_t resp_pkt;
  recv_mc_response_packet(zpl, &resp_pkt);

  return resp_pkt.data;
}

std::queue<int> getchar_queue;
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

void *device_manycore_poll(void *vargp) {
  bsg_zynq_pl *zpl = (bsg_zynq_pl *)vargp;

  int mc_finished = 0;
  while (mc_finished != NUM_MC_FINISH) {
    bsg_pr_dbg_ps("Waiting for incoming request packet\n");
    hb_mc_request_packet_t mc_pkt;
    recv_mc_request_packet(zpl, &mc_pkt);
    bsg_pr_dbg_ps("Request packet signaled\n");
    int mc_epa = (mc_pkt.addr << 2) & 0xffff; // Trim to 16b EPA
    int mc_data = mc_pkt.payload;
    bsg_pr_dbg_ps("Request packet [%x] = %x\n", mc_epa, mc_data);
    if (mc_epa == 0xeadc || mc_epa == 0xeee0) {
        printf("%c", mc_data & 0xff);
        fflush(stdout);
    } else if (mc_epa == 0xead0) {
      bsg_pr_info("MC finish packet received %d\n", ++mc_finished);
    } else {
      bsg_pr_info("Errant request packet: %x %x\n", mc_epa, mc_data);
    }
  }

  bsg_pr_info("Exiting from pthread\n");
  return NULL;
}

void *device_blackparrot_poll(void *vargp) {
  bsg_zynq_pl *zpl = (bsg_zynq_pl *)vargp;

  int bp_finished = 0;
  while (bp_finished != NUM_BP_FINISH) {
    bsg_pr_dbg_ps("Waiting for incoming request packet\n");
    hb_mc_request_packet_t mc_pkt;
    hb_mc_response_packet_t ep_rsp;
    recv_mc_request_packet(zpl, &mc_pkt);
    bsg_pr_dbg_ps("Request packet signaled\n");
    int mc_epa = (mc_pkt.addr << 2) & 0xffff; // Trim to 16b EPA
    int mc_data = mc_pkt.payload;
    bsg_pr_dbg_ps("Request packet [%x] = %x\n", mc_epa, mc_data);
    if (mc_epa == 0x0000) {
      hb_mc_response_packet_fill(&ep_rsp, &mc_pkt);
      if (getchar_queue.empty()) {
        ep_rsp.data = -1;
      } else {
        ep_rsp.data = getchar_queue.front();
        getchar_queue.pop();
      }
      send_mc_response_packet(zpl, &ep_rsp);
    } else if (mc_epa == 0x1000) {
        printf("%c", mc_data & 0xff);
        fflush(stdout);
    } else if (mc_epa == 0x2000) {
      bsg_pr_info("BP finish packet received %d\n", ++bp_finished);
    } else if (mc_epa >= 0x3000 && mc_epa < 0x4000) {
      int rom_idx = (mc_epa & 0xff) >> 2;
      zpl->axil_write(GP0_WR_CSR_ROM_ADDR, rom_idx, 0xf);
      hb_mc_response_packet_fill(&ep_rsp, &mc_pkt);
      ep_rsp.data = zpl->axil_read(GP0_RD_ROM_DATA);
      send_mc_response_packet(zpl, &ep_rsp);
    } else {
      bsg_pr_info("Errant request packet: %x %x\n", mc_epa, mc_data);
    }
  }

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

  pthread_t thread_id;

  bsg_pr_info("ps.cpp: reading three base registers\n");
  bsg_pr_info("ps.cpp: dram_base=%lx\n", zpl->axil_read(0x00 + gp0_addr_base));

  long val;
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, 0xDEADBEEF, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == (0xDEADBEEF)));
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, val, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == val));

  bsg_tag_bitbang *btb = new bsg_tag_bitbang(zpl, GP0_WR_CSR_TAG_BITBANG, TAG_NUM_CLIENTS, TAG_MAX_LEN);
  bsg_tag_client *mc_reset_client = new bsg_tag_client(TAG_CLIENT_MC_RESET_ID, TAG_CLIENT_MC_RESET_WIDTH);

  // Reset the bsg tag master
  btb->reset_master();
  // Reset bsg client0
  btb->reset_client(mc_reset_client);
  // Set bsg client0 to 1 (assert BP reset)
  btb->set_client(mc_reset_client, 0x1);
  // Set bsg client0 to 0 (deassert BP reset)
  btb->set_client(mc_reset_client, 0x0);

  // We need some additional toggles for data to propagate through
  btb->idle(50);
  // Deassert the active-low system reset as we finish initializing the whole system
  zpl->axil_write(GP0_WR_CSR_SYS_RESETN, 0x1, 0xF);

#ifdef FPGA
  unsigned long phys_ptr;
  volatile int32_t *buf;
  long allocated_dram = DRAM_ALLOCATE_SIZE;
  bsg_pr_info("ps.cpp: calling allocate dram with size %ld\n", allocated_dram);
  buf = (volatile int32_t *)zpl->allocate_dram(allocated_dram, &phys_ptr);
  bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, phys_ptr, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == phys_ptr));
  bsg_pr_info("ps.cpp: wrote and verified base register\n");

#else
  zpl->axil_write(GP0_WR_CSR_DRAM_BASE, 0x1234, 0xf);
  assert((zpl->axil_read(GP0_RD_CSR_DRAM_BASE) == 0x1234));
  bsg_pr_info("ps.cpp: wrote and verified base register\n");
#endif

  if (argc == 1) {
    bsg_pr_warn(
        "No nbf file specified, sleeping for 2^31 seconds (this will hold "
        "onto allocated DRAM)\n");
    sleep(1U << 31);
    delete zpl;
    return -1;
  }

  nbf_load(zpl, argv[1]);

  bsg_pr_info("ps.cpp: Starting scan thread\n");
  pthread_create(&thread_id, NULL, monitor, NULL);
  bsg_pr_info("ps.cpp: Starting MC i/o polling thread\n");
  pthread_create(&thread_id, NULL, device_manycore_poll, (void *)zpl);
  bsg_pr_info("ps.cpp: waiting for manycore to finish\n");
  pthread_join(thread_id, NULL);

  configure_blackparrot(zpl);

  bsg_pr_info("ps.cpp: Starting BP i/o polling thread\n");
  pthread_create(&thread_id, NULL, device_blackparrot_poll, (void *)zpl);
  bsg_pr_info("ps.cpp: waiting for BlackParrot to finish\n");
  pthread_join(thread_id, NULL);

  zpl->done();
  delete zpl;
  return 0;
}

// Configure BlackParrot
//
void configure_blackparrot(bsg_zynq_pl *zpl) {
  // From Makefile
  int num_tiles_x            = BSG_MANYCORE_POD_TILES_X;
  int num_tiles_y            = BSG_MANYCORE_POD_TILES_Y;
  int x_cord_width           = BSG_MANYCORE_NOC_COORD_X_WIDTH;
  int y_cord_width           = BSG_MANYCORE_NOC_COORD_Y_WIDTH;
  int x_subcord_width        = (int) std::log2(num_tiles_x);
  int y_subcord_width        = (int) std::log2(num_tiles_y);
  int pod_x_cord_width       = x_cord_width - x_subcord_width;
  int pod_y_cord_width       = y_cord_width - y_subcord_width;
  int bp_y_tile              = (3 << y_subcord_width) | 0;
  int bp_x_tile              = (1 << x_subcord_width) | 0;
  int bp_dram_pod_cord       = (1 << pod_y_cord_width) | 1;
  int bp_host_cord           = (1 << (y_cord_width+x_subcord_width));
  int bp_cfg_base_epa        = 0x2000;
  int bp_cfg_reg_unused      = bp_cfg_base_epa | 0x0000;
  int bp_cfg_reg_freeze      = bp_cfg_base_epa | 0x0008;
  int bp_cfg_reg_npc         = bp_cfg_base_epa | 0x0010;
  int bp_cfg_reg_hio_mask    = bp_cfg_base_epa | 0x0038;
  int bp_cfg_reg_icache_id   = bp_cfg_base_epa | 0x0200;
  int bp_cfg_reg_icache_mode = bp_cfg_base_epa | 0x0208;
  int bp_cfg_reg_dcache_id   = bp_cfg_base_epa | 0x0400;
  int bp_cfg_reg_dcache_mode = bp_cfg_base_epa | 0x0408;

  int bp_bridge_base_epa        = 0x4000;
  int bp_bridge_reg_dram_offset = bp_bridge_base_epa | 0x0000;
  int bp_bridge_reg_dram_pod    = bp_bridge_base_epa | 0x0008;
  int bp_bridge_reg_my_cord     = bp_bridge_base_epa | 0x0010;
  int bp_bridge_reg_host_cord   = bp_bridge_base_epa | 0x0018;
  int bp_bridge_reg_scratchpad  = bp_bridge_base_epa | 0x1000;

  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_cfg_reg_freeze, 1);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_cfg_reg_npc, 0x80000000);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_cfg_reg_icache_mode, 1);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_cfg_reg_dcache_mode, 1);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_bridge_reg_dram_offset, 0x2000000);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_bridge_reg_dram_pod, bp_dram_pod_cord);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_bridge_reg_my_cord, 0);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_bridge_reg_host_cord, bp_host_cord);
  send_mc_write(zpl, bp_x_tile, bp_y_tile, bp_cfg_reg_freeze, 0);
}

void nbf_load(bsg_zynq_pl *zpl, char *nbf_filename) {
  string nbf_command;
  string tmp;
  string delimiter = "_";

  long long int nbf[4];
  int pos = 0;
  long unsigned int base_addr;
  int data;
  ifstream nbf_file(nbf_filename);

  if (!nbf_file.is_open()) {
    bsg_pr_err("ps.cpp: error opening nbf file.\n");
    delete zpl;
    return;
  }

  bsg_pr_info("Starting NBF load\n");
  int line_count = 0;
  while (getline(nbf_file, nbf_command)) {
    int i = 0;
    while ((pos = nbf_command.find(delimiter)) != std::string::npos) {
      tmp = nbf_command.substr(0, pos);
      nbf[i] = std::stoull(tmp, nullptr, 16);
      nbf_command.erase(0, pos + 1);
      i++;
    }
    nbf[i] = std::stoull(nbf_command, nullptr, 16);

    int x_tile   = nbf[0];
    int y_tile   = nbf[1];
    int epa      = nbf[2]; // word addr
    int nbf_data = nbf[3];

    bool finish = (x_tile == 0xff) && (y_tile == 0xff) && (epa == 0x00000000) && (nbf_data == 0x00000000);
    bool fence  = (x_tile == 0xff) && (y_tile == 0xff) && (epa == 0xffffffff) && (nbf_data == 0xffffffff);

    if (finish) {
      bsg_pr_info("ps.cpp: nbf finish command, line %d\n", line_count);
      continue;
    } else if (fence) {
      bsg_pr_dbg_ps("ps.cpp: nbf fence command (ignoring), line %d\n", line_count);
      bsg_pr_info("Waiting for credit drain\n");
      while(zpl->axil_read(GP0_RD_CREDIT_COUNT) > 0);
      bsg_pr_info("Credits drained\n");
      continue;
    } else {
      send_mc_write(zpl, x_tile, y_tile, epa << 2, nbf_data);

#ifdef VERIFY_NBF

      int32_t verif_data;
     
      bsg_pr_dbg_ps("Querying: %x\n", epa << 2);
      verif_data = send_mc_read(zpl, x_tile, y_tile, epa << 2);

      // Some verification reads are expected to fail e.g. CSRs
      if (req_pkt.payload == resp_pkt.data) {
        bsg_pr_info("Received verification: %x==%x\n", req_pkt.payload, resp_pkt.data);
      } else {
        bsg_pr_info("Failed verification: %x!=%x\n", req_pkt.payload, resp_pkt.data);
      }
#endif
    }
  }
}

