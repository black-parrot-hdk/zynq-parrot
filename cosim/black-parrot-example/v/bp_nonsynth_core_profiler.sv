// The BlackParrot core pipeline is a mostly non-stalling pipeline, decoupled between the front-end
// and back-end.
`include "bp_common_defines.svh"
`include "bp_top_defines.svh"
`include "bp_be_defines.svh"
`include "bp_fe_defines.svh"

module bp_nonsynth_core_profiler
  import bp_common_pkg::*;
  import bp_be_pkg::*;
  import bp_fe_pkg::*;
  import bp_profiler_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)
    `declare_bp_core_if_widths(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p)

    , parameter stall_trace_file_p = "stall"

    , localparam dispatch_pkt_width_lp = `bp_be_dispatch_pkt_width(vaddr_width_p)
    , localparam commit_pkt_width_lp   = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    , localparam retire_pkt_width_lp   = `bp_be_retire_pkt_width(vaddr_width_p)
    , localparam wb_pkt_width_lp       = `bp_be_wb_pkt_width(vaddr_width_p)
    )
   (input clk_i
    , input reset_i
    , input freeze_i

    , input [`BSG_SAFE_CLOG2(num_core_p)-1:0] mhartid_i

    , input fe_queue_ready_i
    , input fe_queue_empty_i

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
    );

  `declare_bp_be_internal_if_structs(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `declare_bp_core_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);

  localparam num_stages_p = 7;

  `bp_cast_i(bp_fe_cmd_s, fe_cmd);
  `bp_cast_i(bp_be_dispatch_pkt_s, dispatch_pkt);
  `bp_cast_i(bp_be_retire_pkt_s, retire_pkt);
  `bp_cast_i(bp_be_commit_pkt_s, commit_pkt);
  `bp_cast_i(bp_be_wb_pkt_s, iwb_pkt);
  `bp_cast_i(bp_be_wb_pkt_s, fwb_pkt);

  bp_stall_reason_s [num_stages_p-1:0] stall_stage_n, stall_stage_r;
  bsg_dff_reset
   #(.width_p($bits(bp_stall_reason_s)*num_stages_p))
   stall_pipe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(stall_stage_n)
     ,.data_o(stall_stage_r)
     );

  logic [6:3][vaddr_width_p-1:0] pc_n, pc_r;
  bsg_dff_reset
   #(.width_p(vaddr_width_p*4))
   pc_pipe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(pc_n)
     ,.data_o(pc_r)
     );

  logic [29:0] cycle_cnt;
  bsg_counter_clear_up
   #(.max_val_p(2**30-1), .init_val_p(0))
   cycle_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.clear_i(1'b0)
     ,.up_i(1'b1)
     ,.count_o(cycle_cnt)
     );

  // FE cmd
  wire fe_cmd_nonattaboy_li = fe_cmd_yumi_i & (fe_cmd_cast_i.opcode != e_op_attaboy);
  wire fe_cmd_br_mispredict_li = fe_cmd_yumi_i & (fe_cmd_cast_i.opcode == e_op_pc_redirection)
                               & (fe_cmd_cast_i.operands.pc_redirect_operands.subopcode == e_subop_branch_mispredict);

  // Scoreboard RD and PC
  //// D$-miss
  wire sb_int_dc_miss_w_li = sb_int_v_i & commit_pkt_cast_i.dcache_load_miss & (commit_pkt_cast_i.instr.t.fmatype.opcode inside {`RV64_LOAD_OP, `RV64_AMO_OP});
  wire sb_fp_dc_miss_w_li = sb_fp_v_i & commit_pkt_cast_i.dcache_load_miss & (commit_pkt_cast_i.instr.t.fmatype.opcode inside {`RV64_FLOAD_OP});
  wire sb_dc_miss_w_li =  sb_int_dc_miss_w_li | sb_fp_dc_miss_w_li;
  wire sb_dc_miss_clr_li = sb_dc_miss_fp_lo
                           ? (sb_fp_clr_i & (fwb_pkt_cast_i.rd_addr == sb_dc_miss_rd_lo))
                           : (sb_int_clr_i & (iwb_pkt_cast_i.rd_addr == sb_dc_miss_rd_lo));

  logic sb_dc_miss_fp_lo;
  logic [vaddr_width_p-1:0] sb_dc_miss_pc_lo;
  logic [reg_addr_width_gp-1:0] sb_dc_miss_rd_lo;
  bsg_dff_reset_en
   #(.width_p(reg_addr_width_gp+vaddr_width_p+1))
   sb_dc_miss_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(sb_dc_miss_w_li | sb_dc_miss_clr_li)
     ,.data_i({sb_fp_dc_miss_w_li, commit_pkt_cast_i.pc, sb_dc_miss_w_li ? commit_pkt_cast_i.instr.t.fmatype.rd_addr : '0})
     ,.data_o({sb_dc_miss_fp_lo, sb_dc_miss_pc_lo, sb_dc_miss_rd_lo})
     );

  wire sb_iraw_dc_miss_li = sb_iraw_dep_i & ~sb_dc_miss_fp_lo & (sb_dc_miss_rd_lo == (sb_irs_match_i[0] 
                                                                                      ? dispatch_pkt_cast_i.instr.t.fmatype.rs1_addr 
                                                                                      : dispatch_pkt_cast_i.instr.t.fmatype.rs2_addr));
  wire sb_iwaw_dc_miss_li = sb_iwaw_dep_i & ~sb_dc_miss_fp_lo & (sb_dc_miss_rd_lo == dispatch_pkt_cast_i.instr.t.fmatype.rd_addr);
  wire sb_fraw_dc_miss_li = sb_fraw_dep_i & sb_dc_miss_fp_lo & (sb_dc_miss_rd_lo == (sb_frs_match_i[0]
                                                                                     ? dispatch_pkt_cast_i.instr.t.fmatype.rs1_addr
                                                                                     : sb_frs_match_i[1]
                                                                                       ? dispatch_pkt_cast_i.instr.t.fmatype.rs2_addr
                                                                                       : dispatch_pkt_cast_i.instr.t.fmatype.rs3_addr));
  wire sb_fwaw_dc_miss_li = sb_fwaw_dep_i & sb_dc_miss_fp_lo & (sb_dc_miss_rd_lo == dispatch_pkt_cast_i.instr.t.fmatype.rd_addr);
  wire sb_int_dc_miss_li = sb_iraw_dc_miss_li | sb_iwaw_dc_miss_li;
  wire sb_fp_dc_miss_li = sb_fraw_dc_miss_li | sb_fwaw_dc_miss_li;
  wire sb_dc_miss_li = sb_int_dc_miss_li | sb_fp_dc_miss_li;

  //// long int
  wire sb_ilong_w_li = sb_int_v_i & ~sb_int_dc_miss_w_li;
  wire sb_ilong_clr_li = sb_int_clr_i &  ~sb_dc_miss_clr_li;

  logic [vaddr_width_p-1:0] sb_ilong_pc_lo;
  logic [reg_addr_width_gp-1:0] sb_ilong_rd_lo;
  bsg_dff_reset_en
   #(.width_p(reg_addr_width_gp+vaddr_width_p))
   sb_ilong_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(sb_ilong_w_li | sb_ilong_clr_li)
     ,.data_i({dispatch_pkt_cast_i.pc, sb_ilong_w_li ? dispatch_pkt_cast_i.instr.t.fmatype.rd_addr : '0})
     ,.data_o({sb_ilong_pc_lo, sb_ilong_rd_lo})
     );

  //// long float
  wire sb_flong_w_li = sb_int_v_i & ~sb_int_dc_miss_w_li;
  wire sb_flong_clr_li = sb_int_clr_i &  ~sb_dc_miss_clr_li;

  logic [vaddr_width_p-1:0] sb_flong_pc_lo;
  logic [reg_addr_width_gp-1:0] sb_flong_rd_lo;
  bsg_dff_reset_en
   #(.width_p(reg_addr_width_gp+vaddr_width_p))
   sb_flong_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(sb_flong_w_li | sb_flong_clr_li)
     ,.data_i({dispatch_pkt_cast_i.pc, sb_flong_w_li ? dispatch_pkt_cast_i.instr.t.fmatype.rd_addr : '0})
     ,.data_o({sb_flong_pc_lo, sb_flong_rd_lo})
     );

  // ISD Hazard PC Selection
  logic [2:0][vaddr_width_p-1:0] ex_pc_n, ex_pc_r;
  bsg_dff_reset
   #(.width_p(3*vaddr_width_p))
   ex_pc_pipe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(ex_pc_n)
     ,.data_o(ex_pc_r)
     );
  assign ex_pc_n[0] = dispatch_pkt_cast_i.pc;
  assign ex_pc_n[1] = ex_pc_r[0];
  assign ex_pc_n[2] = ex_pc_r[1];

  wire [2:0] rs_match_vector_li = ({3{dispatch_pkt_cast_i.decode.irs1_r_v}} & rs1_match_vector_i)
                                | ({3{dispatch_pkt_cast_i.decode.irs2_r_v}} & rs2_match_vector_i)
                                | ({3{dispatch_pkt_cast_i.decode.frs1_r_v}} & rs1_match_vector_i)
                                | ({3{dispatch_pkt_cast_i.decode.frs2_r_v}} & rs2_match_vector_i)
                                | ({3{dispatch_pkt_cast_i.decode.frs3_r_v}} & rs3_match_vector_i);

  logic [vaddr_width_p-1:0] dep_pc_lo;
  bsg_mux_one_hot
   #(.width_p(vaddr_width_p)
    ,.els_p(3)
    )
   ex_pc_mux
    (.data_i(ex_pc_r)
    ,.sel_one_hot_i(rs_match_vector_li)
    ,.data_o(dep_pc_lo)
    );

  wire [vaddr_width_p-1:0] pc_chaz_lo = dispatch_pkt_cast_i.pc;
  wire [vaddr_width_p-1:0] pc_dhaz_lo = sb_dc_miss_li
                                        ? sb_dc_miss_pc_lo
                                        : (sb_iraw_dep_i | sb_iwaw_dep_i)
                                          ? sb_ilong_pc_lo
                                          : (sb_fraw_dep_i | sb_fwaw_dep_i)
                                            ? sb_flong_pc_lo
                                            : dep_pc_lo;

  logic [vaddr_width_p-1:0] dc_miss_pc_lo;
  bsg_dff_reset_en
   #(.width_p(vaddr_width_p))
   dc_miss_pc_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(commit_pkt_cast_i.dcache_load_miss | commit_pkt_cast_i.dcache_store_miss)
     ,.data_i(commit_pkt_cast_i.pc)
     ,.data_o(dc_miss_pc_lo)
     );

  logic [vaddr_width_p-1:0] long_pc_lo;
  bsg_dff_reset_en
   #(.width_p(vaddr_width_p))
   long_pc_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(dispatch_pkt_cast_i.v & dispatch_pkt_cast_i.decode.pipe_long_v)
     ,.data_i(dispatch_pkt_cast_i.pc)
     ,.data_o(long_pc_lo)
     );

  //TODO: cover ptw_busy and cmd_haz cases
  wire [vaddr_width_p-1:0] pc_shaz_lo = mem_haz_i
                                        ? dc_miss_pc_lo
                                        : (idiv_haz_i | fdiv_haz_i)
                                          ? long_pc_lo
                                          : '0;
  wire [vaddr_width_p-1:0] pc_isd_haz_lo = data_haz_i ? pc_dhaz_lo : (control_haz_i ? pc_chaz_lo : pc_shaz_lo);

  // ISD suppression on misprediction
  logic mispredict_r;
  logic [vaddr_width_p-1:0] mispredict_pc_r;
  bsg_dff_reset_set_clear
   #(.width_p(1))
   mispredict_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.set_i(mispredict_i)
     ,.clear_i(clear_iss_i)
     ,.data_o(mispredict_r)
     );
  bsg_dff_reset_en
   #(.width_p(vaddr_width_p))
   mispredict_pc_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(mispredict_i)
     ,.data_i(ex_pc_r[0])
     ,.data_o(mispredict_pc_r)
     );

  // debug
  wire unknown_fe = fe_queue_empty_i & ~(|stall_stage_r[2]);
  wire extra_fe = ~fe_queue_empty_i & (|stall_stage_r[2]);
  wire tmp_isd = (pc_n[3] == '0) & ~dispatch_pkt_cast_i.v;
  wire tmp_cmt = (pc_n[6] == '0);

  always_comb
    begin
      // IF0
      stall_stage_n[0]                    = '0;

      // IFr
      stall_stage_n[1]                    = icache_tl_we_i ? stall_stage_r[0] : stall_stage_r[1];
      stall_stage_n[1].fe_cmd            |= fe_cmd_nonattaboy_li & ~fe_cmd_br_mispredict_li;
      stall_stage_n[1].mispredict        |= fe_cmd_br_mispredict_li;
      stall_stage_n[1].br_ovr            |= br_ovr_i;
      stall_stage_n[1].ret_ovr           |= ret_ovr_i;
      stall_stage_n[1].jal_ovr           |= jal_ovr_i;

      // IF2
      stall_stage_n[2]                    = icache_tv_we_i ? stall_stage_r[1] : stall_stage_r[2];
      stall_stage_n[2].fe_cmd            |= fe_cmd_nonattaboy_li & ~fe_cmd_br_mispredict_li;
      stall_stage_n[2].mispredict        |= fe_cmd_br_mispredict_li;
      stall_stage_n[2].ic_miss           |= icache_miss_i;

      // ISD
      // Dispatch stalls
      stall_stage_n[3]                    = fe_queue_empty_i ? stall_stage_r[2] : '0;
      stall_stage_n[3].fe_cmd_fence      |= suppress_iss_i & ~mispredict_r;
      stall_stage_n[3].mispredict        |= mispredict_i | (suppress_iss_i & mispredict_r);
      stall_stage_n[3].data_haz          |= data_haz_i;
      stall_stage_n[3].catchup_dep       |= catchup_dep_i;
      stall_stage_n[3].aux_dep           |= aux_dep_i;
      stall_stage_n[3].load_dep          |= load_dep_i;
      stall_stage_n[3].mul_dep           |= mul_dep_i;
      stall_stage_n[3].fma_dep           |= fma_dep_i;
      stall_stage_n[3].sb_iraw_dep       |= sb_iraw_dep_i & ~sb_iraw_dc_miss_li;
      stall_stage_n[3].sb_fraw_dep       |= sb_fraw_dep_i;
      stall_stage_n[3].sb_iwaw_dep       |= sb_iwaw_dep_i & ~sb_iwaw_dc_miss_li;
      stall_stage_n[3].sb_fwaw_dep       |= sb_fwaw_dep_i;
      stall_stage_n[3].struct_haz        |= struct_haz_i;
      stall_stage_n[3].idiv_haz          |= idiv_haz_i;
      stall_stage_n[3].fdiv_haz          |= fdiv_haz_i;
      stall_stage_n[3].ptw_busy          |= ptw_busy_i;
      stall_stage_n[3].control_haz       |= control_haz_i;
      stall_stage_n[3].long_haz          |= long_haz_i;

      stall_stage_n[3].special           |= |retire_pkt_cast_i.special;
      stall_stage_n[3].mispredict        |= retire_pkt_cast_i.exception.mispredict;
      stall_stage_n[3].exception         |= commit_pkt_cast_i.exception;
      stall_stage_n[3]._interrupt        |= commit_pkt_cast_i._interrupt;
      stall_stage_n[3].itlb_miss         |= commit_pkt_cast_i.itlb_miss | commit_pkt_cast_i.itlb_fill_v;
      stall_stage_n[3].ic_miss           |= commit_pkt_cast_i.icache_miss;
      stall_stage_n[3].dtlb_miss         |= commit_pkt_cast_i.dtlb_load_miss | commit_pkt_cast_i.dtlb_store_miss | commit_pkt_cast_i.dtlb_fill_v;
      stall_stage_n[3].dc_miss           |= commit_pkt_cast_i.dcache_load_miss | commit_pkt_cast_i.dcache_store_miss;
      stall_stage_n[3].dc_miss           |= (mem_haz_i | sb_dc_miss_li);
      stall_stage_n[3].dc_fail           |= commit_pkt_cast_i.dcache_replay;

      pc_n[3]                             = commit_pkt_cast_i.npc_w_v
                                            ? commit_pkt_cast_i.pc
                                            : mispredict_i
                                              ? ex_pc_r[0]
                                              : stall_stage_n[3].mispredict
                                                ? mispredict_pc_r
                                                : (issue_v_i & ~dispatch_v_i)
                                                  ? pc_isd_haz_lo
                                                  : fe_queue_empty_i
                                                    ? isd_expected_npc_i
                                                    : '0;

      // EX1
      // BE exception stalls
      stall_stage_n[4]                    = stall_stage_r[3];
      stall_stage_n[4].special           |= |retire_pkt_cast_i.special;
      stall_stage_n[4].mispredict        |= retire_pkt_cast_i.exception.mispredict;
      stall_stage_n[4].exception         |= commit_pkt_cast_i.exception;
      stall_stage_n[4]._interrupt        |= commit_pkt_cast_i._interrupt;
      stall_stage_n[4].itlb_miss         |= commit_pkt_cast_i.itlb_miss | commit_pkt_cast_i.itlb_fill_v;
      stall_stage_n[4].ic_miss           |= commit_pkt_cast_i.icache_miss;
      stall_stage_n[4].dtlb_miss         |= commit_pkt_cast_i.dtlb_load_miss | commit_pkt_cast_i.dtlb_store_miss | commit_pkt_cast_i.dtlb_fill_v;
      stall_stage_n[4].dc_miss           |= commit_pkt_cast_i.dcache_load_miss | commit_pkt_cast_i.dcache_store_miss;
      stall_stage_n[4].dc_fail           |= commit_pkt_cast_i.dcache_replay;

      pc_n[4]                             = commit_pkt_cast_i.npc_w_v ? commit_pkt_cast_i.pc : pc_r[3];

      // EX2
      // BE exception stalls
      stall_stage_n[5]                    = stall_stage_r[4];
      stall_stage_n[5].special           |= |retire_pkt_cast_i.special;
      stall_stage_n[5].mispredict        |= retire_pkt_cast_i.exception.mispredict;
      stall_stage_n[5].exception         |= commit_pkt_cast_i.exception;
      stall_stage_n[5]._interrupt        |= commit_pkt_cast_i._interrupt;
      stall_stage_n[5].itlb_miss         |= commit_pkt_cast_i.itlb_miss | commit_pkt_cast_i.itlb_fill_v;
      stall_stage_n[5].ic_miss           |= commit_pkt_cast_i.icache_miss;
      stall_stage_n[5].dtlb_miss         |= commit_pkt_cast_i.dtlb_load_miss | commit_pkt_cast_i.dtlb_store_miss | commit_pkt_cast_i.dtlb_fill_v;
      stall_stage_n[5].dc_miss           |= commit_pkt_cast_i.dcache_load_miss | commit_pkt_cast_i.dcache_store_miss;
      stall_stage_n[5].dc_fail           |= commit_pkt_cast_i.dcache_replay;

      pc_n[5]                             = commit_pkt_cast_i.npc_w_v ? commit_pkt_cast_i.pc : pc_r[4];

      // EX3
      // BE exception stalls
      stall_stage_n[6]                    = stall_stage_r[5];
      stall_stage_n[6].mispredict        |= retire_pkt_cast_i.exception.mispredict;
      stall_stage_n[6].exception         |= commit_pkt_cast_i.exception;
      stall_stage_n[6]._interrupt        |= commit_pkt_cast_i._interrupt;
      stall_stage_n[6].itlb_miss         |= commit_pkt_cast_i.itlb_miss | commit_pkt_cast_i.itlb_fill_v;
      stall_stage_n[6].ic_miss           |= commit_pkt_cast_i.icache_miss;
      stall_stage_n[6].dtlb_miss         |= commit_pkt_cast_i.dtlb_load_miss | commit_pkt_cast_i.dtlb_store_miss | commit_pkt_cast_i.dtlb_fill_v;
      stall_stage_n[6].dc_fail           |= commit_pkt_cast_i.dcache_replay;

      pc_n[6]                             = (commit_pkt_cast_i.npc_w_v | commit_pkt_cast_i.instret) ? commit_pkt_cast_i.pc : pc_r[5];
    end

  bp_stall_reason_s stall_reason_dec;
  assign stall_reason_dec = stall_stage_n[num_stages_p-1];
  logic [$bits(bp_stall_reason_e)-1:0] stall_reason_lo;
  bp_stall_reason_e bp_stall_reason_enum;
  logic stall_reason_v;
  bsg_priority_encode
   #(.width_p($bits(bp_stall_reason_s)), .lo_to_hi_p(1))
   stall_encode
    (.i(stall_reason_dec)
     ,.addr_o(stall_reason_lo)
     ,.v_o(stall_reason_v)
     );
  assign bp_stall_reason_enum = bp_stall_reason_e'($bits(bp_stall_reason_s) - stall_reason_lo - 1);

  logic freeze_r;
  bsg_dff_chain
   #(.width_p(1), .num_stages_p(8))
   freeze_chain
    (.clk_i(clk_i)
     ,.data_i(freeze_i)
     ,.data_o(freeze_r)
     );

  // synopsys translate_off
  int stall_hist [bp_stall_reason_e];
  always_ff @(posedge clk_i)
    if (~reset_i & ~freeze_r & ~commit_pkt_cast_i.instret) begin
      stall_hist[bp_stall_reason_enum] <= stall_hist[bp_stall_reason_enum] + 1'b1;
    end

  integer file;
  string file_name;
  wire reset_li = reset_i | freeze_r;
  always_ff @(negedge reset_li)
    begin
      file_name = $sformatf("%s_%x.trace", stall_trace_file_p, mhartid_i);
      file      = $fopen(file_name, "w");
      $fwrite(file, "%s,%s,%s,%s,%s\n", "cycle", "x", "y", "pc", "operation");
    end

  wire x_cord_li = '0;
  wire y_cord_li = '0;

  always_ff @(negedge clk_i)
    begin
      if (~reset_i & ~freeze_r & commit_pkt_cast_i.instret)
        $fwrite(file, "%0d,%x,%x,%x,%s", cycle_cnt, x_cord_li, y_cord_li, commit_pkt_cast_i.pc, "instr");
      else if (~reset_i & ~freeze_r)
        $fwrite(file, "%0d,%x,%x,%x,%s", cycle_cnt, x_cord_li, y_cord_li, commit_pkt_cast_i.pc, bp_stall_reason_enum.name());

      if (~reset_i & ~freeze_r)
        $fwrite(file, "\n");
    end

  `ifndef VERILATOR
  final
    begin
      $fwrite(file, "=============================\n");
      $fwrite(file, "Total Stalls:\n");
      foreach (stall_hist[i])
        $fwrite(file, "%s: %0d\n", i.name(), stall_hist[i]);
    end
  `endif
  // synopsys translate_on

endmodule

