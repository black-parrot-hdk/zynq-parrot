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
    , localparam commit_pkt_width_lp = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    , localparam retire_pkt_width_lp = `bp_be_retire_pkt_width(vaddr_width_p)
    , localparam wb_pkt_width_lp     = `bp_be_wb_pkt_width(vaddr_width_p)
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
    , input suppress_iss_i
    , input clear_iss_i
    , input mispredict_i

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
    , input [reg_addr_width_gp-1:0] sb_rs1_i
    , input [reg_addr_width_gp-1:0] sb_rs2_i
    , input [reg_addr_width_gp-1:0] sb_rd_i
    , input [1:0] sb_irs_match_i

    , input control_haz_i
    , input long_haz_i

    , input struct_haz_i
    , input mem_busy_i
    , input idiv_haz_i
    , input fdiv_haz_i
    , input ptw_busy_i

    , input [retire_pkt_width_lp-1:0] retire_pkt_i
    , input [commit_pkt_width_lp-1:0] commit_pkt_i
    , input [wb_pkt_width_lp-1:0]     iwb_pkt_i
    );

  `declare_bp_be_internal_if_structs(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `declare_bp_core_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);

  localparam num_stages_p = 7;

  bp_be_commit_pkt_s commit_pkt;
  bp_be_retire_pkt_s retire_pkt;
  bp_be_wb_pkt_s iwb_pkt;
  bp_fe_cmd_s fe_cmd_li;
  assign retire_pkt = retire_pkt_i;
  assign commit_pkt = commit_pkt_i;
  assign iwb_pkt = iwb_pkt_i;
  assign fe_cmd_li = fe_cmd_i;

  bp_stall_reason_s [num_stages_p-1:0] stall_stage_n, stall_stage_r;
  bsg_dff_reset
   #(.width_p($bits(bp_stall_reason_s)*num_stages_p))
   stall_pipe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(stall_stage_n)
     ,.data_o(stall_stage_r)
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

  logic mispredict_r;
  bsg_dff_reset_set_clear
   #(.width_p(1))
   mispredict_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.set_i(mispredict_i)
     ,.clear_i(clear_iss_i)
     ,.data_o(mispredict_r)
     );

  wire sb_dc_miss_w_li = sb_int_v_i & commit_pkt.dcache_load_miss;
  wire sb_dc_miss_clr_li = sb_int_clr_i & (iwb_pkt.rd_addr == sb_dc_miss_rd_lo);
  logic [reg_addr_width_gp-1:0] sb_dc_miss_rd_lo;
  bsg_dff_reset_en
   #(.width_p(reg_addr_width_gp))
   sb_dc_miss_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(sb_dc_miss_w_li | sb_dc_miss_clr_li)
     ,.data_i(sb_dc_miss_w_li ? sb_rd_i : '0)
     ,.data_o(sb_dc_miss_rd_lo)
     );

  wire sb_iraw_dc_miss_li = sb_iraw_dep_i & (sb_dc_miss_rd_lo == (sb_irs_match_i[0] ? sb_rs1_i : sb_rs2_i));
  wire sb_iwaw_dc_miss_li = sb_iwaw_dep_i & (sb_dc_miss_rd_lo == sb_rd_i);
  wire sb_dc_miss_li = (sb_iraw_dc_miss_li | sb_iwaw_dc_miss_li);

  wire fe_cmd_nonattaboy_li = fe_cmd_yumi_i & (fe_cmd_li.opcode != e_op_attaboy);
  wire fe_cmd_br_mispredict_li = fe_cmd_yumi_i & (fe_cmd_li.opcode == e_op_pc_redirection)
                               & (fe_cmd_li.operands.pc_redirect_operands.subopcode == e_subop_branch_mispredict);

  wire unknown_fe = fe_queue_empty_i & ~(|stall_stage_r[2]);
  wire extra_fe = ~fe_queue_empty_i & (|stall_stage_r[2]);

  always_comb
    begin
      // IF0
      stall_stage_n[0]                    = '0;

      // IF1
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

      stall_stage_n[3].special           |= |retire_pkt.special;
      //stall_stage_n[3].replay            |= |retire_pkt.exception;
      stall_stage_n[3].mispredict        |= retire_pkt.exception.mispredict;
      stall_stage_n[3].exception         |= commit_pkt.exception;
      stall_stage_n[3]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[3].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[3].ic_miss           |= commit_pkt.icache_miss;
      stall_stage_n[3].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[3].dc_miss           |= commit_pkt.dcache_load_miss | commit_pkt.dcache_store_miss;
      stall_stage_n[3].dc_miss           |= (mem_busy_i | sb_dc_miss_li);
      stall_stage_n[3].dc_fail           |= commit_pkt.dcache_replay;

      // EX1
      // BE exception stalls
      stall_stage_n[4]                    = stall_stage_r[3];
      stall_stage_n[4].special           |= |retire_pkt.special;
      //stall_stage_n[4].replay            |= |retire_pkt.exception;
      stall_stage_n[4].mispredict        |= retire_pkt.exception.mispredict;
      stall_stage_n[4].exception         |= commit_pkt.exception;
      stall_stage_n[4]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[4].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[4].ic_miss           |= commit_pkt.icache_miss;
      stall_stage_n[4].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[4].dc_miss           |= commit_pkt.dcache_load_miss | commit_pkt.dcache_store_miss;
      stall_stage_n[4].dc_fail           |= commit_pkt.dcache_replay;

      // EX2
      // BE exception stalls
      stall_stage_n[5]                    = stall_stage_r[4];
      stall_stage_n[5].special           |= |retire_pkt.special;
      //stall_stage_n[5].replay            |= |retire_pkt.exception;
      stall_stage_n[5].mispredict        |= retire_pkt.exception.mispredict;
      stall_stage_n[5].exception         |= commit_pkt.exception;
      stall_stage_n[5]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[5].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[5].ic_miss           |= commit_pkt.icache_miss;
      stall_stage_n[5].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[5].dc_miss           |= commit_pkt.dcache_load_miss | commit_pkt.dcache_store_miss;
      stall_stage_n[5].dc_fail           |= commit_pkt.dcache_replay;

      // EX3
      // BE exception stalls
      stall_stage_n[6]                    = stall_stage_r[5];
      //stall_stage_n[6].special           |= |retire_pkt.special;
      //stall_stage_n[6].replay            |= |retire_pkt.exception;
      stall_stage_n[6].mispredict        |= retire_pkt.exception.mispredict;
      stall_stage_n[6].exception         |= commit_pkt.exception;
      stall_stage_n[6]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[6].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[6].ic_miss           |= commit_pkt.icache_miss;
      stall_stage_n[6].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      //stall_stage_n[6].dc_miss           |= commit_pkt.dcache_load_miss | commit_pkt.dcache_store_miss;
      stall_stage_n[6].dc_fail           |= commit_pkt.dcache_replay;

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
    if (~reset_i & ~freeze_r & ~commit_pkt.instret) begin
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
      if (~reset_i & ~freeze_r & commit_pkt.instret)
        $fwrite(file, "%0d,%x,%x,%x,%s", cycle_cnt, x_cord_li, y_cord_li, commit_pkt.pc, "instr");
      else if (~reset_i & ~freeze_r)
        $fwrite(file, "%0d,%x,%x,%x,%s", cycle_cnt, x_cord_li, y_cord_li, commit_pkt.pc, bp_stall_reason_enum.name());

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

