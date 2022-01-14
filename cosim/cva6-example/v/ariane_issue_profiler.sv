
  typedef struct packed
  {
    logic iq_full;
    logic ic_invl;
    logic ic_miss;
    logic ic_flush;
    logic ic_atrans;
    logic bp_haz;
    logic ireplay;
    logic realign;
    logic sb_full;
    logic waw_flu;
    logic waw_ld_pipe;
    logic waw_ld_grant;
    logic waw_ld_pgoff;
    logic waw_dcache;
    logic waw_fpu;
    logic waw_reorder;
    logic raw_flu;
    logic raw_ld_pipe;
    logic raw_ld_grant;
    logic raw_ld_pgoff;
    logic raw_dcache;
    logic raw_fpu;
    logic br_haz;
    logic mul_haz;
    logic flu_busy;
    logic lsu_busy_ld_grant;
    logic lsu_busy_ld_pgoff;
    logic lsu_busy_st_buffer;
    logic lsu_busy_other;
    logic fpu_busy;
    logic br_miss;
    logic amo_flush;
    logic csr_flush;
    logic exception;
    logic unknown;
  } stall_reason_s;

  typedef enum logic [5:0]
  {
    iq_full             = 6'd34
    ,ic_invl            = 6'd33
    ,ic_miss            = 6'd32
    ,ic_flush           = 6'd31
    ,ic_atrans          = 6'd30
    ,bp_haz             = 6'd29
    ,ireplay            = 6'd28
    ,realign            = 6'd27
    ,sb_full            = 6'd26
    ,waw_flu            = 6'd25
    ,waw_ld_pipe        = 6'd24
    ,waw_ld_grant       = 6'd23
    ,waw_ld_pgoff       = 6'd22
    ,waw_dcache         = 6'd21
    ,waw_fpu            = 6'd20
    ,waw_reorder        = 6'd19
    ,raw_flu            = 6'd18
    ,raw_ld_pipe        = 6'd17
    ,raw_ld_grant       = 6'd16
    ,raw_ld_pgoff       = 6'd15
    ,raw_dcache         = 6'd14
    ,raw_fpu            = 6'd13
    ,br_haz             = 6'd12
    ,mul_haz            = 6'd11
    ,flu_busy           = 6'd10
    ,lsu_busy_ld_grant  = 6'd9
    ,lsu_busy_ld_pgoff  = 6'd8
    ,lsu_busy_st_buffer = 6'd7
    ,lsu_busy_other     = 6'd6
    ,fpu_busy           = 6'd5
    ,br_miss            = 6'd4
    ,amo_flush          = 6'd3
    ,csr_flush          = 6'd2
    ,exception          = 6'd1
    ,unknown            = 6'd0
  } stall_reason_e;

module ariane_issue_profiler
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
    , input is_ro_mul_stall_i
    , input is_ro_stall_i
    , input is_ro_fubusy_i
    , input scoreboard_entry_t is_instr_i
    , input fu_t [2**REG_ADDR_SIZE-1:0] is_rd_clobber_gpr_i
    , input fu_t [2**REG_ADDR_SIZE-1:0] is_rd_clobber_fpr_i
    , input is_forward_rs1_i
    , input is_forward_rs2_i
    , input is_forward_rs3_i
    , input is_forward_rd_i

    , input lsu_ctrl_t lsu_ctrl_i
    , input pop_ld_i
    , input ld_done_i
    , input [3:0] ld_state_q_i
    , input [1:0] st_state_q_i

    , output [width_p-1:0] iq_full_o
    , output [width_p-1:0] ic_invl_o
    , output [width_p-1:0] ic_miss_o
    , output [width_p-1:0] ic_flush_o
    , output [width_p-1:0] ic_atrans_o
    , output [width_p-1:0] bp_haz_o
    , output [width_p-1:0] ireplay_o
    , output [width_p-1:0] realign_o
    , output [width_p-1:0] sb_full_o
    , output [width_p-1:0] waw_flu_o
    , output [width_p-1:0] waw_ld_pipe_o
    , output [width_p-1:0] waw_ld_grant_o
    , output [width_p-1:0] waw_ld_pgoff_o
    , output [width_p-1:0] waw_dcache_o
    , output [width_p-1:0] waw_fpu_o
    , output [width_p-1:0] waw_reorder_o
    , output [width_p-1:0] raw_flu_o
    , output [width_p-1:0] raw_ld_pipe_o
    , output [width_p-1:0] raw_ld_grant_o
    , output [width_p-1:0] raw_ld_pgoff_o
    , output [width_p-1:0] raw_dcache_o
    , output [width_p-1:0] raw_fpu_o
    , output [width_p-1:0] br_haz_o
    , output [width_p-1:0] mul_haz_o
    , output [width_p-1:0] flu_busy_o
    , output [width_p-1:0] lsu_busy_ld_grant_o
    , output [width_p-1:0] lsu_busy_ld_pgoff_o
    , output [width_p-1:0] lsu_busy_st_buffer_o
    , output [width_p-1:0] lsu_busy_other_o
    , output [width_p-1:0] fpu_busy_o
    , output [width_p-1:0] br_miss_o
    , output [width_p-1:0] amo_flush_o
    , output [width_p-1:0] csr_flush_o
    , output [width_p-1:0] exception_o
    , output [width_p-1:0] unknown_o
    );

  typedef enum logic [2:0] {IC_FLUSH, IC_IDLE, IC_READ, IC_MISS, IC_KILL_ATRANS, IC_KILL_MISS} icache_state_e;
  typedef enum logic [3:0] {LD_IDLE, LD_WAIT_GNT, LD_SEND_TAG, LD_WAIT_PAGE_OFFSET,
                            LD_ABORT_TRANSACTION, LD_ABORT_TRANSACTION_NI, LD_WAIT_TRANSLATION, LD_WAIT_FLUSH,
                            LD_WAIT_WB_EMPTY} load_state_e;
  typedef enum logic [1:0] {ST_IDLE, ST_VALID_STORE, ST_WAIT_TRANSLATION, ST_WAIT_STORE_READY} store_state_e;

  stall_reason_s pc, pc_r, ic, ic_r, re, re_r, fe;
  stall_reason_s id, id_r, is, ld, ld_r, ld_lo;
  stall_reason_s ic_busy;
  fu_t rs1_clobber_li, rs2_clobber_li, raw_clobber_li, waw_clobber_li;
  logic[REG_ADDR_SIZE-1:0] lsu_ld_rd, lsu_ld_rd_r, raw_rs_li;
  logic[TRANS_ID_BITS-1:0] lsu_ld_trans_id;
  logic raw_haz_r, waw_haz_r;

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
  wire mul_haz_li = is_stall_li & is_ro_mul_stall_i;
  wire fu_busy_li = is_stall_li & is_ro_fubusy_i;
  wire raw_haz_li = is_stall_li & is_ro_stall_i;
  wire waw_haz_li = is_stall_li & ~sb_full_li & ~br_haz_li & ~mul_haz_li & ~raw_haz_li & ~fu_busy_li;
  wire flu_busy_li = fu_busy_li & (is_instr_i.fu inside {ALU, CTRL_FLOW, CSR, MULT});
  wire lsu_busy_li = fu_busy_li & (is_instr_i.fu inside {LOAD, STORE});
  wire fpu_busy_li = fu_busy_li & (is_instr_i.fu inside {FPU, FPU_VEC});

  // LSU stalls
  wire waw_in_ex = ~is_forward_rd_i;
  wire ld_valid_li = lsu_ctrl_i.valid & (lsu_ctrl_i.fu == LOAD);
  wire ld_wait_gnt_li = ld_valid_li & (ld_state_q_i == LD_WAIT_GNT);
  wire ld_page_off_li = ld_valid_li & (ld_state_q_i == LD_WAIT_PAGE_OFFSET);
  wire st_wait_rdy_li = ~ld_valid_li & (st_state_q_i == ST_WAIT_STORE_READY);
  wire ld_in_dcache = (lsu_ld_rd_r == (waw_haz_li ? is_instr_i.rd : raw_rs_li))
                    | ((lsu_ld_rd == (waw_haz_li ? is_instr_i.rd : raw_rs_li)) & (ld_state_q_i == LD_SEND_TAG) & ~ld_done_i);

  always_ff @(posedge clk_i) begin
    if(reset_i)
      lsu_ld_rd_r <= '0;
    else if(pop_ld_i)
      lsu_ld_rd_r <= lsu_ld_rd;
  end

  fifo_v3
   #(.FALL_THROUGH(0)
    ,.DATA_WIDTH(REG_ADDR_SIZE+TRANS_ID_BITS)
    ,.DEPTH(2)
   )
   i_fifo
   (.clk_i     (clk_i)
   ,.rst_ni    (~reset_i)
   ,.flush_i   (flush_ex_i)
   ,.testmode_i('0)
   ,.full_o    ()
   ,.empty_o   ()
   ,.usage_o   ()
   ,.data_i    ({is_instr_i.rd, is_instr_i.trans_id})
   ,.push_i    (is_ack_i & (is_instr_i.fu == LOAD) & ~flush_unissued_instr_i)
   ,.data_o    ({lsu_ld_rd, lsu_ld_trans_id})
   ,.pop_i     (pop_ld_i)
   );

  always_ff @(negedge clk_i) begin
    assert(!(ld_valid_li && (lsu_ld_trans_id != lsu_ctrl_i.trans_id)))
      else $error("LD trans_id mismatch: %x != %x", lsu_ld_trans_id, lsu_ctrl_i.trans_id);
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      pc_r <= '0;
      ic_r <= '0;
      re_r <= '0;
      id_r <= '0;
      ld_r <= '0;
      raw_haz_r <= '0;
      waw_haz_r <= '0;
    end else begin
      pc_r <= pc;
      ic_r <= ic;
      re_r <= re;
      id_r <= id;
      ld_r <= ld;
      raw_haz_r <= raw_haz_li;
      waw_haz_r <= waw_haz_li;
    end
  end

  always_comb begin

    ic_busy = '0;
    casez({icache_atrans, icache_flush, icache_miss, icache_invl})
      4'b1???: ic_busy.ic_atrans |= 1'b1;
      4'b01??: ic_busy.ic_flush  |= 1'b1;
      4'b001?: ic_busy.ic_miss   |= 1'b1;
      4'b0001: ic_busy.ic_invl   |= 1'b1;
    endcase

    ld = '0;
    ld.waw_ld_pipe  = ld_valid_li & (ld_state_q_i inside {LD_IDLE, LD_SEND_TAG});
    ld.waw_ld_grant = ~ld_in_dcache & ld_wait_gnt_li;
    ld.waw_ld_pgoff = ~ld_in_dcache & ld_page_off_li;
    ld.waw_dcache   = ld_in_dcache;

    ld_lo = ld_r;
    ld_lo.waw_ld_pipe |= ld_valid_li & (ld_state_q_i inside {LD_IDLE, LD_SEND_TAG});
    ld_lo.waw_dcache  |= ld_in_dcache;

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

    //I$ output
    ic = (|ic_busy) ? ic_busy : pc_r;
    ic.bp_haz    |= fe_bp_valid_i;
    ic.ireplay   |= fe_replay_i;
    ic.br_miss   |= branch_mispredict_i;
    ic.amo_flush |= flush_amo_i;
    ic.csr_flush |= flush_csr_i;
    ic.exception |= exception_i;

    //Instr queue input
    re = ic_r;
    re.realign   |= fe_realign_bubble_i;
    re.br_miss   |= branch_mispredict_i;
    re.amo_flush |= flush_amo_i;
    re.csr_flush |= flush_csr_i;
    re.exception |= exception_i;

    //Instr queue output
    fe = instr_qeueu_valid_i ? '0 : re_r;

    //Decode
    id = fe;
    id.br_miss   |= branch_mispredict_i;
    id.amo_flush |= flush_amo_i;
    id.csr_flush |= flush_csr_i;
    id.exception |= exception_i;

    //Issue stage
    is = id_r;
    is.sb_full      |= sb_full_li;
    is.waw_flu      |= waw_haz_li & (waw_clobber_li inside {ALU, CTRL_FLOW, CSR, MULT}) & ~waw_in_ex;
    is.waw_fpu      |= waw_haz_li & (waw_clobber_li inside {FPU, FPU_VEC}) & ~waw_in_ex;
    is.waw_ld_pipe  |= waw_haz_li & (waw_clobber_li inside {LOAD, STORE}) & ~waw_in_ex & ld_lo.waw_ld_pipe;
    is.waw_ld_grant |= waw_haz_li & (waw_clobber_li inside {LOAD, STORE}) & ~waw_in_ex & ld_lo.waw_ld_grant;
    is.waw_ld_pgoff |= waw_haz_li & (waw_clobber_li inside {LOAD, STORE}) & ~waw_in_ex & ld_lo.waw_ld_pgoff;
    is.waw_dcache   |= waw_haz_li & (waw_clobber_li inside {LOAD, STORE}) & ~waw_in_ex & ld_lo.waw_dcache;
    is.waw_reorder  |= waw_haz_li & waw_in_ex;
    is.raw_flu      |= raw_haz_li & (raw_clobber_li inside {ALU, CTRL_FLOW, CSR, MULT});
    is.raw_fpu      |= raw_haz_li & (raw_clobber_li inside {FPU, FPU_VEC});
    is.raw_ld_pipe  |= raw_haz_li & (raw_clobber_li inside {LOAD, STORE}) & ld_lo.waw_ld_pipe;
    is.raw_ld_grant |= raw_haz_li & (raw_clobber_li inside {LOAD, STORE}) & ld_lo.waw_ld_grant;
    is.raw_ld_pgoff |= raw_haz_li & (raw_clobber_li inside {LOAD, STORE}) & ld_lo.waw_ld_pgoff;
    is.raw_dcache   |= raw_haz_li & (raw_clobber_li inside {LOAD, STORE}) & ld_lo.waw_dcache;
    is.br_haz       |= br_haz_li;
    is.mul_haz      |= mul_haz_li;
    is.flu_busy     |= flu_busy_li;
    is.lsu_busy_ld_grant  |= lsu_busy_li & ld_wait_gnt_li;
    is.lsu_busy_ld_pgoff  |= lsu_busy_li & ld_page_off_li;
    is.lsu_busy_st_buffer |= lsu_busy_li & st_wait_rdy_li;
    is.lsu_busy_other     |= lsu_busy_li & ~ld_wait_gnt_li & ~ld_page_off_li & ~st_wait_rdy_li;
    is.fpu_busy     |= fpu_busy_li;
    is.br_miss      |= branch_mispredict_i;
    is.amo_flush    |= flush_amo_i;
    is.csr_flush    |= flush_csr_i;
    is.exception    |= exception_i;
  end

  wire unknown_lo = ~is_ack_i & ~(|is);
  wire extra_lo = is_ack_i & (|is);

  logic [$bits(stall_reason_e)-1:0] stall_reason_lo;
  stall_reason_e stall_reason_enum;
  logic stall_reason_v;
  bsg_priority_encode
   #(.width_p($bits(stall_reason_s)), .lo_to_hi_p(1))
   stall_encode
    (.i(is)
     ,.addr_o(stall_reason_lo)
     ,.v_o(stall_reason_v)
     );
  assign stall_reason_enum = stall_reason_e'(stall_reason_lo);

  wire stall_v = ~is_ack_i;


  // Output generation
  `define declare_counter(name)                              \
  bsg_counter_clear_up                                       \
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0)) \
   ``name``_cnt                                              \
   (.clk_i(clk_i)                                            \
   ,.reset_i(reset_i)                                        \
   ,.clear_i(reset_i)                                        \
   ,.up_i(en_i & stall_v & (stall_reason_enum == ``name``))  \
   ,.count_o(``name``_o)                                     \
   );

  `declare_counter(iq_full)
  `declare_counter(ic_invl)
  `declare_counter(ic_miss)
  `declare_counter(ic_flush)
  `declare_counter(ic_atrans)
  `declare_counter(bp_haz)
  `declare_counter(ireplay)
  `declare_counter(realign)
  `declare_counter(sb_full)
  `declare_counter(waw_flu)
  `declare_counter(waw_ld_pipe)
  `declare_counter(waw_ld_grant)
  `declare_counter(waw_ld_pgoff)
  `declare_counter(waw_dcache)
  `declare_counter(waw_reorder)
  `declare_counter(waw_fpu)
  `declare_counter(raw_flu)
  `declare_counter(raw_ld_pipe)
  `declare_counter(raw_ld_grant)
  `declare_counter(raw_ld_pgoff)
  `declare_counter(raw_dcache)
  `declare_counter(raw_fpu)
  `declare_counter(br_haz)
  `declare_counter(mul_haz)
  `declare_counter(flu_busy)
  `declare_counter(lsu_busy_ld_grant)
  `declare_counter(lsu_busy_ld_pgoff)
  `declare_counter(lsu_busy_st_buffer)
  `declare_counter(lsu_busy_other)
  `declare_counter(fpu_busy)
  `declare_counter(br_miss)
  `declare_counter(amo_flush)
  `declare_counter(csr_flush)
  `declare_counter(exception)

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   unknown_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(en_i & stall_v & ((stall_reason_enum == unknown) | ~(|is)))
   ,.count_o(unknown_o)
   );

endmodule
