/*
  typedef struct packed
  {
    logic icache_miss;
    logic branch_override;
    logic ret_override;
    logic fe_cmd;
    logic fe_cmd_fence;
    logic mispredict;
    logic control_haz;
    logic long_haz;
    logic data_haz;
    logic aux_dep;
    logic load_dep;
    logic mul_dep;
    logic fma_dep;
    logic sb_iraw_dep;
    logic sb_fraw_dep;
    logic sb_iwaw_dep;
    logic sb_fwaw_dep;
    logic struct_haz;
    logic idiv_haz;
    logic fdiv_haz;
    logic ptw_busy;
    logic special;
    logic replay;
    logic exception;
    logic _interrupt;
    logic itlb_miss;
    logic dtlb_miss;
    logic dcache_miss;
    logic l2_miss;
    logic dma;
    logic unknown;
  }  bp_stall_reason_s;

  typedef enum logic [4:0]
  {
    icache_miss          = 5'd30
    ,branch_override     = 5'd29
    ,ret_override        = 5'd28
    ,fe_cmd              = 5'd27
    ,fe_cmd_fence        = 5'd26
    ,mispredict          = 5'd25
    ,control_haz         = 5'd24
    ,long_haz            = 5'd23
    ,data_haz            = 5'd22
    ,aux_dep             = 5'd21
    ,load_dep            = 5'd20
    ,mul_dep             = 5'd19
    ,fma_dep             = 5'd18
    ,sb_iraw_dep         = 5'd17
    ,sb_fraw_dep         = 5'd16
    ,sb_iwaw_dep         = 5'd15
    ,sb_fwaw_dep         = 5'd14
    ,struct_haz          = 5'd13
    ,idiv_haz            = 5'd12
    ,fdiv_haz            = 5'd11
    ,ptw_busy            = 5'd10
    ,special             = 5'd9
    ,replay              = 5'd8
    ,exception           = 5'd7
    ,_interrupt          = 5'd6
    ,itlb_miss           = 5'd5
    ,dtlb_miss           = 5'd4
    ,dcache_miss         = 5'd3
    ,l2_miss             = 5'd2
    ,dma                 = 5'd1
    ,unknown             = 5'd0
  } bp_stall_reason_e;
*/
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
    , localparam lg_l2_banks_lp = `BSG_SAFE_CLOG2(l2_banks_p)
    )
   (input clk_i
    , input reset_i
    , input freeze_i

    , input [`BSG_SAFE_CLOG2(num_core_p)-1:0] mhartid_i

    , input fe_queue_ready_i
    , input icache_ready_i

    , input if2_v_i
    , input br_ovr_i
    , input ret_ovr_i
    , input icache_data_v_i

    , input fe_cmd_yumi_i
    , input [fe_cmd_width_lp-1:0] fe_cmd_i
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

    , input m_arvalid_i
    , input m_arready_i
    , input m_rlast_i
    , input m_awvalid_i
    , input m_awready_i
    , input m_bvalid_i

    , input [retire_pkt_width_lp-1:0] retire_pkt_i
    , input [commit_pkt_width_lp-1:0] commit_pkt_i
    );

  `declare_bp_be_internal_if_structs(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `declare_bp_core_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);

  localparam num_stages_p = 7;

  bp_be_commit_pkt_s commit_pkt;
  bp_be_retire_pkt_s retire_pkt;
  bp_fe_cmd_s fe_cmd_li;
  assign retire_pkt = retire_pkt_i;
  assign commit_pkt = commit_pkt_i;
  assign fe_cmd_li = fe_cmd_i;

  wire l2_ready_li = l2_ready_i[l2_bank_i];

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
  bsg_dff_reset
   #(.width_p(1))
   mispredict_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(mispredict_i)
     ,.data_o(mispredict_r)
     );

  logic rdma_pending_r, wdma_pending_r;
  wire dma_pending_li = rdma_pending_r | wdma_pending_r;
  bsg_dff_reset_en_bypass
   #(.width_p(1))
   rdma_pending_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(m_arvalid_i | m_rlast_i)
     ,.data_i(m_arvalid_i)
     ,.data_o(rdma_pending_r)
     );

  bsg_dff_reset_en_bypass
   #(.width_p(1))
   wdma_pending_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(m_awvalid_i | m_bvalid_i)
     ,.data_i(m_awvalid_i)
     ,.data_o(wdma_pending_r)
     );

  wire fe_cmd_br_mispredict_li = fe_cmd_yumi_i & (fe_cmd_li.opcode == e_op_pc_redirection)
                               & (fe_cmd_li.operands.pc_redirect_operands.subopcode == e_subop_branch_mispredict);

  always_comb
    begin
      // IF0
      stall_stage_n[0]                    = '0;
      stall_stage_n[0].fe_cmd            |= fe_cmd_yumi_i & ~fe_cmd_br_mispredict_li;
      stall_stage_n[0].mispredict        |= fe_cmd_yumi_i & fe_cmd_br_mispredict_li;
      stall_stage_n[0].icache_miss       |= (~icache_ready_i | (if2_v_i & ~icache_data_v_i));
      stall_stage_n[0].l2_miss           |= ~icache_ready_i & ~l2_ready_li;
      stall_stage_n[0].dma               |= ~icache_ready_i & ~l2_ready_li & dma_pending_li;

      // IF1
      stall_stage_n[1]                    = stall_stage_r[0];
      stall_stage_n[1].fe_cmd            |= fe_cmd_yumi_i & ~fe_cmd_br_mispredict_li;
      stall_stage_n[1].mispredict        |= fe_cmd_yumi_i & fe_cmd_br_mispredict_li;
      stall_stage_n[1].icache_miss       |= if2_v_i & ~icache_data_v_i;
      stall_stage_n[1].branch_override   |= br_ovr_i;
      stall_stage_n[1].ret_override      |= ret_ovr_i;

      // IF2
      stall_stage_n[2]                    = stall_stage_r[1];
      stall_stage_n[2].fe_cmd            |= fe_cmd_yumi_i & ~fe_cmd_br_mispredict_li;
      stall_stage_n[2].mispredict        |= fe_cmd_yumi_i & fe_cmd_br_mispredict_li;
      stall_stage_n[2].icache_miss       |= if2_v_i & ~icache_data_v_i;

      // ISD
      // Dispatch stalls
      stall_stage_n[3]                    = fe_queue_empty_i ? stall_stage_r[2] : '0;
      stall_stage_n[3].fe_cmd_fence      |= fe_cmd_fence_i & ~mispredict_r;
      stall_stage_n[3].mispredict        |= mispredict_i | (fe_cmd_fence_i & mispredict_r);
      stall_stage_n[3].dcache_miss       |= ~dcache_ready_i;
      stall_stage_n[3].data_haz          |= data_haz_i;
      stall_stage_n[3].aux_dep           |= aux_dep_i;
      stall_stage_n[3].load_dep          |= load_dep_i;
      stall_stage_n[3].mul_dep           |= mul_dep_i;
      stall_stage_n[3].fma_dep           |= fma_dep_i;
      stall_stage_n[3].sb_iraw_dep       |= sb_iraw_dep_i;
      stall_stage_n[3].sb_fraw_dep       |= sb_fraw_dep_i;
      stall_stage_n[3].sb_iwaw_dep       |= sb_iwaw_dep_i;
      stall_stage_n[3].sb_fwaw_dep       |= sb_fwaw_dep_i;
      stall_stage_n[3].struct_haz        |= struct_haz_i;
      stall_stage_n[3].idiv_haz          |= idiv_haz_i;
      stall_stage_n[3].fdiv_haz          |= fdiv_haz_i;
      stall_stage_n[3].ptw_busy          |= ptw_busy_i;
      stall_stage_n[3].control_haz       |= control_haz_i;
      stall_stage_n[3].long_haz          |= long_haz_i;

      stall_stage_n[3].special           |= |retire_pkt.special;
      stall_stage_n[3].replay            |= |retire_pkt.exception;
      stall_stage_n[3].exception         |= commit_pkt.exception;
      stall_stage_n[3]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[3].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[3].icache_miss       |= commit_pkt.icache_miss;
      stall_stage_n[3].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[3].dcache_miss       |= commit_pkt.dcache_miss | commit_pkt.dcache_fail;
      stall_stage_n[3].l2_miss           |= ~dcache_ready_i & ~l2_ready_li;
      stall_stage_n[3].dma               |= ~dcache_ready_i & ~l2_ready_li & dma_pending_li;

      // EX1
      // BE exception stalls
      stall_stage_n[4]                    = stall_stage_r[3];
      stall_stage_n[4].special           |= |retire_pkt.special;
      stall_stage_n[4].replay            |= |retire_pkt.exception;
      stall_stage_n[4].exception         |= commit_pkt.exception;
      stall_stage_n[4]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[4].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[4].icache_miss       |= commit_pkt.icache_miss;
      stall_stage_n[4].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[4].dcache_miss       |= commit_pkt.dcache_miss | commit_pkt.dcache_fail;

      // EX2
      // BE exception stalls
      stall_stage_n[5]                    = stall_stage_r[4];
      stall_stage_n[5].special           |= |retire_pkt.special;
      stall_stage_n[5].replay            |= |retire_pkt.exception;
      stall_stage_n[5].exception         |= commit_pkt.exception;
      stall_stage_n[5]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[5].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[5].icache_miss       |= commit_pkt.icache_miss;
      stall_stage_n[5].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[5].dcache_miss       |= commit_pkt.dcache_miss | commit_pkt.dcache_fail;

      // EX3
      // BE exception stalls
      stall_stage_n[6]                    = stall_stage_r[5];
      stall_stage_n[6].special           |= |retire_pkt.special;
      stall_stage_n[6].replay            |= |retire_pkt.exception;
      stall_stage_n[6].exception         |= commit_pkt.exception;
      stall_stage_n[6]._interrupt        |= commit_pkt._interrupt;
      stall_stage_n[6].itlb_miss         |= commit_pkt.itlb_miss | commit_pkt.itlb_fill_v;
      stall_stage_n[6].icache_miss       |= commit_pkt.icache_miss;
      stall_stage_n[6].dtlb_miss         |= commit_pkt.dtlb_load_miss | commit_pkt.dtlb_store_miss | commit_pkt.dtlb_fill_v;
      stall_stage_n[6].dcache_miss       |= commit_pkt.dcache_miss | commit_pkt.dcache_fail;

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
  assign bp_stall_reason_enum = bp_stall_reason_e'(stall_reason_lo);

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

