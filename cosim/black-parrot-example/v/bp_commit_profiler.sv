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
    , parameter width_p = 32

    , localparam commit_pkt_width_lp = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    , localparam retire_pkt_width_lp = `bp_be_retire_pkt_width(vaddr_width_p)
    , localparam wb_pkt_width_lp     = `bp_be_wb_pkt_width(vaddr_width_p)
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

    , input sb_int_v_i
    , input sb_int_clr_i
    , input [reg_addr_width_gp-1:0] sb_rs1_i
    , input [reg_addr_width_gp-1:0] sb_rs2_i
    , input [reg_addr_width_gp-1:0] sb_rd_i
    , input [1:0] sb_irs_match_i

    , input [lg_l2_banks_lp-1:0] l2_bank_i
    , input [l2_banks_p-1:0] l2_ready_i
    , input [l2_banks_p-1:0] l2_miss_done_i
    , input l2_backlog_i
    , input l2_serving_ic_i
    , input l2_serving_dfetch_i
    , input l2_serving_devict_i

    , input dc_miss_i
    , input dc_late_i
    , input dc_resume_i
    , input dc_busy_i

    , input m_arvalid_i
    , input m_arready_i
    , input m_rlast_i
    , input m_rready_i
    , input m_awvalid_i
    , input m_awready_i
    , input m_bvalid_i
    , input m_bready_i
    , input [1:0] dma_sel_i

    , input icache_valid_i
    , input dcache_valid_i

    , input flong_v_i
    , input flong_ready_i

    , input ilong_v_i
    , input ilong_ready_i

    , input [retire_pkt_width_lp-1:0] retire_pkt_i
    , input [commit_pkt_width_lp-1:0] commit_pkt_i
    , input [wb_pkt_width_lp-1:0]     iwb_pkt_i

    , output [75:0][width_p-1:0] data_o
    );

  `declare_bp_core_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `declare_bp_fe_branch_metadata_fwd_s(btb_tag_width_p, btb_idx_width_p, bht_idx_width_p, ghist_width_p, bht_row_width_p);

  // Branching
  bp_fe_cmd_s fe_cmd_li;
  bp_fe_branch_metadata_fwd_s br_metadata;
  assign fe_cmd_li = fe_cmd_i;
  assign br_metadata = attaboy_li
                       ? fe_cmd_li.operands.attaboy.branch_metadata_fwd
                       : fe_cmd_li.operands.pc_redirect_operands.branch_metadata_fwd;

  wire br_mispredict_li = fe_cmd_yumi_i & (fe_cmd_li.opcode == e_op_pc_redirection)
                               & (fe_cmd_li.operands.pc_redirect_operands.subopcode == e_subop_branch_mispredict);
  wire attaboy_li = fe_cmd_yumi_i & (fe_cmd_li.opcode == e_op_attaboy);

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

  // Profiler
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
  `define declare_stall_counter(name,i)                             \
  bsg_counter_clear_up                                              \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))        \
   ``name``_cnt                                                     \
   (.clk_i(clk_i)                                                   \
   ,.reset_i(reset_i)                                               \
   ,.clear_i(freeze_i)                                              \
   ,.up_i(en_i & stall_v & (prof.stall_reason_lo == bp_profiler_pkg::``name``))      \
   ,.count_o(data_o[``i``])                                         \
   );

  `declare_stall_counter(ic_miss,2)
  `declare_stall_counter(branch_override,3)
  `declare_stall_counter(ret_override,4)
  `declare_stall_counter(fe_cmd,5)
  `declare_stall_counter(fe_cmd_fence,6)
  `declare_stall_counter(mispredict,7)
  `declare_stall_counter(control_haz,8)
  `declare_stall_counter(long_haz,9)
  `declare_stall_counter(data_haz,10)
  `declare_stall_counter(aux_dep,11)
  `declare_stall_counter(load_dep,12)
  `declare_stall_counter(mul_dep,13)
  `declare_stall_counter(fma_dep,14)
  `declare_stall_counter(sb_iraw_dep,15)
  `declare_stall_counter(sb_fraw_dep,16)
  `declare_stall_counter(sb_iwaw_dep,17)
  `declare_stall_counter(sb_fwaw_dep,18)
  `declare_stall_counter(struct_haz,19)
  `declare_stall_counter(idiv_haz,20)
  `declare_stall_counter(fdiv_haz,21)
  `declare_stall_counter(ptw_busy,22)
  `declare_stall_counter(special,23)
  `declare_stall_counter(replay,24)
  `declare_stall_counter(exception,25)
  `declare_stall_counter(_interrupt,26)
  `declare_stall_counter(itlb_miss,27)
  `declare_stall_counter(dtlb_miss,28)
  `declare_stall_counter(dc_miss,29)
  `declare_stall_counter(dc_fail,30)
  `declare_stall_counter(unknown,31)


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

  `declare_counter(mcycle,1'b1,0)
  `declare_counter(minstret,prof.commit_pkt.instret,1)

  // Metrics
  // L1
  logic icache_ready_r, dcache_ready_r;
  logic dcache_valid_r, dcache_valid_rr;
  logic l2_serving_ic_r, l2_serving_dfetch_r, l2_serving_devict_r;
  bsg_dff_reset
   #(.width_p(5))
   flop_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i({icache_ready_i, dcache_ready_i, l2_serving_ic_i, l2_serving_dfetch_i, l2_serving_devict_i})
     ,.data_o({icache_ready_r, dcache_ready_r, l2_serving_ic_r, l2_serving_dfetch_r, l2_serving_devict_r})
     );

  bsg_dff_reset
   #(.width_p(2))
   dcache_valid_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i({dcache_valid_i, dcache_valid_r})
     ,.data_o({dcache_valid_r, dcache_valid_rr})
     );

  `declare_counter(e_ic_req_cnt,(icache_valid_i & icache_ready_i),32)
  `declare_counter(e_ic_miss_cnt,(~icache_ready_i & icache_ready_r),33)
  `declare_counter(e_ic_miss,~icache_ready_i,34)

  `declare_counter(e_dc_req_cnt,(dcache_valid_rr & dcache_ready_r & ~prof.commit_pkt.dcache_fail),35)
  `declare_counter(e_dc_miss_cnt,(~dcache_ready_i & dcache_ready_r),36)
  `declare_counter(e_dc_miss,~dcache_ready_i,37)

  // L2 and DMA
  // TODO: works only for 1 bank L2
  // L2 under L1 miss
  `declare_counter(e_ic_miss_l2_ic,(~icache_ready_i & l2_serving_ic_i),38)
  `declare_counter(e_ic_miss_l2_dc_fetch,(~icache_ready_i & l2_backlog_i & l2_serving_dfetch_i),39)
  `declare_counter(e_ic_miss_l2_dc_evict,(~icache_ready_i & l2_backlog_i & l2_serving_devict_i),40)

  `declare_counter(e_dc_miss_l2_ic,(~dcache_ready_i & l2_backlog_i & l2_serving_ic_i),41)
  `declare_counter(e_dc_miss_l2_dc_fetch,(~dcache_ready_i & l2_serving_dfetch_i),42)
  `declare_counter(e_dc_miss_l2_dc_evict,(~dcache_ready_i & l2_backlog_i & l2_serving_devict_i),43)
 
  `declare_counter(e_dc_miss_is_miss,(~dcache_ready_i & dc_miss_i),44)
  `declare_counter(e_dc_miss_is_late,(~dcache_ready_i & dc_late_i),45)
  `declare_counter(e_dc_miss_is_resume,(~dcache_ready_i & dc_resume_i),46)
  `declare_counter(e_dc_miss_is_busy_cnt,(~dcache_ready_i & dcache_ready_r & dc_busy_i),47)
  `declare_counter(e_dc_miss_is_busy,(~dcache_ready_i & dc_busy_i),48)

  // L2 miss
  `declare_counter(e_l2_ic_cnt,l2_serving_ic_i & ~l2_serving_ic_r,49)
  `declare_counter(e_l2_dc_fetch_cnt,l2_serving_dfetch_i & ~l2_serving_dfetch_r,50)
  `declare_counter(e_l2_dc_evict_cnt,l2_serving_devict_i & ~l2_serving_devict_r,51)

  `declare_counter(e_l2_ic,l2_serving_ic_i,52)
  `declare_counter(e_l2_dc_fetch,l2_serving_dfetch_i,53)
  `declare_counter(e_l2_dc_evict,l2_serving_devict_i,54)

  `declare_counter(e_l2_ic_miss_cnt,(l2_en_p ? (l2_miss_done_i[l2_bank_i] & (dma_sel_i == 2'b00)) : (l2_serving_ic_i & ~l2_serving_ic_r)),55)
  `declare_counter(e_l2_dc_fetch_miss_cnt,(l2_en_p ? (l2_miss_done_i[l2_bank_i] & (dma_sel_i == 2'b01)) : (l2_serving_dfetch_i & ~l2_serving_dfetch_r)),56)
  `declare_counter(e_l2_dc_evict_miss_cnt,(l2_en_p ? (l2_miss_done_i[l2_bank_i] & (dma_sel_i == 2'b10)) : (l2_serving_devict_i & ~l2_serving_devict_r)),57)

  `declare_counter(e_l2_ic_miss,(l2_en_p ? (~l2_ready_i[l2_bank_i] & (dma_sel_i == 2'b00)) : l2_serving_ic_i),58)
  `declare_counter(e_l2_dc_fetch_miss,(l2_en_p ? (~l2_ready_i[l2_bank_i] & (dma_sel_i == 2'b01)) : l2_serving_dfetch_i),59)
  `declare_counter(e_l2_dc_evict_miss,(l2_en_p ? (~l2_ready_i[l2_bank_i] & (dma_sel_i == 2'b10)) : l2_serving_devict_i),60)

  //`declare_counter(e_l2_ic_miss_cnt,((l2_en_p ? l2_miss_done_i[l2_bank_i] : ~l2_serving_ic_r) & l2_serving_ic_i),55)
  //`declare_counter(e_l2_dc_fetch_miss_cnt,((l2_en_p ? l2_miss_done_i[l2_bank_i] : ~l2_serving_dfetch_r) & l2_serving_dfetch_i),56)
  //`declare_counter(e_l2_dc_evict_miss_cnt,((l2_en_p ? l2_miss_done_i[l2_bank_i] : ~l2_serving_devict_r) & l2_serving_devict_i),57)

  //`declare_counter(e_l2_ic_miss,~l2_ready_i[l2_bank_i] & l2_serving_ic_i,58)
  //`declare_counter(e_l2_dc_fetch_miss,~l2_ready_i[l2_bank_i] & l2_serving_dfetch_i,59)
  //`declare_counter(e_l2_dc_evict_miss,~l2_ready_i[l2_bank_i] & l2_serving_devict_i,60)

  // DMA under L2 miss
  `declare_counter(e_l2_ic_dma,(~l2_ready_i[l2_bank_i] & l2_serving_ic_i & ic_dma_li),61)
  `declare_counter(e_l2_dc_fetch_dma,(~l2_ready_i[l2_bank_i] & l2_serving_dfetch_i & dfetch_dma_li),62)
  `declare_counter(e_l2_dc_evict_dma,(~l2_ready_i[l2_bank_i] & l2_serving_devict_i & devict_wdma_li),63)

  // DMA
  `declare_counter(e_wdma_ic_cnt,(m_awvalid_i & m_awready_i & (dma_sel_i == 2'b00)),64)
  `declare_counter(e_rdma_ic_cnt,(m_arvalid_i & m_arready_i & (dma_sel_i == 2'b00)),65)
  `declare_counter(e_wdma_ic,ic_wdma_li,66)
  `declare_counter(e_rdma_ic,ic_rdma_li,67)
  `declare_counter(e_dma_ic,ic_dma_li,68)

  `declare_counter(e_wdma_dc_fetch_cnt,(m_awvalid_i & m_awready_i & (dma_sel_i == 2'b01)),69)
  `declare_counter(e_rdma_dc_fetch_cnt,(m_arvalid_i & m_arready_i & (dma_sel_i == 2'b01)),70)
  `declare_counter(e_wdma_dc_fetch,dfetch_wdma_li,71)
  `declare_counter(e_rdma_dc_fetch,dfetch_rdma_li,72)
  `declare_counter(e_dma_dc_fetch,dfetch_dma_li,73)

  `declare_counter(e_wdma_dc_evict_cnt,(m_awvalid_i & m_awready_i & (dma_sel_i == 2'b10)),74)
  `declare_counter(e_wdma_dc_evict,devict_wdma_li,75)

/*
  // Prediction
  `declare_counter(e_br_cnt,((br_mispredict_li | attaboy_li) & br_metadata.is_br),64)
  `declare_counter(e_br_miss,(br_mispredict_li & br_metadata.is_br),65)
  `declare_counter(e_jalr_cnt,((br_mispredict_li | attaboy_li) & br_metadata.is_jalr & ~br_metadata.is_ret),66)
  `declare_counter(e_jalr_miss,(br_mispredict_li & br_metadata.is_jalr & ~br_metadata.is_ret),67)
  `declare_counter(e_ret_cnt,((br_mispredict_li | attaboy_li) & br_metadata.is_ret),68)
  `declare_counter(e_ret_miss,(br_mispredict_li & br_metadata.is_ret),69)

  // FPU
  `declare_counter(e_fpu_flong_cnt,(flong_v_i & flong_ready_i),70)
  `declare_counter(e_fpu_flong_wait,(~flong_ready_i),71)

  // DIV
  `declare_counter(e_div_cnt,(ilong_v_i & ilong_ready_i),72)
  `declare_counter(e_div_wait,(~ilong_ready_i),73)
*/

/*
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
*/

endmodule
