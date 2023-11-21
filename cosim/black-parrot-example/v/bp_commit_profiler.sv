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
    `declare_bp_bedrock_mem_if_widths(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter `BSG_INV_PARAM(width_p)

    , localparam issue_pkt_width_lp    = `bp_be_issue_pkt_width(vaddr_width_p, branch_metadata_fwd_width_p)
    , localparam dispatch_pkt_width_lp = `bp_be_dispatch_pkt_width(vaddr_width_p)
    , localparam commit_pkt_width_lp   = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    , localparam retire_pkt_width_lp   = `bp_be_retire_pkt_width(vaddr_width_p)
    , localparam wb_pkt_width_lp       = `bp_be_wb_pkt_width(vaddr_width_p)
    , localparam lg_dma_els_lp = `BSG_SAFE_CLOG2(dma_els_p)
    )
   (input aclk_i
    , input areset_i
    , input aen_i

    , input clk_i
    , input reset_i
    , input freeze_i
    , input en_i

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

    , input mem_fwd_v_i
    , input mem_fwd_ready_and_i
    , input [mem_fwd_header_width_lp-1:0] mem_fwd_header_i

    , input mem_rev_v_i
    , input mem_rev_ready_and_i
    , input [mem_rev_header_width_lp-1:0] mem_rev_header_i

    , input dcache_v_i
    , input dcache_miss_i

    , input [lg_dma_els_lp-1:0] l2_bank_i
    , input [dma_els_p-1:0] l2_ready_i
    , input [dma_els_p-1:0] l2_miss_done_i

    , input m_arvalid_i
    , input m_arready_i
    , input m_rlast_i
    , input m_rready_i
    , input m_awvalid_i
    , input m_awready_i
    , input m_bvalid_i
    , input m_bready_i
    , input [1:0] dma_sel_i

    , output [els_p-1:0][width_p-1:0] data_o
    , output v_o
    , output instret_o
    , output [$bits(bp_stall_reason_e)-1:0] stall_o
    , output [vaddr_width_p-1:0] pc_o
    );

  `declare_bp_core_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `declare_bp_fe_branch_metadata_fwd_s(ras_idx_width_p, btb_tag_width_p, btb_idx_width_p, bht_idx_width_p, ghist_width_p, bht_row_els_p);
  `declare_bp_bedrock_mem_if(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p);
/*
  // L2
  `bp_cast_i(bp_bedrock_mem_fwd_header_s, mem_fwd_header);
  `bp_cast_i(bp_bedrock_mem_rev_header_s, mem_rev_header);

  localparam l2_cnt_width_lp = `BSG_SAFE_CLOG2(l2_block_width_p/l2_fill_width_p);
  logic [l2_cnt_width_lp-1:0] fwd_cnt_r, rev_cnt_r;
  logic l2_serving_ic_li, l2_serving_dfetch_li, l2_serving_devict_li;
  wire l2_backlog_li = mem_fwd_v_i & ~mem_fwd_ready_and_i;
  wire [l2_cnt_width_lp-1:0] fwd_size_li = `BSG_MAX((1'b1 << mem_fwd_header_cast_i.size)/(l2_fill_width_p>>3), 1'b1) - 1'b1;
  wire [l2_cnt_width_lp-1:0] rev_size_li = `BSG_MAX((1'b1 << mem_rev_header_cast_i.size)/(l2_fill_width_p>>3), 1'b1) - 1'b1;
  wire mem_fwd_new_li = mem_fwd_v_i & mem_fwd_ready_and_i & (fwd_cnt_r == '0);
  wire mem_fwd_last_li = mem_fwd_v_i & mem_fwd_ready_and_i & (fwd_cnt_r == fwd_size_li);
  wire mem_rev_new_li = mem_rev_v_i & mem_rev_ready_and_i & (rev_cnt_r == '0);
  wire mem_rev_last_li = mem_rev_v_i & mem_rev_ready_and_i & (rev_cnt_r == rev_size_li);

  bsg_counter_clear_up
   #(.max_val_p(2**l2_cnt_width_lp-1))
   fwd_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.clear_i(mem_fwd_v_i & mem_fwd_ready_and_i & mem_fwd_last_li)
     ,.up_i(mem_fwd_v_i & mem_fwd_ready_and_i & ~mem_fwd_last_li)
     ,.count_o(fwd_cnt_r)
     );

  bsg_counter_clear_up
   #(.max_val_p(2**l2_cnt_width_lp-1))
   rev_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.clear_i(mem_rev_v_i & mem_rev_ready_and_i & mem_rev_last_li)
     ,.up_i(mem_rev_v_i & mem_rev_ready_and_i & ~mem_rev_last_li)
     ,.count_o(rev_cnt_r)
     );

  bsg_dff_reset_set_clear
   #(.width_p(1))
   ic_reg
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(mem_fwd_new_li & ~mem_fwd_header_cast_i.payload.lce_id[0])
    ,.clear_i(mem_rev_last_li & ~mem_rev_header_cast_i.payload.lce_id[0])
    ,.data_o(l2_serving_ic_li)
    );

  bsg_dff_reset_set_clear
   #(.width_p(1))
   dfetch_reg
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(mem_fwd_new_li & mem_fwd_header_cast_i.payload.lce_id[0] & (mem_fwd_header_cast_i.msg_type.fwd != e_bedrock_mem_wr))
    ,.clear_i(mem_rev_last_li & mem_rev_header_cast_i.payload.lce_id[0] & (mem_rev_header_cast_i.msg_type.rev != e_bedrock_mem_wr))
    ,.data_o(l2_serving_dfetch_li)
    );

  bsg_dff_reset_set_clear
   #(.width_p(1))
   devict_reg
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(mem_fwd_new_li & mem_fwd_header_cast_i.payload.lce_id[0] & (mem_fwd_header_cast_i.msg_type.fwd == e_bedrock_mem_wr))
    ,.clear_i(mem_rev_last_li & mem_rev_header_cast_i.payload.lce_id[0] & (mem_rev_header_cast_i.msg_type.rev == e_bedrock_mem_wr))
    ,.data_o(l2_serving_devict_li)
    );

  // Branching
  bp_fe_cmd_s fe_cmd_li;
  bp_fe_branch_metadata_fwd_s br_metadata;
  assign fe_cmd_li = fe_cmd_i;
  wire attaboy_li = fe_cmd_yumi_i & (fe_cmd_li.opcode == e_op_attaboy);
  wire br_mispredict_li = fe_cmd_yumi_i & (fe_cmd_li.opcode == e_op_pc_redirection)
                               & (fe_cmd_li.operands.pc_redirect_operands.subopcode == e_subop_branch_mispredict);
  assign br_metadata = attaboy_li
                       ? fe_cmd_li.operands.attaboy.branch_metadata_fwd
                       : fe_cmd_li.operands.pc_redirect_operands.branch_metadata_fwd;

  // DMA
  logic [1:0] rdma_sel_li, wdma_sel_li;
  logic ic_rdma_r, dfetch_rdma_r;
  logic ic_wdma_r, dfetch_wdma_r, devict_wdma_r;
  wire ic_rdma_li = ic_rdma_r | (m_arvalid_i & m_arready_i & (dma_sel_i == 2'b00));
  wire ic_wdma_li = ic_wdma_r | (m_awvalid_i & m_awready_i & (dma_sel_i == 2'b00));
  wire ic_dma_li = ic_rdma_li | ic_wdma_li;
  wire dfetch_rdma_li = dfetch_rdma_r | (m_arvalid_i & m_arready_i & (dma_sel_i == 2'b01));
  wire dfetch_wdma_li = dfetch_wdma_r | (m_awvalid_i & m_awready_i & (dma_sel_i == 2'b01));
  wire dfetch_dma_li = dfetch_rdma_li | dfetch_wdma_li;
  wire devict_wdma_li = devict_wdma_r | (m_awvalid_i & m_awready_i & (dma_sel_i == 2'b10));

  always_ff @(posedge clk_i) begin
    if(reset_i | freeze_i) begin
      ic_rdma_r <= 1'b0;
      ic_wdma_r <= 1'b0;
      dfetch_rdma_r <= 1'b0;
      dfetch_wdma_r <= 1'b0;
      devict_wdma_r <= 1'b0;
    end
    else begin
      if(m_rlast_i) begin
        casez(rdma_sel_li)
          2'b00: ic_rdma_r <= 1'b0;
          2'b01: dfetch_rdma_r <= 1'b0;
        endcase
      end
      if(m_arvalid_i & m_arready_i) begin
        casez(dma_sel_i)
          2'b00: ic_rdma_r <= 1'b1;
          2'b01: dfetch_rdma_r <= 1'b1;
        endcase
      end
      if(m_bvalid_i) begin
        casez(wdma_sel_li)
          2'b00: ic_wdma_r <= 1'b0;
          2'b01: dfetch_wdma_r <= 1'b0;
          2'b10: devict_wdma_r <= 1'b0;
        endcase
      end
      if(m_awvalid_i & m_awready_i) begin
        casez(dma_sel_i)
          2'b00: ic_wdma_r <= 1'b1;
          2'b01: dfetch_wdma_r <= 1'b1;
          2'b10: devict_wdma_r <= 1'b1;
        endcase
      end
    end
  end

  bsg_fifo_1r1w_small
   #(.width_p(2), .els_p(l2_outstanding_reqs_p))
   rdma_sel_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(m_arvalid_i & m_arready_i)
     ,.data_i(dma_sel_i)
     ,.ready_o()

     ,.v_o()
     ,.data_o(rdma_sel_li)
     ,.yumi_i(m_rlast_i & m_rready_i)
     );

  bsg_fifo_1r1w_small
   #(.width_p(2), .els_p(l2_outstanding_reqs_p))
   wdma_sel_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(m_awvalid_i & m_awready_i)
     ,.data_i(dma_sel_i)
     ,.ready_o()

     ,.v_o()
     ,.data_o(wdma_sel_li)
     ,.yumi_i(m_bvalid_i & m_bready_i)
     );
*/
  // Profiler
  // TODO: extend to multicore
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

  localparam stall_offset_lp = 3;
  localparam event_offset_lp = 3 + $bits(bp_stall_reason_s);

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

  // cycle, mcycle, and instret
  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   cycle_cnt
    (.clk_i(aclk_i)
    ,.reset_i(areset_i)
    ,.clear_i(1'b0)
    ,.up_i(aen_i)
    ,.count_o(data_o[0])
    );

  `declare_counter(mcycle,1'b1,1)
  `declare_counter(minstret,prof.commit_pkt_cast_i.instret,2)

  // Stalls
  // Assigned to counters: 3-33
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

  // Events
  // L1
/*
  wire icache_ready_li = ~icache_miss_i;
  wire dcache_ready_li = ~dcache_miss_i;
  logic icache_ready_r, dcache_ready_r;
  logic dcache_v_r, dcache_v_rr;
  logic l2_serving_ic_r, l2_serving_dfetch_r, l2_serving_devict_r;
  bsg_dff_reset
   #(.width_p(7))
   flop_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i({dcache_v_r, dcache_v_i, icache_ready_li, dcache_ready_li, l2_serving_ic_li, l2_serving_dfetch_li, l2_serving_devict_li})
     ,.data_o({dcache_v_rr, dcache_v_r, icache_ready_r, dcache_ready_r, l2_serving_ic_r, l2_serving_dfetch_r, l2_serving_devict_r})
     );

  `declare_event_counter(e_ic_req_cnt, icache_yumi_i)
  `declare_event_counter(e_ic_miss_cnt, ~icache_ready_li & icache_ready_r)
  `declare_event_counter(e_ic_miss, ~icache_ready_li)

  `declare_event_counter(e_dc_req_cnt, dcache_v_rr & dcache_ready_r & ~prof.commit_pkt_cast_i.dcache_replay)
  `declare_event_counter(e_dc_miss_cnt, ~dcache_ready_li & dcache_ready_r)
  `declare_event_counter(e_dc_miss, ~dcache_ready_li)

  // L2 and DMA
  // TODO: works only for single-bank L2
  // L2 during L1 miss
  `declare_event_counter(e_ic_miss_l2_ic, ~icache_ready_li & l2_serving_ic_li)
  `declare_event_counter(e_ic_miss_l2_dfetch, ~icache_ready_li & l2_backlog_li & l2_serving_dfetch_li)
  `declare_event_counter(e_ic_miss_l2_devict, ~icache_ready_li & l2_backlog_li & l2_serving_devict_li)

  `declare_event_counter(e_dc_miss_l2_ic, ~dcache_ready_li & l2_backlog_li & l2_serving_ic_li)
  `declare_event_counter(e_dc_miss_l2_dfetch, ~dcache_ready_li & l2_serving_dfetch_li)
  `declare_event_counter(e_dc_miss_l2_devict, ~dcache_ready_li & l2_backlog_li & l2_serving_devict_li)
 
  // L2 miss
  `declare_event_counter(e_l2_ic_cnt, l2_serving_ic_li & ~l2_serving_ic_r)
  `declare_event_counter(e_l2_dfetch_cnt, l2_serving_dfetch_li & ~l2_serving_dfetch_r)
  `declare_event_counter(e_l2_devict_cnt, l2_serving_devict_li & ~l2_serving_devict_r)

  `declare_event_counter(e_l2_ic, l2_serving_ic_li)
  `declare_event_counter(e_l2_dfetch, l2_serving_dfetch_li)
  `declare_event_counter(e_l2_devict, l2_serving_devict_li)

  `declare_event_counter(e_l2_ic_miss_cnt, l2_en_p ? (l2_miss_done_i[l2_bank_i] & (dma_sel_i == 2'b00)) : (l2_serving_ic_li & ~l2_serving_ic_r))
  `declare_event_counter(e_l2_dfetch_miss_cnt, l2_en_p ? (l2_miss_done_i[l2_bank_i] & (dma_sel_i == 2'b01)) : (l2_serving_dfetch_li & ~l2_serving_dfetch_r))
  `declare_event_counter(e_l2_devict_miss_cnt, l2_en_p ? (l2_miss_done_i[l2_bank_i] & (dma_sel_i == 2'b10)) : (l2_serving_devict_li & ~l2_serving_devict_r))

  `declare_event_counter(e_l2_ic_miss, l2_en_p ? (~l2_ready_i[l2_bank_i] & (dma_sel_i == 2'b00)) : l2_serving_ic_li)
  `declare_event_counter(e_l2_dfetch_miss, l2_en_p ? (~l2_ready_i[l2_bank_i] & (dma_sel_i == 2'b01)) : l2_serving_dfetch_li)
  `declare_event_counter(e_l2_devict_miss, l2_en_p ? (~l2_ready_i[l2_bank_i] & (dma_sel_i == 2'b10)) : l2_serving_devict_li)

  // DMA during L2 miss
  `declare_event_counter(e_l2_ic_dma, ~l2_ready_i[l2_bank_i] & l2_serving_ic_li & ic_dma_li)
  `declare_event_counter(e_l2_dfetch_dma, ~l2_ready_i[l2_bank_i] & l2_serving_dfetch_li & dfetch_dma_li)
  `declare_event_counter(e_l2_devict_dma, ~l2_ready_i[l2_bank_i] & l2_serving_devict_li & devict_wdma_li)

  // DMA
  `declare_event_counter(e_wdma_ic_cnt, m_awvalid_i & m_awready_i & (dma_sel_i == 2'b00))
  `declare_event_counter(e_rdma_ic_cnt, m_arvalid_i & m_arready_i & (dma_sel_i == 2'b00))
  `declare_event_counter(e_wdma_ic, ic_wdma_li)
  `declare_event_counter(e_rdma_ic, ic_rdma_li)
  `declare_event_counter(e_dma_ic, ic_dma_li)

  `declare_event_counter(e_wdma_dfetch_cnt, m_awvalid_i & m_awready_i & (dma_sel_i == 2'b01))
  `declare_event_counter(e_rdma_dfetch_cnt, m_arvalid_i & m_arready_i & (dma_sel_i == 2'b01))
  `declare_event_counter(e_wdma_dfetch, dfetch_wdma_li)
  `declare_event_counter(e_rdma_dfetch, dfetch_rdma_li)
  `declare_event_counter(e_dma_dfetch, dfetch_dma_li)

  `declare_event_counter(e_wdma_devict_cnt, m_awvalid_i & m_awready_i & (dma_sel_i == 2'b10))
  `declare_event_counter(e_wdma_devict, devict_wdma_li)
*/
endmodule
