`include "bp_common_defines.svh"
`include "bp_top_defines.svh"
`include "bp_be_defines.svh"

module bp_stall_counters
  import bp_common_pkg::*;
  import bp_be_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)
    , parameter width_p = 32

    , localparam commit_pkt_width_lp = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    , localparam retire_pkt_width_lp = `bp_be_retire_pkt_width(vaddr_width_p)
    , localparam lg_l2_banks_lp = `BSG_SAFE_CLOG2(l2_banks_p)
    )
   (input clk_i
    , input reset_i
    , input freeze_i
    , input en_i

    , input fe_queue_ready_i
    , input icache_ready_i

    , input if2_v_i
    , input br_ovr_i
    , input ret_ovr_i
    , input icache_data_v_i

    , input fe_cmd_nonattaboy_i
    , input fe_cmd_fence_i
    , input fe_queue_empty_i

    , input dcache_ready_i
    , input mispredict_i
    , input long_haz_i
    , input control_haz_i
    , input data_haz_i
    , input aux_dep_i
    , input load_dep_i
    , input mul_dep_i
    , input fma_dep_i
    , input sb_iraw_dep_i
    , input sb_fraw_dep_i
    , input sb_iwaw_dep_i
    , input sb_fwaw_dep_i
    , input struct_haz_i
    , input idiv_haz_i
    , input fdiv_haz_i
    , input ptw_busy_i

    , input [lg_l2_banks_lp-1:0] l2_bank_i
    , input [l2_banks_p-1:0] l2_ready_i
    , input [l2_banks_p-1:0] l2_miss_done_i

    , input m_arvalid_i
    , input m_arready_i
    , input m_rlast_i
    , input m_awvalid_i
    , input m_awready_i
    , input m_bvalid_i

    , input [retire_pkt_width_lp-1:0] retire_pkt_i
    , input [commit_pkt_width_lp-1:0] commit_pkt_i

    // output counters
    , output [width_p-1:0] mcycle_o
    , output [width_p-1:0] minstret_o

    , output [width_p-1:0] icache_miss_o
    , output [width_p-1:0] branch_override_o
    , output [width_p-1:0] ret_override_o

    , output [width_p-1:0] fe_cmd_o
    , output [width_p-1:0] fe_cmd_fence_o

    , output [width_p-1:0] mispredict_o

    , output [width_p-1:0] control_haz_o
    , output [width_p-1:0] long_haz_o

    , output [width_p-1:0] data_haz_o
    , output [width_p-1:0] aux_dep_o
    , output [width_p-1:0] load_dep_o
    , output [width_p-1:0] mul_dep_o
    , output [width_p-1:0] fma_dep_o
    , output [width_p-1:0] sb_iraw_dep_o
    , output [width_p-1:0] sb_fraw_dep_o
    , output [width_p-1:0] sb_iwaw_dep_o
    , output [width_p-1:0] sb_fwaw_dep_o

    , output [width_p-1:0] struct_haz_o
    , output [width_p-1:0] idiv_haz_o
    , output [width_p-1:0] fdiv_haz_o

    , output [width_p-1:0] ptw_busy_o
    , output [width_p-1:0] special_o
    , output [width_p-1:0] replay_o
    , output [width_p-1:0] exception_o
    , output [width_p-1:0] _interrupt_o
    , output [width_p-1:0] itlb_miss_o
    , output [width_p-1:0] dtlb_miss_o
    , output [width_p-1:0] dcache_miss_o
    , output [width_p-1:0] l2_miss_o
    , output [width_p-1:0] dma_o

    , output [width_p-1:0] unknown_o

    , output [width_p-1:0] mem_instr_o
    , output [width_p-1:0] aux_instr_o
    , output [width_p-1:0] fma_instr_o
    , output [width_p-1:0] ilong_instr_o
    , output [width_p-1:0] flong_instr_o
    , output [width_p-1:0] l2_miss_cnt_o
    , output [width_p-1:0] l2_miss_wait_o
    , output [width_p-1:0] wdma_cnt_o
    , output [width_p-1:0] rdma_cnt_o
    , output [width_p-1:0] wdma_wait_o
    , output [width_p-1:0] rdma_wait_o
    , output [width_p-1:0] dma_wait_o
    );

   bp_nonsynth_core_profiler
    #(.bp_params_p(bp_params_p))
    prof
    (.clk_i          (clk_i)
    ,.reset_i        (reset_i)
    ,.freeze_i       (freeze_i)
    ,.mhartid_i      ('0)
    ,.*
    );

   wire stall_v = ~prof.commit_pkt.instret;

  // Output generation
  `define declare_counter(name)                              \
  bsg_counter_clear_up                                       \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0)) \
   ``name``_cnt                                              \
   (.clk_i(clk_i)                                            \
   ,.reset_i(reset_i)                                        \
   ,.clear_i(freeze_i)                                       \
   ,.up_i(en_i & stall_v & (prof.bp_stall_reason_enum == ``name``))    \
   ,.count_o(``name``_o)                                     \
   );

  `declare_counter(icache_miss)
  `declare_counter(branch_override)
  `declare_counter(ret_override)
  `declare_counter(fe_cmd)
  `declare_counter(fe_cmd_fence)
  `declare_counter(mispredict)
  `declare_counter(control_haz)
  `declare_counter(long_haz)
  `declare_counter(data_haz)
  `declare_counter(aux_dep)
  `declare_counter(load_dep)
  `declare_counter(mul_dep)
  `declare_counter(fma_dep)
  `declare_counter(sb_iraw_dep)
  `declare_counter(sb_fraw_dep)
  `declare_counter(sb_iwaw_dep)
  `declare_counter(sb_fwaw_dep)
  `declare_counter(struct_haz)
  `declare_counter(idiv_haz)
  `declare_counter(fdiv_haz)
  `declare_counter(ptw_busy)
  `declare_counter(special)
  `declare_counter(replay)
  `declare_counter(exception)
  `declare_counter(_interrupt)
  `declare_counter(itlb_miss)
  `declare_counter(dtlb_miss)
  `declare_counter(dcache_miss)
  `declare_counter(l2_miss)
  `declare_counter(dma)
  `declare_counter(unknown)

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    mcycle_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i)
    ,.count_o(mcycle_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    minstret_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & prof.commit_pkt.instret)
    ,.count_o(minstret_o)
    );

   rv64_instr_fmatype_s instr;
   assign instr = prof.commit_pkt.instr;

   wire instret       = prof.commit_pkt.instret;
   wire ilong_instr_v = (instr.opcode inside {`RV64_OP_OP, `RV64_OP_32_OP})
                      & (instr inside {`RV64_DIV, `RV64_DIVU, `RV64_DIVW, `RV64_DIVUW ,`RV64_REM, `RV64_REMU, `RV64_REMW, `RV64_REMUW});
   wire flong_instr_v = (instr.opcode == `RV64_FP_OP) & (instr inside {`RV64_FDIV_S, `RV64_FDIV_D, `RV64_FSQRT_S, `RV64_FSQRT_D});
   wire fma_instr_v   = (instr.opcode inside {`RV64_FMADD_OP, `RV64_FMSUB_OP, `RV64_FNMSUB_OP, `RV64_FNMADD_OP})
                      | ((instr.opcode == `RV64_FP_OP)
                      & (instr inside {`RV64_FADD_S, `RV64_FADD_D, `RV64_FSUB_S, `RV64_FSUB_D, `RV64_FMUL_S, `RV64_FMUL_D}));
   wire aux_instr_v   = (instr.opcode == `RV64_FP_OP) & ~fma_instr_v & ~flong_instr_v;
   wire mem_instr_v   = (instr.opcode inside {`RV64_LOAD_OP, `RV64_FLOAD_OP, `RV64_STORE_OP, `RV64_FSTORE_OP, `RV64_MISC_MEM_OP, `RV64_AMO_OP});

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    mem_instr_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & instret & mem_instr_v)
    ,.count_o(mem_instr_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    aux_instr_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & instret & aux_instr_v)
    ,.count_o(aux_instr_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    fma_instr_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & instret & fma_instr_v)
    ,.count_o(fma_instr_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    ilong_instr_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & instret & ilong_instr_v)
    ,.count_o(ilong_instr_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    flong_instr_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & instret & flong_instr_v)
    ,.count_o(flong_instr_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    l2_miss_done_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & l2_miss_done_i[l2_bank_i])
    ,.count_o(l2_miss_cnt_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    l2_miss_wait_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & ~l2_ready_i[l2_bank_i])
    ,.count_o(l2_miss_wait_o)
    );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   wdma_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(freeze_i)
   ,.up_i(en_i & m_awvalid_i & m_awready_i)
   ,.count_o(wdma_cnt_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   rdma_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(freeze_i)
   ,.up_i(en_i & m_arvalid_i & m_arready_i)
   ,.count_o(rdma_cnt_o)
   );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    wdma_wait_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & prof.wdma_pending_r)
    ,.count_o(wdma_wait_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    rdma_wait_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & prof.rdma_pending_r)
    ,.count_o(rdma_wait_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    dma_wait_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(en_i & (prof.rdma_pending_r | prof.wdma_pending_r))
    ,.count_o(dma_wait_o)
    );

endmodule
