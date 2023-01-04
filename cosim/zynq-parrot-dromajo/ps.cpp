// AM: this is scavenged from vanilla black-parrot-example (ultra96 branch)
// there are differences in headers, changes may not be directly integrable with the master branch (pynq z2)

#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <time.h>
#include <queue>
#include <unistd.h>
#include <bitset>
#include <cstdint>
#include <iostream>
#include "stdlib.h"
#include <string>
#include <vector>
#include <queue>

// contains dromajo ancillary functions and other helper functions 
#include "ps.h"

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

  uint32_t data;
  int mask = 0xf;
  int allocated_dram = DRAM_ALLOCATE_SIZE;
#ifdef FPGA
  unsigned long phys_ptr;
  volatile int *buf;
#endif

  bsg_pr_info("ps.cpp: putting BP into reset\n");
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x0, mask); // BP reset
  bsg_pr_info("ps.cpp: reset(lo)=%d dram_init=%d, dram_base=%x\n",
      zpl->axil_read(get_addr(r_ps2pl_reg)), zpl->axil_read(get_addr(r_ps2pl_reg, 1)), zpl->axil_read(get_addr(r_ps2pl_reg, 2)));

#ifdef FPGA
  data = zpl->axil_read(get_addr(r_ps2pl_reg, 1));
  if (data == 0) {
    bsg_pr_info(
        "ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate "
        "dram with size %d\n",
        allocated_dram);
    buf = (volatile int *)zpl->allocate_dram(allocated_dram, &phys_ptr);
    bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
    zpl->axil_write(get_addr(w_ps2pl_reg, 2), phys_ptr, mask);
    assert((zpl->axil_read(get_addr(r_ps2pl_reg, 2)) == (phys_ptr)));
    bsg_pr_info("ps.cpp: wrote and verified base register\n");
    zpl->axil_write(get_addr(w_ps2pl_reg, 1), 0x1, mask);
    assert(zpl->axil_read(get_addr(r_ps2pl_reg, 1)) == 1);
  } else
    bsg_pr_info("ps.cpp: reusing dram base pointer %x\n",
        zpl->axil_read(get_addr(r_ps2pl_reg, 2)));
#else
  zpl->axil_write(get_addr(w_ps2pl_reg, 2), 0x1, mask);
  assert((zpl->axil_read(get_addr(w_ps2pl_reg, 2)) == 0x1));
  bsg_pr_info("ps.cpp: wrote and verified base register\n");
#endif

  if (argc == 1) {
    bsg_pr_warn(
        "No nbf file specified, sleeping for 2^31 seconds (this will hold "
        "onto allocated DRAM)\n");
    sleep(1 << 31);
    delete zpl;
    exit(0);
  }

  // assert reset, we do it repeatedly just to make sure that enough cycles pass
  bsg_pr_info("ps.cpp: asserting reset to BP\n");
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x0, mask);
  assert((zpl->axil_read(get_addr(r_ps2pl_reg)) == (0)));
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x0, mask);
  assert((zpl->axil_read(get_addr(r_ps2pl_reg)) == (0)));
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x0, mask);
  assert((zpl->axil_read(get_addr(r_ps2pl_reg)) == (0)));
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x0, mask);
  assert((zpl->axil_read(get_addr(r_ps2pl_reg)) == (0)));

  // deassert reset
  bsg_pr_info("ps.cpp: deasserting reset to BP\n");
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x1, mask);
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x1, mask);
  zpl->axil_write(get_addr(w_ps2pl_reg), 0x1, mask);
  bsg_pr_info("Reset asserted and deasserted\n");

  // declarations of data structures for cosimulation
  uint32_t bp_insn, bp_md;
  uint64_t bp_ird_data, bp_ird_addr, bp_frd_data, bp_frd_addr, wdata, bp_mstatus, bp_pc, bp_cause, bp_epc;
  typedef struct {
    bool idep;
    bool fdep;
    bool cdep;
    uint8_t rfaddr;
  } dep;
  dep bp_deps;

  std::queue<uint64_t> ird[32], frd[32], pc, mstatus, cause, epc;
  std::queue<uint32_t> insn;
  std::queue<dep> deps; // TODO eliminate this via dromajo hooks
  bool cosim_status = false;
  bool cosimulation_done = false;
  int watchdog = 0;
  int req_correction = 0;
  int self_destruct = 0;

  // refer to the README file for why disabling gating here is necessary.
  bsg_pr_dbg_ps("ps.cpp: disabling gating for nbf_load\n");
  zpl->axil_write(get_addr(w_ps2pl_reg, 3), 0x0, mask);

  bsg_pr_dbg_ps("ps.cpp: beginning nbf load\n");
  nbf_load(zpl, argv[1]);
  bsg_pr_info("ps.cpp: finished nbf load\n");

  unsigned long long mtime_stop, minstrret_start = zpl->axil_read(get_addr(r_pl2ps_reg));
  unsigned long long minstrret_stop, mtime_start = get_counter_64(zpl, GP1_ADDR_BASE+0x20000000 + 0x30bff8);
  bsg_pr_dbg_ps("minstret_start=0x%llx |  mtime_start=%llu\n", minstrret_start, mtime_start);

  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);

  bsg_pr_dbg_ps("ps.cpp: reallowing gate\n");
  zpl->axil_write(get_addr(w_ps2pl_reg, 3), 0x1, mask);

  bsg_pr_dbg_ps("ps.cpp: unfreezing BP\n");
  zpl->axil_write(GP1_ADDR_BASE+0x20000000 +0x200008, 0x0, mask);

  // debug prints to verify fifo existence; 
  // messes up the subsequent loop, so comment it after testing
  //for(int m=0; m<0x8; m+=1)
  //  for(int l=0; l<0x100; l+=4) {
  //    bsg_pr_info("Round: %d\n", m);
  //    bsg_pr_info("\t0x%x %x\n", l, zpl->axil_read(GP0_ADDR_BASE + l));
  //  }

  // initialize dromajo VM
  dromajo_init(0, 1, 256); // TODO

  bsg_pr_info("ps.cpp: polling i/o\n");
  while (max_insns > 0) {
    bsg_pr_dbg_ps("Head of loop\n");
    // bsg_pr_dbg_ps(" %d %d | ", insn.size(), cause.size());

    //for(int i=0; i<32; i++)
    //  printf("%016llx ", ird[i].size());
    //printf("\n");

#ifndef FPGA
    zpl->axil_poll();
#endif
#ifdef SIM_BACKPRESSURE_ENABLE
    if (!(rand() % SIM_BACKPRESSURE_CHANCE))
      for (int i = 0; i < SIM_BACKPRESSURE_LENGTH; i++) {
        zpl->tick();
      }
#endif

    // pl_to_ps communication
    data = zpl->axil_read(get_addr(r_pl2ps_cnt));
    if (data != 0) {
      bsg_pr_dbg_ps("pl_to_ps not empty! cnt %x |", data);
      data = zpl->axil_read(get_addr(r_pl2ps));
      bsg_pr_dbg_ps("data %x\n", data);
      cosimulation_done |= decode_bp_output(zpl, data);
    } 
    if (cosimulation_done) {
      // TODO at this point, sum(size(pl_ps_fifo+async_cmt_fifo+sync_cmt_fifo)) commits will be dropped!!
      bsg_pr_info("ps.cpp: cosimulation complete; either exiting gracefully or waiting for dromajo to catch up\n");
      self_destruct++; //TODO this is a bad solution
      //break;
    }
    if(self_destruct == 0xfff)
      break;

    // commit_fifo
    data = zpl->axil_read(get_addr(r_pl2ps_cnt, 1));
    if (data != 0) {
      max_insns--;

      bp_insn = zpl->axil_read(get_addr(r_pl2ps, 1));
      insn.push(bp_insn);

      uint32_t bp_md = zpl->axil_read(get_addr(r_pl2ps, 2));
      bp_deps = {.idep = (bool)(bp_md & 1), .fdep = (bool)(bp_md & 2), .cdep = (bool)(bp_md & 4)};
      if(bp_deps.cdep)
        for(int k=0; k<5; k++)
          bsg_pr_dbg_ps("##############\n");
      bp_deps.rfaddr = (bp_md & 0xf8) >> 3;
      deps.push(bp_deps);

      bp_pc = ((uint64_t)zpl->axil_read(get_addr(r_pl2ps, 4)) << 32) | (uint32_t)zpl->axil_read(get_addr(r_pl2ps, 3));
      pc.push(bp_pc);

      bp_mstatus = ((uint64_t)zpl->axil_read(get_addr(r_pl2ps, 6)) << 32) | (uint32_t)zpl->axil_read(get_addr(r_pl2ps, 5));
      mstatus.push(bp_mstatus);

      bsg_pr_dbg_ps("ps.cpp: cmt_fifo: md %02x | insn %08x | pc %016x | mstat %016x\n", bp_md, bp_insn, bp_pc, bp_mstatus);
    } else bsg_pr_dbg_ps("cmt_fifo empty\n");

    // trap data
    if (zpl->axil_read(get_addr(r_pl2ps_cnt, 13))) {
      bp_cause = ((uint64_t)zpl->axil_read(get_addr(r_pl2ps, 14)) << 32) | (uint32_t)zpl->axil_read(get_addr(r_pl2ps, 13));
      bp_epc = ((uint64_t)zpl->axil_read(get_addr(r_pl2ps, 16)) << 32) | (uint32_t)zpl->axil_read(get_addr(r_pl2ps, 15));
      if((bp_cause & 0xFFFFFFF) != 0xFFFFFFF) {
        bsg_pr_info("ps.cpp: cause: %016llx\n", bp_cause); 
        bsg_pr_dbg_ps("ps.cpp epc = 0x%016llx\n", bp_epc);
        cause.push(bp_cause);
        epc.push(bp_epc);
      }
    } else {
      bsg_pr_dbg_ps("Cause empty\n");
    }

    // IRF data
    while(1)
      if (zpl->axil_read(get_addr(r_pl2ps_cnt, 7))) {
        bp_ird_addr = zpl->axil_read(get_addr(r_pl2ps, 7));
        bp_ird_data = ((uint64_t)zpl->axil_read(get_addr(r_pl2ps, 9)) << 32) | (uint32_t)zpl->axil_read(get_addr(r_pl2ps, 8));

        assert(bp_ird_addr<32);
        ird[bp_ird_addr].push(bp_ird_data);
        bsg_pr_dbg_ps("ps.cpp: IRF[%d] = %016llx\n", bp_ird_addr, bp_ird_data);
      } else {
        bsg_pr_dbg_ps("IRF empty\n");
        break;
      }

    // FRF data
    while(1)
      if (zpl->axil_read(get_addr(r_pl2ps_cnt, 11))) {
        bp_frd_addr = zpl->axil_read(get_addr(r_pl2ps, 10));
        bp_frd_data = ((uint64_t)zpl->axil_read(get_addr(r_pl2ps, 12)) << 32) | (uint32_t)zpl->axil_read(get_addr(r_pl2ps, 11));

        assert(bp_frd_addr<32);
        frd[bp_frd_addr].push(bp_frd_data);
        bsg_pr_dbg_ps("ps.cpp: FRF[%d] = %016llx\n", bp_frd_addr, bp_frd_data);
      } else {
        bsg_pr_dbg_ps("FRF empty\n");
        break;
      }

    bsg_pr_dbg_ps("ps.cpp: minstret: dromajo %08x | bp %16llx\n", dromajo_instret, zpl->axil_read(get_addr(r_pl2ps_reg)));

    uint32_t machine_state = zpl->axil_read(get_addr(r_pl2ps_reg, 1));
    bsg_pr_dbg_ps("ps.cpp: machine state = %x\n", machine_state);
    int cache_req_sent = machine_state & 0x3f;
    machine_state = machine_state >> 6;
    int cache_req_done = machine_state & 0x3f;
    bsg_pr_dbg_ps("ps.cpp: cache_req_sent 0x%x done 0x%x\n", cache_req_sent, cache_req_done);
    //TODO clean unused registers

    // cause is only updated on exception | irreproducible interrupts
    bsg_pr_dbg_ps("ps.cpp: Dromajo expecting to execute PC 0x%016llx\n", dromajo_get_pc());
    while(1)
      if(!cause.empty() && (epc.front() == dromajo_get_pc())) {
      // TODO this is incorrect!! Gotta compare minstret too! For that, collect dromajo minstret
        bsg_pr_info("ps.cpp: Taking the trap now; cause 0x%016llx | epc 0x%016llx!\n", cause.front(), epc.front());
        dromajo_trap(0, cause.front()); // updates virt_machine state
        cause.pop(); epc.pop();
      } else break;

    if(!insn.empty()) {
      bsg_pr_dbg_ps("New entries: %x; cause size: %d\n", insn.size(), cause.size());
      dep d = deps.front();
      if(
          !(d.idep || d.fdep || d.cdep)                                     // no dependancy
          || d.idep && !ird[d.rfaddr].empty()                               // ird dependancy
          || d.fdep && !frd[d.rfaddr].empty()                               // frd dependancy
          || d.cdep && (cache_req_sent + req_correction == cache_req_done)  // cache dependancy
        ) {
        bsg_pr_dbg_ps("Cosimulatable because: %d %d %d %d\n", !(d.idep || d.fdep || d.cdep),
            d.idep && !ird[d.rfaddr].empty(), d.fdep && !frd[d.rfaddr].empty(), d.cdep);
        if(d.idep) {
          wdata = ird[d.rfaddr].front();
          ird[d.rfaddr].pop();
        } else if(d.fdep) {
          wdata = frd[d.rfaddr].front();
          frd[d.rfaddr].pop();
        } else if(d.cdep) {
          bsg_pr_dbg_ps("ps.cpp: Cache dependancy got accounted for\n");
        } else
          wdata = 0;

        bsg_pr_dbg_ps("ps.cpp: Sending from DUT: PC=%08x | INSN=%08x | WDATA=%016llx | MSTAT=%016llx\n", pc.front(), insn.front(), wdata, mstatus.front());
#ifdef ZYNQ_PS_DEBUG
        cosim_status = dromajo_step(0, pc.front(), insn.front(), wdata, mstatus.front(), true);
#else
        cosim_status = dromajo_step(0, pc.front(), insn.front(), wdata, mstatus.front(), false);
#endif
        if(!cosim_status) {
          dromajo_instret++;
          bsg_pr_dbg_ps("++++++ MATCH ++++++\n");
        } else {
          for(int e=0; e<5; e++)
            bsg_pr_info("-----------------------\n");
          bsg_pr_info("------ MISMATCH -------\n");
          for(int e=0; e<5; e++)
            bsg_pr_info("-----------------------\n");
          //break;
        }
        pc.pop(); insn.pop(); deps.pop(); mstatus.pop(); 
        watchdog = 0;
      } else { // dependancy not satisfied; cannot cosimulate
        // TODO req_correction isn't needed if the req_dones are updated at negedge -- check!
        if(watchdog > 0xfff) {
          req_correction = cache_req_done - cache_req_sent;
          bsg_pr_info("[CRITICAL] correcting cache_req_done; check correctness!\n");
        }
        if(watchdog > 0xffff) {
          bsg_pr_info("[ERROR] Hasn't simulated in 0xff iters; Exiting!\n");
          break;
        }
        watchdog++;
        bsg_pr_dbg_ps("Not cosimulatable because:\n");
        bsg_pr_dbg_ps("deps: i,f,c :: %d,%d,%d\n", d.idep, d.fdep, d.cdep);
        bsg_pr_dbg_ps("addr: 0x%x contents: %d %d\n", d.rfaddr, ird[d.rfaddr].size(), frd[d.rfaddr].size());
        bsg_pr_dbg_ps("pc.front(): 0x%llx\n", pc.front());
      }
    }    
  }

  if(max_insns == 0)
    bsg_pr_info("ps.cpp: Exiting because max_insns=%d expired!\n", max_insns);

  bsg_pr_dbg_ps("ps.cpp: getting minstret\n");
  minstrret_stop = zpl->axil_read(get_addr(r_pl2ps_reg)) & 0x7fffffff; // ignore the MSB which is actually gate-status;
  double termination = get_current_time_in_seconds();
  clock_gettime(CLOCK_MONOTONIC, &end);
  setlocale(LC_NUMERIC, "");

  // TODO the cycles measured here are actually an as yet unquatifiable amount more than actually elapsed
  // from the time of actually having completed cosimulation.
  bsg_pr_dbg_ps("ps.cpp: disabling gate again for reading internal MM regs\n");
  zpl->axil_write(get_addr(w_ps2pl_reg, 3), 0x0, mask);
  mtime_stop = get_counter_64(zpl, GP1_ADDR_BASE+0x20000000 + 0x30bff8);

  unsigned long long minstrret_delta = minstrret_stop - minstrret_start;
  bsg_pr_info("ps.cpp: BP insn delta:                   %'16llu (%16llx)\n", minstrret_delta, minstrret_delta);
  unsigned long long mtime_delta = mtime_stop - mtime_start;
  bsg_pr_info("ps.cpp: BP time delta (=1/8 BP cycles):  %'16llu (%16llx)\n", mtime_delta, mtime_delta);

  bsg_pr_info("ps.cpp: IPC  :                           %'16f\n", ((double)minstrret_delta) / ((double)(mtime_delta)) / 8.0);
  unsigned long long diff_ns = 1000LL * 1000LL * 1000LL *
    ((unsigned long long)(end.tv_sec - start.tv_sec)) +
    (end.tv_nsec - start.tv_nsec);
  bsg_pr_info("ps.cpp: wall clock time:                 %'16llu (%16llx) ns\n",diff_ns, diff_ns);
  bsg_pr_info("ps.cpp: sim/emul speed:                  %'16.2f BP cycles per minute\n",
      mtime_delta * 8 / ((double)(diff_ns) / (60.0 * 1000.0 * 1000.0 * 1000.0)));

  bsg_pr_info("ps.cpp: dromajo time delta:              %lf ns\n", termination - inception);
  bsg_pr_info("ps.cpp: dromajo insn delta:              %d BP insns\n", dromajo_instret);
  bsg_pr_info("ps.cpp: dromajo cosim speed:             %lf MIPS\n", 1e-6 * (double)dromajo_instret / (termination - inception));

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
    zpl->axil_write(get_addr(w_ps2pl_reg), 0x0, mask);
  }
#endif

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}
