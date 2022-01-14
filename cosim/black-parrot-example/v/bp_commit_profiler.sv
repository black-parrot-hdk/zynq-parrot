`include "bp_common_defines.svh"
`include "bp_top_defines.svh"
`include "bp_be_defines.svh"
`include "bp_fe_defines.svh"

module bp_commit_profiler
  import bp_common_pkg::*;
  import bp_be_pkg::*;
  import bp_profiler_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)
    `declare_bp_core_if_widths(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter `BSG_INV_PARAM(width_p)

    , localparam issue_pkt_width_lp    = `bp_be_issue_pkt_width(vaddr_width_p, branch_metadata_fwd_width_p)
    , localparam dispatch_pkt_width_lp = `bp_be_dispatch_pkt_width(vaddr_width_p)
    , localparam commit_pkt_width_lp   = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    , localparam retire_pkt_width_lp   = `bp_be_retire_pkt_width(vaddr_width_p)
    , localparam wb_pkt_width_lp       = `bp_be_wb_pkt_width(vaddr_width_p)
    )
   (  input clk_i
    , input reset_i
    , input en_i
    , input freeze_i

    , input fe_queue_ready_i
    , input fe_queue_empty_i

    , input icache_yumi_i
    , input icache_miss_i
    , input icache_tl_we_i
    , input icache_tv_we_i

    , input br_ovr_i
    , input ret_ovr_i
    , input jal_ovr_i

    , input fe_cmd_yumi_i
    , input [fe_cmd_width_lp-1:0] fe_cmd_i
    , input issue_v_i
    , input suppress_iss_i
    , input clear_iss_i
    , input mispredict_i
    , input dispatch_v_i
    , input [vaddr_width_p-1:0] isd_expected_npc_i

    , input data_haz_i
    , input catchup_dep_i
    , input aux_dep_i
    , input load_dep_i
    , input mul_dep_i
    , input fma_dep_i
    , input sb_iraw_dep_i
    , input sb_fraw_dep_i
    , input sb_iwaw_dep_i
    , input sb_fwaw_dep_i

    , input sb_int_v_i
    , input sb_int_clr_i
    , input sb_fp_v_i
    , input sb_fp_clr_i
    , input [1:0] sb_irs_match_i
    , input [2:0] sb_frs_match_i
    , input [2:0] rs1_match_vector_i
    , input [2:0] rs2_match_vector_i
    , input [2:0] rs3_match_vector_i

    , input control_haz_i
    , input long_haz_i

    , input struct_haz_i
    , input mem_haz_i
    , input idiv_haz_i
    , input fdiv_haz_i
    , input ptw_busy_i

    , input [dispatch_pkt_width_lp-1:0] dispatch_pkt_i
    , input [retire_pkt_width_lp-1:0]   retire_pkt_i
    , input [commit_pkt_width_lp-1:0]   commit_pkt_i
    , input [wb_pkt_width_lp-1:0]       iwb_pkt_i
    , input [wb_pkt_width_lp-1:0]       fwb_pkt_i

    , output [els_p-1:0][width_p-1:0] data_o
    , output v_o
    , output instret_o
    , output [$bits(bp_stall_reason_e)-1:0] stall_o
    , output [vaddr_width_p-1:0] pc_o
    );

  `declare_bp_core_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);

  // Profiler
  assign v_o = ~prof.freeze_r;
  assign instret_o = prof.commit_pkt_cast_i.instret;
  assign stall_o = prof.bp_stall_reason_enum;
  assign pc_o = prof.pc_n[6];

  wire stall_v = ~prof.commit_pkt_cast_i.instret;
  bp_nonsynth_core_profiler
   #(.bp_params_p(bp_params_p))
   prof
   (.clk_i          (clk_i)
   ,.reset_i        (reset_i)
   ,.freeze_i       (freeze_i)
   ,.mhartid_i      ('0)
   ,.*
   );

  localparam stall_offset_lp = 0;
  localparam event_offset_lp = stall_offset_lp + $bits(bp_stall_reason_s);

  // Output generation
  `define declare_counter(name,up,i)                                \
  bsg_counter_clear_up                                              \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))        \
   ``name``_cnt                                                     \
   (.clk_i(clk_i)                                                   \
   ,.reset_i(reset_i)                                               \
   ,.clear_i(freeze_i)                                              \
   ,.up_i(en_i & (``up``))                                          \
   ,.count_o(data_o[``i``])                                         \
   );

  `define declare_event_counter(name,up)                            \
  bsg_counter_clear_up                                              \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))        \
   ``name``_cnt                                                     \
   (.clk_i(clk_i)                                                   \
   ,.reset_i(reset_i)                                               \
   ,.clear_i(freeze_i)                                              \
   ,.up_i(en_i & (``up``))                                          \
   ,.count_o(data_o[bp_profiler_pkg::``name`` + event_offset_lp])   \
   );

  `define declare_stall_counter(name)                                                \
  bsg_counter_clear_up                                                               \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))                         \
   ``name``_cnt                                                                      \
   (.clk_i(clk_i)                                                                    \
   ,.reset_i(reset_i)                                                                \
   ,.clear_i(freeze_i)                                                               \
   ,.up_i(en_i & stall_v & (prof.bp_stall_reason_enum == bp_profiler_pkg::``name``)) \
   ,.count_o(data_o[bp_profiler_pkg::``name`` + stall_offset_lp])                    \
   );

  // Stalls
  // Assigned to counters: 0-30
  `declare_stall_counter(ic_miss)
  `declare_stall_counter(br_ovr)
  `declare_stall_counter(ret_ovr)
  `declare_stall_counter(jal_ovr)
  `declare_stall_counter(fe_cmd)
  `declare_stall_counter(fe_cmd_fence)
  `declare_stall_counter(mispredict)
  `declare_stall_counter(control_haz)
  `declare_stall_counter(long_haz)
  `declare_stall_counter(data_haz)
  `declare_stall_counter(catchup_dep)
  `declare_stall_counter(aux_dep)
  `declare_stall_counter(load_dep)
  `declare_stall_counter(mul_dep)
  `declare_stall_counter(fma_dep)
  `declare_stall_counter(sb_iraw_dep)
  `declare_stall_counter(sb_fraw_dep)
  `declare_stall_counter(sb_iwaw_dep)
  `declare_stall_counter(sb_fwaw_dep)
  `declare_stall_counter(struct_haz)
  `declare_stall_counter(idiv_haz)
  `declare_stall_counter(fdiv_haz)
  `declare_stall_counter(ptw_busy)
  `declare_stall_counter(special)
  `declare_stall_counter(exception)
  `declare_stall_counter(_interrupt)
  `declare_stall_counter(itlb_miss)
  `declare_stall_counter(dtlb_miss)
  `declare_stall_counter(dc_miss)
  `declare_stall_counter(dc_fail)
  `declare_stall_counter(unknown)

endmodule
