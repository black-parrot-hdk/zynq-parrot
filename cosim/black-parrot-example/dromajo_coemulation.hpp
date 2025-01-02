//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#ifdef DROMAJO_COEMU
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <unordered_set>

#include "dromajo_cosim.h"
#include "riscv_machine.h"
#include "riscv_cpu.h"

// Dromajo globals
#define MAX_INSNS 0x7fff'ffff'ffff'ffffull
long long             max_insns_cnt = MAX_INSNS;
dromajo_cosim_state_t *dromajo_pointer;
bool                  coemu_failed;
bool                  coemu_inited = false;
std::vector<bool>*    coemu_finished;
long long int         coemu_start_time = 0; // start time of dromajo
long long int         coemu_instret = 0;

// ignores the first 14 (or more) insns while dromajo executes setup code
#ifdef FPGA
int                   dromajo_ignore_setup_insns = 0;
#else
int                   dromajo_ignore_setup_insns = 14;
#endif
int                   dromajo_setup_insns_cnt = 0;

void coemu_init(int hartid, int ncpus, int memory_size, std::string _prog_str) {
  coemu_inited = true;
  bsg_pr_info("[COEMU]: Initiating Dromajo co-emulation\n");
  coemu_finished = new vector<bool>(ncpus, false);

  char dromajo_str[50];
  sprintf(dromajo_str, "dromajo");
  char ncpus_str[50];
  sprintf(ncpus_str, "--ncpus=%d", ncpus);
  char memsize_str[50];
  sprintf(memsize_str, "--memory_size=%d", memory_size);
  //TODO: integrate this for checkpointing during fuzzing
  //char load_str[50];
  //sprintf(load_str, "--load=prog");
  char trace_str[50]; // reserved for later
  sprintf(trace_str, "--trace=0");
  char *prog_str = new char [_prog_str.length()+1];
  strcpy(prog_str, _prog_str.c_str());

  char* argv[] = {dromajo_str, ncpus_str, memsize_str, trace_str, prog_str};
  dromajo_pointer = dromajo_cosim_init(sizeof(argv)/sizeof(char *), argv);

  dromajo_setup_insns_cnt = dromajo_ignore_setup_insns;
}

bool dromajo_step(int hartid, uint64_t pc, uint32_t insn,
    uint64_t wdata, uint64_t mstatus, bool verbose) {
  if(coemu_instret == 0) {
    coemu_start_time = get_current_time_in_seconds();
    bsg_pr_dbg_ps("dromajo_start_time time: %lf\n", coemu_start_time);
    while(dromajo_setup_insns_cnt-- > 0) {
      int exit_code = dromajo_cosim_step(dromajo_pointer, hartid, pc, insn, wdata, mstatus, true, verbose);
      if(exit_code)
        bsg_pr_dbg_ps("Dromajo VM out-of-sync!\n\n\n");
      else {
        bsg_pr_dbg_ps("Dromajo VM henceforth in-sync\n");
        coemu_instret++;
        return false;
      }
      coemu_instret++;
    }
  }
  return dromajo_cosim_step(dromajo_pointer, hartid, pc, insn, wdata, mstatus, true, verbose);
}

void coemu_finish() {
  dromajo_cosim_fini(dromajo_pointer);
}

uint64_t dromajo_get_pc() {
  return (uint64_t)(((RISCVMachine *)dromajo_pointer)->cpu_state[0]->pc);
}

uint64_t dromajo_get_minstret() {
  return (uint64_t)(((RISCVMachine *)dromajo_pointer)->cpu_state[0]->minstret);
}

void dromajo_trap(int hartid, uint64_t cause) {
  dromajo_cosim_raise_trap(dromajo_pointer, hartid, cause, true);
}

uint32_t bp_insn, bp_md, bp_mcycle_partial;
uint64_t bp_ird_data, bp_ird_addr, bp_frd_data, bp_frd_addr, wdata, bp_mstatus, bp_minstret, bp_pc, bp_cause, bp_epc, bp_eminstret, bp_ird_mcycle, bp_frd_mcycle;
typedef struct {
  bool idep;
  bool fdep;
  uint8_t rfaddr;
} dep;
dep bp_deps;

std::queue<uint64_t> irf[32], frf[32], pc, mstatus, cause, epc, eminstret, minstret;
std::queue<uint32_t> insn, ninsns;
std::queue<dep> deps; // TODO eliminate this via dromajo hooks -- Dromajo doesn't seem to present dest reg dependancies
bool cosim_status = false;
bool bp_done = false;
bool last_commit = false;
int self_destruct = 0;

#ifdef NEON
uint32x4_t temp_vector;
#endif

bool coemu_exec(bsg_zynq_pl *zpl) {
  static int trap_cnt = 0;
  static int cmt_cnt = 0;
  // commit_fifo
  if (cmt_cnt == 0)
    cmt_cnt = zpl->shell_read(GP0_RD_PL2PS_FIFO_4_CTRS);

  if (cmt_cnt != 0) {
    cmt_cnt--;
#ifdef NEON
    temp_vector = zpl->shell_read4(GP0_RD_PL2PS_FIFO_4_DATA)
    bp_insn     = temp_vector[0];
    bp_md       = temp_vector[1];
    bp_pc       = join(temp_vector[3], temp_vector[2]);

    temp_vector = zpl->shell_read4(GP0_RD_PL2PS_FIFO_8_CTRS);
    bp_mstatus  = join(temp_vector[1], temp_vector[0]);
    bp_minstret = join(temp_vector[3], temp_vector[2]);
#else
    bp_insn     = zpl->shell_read(GP0_RD_PL2PS_FIFO_4_DATA);
    bp_md       = zpl->shell_read(GP0_RD_PL2PS_FIFO_5_DATA);
    bp_pc       = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_7_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_6_DATA);
    bp_mstatus  = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_9_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_8_DATA);
    bp_minstret   = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_11_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_10_DATA);

#endif
    insn.push(bp_insn);
    bp_deps = {.idep = (bool)(bp_md & 1), .fdep = (bool)(bp_md & 2)};
    bp_deps.rfaddr = (bp_md & 0x7c) >> 2;
    deps.push(bp_deps);
    last_commit = (bp_md & 0x80) >> 7;
    if(last_commit)
      bsg_pr_info("ps.cpp: Last commit received; starting termination in the next iteration\n");
    bp_mcycle_partial = (bp_md >> 8);
    pc.push(bp_pc);
    mstatus.push(bp_mstatus);
    minstret.push(bp_minstret);

    bsg_pr_dbg_ps("[Trace]: pc %016x | md %1x %1x | insn %08x | mcycle ...%08x | mstatus %016x | minstret %016x\n", bp_pc, bp_deps.idep, bp_deps.fdep, bp_insn, bp_mcycle_partial, bp_mstatus, bp_minstret);
  }

  // trap data
  if (trap_cnt == 0)
    trap_cnt = zpl->shell_read(GP0_RD_PL2PS_FIFO_20_CTRS);
  if (trap_cnt != 0) {
    trap_cnt--;
#ifdef NEON
    temp_vector = zpl->shell_read4(GP0_RD_PL2PS_FIFO_20_DATA);
    bp_cause = join(temp_vector[1], temp_vector[0]);
    bp_epc   = join(temp_vector[3], temp_vector[2]);
#else
    bp_cause = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_21_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_20_DATA);
    bp_epc   = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_23_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_22_DATA);
#endif
    if((bp_cause & 0xFFFFFFF) != 0xFFFFFFF) { // when '1, not a trap
      bsg_pr_dbg_ps("[Trace]:\033[31m cause: 0x%016llx | epc: 0x%016llx | minstret: 0x%016llx \033[0m\n", bp_cause, bp_epc, bp_minstret);
      cause.push(bp_cause);
      epc.push(bp_epc);
      eminstret.push(bp_minstret);
    }
  }

  // IRF data
  if(zpl->shell_read(GP0_RD_PL2PS_FIFO_12_CTRS)) {
#ifdef NEON
    temp_vector = zpl->shell_read4(GP0_RD_PL2PS_FIFO_12_DATA);
    bp_ird_addr = temp_vector[0] & 0x1f;
    bp_ird_data = join(temp_vector[2], temp_vector[1]);
#else
    bp_ird_addr = 0x1f & zpl->shell_read(GP0_RD_PL2PS_FIFO_12_DATA);
    bp_ird_data = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_14_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_13_DATA);
#endif
    assert(bp_ird_addr<32); // sanity check for accidental frame shifts
    irf[bp_ird_addr].push((uint64_t)bp_ird_data);
    bsg_pr_dbg_ps("[Trace]: irf[%d] = %016llx\n", bp_ird_addr, bp_ird_data);
  }

  // gate data -- not hooked up in v/top_zynq.sv TODO
  //if(zpl->shell_read(GP0_RD_PL2PS_FIFO_25_CTRS))
  //  bsg_pr_dbg_ps("ps.cpp: BP gated at: %016llx\n", join(zpl->shell_read(GP0_RD_PL2PS_FIFO_26_DATA), zpl->shell_read(GP0_RD_PL2PS_FIFO_25_DATA)));

  // FRF data
  if(zpl->shell_read(GP0_RD_PL2PS_FIFO_16_CTRS)) {
#ifdef NEON
    temp_vector = zpl->shell_read4(GP0_RD_PL2PS_FIFO_16_DATA);
    bp_frd_addr = temp_vector[0] & 0x1f;
    bp_frd_data = join(temp_vector[2], temp_vector[1]);
#else
    bp_frd_addr = 0x1f & zpl->shell_read(GP0_RD_PL2PS_FIFO_16_DATA);
    bp_frd_data = ((uint64_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_18_DATA) << 32)
      | (uint32_t)zpl->shell_read(GP0_RD_PL2PS_FIFO_17_DATA);
#endif
    assert(bp_frd_addr<32);
    frf[bp_frd_addr].push(bp_frd_data);
    bsg_pr_dbg_ps("[Trace]: frf[%d] = %016llx\n", bp_frd_addr, bp_frd_data);
  }

  // taking trap
  while(1) // while necessary for recursive traps
    if(!cause.empty() && (minstret.front() == dromajo_get_minstret()) && (epc.front() == dromajo_get_pc())) {
      bsg_pr_info("ps.cpp: Can take trap | eminstret: 0x%x | coemu_instret: 0x%x | dromajo_instret: 0x%x\n",
          eminstret.front(), coemu_instret, dromajo_get_minstret());
      if(
          ( ((eminstret.front()+2)&0xffffff) == (dromajo_get_minstret() & 0xffffff))
        ){
        bsg_pr_info("ps.cpp: minstret right now: %x (should be %x)\n", dromajo_get_minstret(), eminstret.front());
        bsg_pr_info("ps.cpp: Taking the trap now; cause 0x%016llx | epc 0x%016llx!\n", cause.front(), epc.front());
        dromajo_trap(0, cause.front()); // updates virt_machine state
        cause.pop(); epc.pop(); eminstret.pop();
      } else break;
    } else break;
  
  // cosimulating
  if(!insn.empty()) {
    bsg_pr_dbg_ps("ps.cpp: Dromajo expecting to execute PC 0x%016llx\n", dromajo_get_pc());
    dep d = deps.front();
    if(
        !(d.idep || d.fdep)                  // no dependancy
        || d.idep && !irf[d.rfaddr].empty()  // irf dependancy
        || d.fdep && !frf[d.rfaddr].empty()  // frf dependancy
      ) {

      // either insn didn't need to wait for any IRF/FRF update, or needed one of those
      bsg_pr_dbg_ps("Cosimulatable because: %d %d %d\n", !(d.idep || d.fdep),
          d.idep && !irf[d.rfaddr].empty(), d.fdep && !frf[d.rfaddr].empty());

      if(d.idep) {
        wdata = irf[d.rfaddr].front();
        irf[d.rfaddr].pop();
        fprintf(stderr, "[Coemulation]: %016llx | %08x | %016llx | %016llx | i%d %016llx\n",
            pc.front(), insn.front(), mstatus.front(), coemu_instret, d.rfaddr, wdata);
      } else if(d.fdep) {
        wdata = frf[d.rfaddr].front();
        frf[d.rfaddr].pop();
        fprintf(stderr, "[Coemulation]: %016llx | %08x | %016llx | %016llx | f%d %016llx\n",
            pc.front(), insn.front(), mstatus.front(), coemu_instret, d.rfaddr, wdata);
      } else {
        wdata = 0;
        fprintf(stderr, "[Coemulation]: %016llx | %08x | %016llx | %016llx\n",
            pc.front(), insn.front(), mstatus.front(), coemu_instret);
      }

#ifdef   ZYNQ_PS_DEBUG
      cosim_status = dromajo_step(0, pc.front(), insn.front(),
          wdata, mstatus.front(), true);
#else
      cosim_status = dromajo_step(0, pc.front(), insn.front(),
          wdata, mstatus.front(), true);

#endif
      if(!cosim_status) {
        coemu_instret++;
        bsg_pr_dbg_ps("++++++ MATCH ++++++\n");
      } else {
        bsg_pr_info("\033[31m ------ MISMATCH ------ \033[0m\n");
        return false;
      }
      pc.pop(); insn.pop(); deps.pop(); mstatus.pop();

    } else {
      // dependancy not satisfied; cannot cosimulate
      bsg_pr_dbg_ps("Not cosimulatable because pc=0x%llx has %s dependency unfulfilled\n", pc.front(), d.idep ? "irf" : "frf");
    }
  }
  return true;
}

#endif // DROMAJO_COEMU
