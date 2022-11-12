
  typedef struct packed
  {
    logic iq_full;
    logic ic_invl;
    logic ic_miss;
    logic ic_dma;
    logic ic_flush;
    logic ic_atrans;
    logic bp_haz;
    logic ireplay;
    logic realign;
    logic sb_full;
    logic waw_flu;
    logic waw_lsu;
    logic waw_fpu;
    logic waw_reorder;
    logic raw_flu;
    logic raw_lsu;
    logic raw_fpu;
    logic br_haz;
    logic br_miss;
    logic mul_haz;
    logic csr_buf;
    logic div_busy;
    logic ld_pipe;
    logic ld_grant;
    logic st_pipe;
    logic sbuf_spec;
    logic fpu_busy;
    logic amo_flush;
    logic csr_flush;
    logic fence;
    logic exception;
    logic dc_pipe;
    logic dc_miss;
    logic dc_dma;
    logic cmt_haz;
    logic unknown;
  } stall_reason_s;

  typedef enum logic [5:0]
  {
     iq_full      = 6'd35
     ,ic_invl     = 6'd34
     ,ic_miss     = 6'd33
     ,ic_dma      = 6'd32
     ,ic_flush    = 6'd31
     ,ic_atrans   = 6'd30
     ,bp_haz      = 6'd29
     ,ireplay     = 6'd28
     ,realign     = 6'd27
     ,sb_full     = 6'd26
     ,waw_flu     = 6'd25
     ,waw_lsu     = 6'd24
     ,waw_fpu     = 6'd23
     ,waw_reorder = 6'd22
     ,raw_flu     = 6'd21
     ,raw_lsu     = 6'd20
     ,raw_fpu     = 6'd19
     ,br_haz      = 6'd18
     ,br_miss     = 6'd17
     ,mul_haz     = 6'd16
     ,csr_buf     = 6'd15
     ,div_busy    = 6'd14
     ,ld_pipe     = 6'd13
     ,ld_grant    = 6'd12
     ,st_pipe     = 6'd11
     ,sbuf_spec   = 6'd10
     ,fpu_busy    = 6'd9
     ,amo_flush   = 6'd8
     ,csr_flush   = 6'd7
     ,fence       = 6'd6
     ,exception   = 6'd5
     ,dc_pipe     = 6'd4
     ,dc_miss     = 6'd3
     ,dc_dma      = 6'd2
     ,cmt_haz     = 6'd1
     ,unknown     = 6'd0
  } stall_reason_e;

module ariane_commit_profiler
  import ariane_pkg::*;
  #(parameter width_p = 64
   )
   (input clk_i
    , input reset_i
    , input en_i

    , input instr_qeueu_valid_i
    , input instr_queue_ready_i
    , input fe_bp_valid_i
    , input fe_replay_i
    , input fe_realign_bubble_i

    , input icache_valid_i
    , input icache_ready_i
    , input icache_flush_d_i
    , input icache_rtrn_vld_i
    , input icache_hit_i
    , input [2:0] icache_state_q_i
    , input [2:0] icache_state_d_i

    , input flush_unissued_instr_i
    , input flush_ex_i
    , input branch_mispredict_i
    , input flush_amo_i
    , input flush_csr_i
    , input exception_i

    , input is_valid_i
    , input is_ack_i
    , input is_unresolved_branch_i
    , input is_sb_full_i
    , input is_ro_stall_i
    , input is_ro_fubusy_i
    , input scoreboard_entry_t is_instr_i
    , input fu_t [2**REG_ADDR_SIZE-1:0] is_rd_clobber_gpr_i
    , input fu_t [2**REG_ADDR_SIZE-1:0] is_rd_clobber_fpr_i
    , input is_forward_rs1_i
    , input is_forward_rs2_i
    , input is_forward_rs3_i
    , input is_forward_rd_i

    , input ex_mul_valid_i
    , input ex_csr_ready_i
    , input ex_div_ready_i
    , input ex_fpu_busy_i

    , input wb_flu_valid_i
    , input wb_fpu_valid_i
    , input wb_ld_valid_i
    , input wb_st_valid_i

    , input lsu_ctrl_t lsu_ctrl_i
    , input pop_ld_i
    , input ld_done_i
    , input [3:0] ld_state_q_i
    , input [3:0] ld_state_d_i
    , input [1:0] st_state_q_i

    , input issue_en_i
    , input [$clog2(NR_SB_ENTRIES)-1:0] issue_pointer_q_i

    , input [1:0] cmt_ack_i
    , input scoreboard_entry_t [1:0] cmt_instr_i
    , input cmt_issued_q_i
    , input cmt_lsu_ready_i
    , input [$clog2(NR_SB_ENTRIES)-1:0] cmt_pointer_q_i

    , input m_arvalid_i
    , input m_arready_i
    , input [4:0] m_arid_i
    , input m_rlast_i

    , input m_awvalid_i
    , input m_awready_i
    , input [4:0] m_awid_i
    , input m_bvalid_i

    , input icache_dreq_i_t ic_dreq_i
    , input icache_dreq_o_t ic_dresp_i
    , input ic_miss_i
    , input dcache_req_i_t [2:0] dc_req_i
    , input dcache_req_o_t [2:0] dc_resp_i
    , input [2:0] dc_miss_gnt_i
    , input [3:0] dc_st_state_i

    , input fu_data_t bu_fu_data_i
    , input bp_resolve_t bu_resolved_branch_i

    , input [fpnew_pkg::NUM_OPGROUPS-1:0] fpu_opgrp_req_i
    , input [fpnew_pkg::NUM_OPGROUPS-1:0] fpu_opgrp_busy_i

    , input div_valid_i
    , input div_ready_i

    , output [62:0][width_p-1:0] data_o
  );

  typedef enum logic [2:0] {IC_FLUSH, IC_IDLE, IC_READ, IC_MISS, IC_KILL_ATRANS, IC_KILL_MISS} icache_state_e;
  typedef enum logic [3:0] {LD_IDLE, LD_WAIT_GNT, LD_SEND_TAG, LD_WAIT_PAGE_OFFSET,
                            LD_ABORT_TRANSACTION, LD_ABORT_TRANSACTION_NI, LD_WAIT_TRANSLATION, LD_WAIT_FLUSH,
                            LD_WAIT_WB_EMPTY} load_state_e;
  typedef enum logic [1:0] {ST_IDLE, ST_VALID_STORE, ST_WAIT_TRANSLATION, ST_WAIT_STORE_READY} store_state_e;

  stall_reason_s pc, pc_r, ic, ic_r, re, re_r, fe, ic_busy;
  stall_reason_s id, id_r, is, is_r, ex, ex_r;
  stall_reason_s flu, st, fpu, commit;
  stall_reason_s [1:0] ld, ld_r;
  stall_reason_s [3:0] wb, wb_r;

  fu_t rs1_clobber_li, rs2_clobber_li, raw_clobber_li, waw_clobber_li;
  logic[REG_ADDR_SIZE-1:0] raw_rs_li;
  logic [1:0] ld_cntr;
  logic issue_en_r;
  logic [$clog2(NR_SB_ENTRIES)-1:0] issue_pointer_q_r;

  //I$ stalls
  wire icache_atrans = ((icache_state_q_i inside {IC_READ}) & (icache_state_d_i inside {IC_READ, IC_KILL_ATRANS}) & ~icache_hit_i) | (icache_state_q_i inside {IC_KILL_ATRANS});
  wire icache_flush = ((icache_state_q_i inside {IC_READ}) & icache_flush_d_i) | (icache_state_q_i inside {IC_FLUSH});
  wire icache_miss = ((icache_state_q_i inside {IC_READ}) & ~icache_hit_i) | (icache_state_q_i inside {IC_MISS, IC_KILL_MISS});
  wire icache_invl = (icache_state_q_i inside {IC_IDLE, IC_READ}) & icache_rtrn_vld_i;

  // Clobber
  assign rs1_clobber_li = is_rs1_fpr(is_instr_i.op) ? is_rd_clobber_fpr_i[is_instr_i.rs1] : is_rd_clobber_gpr_i[is_instr_i.rs1];
  assign rs2_clobber_li = is_rs2_fpr(is_instr_i.op) ? is_rd_clobber_fpr_i[is_instr_i.rs2] : is_rd_clobber_gpr_i[is_instr_i.rs2];
  assign {raw_rs_li, raw_clobber_li}
                        = (!is_forward_rs3_i && is_imm_fpr(is_instr_i.op) && (is_rd_clobber_fpr_i[is_instr_i.result[REG_ADDR_SIZE-1:0]] != NONE))
                          ? {is_instr_i.result[REG_ADDR_SIZE-1:0], is_rd_clobber_fpr_i[is_instr_i.result[REG_ADDR_SIZE-1:0]]}
                          : (!is_forward_rs2_i && (rs2_clobber_li != NONE))
                            ? {is_instr_i.rs2, rs2_clobber_li}
                            : {is_instr_i.rs1, rs1_clobber_li};
  assign waw_clobber_li = is_rd_fpr(is_instr_i.op) ? is_rd_clobber_fpr_i[is_instr_i.rd] : is_rd_clobber_gpr_i[is_instr_i.rd];

  // Issue stage stalls
  wire is_stall_li = is_valid_i & ~is_ack_i;
  wire sb_full_li = is_stall_li & is_sb_full_i;
  wire br_haz_li  = is_stall_li & is_unresolved_branch_i;
  wire mul_haz_li = is_stall_li & ex_mul_valid_i & (is_instr_i.fu != MULT);
  wire fu_busy_li = is_stall_li & is_ro_fubusy_i;
  wire raw_haz_li = is_stall_li & is_ro_stall_i;
  wire waw_haz_li = is_stall_li & ~sb_full_li & ~br_haz_li & ~mul_haz_li & ~raw_haz_li & ~fu_busy_li;
  wire flu_busy_li = fu_busy_li & (is_instr_i.fu inside {ALU, CTRL_FLOW, CSR, MULT});
  wire lsu_busy_li = fu_busy_li & (is_instr_i.fu inside {LOAD, STORE});
  wire fpu_busy_li = fu_busy_li & (is_instr_i.fu inside {FPU, FPU_VEC});

  // LSU stalls
  wire waw_in_ex = ~is_forward_rd_i;
  wire ld_valid_li = lsu_ctrl_i.valid & (lsu_ctrl_i.fu == LOAD);
  wire st_valid_li = lsu_ctrl_i.valid & (lsu_ctrl_i.fu == STORE);

  wire ld_pipe_li     = ld_valid_li & (ld_state_q_i == LD_IDLE);
  wire ld_wait_gnt_li = ld_valid_li & ~pop_ld_i & (ld_state_d_i == LD_WAIT_GNT) & (ld_state_q_i != LD_WAIT_PAGE_OFFSET);
  wire ld_page_off_li = ld_valid_li & ((ld_state_q_i == LD_WAIT_PAGE_OFFSET) | (ld_state_d_i == LD_WAIT_PAGE_OFFSET));
  wire ld_dc_miss_li  = (ld_cntr != '0) & ~ld_done_i;
  wire lu_dc_pipe_li  = (ld_valid_li & pop_ld_i) | (ld_page_off_li & ~st_dc_miss_li & ~dc_dma_li);
  wire lu_dc_miss_li  = (ld_dc_miss_li | (ld_page_off_li & st_dc_miss_li)) & ~dc_dma_li;
  wire lu_dc_dma_li   = (ld_dc_miss_li | ld_page_off_li) & dc_dma_li;

  wire st_dc_miss_li = (dc_st_state_i inside {4'd7, 4'd8, 4'd9});
  wire st_pipe_li = st_valid_li & (st_state_q_i inside {ST_IDLE, ST_VALID_STORE});
  wire sbuf_spec_haz_li = st_valid_li & (st_state_q_i == ST_WAIT_STORE_READY);

  // Commit stalls
  wire cmt_haz_li = cmt_instr_i[0].valid & ~cmt_ack_i[0];
  wire sbuf_cmt_haz_li = cmt_instr_i[0].valid & (cmt_instr_i[0].fu == STORE) & ~(is_amo(cmt_instr_i[0].op)) & ~cmt_lsu_ready_i;

  // DMA stalls
  wire ic_dma_li = rdma_pending_r & (rdma_id_r == 5'b00000);
  wire dc_dma_li = (rdma_pending_r & (rdma_id_r == 5'b01100)) | (wdma_pending_r & (wdma_id_r == 5'b01100));
/
  bsg_counter_up_down
   #(.max_val_p(3)
    ,.init_val_p(0)
    ,.max_step_p(1)
   ) ld_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i | flush_ex_i)
   ,.down_i(ld_done_i)
   ,.up_i(pop_ld_i)
   ,.count_o(ld_cntr)
   );

  logic rdma_pending_r, wdma_pending_r;
  logic[4:0] rdma_id_r, wdma_id_r;

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

  bsg_dff_reset_en_bypass
   #(.width_p(5))
   rdma_id_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(m_arvalid_i)
     ,.data_i(m_arid_i)
     ,.data_o(rdma_id_r)
     );

  bsg_dff_reset_en_bypass
   #(.width_p(5))
   wdma_id_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(m_awvalid_i)
     ,.data_i(m_awid_i)
     ,.data_o(wdma_id_r)
     );

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      pc_r <= '0;
      ic_r <= '0;
      re_r <= '0;
      id_r <= '0;
      is_r <= '0;
      ex_r <= '0;
      ld_r <= '0;
      wb_r <= '0;
      {issue_en_r, issue_pointer_q_r} <= '0;
    end else begin
      pc_r <= pc;
      ic_r <= ic;
      re_r <= re;
      id_r <= id;
      is_r <= is;
      ex_r <= ex;
      ld_r <= ld;
      wb_r <= wb;
      {issue_en_r, issue_pointer_q_r} <= {issue_en_i, issue_pointer_q_i};
    end
  end

  always_comb begin

    ic_busy = '0;
    casez({icache_atrans, icache_flush, icache_miss, icache_invl})
      4'b1???: ic_busy.ic_atrans |= 1'b1;
      4'b01??: ic_busy.ic_flush  |= 1'b1;
      4'b001?: begin
                 ic_busy.ic_miss |= ~ic_dma_li;
                 ic_busy.ic_dma  |= ic_dma_li;
               end
      4'b0001: ic_busy.ic_invl   |= 1'b1;
    endcase

    //Frontend
    //PC gen
    pc = '0;
    pc.iq_full   |= ~instr_queue_ready_i;
    pc           |= ic_busy;
    pc.ireplay   |= fe_replay_i;
    pc.br_miss   |= branch_mispredict_i;
    pc.amo_flush |= flush_amo_i;
    pc.csr_flush |= flush_csr_i;
    pc.exception |= exception_i;
    pc.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    //I$ output
    ic = (|ic_busy) ? ic_busy : pc_r;
    ic.bp_haz    |= fe_bp_valid_i;
    ic.ireplay   |= fe_replay_i;
    ic.br_miss   |= branch_mispredict_i;
    ic.amo_flush |= flush_amo_i;
    ic.csr_flush |= flush_csr_i;
    ic.exception |= exception_i;
    ic.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    //Instr queue input
    re = ic_r;
    re.realign   |= fe_realign_bubble_i;
    re.br_miss   |= branch_mispredict_i;
    re.amo_flush |= flush_amo_i;
    re.csr_flush |= flush_csr_i;
    re.exception |= exception_i;
    re.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    //Instr queue output
    fe = instr_qeueu_valid_i ? '0 : re_r;

    //Decode
    id = fe;
    id.br_miss   |= branch_mispredict_i;
    id.amo_flush |= flush_amo_i;
    id.csr_flush |= flush_csr_i;
    id.exception |= exception_i;
    id.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    //Issue stage
    is = id_r;
    is.sb_full      |= sb_full_li;
    is.waw_flu      |= waw_haz_li & (waw_clobber_li inside {ALU, CTRL_FLOW, CSR, MULT}) & waw_in_ex;
    is.waw_fpu      |= waw_haz_li & (waw_clobber_li inside {FPU, FPU_VEC}) & waw_in_ex;
    is.waw_lsu      |= waw_haz_li & (waw_clobber_li inside {LOAD, STORE}) & waw_in_ex;
    is.waw_reorder  |= waw_haz_li & ~waw_in_ex;
    is.raw_flu      |= raw_haz_li & (raw_clobber_li inside {ALU, CTRL_FLOW, CSR, MULT});
    is.raw_fpu      |= raw_haz_li & (raw_clobber_li inside {FPU, FPU_VEC});
    is.raw_lsu      |= raw_haz_li & (raw_clobber_li inside {LOAD, STORE});
    is.br_haz       |= br_haz_li;
    is.mul_haz      |= mul_haz_li;
    is.csr_buf      |= flu_busy_li & ~ex_csr_ready_i;
    is.div_busy     |= flu_busy_li & ~ex_div_ready_i;
    is.ld_grant     |= lsu_busy_li & ld_wait_gnt_li;
    is.dc_pipe      |= lsu_busy_li & ld_page_off_li & ~st_dc_miss_li & ~dc_dma_li;
    is.dc_miss      |= lsu_busy_li & ld_page_off_li & st_dc_miss_li & ~dc_dma_li;
    is.dc_dma       |= lsu_busy_li & ld_page_off_li & dc_dma_li;
    is.sbuf_spec    |= lsu_busy_li & sbuf_spec_haz_li;
    is.fpu_busy     |= fpu_busy_li;
    is.br_miss      |= branch_mispredict_i;
    is.amo_flush    |= flush_amo_i;
    is.csr_flush    |= flush_csr_i;
    is.exception    |= exception_i;
    is.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    //FLU
    flu = is_r;
    flu.mul_haz     |= ex_mul_valid_i & ex_div_ready_i;
    flu.csr_buf     |= ~ex_csr_ready_i;
    flu.div_busy    |= ~ex_div_ready_i;
    flu.amo_flush   |= flush_amo_i;
    flu.csr_flush   |= flush_csr_i;
    flu.exception   |= exception_i;
    flu.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);
    wb[3] = wb_flu_valid_i ? '0 : flu;

    //Load unit
    ld[0] = is_r;
    ld[0].ld_grant  |= ld_wait_gnt_li;
    ld[0].dc_pipe   |= lu_dc_pipe_li;
    ld[0].dc_miss   |= lu_dc_miss_li;
    ld[0].dc_dma    |= lu_dc_dma_li;
    ld[0].amo_flush |= flush_amo_i;
    ld[0].csr_flush |= flush_csr_i;
    ld[0].exception |= exception_i;
    ld[0].fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    ld[1] = ld_r[0];
    ld[1].ld_pipe   |= ld_pipe_li;
    ld[1].amo_flush |= flush_amo_i;
    ld[1].csr_flush |= flush_csr_i;
    ld[1].exception |= exception_i;
    ld[1].fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);
    wb[2] = wb_ld_valid_i ? '0 : ld[1];

    //Store unit
    st = is_r;
    st.st_pipe      |= st_pipe_li;
    st.sbuf_spec    |= sbuf_spec_haz_li;
    st.amo_flush    |= flush_amo_i;
    st.csr_flush    |= flush_csr_i;
    st.exception    |= exception_i;
    st.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);
    wb[1] = wb_st_valid_i ? '0 : st;

    //FPU
    //FPU is OOO so a valid output can still indicate a stall
    fpu = is_r;
    fpu.fpu_busy    |= ex_fpu_busy_i;
    fpu.amo_flush   |= flush_amo_i;
    fpu.csr_flush   |= flush_csr_i;
    fpu.exception   |= exception_i;
    fpu.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);
    wb[0] = fpu;

    ex = is_r;
    ex.amo_flush    |= flush_amo_i;
    ex.csr_flush    |= flush_csr_i;
    ex.exception    |= exception_i;
    ex.fence |= flush_unissued_instr_i & ~(branch_mispredict_i | flush_amo_i | flush_csr_i | exception_i);

    //Scoreboard WB
    //If this instruction is issued and was not issued in the prev cycle
    if(cmt_issued_q_i && !(issue_en_r && (issue_pointer_q_r == cmt_pointer_q_i))) begin
      unique case(cmt_instr_i[0].fu)
        ALU, CTRL_FLOW, CSR, MULT:
          commit = wb_r[3];
        LOAD:
          commit = wb_r[2];
        STORE:
          commit = wb_r[1];
        FPU, FPU_VEC:
          commit = wb_r[0];
        default:
          commit = '0;
      endcase
    end
    else begin
      commit = ex_r;
    end

    commit.dc_pipe  |= cmt_haz_li & sbuf_cmt_haz_li & ~st_dc_miss_li & ~dc_dma_li;
    commit.dc_miss  |= cmt_haz_li & sbuf_cmt_haz_li & st_dc_miss_li & ~dc_dma_li;
    commit.dc_dma   |= cmt_haz_li & sbuf_cmt_haz_li & dc_dma_li;
    commit.cmt_haz  |= cmt_haz_li & ~sbuf_cmt_haz_li;

  end

  logic [$bits(stall_reason_e)-1:0] stall_reason_lo;
  stall_reason_e stall_reason_enum;
  logic stall_reason_v;

  logic [$bits(stall_reason_e)-1:0] extra_stall_lo;
  wire unknown_lo = ~cmt_ack_i[0] & ~(|commit);
  wire extra_lo = cmt_ack_i[0] & (|commit);
  assign extra_stall_lo = extra_lo ? stall_reason_lo : '0;

  wire stall_v = ~cmt_ack_i[0];
  assign stall_reason_enum = stall_reason_e'(stall_reason_lo);
  bsg_priority_encode
   #(.width_p($bits(stall_reason_s)), .lo_to_hi_p(1))
   stall_encode
    (.i(commit)
     ,.addr_o(stall_reason_lo)
     ,.v_o(stall_reason_v)
     );

  // Output stall generation
  `define declare_stall_counter(name,i)                      \
  bsg_counter_clear_up                                       \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0)) \
   ``name``_cnt                                              \
   (.clk_i(clk_i)                                            \
   ,.reset_i(reset_i)                                        \
   ,.clear_i(1'b0)                                           \
   ,.up_i(en_i & stall_v & (stall_reason_enum == ``name``))  \
   ,.count_o(data_o[``i``])                                  \
   );


  `declare_stall_counter(iq_full,0)
  `declare_stall_counter(ic_invl,1)
  `declare_stall_counter(ic_miss,2)
  `declare_stall_counter(ic_dma,3)
  `declare_stall_counter(ic_flush,4)
  `declare_stall_counter(ic_atrans,5)
  `declare_stall_counter(bp_haz,6)
  `declare_stall_counter(ireplay,7)
  `declare_stall_counter(realign,8)
  `declare_stall_counter(sb_full,9)
  `declare_stall_counter(waw_flu,10)
  `declare_stall_counter(waw_lsu,11)
  `declare_stall_counter(waw_fpu,12)
  `declare_stall_counter(waw_reorder,13)
  `declare_stall_counter(raw_flu,14)
  `declare_stall_counter(raw_lsu,15)
  `declare_stall_counter(raw_fpu,16)
  `declare_stall_counter(br_haz,17)
  `declare_stall_counter(br_miss,18)
  `declare_stall_counter(mul_haz,19)
  `declare_stall_counter(csr_buf,20)
  `declare_stall_counter(div_busy,21)
  `declare_stall_counter(ld_pipe,22)
  `declare_stall_counter(ld_grant,23)
  `declare_stall_counter(st_pipe,24)
  `declare_stall_counter(sbuf_spec,25)
  `declare_stall_counter(fpu_busy,26)
  `declare_stall_counter(amo_flush,27)
  `declare_stall_counter(csr_flush,28)
  `declare_stall_counter(fence,29)
  `declare_stall_counter(exception,30)
  `declare_stall_counter(dc_pipe,31)
  `declare_stall_counter(dc_miss,32)
  `declare_stall_counter(dc_dma,33)
  `declare_stall_counter(cmt_haz,34)

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   unknown_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(1'b0)
   ,.up_i(en_i & stall_v & ((stall_reason_enum == unknown) | ~(|commit)))
   ,.count_o(data_o[35])
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   extra_cmt_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(1'b0)
   ,.up_i(en_i & cmt_ack_i[1])
   ,.count_o(data_o[36])
   );

  // Event profiling
  `define declare_counter(name,up,i)                         \
  bsg_counter_clear_up                                       \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0)) \
   ``name``_cnt                                              \
   (.clk_i(clk_i)                                            \
   ,.reset_i(reset_i)                                        \
   ,.clear_i(1'b0)                                           \
   ,.up_i(en_i & ``up``)                                     \
   ,.count_o(data_o[``i``])                                  \
   );

  // DMA metrics
  `declare_counter(e_wdma_cnt,(m_awvalid_i & m_awready_i),37)
  `declare_counter(e_rdma_cnt,(m_arvalid_i & m_arready_i),38)
  `declare_counter(e_wdma_wait,wdma_pending_r,39)
  `declare_counter(e_rdma_wait,rdma_pending_r,40)
  `declare_counter(e_dma_wait,(wdma_pending_r | rdma_pending_r),40)
  `declare_counter(e_dma_ic_wait,ic_dma_li,40)
  `declare_counter(e_dma_dc_wait,dc_dma_li,40)
  `declare_counter(e_ic_dma_wait,(icache_miss & ic_dma_li),40)
  `declare_counter(e_dc_dma_wait,((ld_dc_miss_li | st_dc_miss_li) & dc_dma_li),40)


  // I$ metrics
  logic ic_miss_pending_r;
  bsg_dff_reset_en_bypass
   #(.width_p(1))
   ic_miss_pending_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(ic_miss_i | ic_dresp_i.valid)
     ,.data_i(ic_miss_i)
     ,.data_o(ic_miss_pending_r)
     );

  `declare_counter(e_ic_req_cnt,ic_dresp_i.valid,41)
  `declare_counter(e_ic_miss_cnt,ic_miss_i,42)
  `declare_counter(e_ic_miss_wait,ic_miss_pending_r,43)

  // D$ metrics
  bsg_counter_up_down
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0), .max_step_p(2))
   dc_req_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.down_i('0)
   ,.up_i(en_i ? (dc_resp_i[1].data_gnt + dc_resp_i[2].data_gnt) : '0)
   ,.count_o(data_o[44])
   ); 

  `declare_counter(e_dc_miss_cnt,(|dc_miss_gnt_i),45)
  `declare_counter(e_dc_miss_wait,(ld_dc_miss_li | st_dc_miss_li),46)

  // Predictor metrics
  wire bu_is_br = bu_resolved_branch_i.valid & ariane_pkg::op_is_branch(bu_fu_data_i.operator);
  wire bu_is_jalr = bu_resolved_branch_i.valid & (bu_fu_data_i.operator == ariane_pkg::JALR) & (bu_resolved_branch_i.cf_type != ariane_pkg::Return);
  wire bu_is_ret = bu_resolved_branch_i.valid & (bu_fu_data_i.operator == ariane_pkg::JALR) & (bu_resolved_branch_i.cf_type == ariane_pkg::Return);
  `declare_counter(e_br_cnt,bu_is_br,47)
  `declare_counter(e_br_miss,(bu_is_br & bu_resolved_branch_i.is_mispredict),48)
  `declare_counter(e_jalr_cnt,bu_is_jalr,49)
  `declare_counter(e_jalr_miss,(bu_is_jalr & bu_resolved_branch_i.is_mispredict),50)
  `declare_counter(e_ret_cnt,bu_is_ret,51)
  `declare_counter(e_ret_miss,(bu_is_ret & bu_resolved_branch_i.is_mispredict),52)

  // FPU metrics
  `declare_counter(e_fpu_addmul_cnt,fpu_opgrp_req_i[0],53)
  `declare_counter(e_fpu_divsqrt_cnt,fpu_opgrp_req_i[1],54)
  `declare_counter(e_fpu_noncomp_cnt,fpu_opgrp_req_i[2],55)
  `declare_counter(e_fpu_conv_cnt,fpu_opgrp_req_i[3],56)
  `declare_counter(e_fpu_addmul_wait,fpu_opgrp_busy_i[0],57)
  `declare_counter(e_fpu_divsqrt_wait,fpu_opgrp_busy_i[1],58)
  `declare_counter(e_fpu_noncomp_wait,fpu_opgrp_busy_i[2],59)
  `declare_counter(e_fpu_conv_wait,fpu_opgrp_busy_i[3],60)

  // DIV metrics
  `declare_counter(e_div_cnt,div_valid_i,61)
  `declare_counter(e_div_wait,(~div_ready_i),62)

/*
  // Instruction profiling
  `define is_ilong(instr) ((``instr``.fu inside {MULT}) & (``instr``.op inside {DIV, DIVU, DIVW, DIVUW, REM, REMU, REMW, REMUW}))
  `define is_flong(instr) ((``instr``.fu inside {FPU}) & (``instr``.op inside {FDIV, FSQRT}))
  `define is_fma(instr) ((``instr``.fu inside {FPU}) & (``instr``.op inside {FADD, FSUB, FMUL, FMADD, FMSUB, FNMSUB, FNMADD}))
  `define is_aux(instr) ((``instr``.fu inside {FPU}) & ~`is_flong(``instr``) & ~`is_fma(``instr``))
  `define is_mem(instr) ((``instr``.fu inside {LOAD, STORE}) | ((``instr``.fu inside {CSR}) & (``instr``.op inside {FENCE, FENCE_I})))

  `define declare_instr_counter(name) \
  bsg_counter_up_down \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0), .max_step_p(2)) \
   ``name``_instr_cnt \
   (.clk_i(clk_i) \
   ,.reset_i(reset_i) \
   ,.down_i('0) \
   ,.up_i(en_i ? ((cmt_ack_i[0] & `is_``name``(cmt_instr_i[0])) + (cmt_ack_i[1] & `is_``name``(cmt_instr_i[1]))) : '0) \
   ,.count_o(``name``_instr_o) \
   );

  `declare_instr_counter(ilong)
  `declare_instr_counter(flong)
  `declare_instr_counter(fma)
  `declare_instr_counter(aux)
  `declare_instr_counter(mem)
*/

endmodule
