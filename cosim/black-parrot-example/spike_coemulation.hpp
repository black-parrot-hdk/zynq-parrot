#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <time.h>
#include <queue>
#include <unistd.h>
#include <bitset>
#include <cstdint>
#include <iostream>
#include <iomanip>
#include <unordered_set>
#ifdef ZYNQ
#include <pynq_api.h>
#endif

#include "ps.hpp"

#include "bsg_tag_bitbang.h"
#include "bsg_zynq_pl.h"
#include "bsg_printing.h"

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifdef SPIKE_COEMU
#define MAX_INSNS 0x7fff'ffff'ffff'ffffull
long long             max_insns_cnt = MAX_INSNS;
bool                  coemu_failed;
bool                  coemu_inited = false;
std::vector<bool>*    coemu_finished;
long long int         coemu_start_time = 0; // start time
long long int         coemu_instret = 0;

#include <riscv/cfg.h>
#include <riscv/debug_module.h>
#include <riscv/devices.h>
#include <riscv/log_file.h>
#include <riscv/processor.h>
#include <riscv/simif.h>

#include <fesvr/memif.h>
#include <fesvr/elfloader.h>
#include <riscv/sim.h>
#include <fesvr/htif.h>

cfg_t* cfg = NULL;
sim_t* sim = NULL;
std::vector<std::pair<reg_t, abstract_mem_t*>> mems;
std::vector<const device_factory_t*> plugin_device_factories;
std::vector<std::string> args;
debug_module_config_t dm_config;

class loadmem_memif_t : public memif_t {
    public:
        loadmem_memif_t(uint8_t* _data, size_t _start) : memif_t(nullptr), data(_data), start(_start) {}
        void write(addr_t taddr, size_t len, const void* src) override
        {
            addr_t addr = taddr - start;
            memcpy(data + addr, src, len);
        }
        void read(addr_t taddr, size_t len, void* bytes) override {
            assert(false);
        }
        endianness_t get_target_endianness() const override {
            return endianness_little;
        }
    private:
        uint8_t* data;
        size_t start;
};

void coemu_init(int hartid, int ncpus, int memory_size, const char *_prog_str, bool checkpoint = false) {
    size_t base = 0x80000000;
    size_t size = memory_size*1024*1024;

    if (cfg == NULL && hartid == 0) {
        std::vector<mem_cfg_t> mem_cfg;
        mem_cfg.push_back(mem_cfg_t(base, size));
        std::vector<size_t> hartids;
        hartids.push_back(hartid);
        std::string visa = "vlen:" + std::to_string(64) + ",elen:64";
        cfg = new cfg_t(std::make_pair(0ll, 0ll),
                    nullptr,
                    "rv64imafdcZifencei_Zicsr_Zba_Zbb_Zbc_Zbs",
                    "msu",
                    visa.c_str(),
                    false,
                    endianness_little,
                    0, 4, // pmpregions
                    mem_cfg,
                    hartids,
                    false,
                    0
                    );

        uint8_t *data = (uint8_t*) mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        mems.push_back(std::make_pair(base, new mem_t(size)));
        cfg->bootargs = nullptr;
        cfg->start_pc = base;
        cfg->pmpregions = 0;

        args.push_back(_prog_str);

        sim = new sim_t(cfg, false,
                mems,
                plugin_device_factories,
                args,
                dm_config, nullptr,
                false, nullptr,
                false,
                nullptr
                );

        reg_t entry;
        loadmem_memif_t loadmem_memif(data, base);
        load_elf(_prog_str, &loadmem_memif, &entry);

        bus_t temp_mem_bus;
        for (auto& pair : mems) temp_mem_bus.add_device(pair.first, pair.second);

        printf("Matching spike memory initial state for region %lx-%lx\n", base, base + size);
        if (!temp_mem_bus.store(base, size, data)) {
            printf("Error, unable to match memory at address %lx\n", base);
            abort();
        }

        std::shared_ptr<mem_t> host = std::make_shared<mem_t>(1 << 24);
        sim->add_device(0, host);

        sim->configure_log(true, false); //TODO true, true
        sim->get_core(0)->get_state()->pc = base;
        sim->set_debug(0);
    }
}


int coemu_step(int hartid,
        uint64_t pc,
        uint32_t insn,
        uint64_t wdata,
        uint64_t mstatus,
        bool verbose = false) {

    if (!sim) 
      return 0;

    processor_t *p = sim->get_core(0);
    state_t *s = p->get_state();
    uint64_t emu_pc = s->pc;
    if (pc != s->pc) {
        printf("[error] EMU PC %016" PRIx64 ", DUT PC %016" PRIx64 "\n", emu_pc, pc);
        return -1;
    }

    p->step(1);

    auto& mem_write = s->log_mem_write;
    auto& log = s->log_reg_write;
    auto& mem_read = s->log_mem_read;

    for (auto &regwrite : log) {
        int emu_rd = regwrite.first >> 4;
        int emu_type = regwrite.first & 0xf;
        int emu_wdata = regwrite.second.v[0];

        if (wdata != emu_wdata) {
            printf("[error] EMU PC %016" PRIx64 ", DUT PC %016" PRIx64 "\n", emu_pc, pc);
            printf("[error] EMU WDATA %016" PRIx64 ", DUT WDATA %016" PRIx64 "\n", emu_wdata, wdata);
            return -1;
        }
    }

    return 0;
}

void coemu_finish() {
    if (sim) {
        delete sim;
        sim = NULL;
    }
}

void coemu_trap(int hartid, uint64_t cause) { // cause unused?
    processor_t *p = sim->get_core(0);
    p->step(1);
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
std::queue<dep> deps; // TODO eliminate this via dromajo hooks
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
    if(!cause.empty() && (minstret.front() == 0) && (epc.front() == sim->get_core(0)->get_state()->pc)) { //TODO
      bsg_pr_info("ps.cpp: Can take trap | eminstret: 0x%x | coemu_instret: 0x%x | dromajo_instret: 0x%x\n",
          eminstret.front(), coemu_instret, 0);
      if(
          ( ((eminstret.front()+2)&0xffffff) == (0 & 0xffffff))
        ){
        bsg_pr_info("ps.cpp: minstret right now: %x (should be %x)\n", 0, eminstret.front());
        bsg_pr_info("ps.cpp: Taking the trap now; cause 0x%016llx | epc 0x%016llx!\n", cause.front(), epc.front());
        coemu_trap(0, cause.front()); // updates virt_machine state
        cause.pop(); epc.pop(); eminstret.pop();
      } else break;
    } else break;
  
  // cosimulating
  if(!insn.empty()) {
    bsg_pr_dbg_ps("ps.cpp: ISA sim expecting to execute PC 0x%016llx\n", sim->get_core(0)->get_state()->pc); // TODO
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
      cosim_status = coemu_step(0, pc.front(), insn.front(),
          wdata, mstatus.front(), true);
#else
      cosim_status = coemu_step(0, pc.front(), insn.front(),
          wdata, mstatus.front(), true);

#endif
      if(!cosim_status) {
        coemu_instret++;
        bsg_pr_dbg_ps("++++++ MATCH ++++++\n");
      } else {
        bsg_pr_info("\033[31m ------ MISMATCH ------ \033[0m\n");
        //return false;
      }
      pc.pop(); insn.pop(); deps.pop(); mstatus.pop();

    } else {
      // dependancy not satisfied; cannot cosimulate
      bsg_pr_dbg_ps("Not cosimulatable because pc=0x%llx has %s dependency unfulfilled\n", pc.front(), d.idep ? "irf" : "frf");
    }
  }
  return true;
}

#endif
