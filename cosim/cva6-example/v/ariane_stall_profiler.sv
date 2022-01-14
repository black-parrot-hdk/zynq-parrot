
  typedef struct packed
  {
    logic fe_wait;
    logic is_busy;
    logic sb_full;
    logic br_haz;
    logic waw_haz;
    logic csr_haz;
    logic mul_haz;
    logic flu_busy;
    logic lsu_busy;
    logic fpu_busy;
    logic br_miss;
    logic lsu_tl;
    logic lsu_wait;
    logic amo_flush;
    logic csr_flush;
    logic exception;
    logic cmt_haz;
    logic unknown;
  } stall_reason_s;

  typedef enum logic [4:0]
  {
    fe_wait    = 5'd17
    ,is_busy   = 5'd16
    ,sb_full   = 5'd15
    ,br_haz    = 5'd14
    ,waw_haz   = 5'd13
    ,csr_haz   = 5'd12
    ,mul_haz   = 5'd11
    ,flu_busy  = 5'd10
    ,lsu_busy  = 5'd9
    ,fpu_busy  = 5'd8
    ,br_miss   = 5'd7
    ,lsu_tl    = 5'd6
    ,lsu_wait  = 5'd5
    ,amo_flush = 5'd4
    ,csr_flush = 5'd3
    ,exception = 5'd2
    ,cmt_haz   = 5'd1
    ,unknown   = 5'd0
  } stall_reason_e;


module ariane_stall_profiler
  import ariane_pkg::*;
  #(parameter width_p = 64
   )
   (input clk_i
    , input reset_i

    , input branch_mispredict_i
    , input flush_amo_i
    , input flush_csr_i
    , input exception_i

    , input fe_bubble_i

    , input is_valid_i
    , input is_ack_i
    , input is_unresolved_branch_i
    , input is_sb_full_i
    , input is_ro_mul_stall_i
    , input is_ro_stall_i
    , input is_ro_fubusy_i
    , input [$bits(fu_t)-1:0] is_ro_fu_i

    , input issue_en_i
    , input [$clog2(NR_SB_ENTRIES)-1:0] issue_pointer_q_i

    , input flu_ready_i

    , input load_valid_i
    , input pop_ld_i
    , input load_done_i

    , input store_valid_i
    , input pop_st_i
    , input store_done_i

    , input [3:0] load_state_i
    , input [1:0] store_state_i
    , input fpu_busy_i

    , input commit_ack_i
    , input [$clog2(NR_SB_ENTRIES)-1:0] commit_pointer_q_i
    , input commit_issued_q_i
    , input [$bits(fu_t)-1:0] commit_fu_q_i
    , input commit_haz_i

    , output [width_p-1:0] fe_wait_o
    , output [width_p-1:0] is_busy_o
    , output [width_p-1:0] sb_full_o
    , output [width_p-1:0] br_haz_o
    , output [width_p-1:0] waw_haz_o
    , output [width_p-1:0] csr_haz_o
    , output [width_p-1:0] mul_haz_o
    , output [width_p-1:0] flu_busy_o
    , output [width_p-1:0] lsu_busy_o
    , output [width_p-1:0] fpu_busy_o
    , output [width_p-1:0] br_miss_o
    , output [width_p-1:0] lsu_tl_o
    , output [width_p-1:0] lsu_wait_o
    , output [width_p-1:0] amo_flush_o
    , output [width_p-1:0] csr_flush_o
    , output [width_p-1:0] exception_o
    , output [width_p-1:0] cmt_haz_o
    , output [width_p-1:0] unknown_o
    );

  stall_reason_s fe, id, is, ex_n, ex, ex_r, flu, flu_n, fpu, fpu_n, commit, filler;
  stall_reason_s st, st_n;
  stall_reason_s [1:0] ld, ld_n;
  stall_reason_s [3:0] wb, wb_r;
  logic issue_en_r;
  logic [$clog2(NR_SB_ENTRIES)-1:0] issue_pointer_r;
  logic [1:0] ld_cntr, st_cntr;

  // Issue stage stalls
  wire is_stall_li = is_valid_i & ~is_ack_i;
  wire sb_full_li = is_stall_li & is_sb_full_i;
  wire br_haz_li  = is_stall_li & is_unresolved_branch_i;
  wire mul_haz_li = is_stall_li & is_ro_mul_stall_i;
  wire csr_haz_li = is_stall_li & is_ro_stall_i;
  wire fu_busy_li = is_stall_li & is_ro_fubusy_i;
  wire waw_haz_li = is_stall_li & ~sb_full_li & ~br_haz_li & ~mul_haz_li & ~csr_haz_li & ~fu_busy_li;
  wire flu_busy_li = fu_busy_li & (is_ro_fu_i inside {ALU, CTRL_FLOW, CSR, MULT});
  wire lsu_busy_li = fu_busy_li & (is_ro_fu_i inside {LOAD, STORE});
  wire fpu_busy_li = fu_busy_li & (is_ro_fu_i inside {FPU, FPU_VEC});

  always_ff @(posedge clk_i) begin
    if(reset_i)
      ld_cntr <= '0;
    else if(pop_ld_i ^ load_done_i) begin
      if(pop_ld_i)
        ld_cntr <= ld_cntr + 2'b1;
      else
        ld_cntr <= ld_cntr - 2'b1;
    end
  end

  always_ff @(posedge clk_i) begin
    if(reset_i)
      st_cntr <= '0;
    else if(pop_st_i ^ store_done_i) begin
      if(pop_st_i)
        st_cntr <= st_cntr + 2'b1;
      else
        st_cntr <= st_cntr - 2'b1;
    end
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
        //id <= '0;
        is <= '0;
        flu <= '0;
      for (integer i=0; i<=1; i++)
        ld[i] <= '0;
      st <= '0;
      fpu <= '0;

      ex <= '0;
      ex_r <= '0;
      for (integer i=0; i<=3; i++)
        wb_r[i] <= '0;
      {issue_en_r, issue_pointer_r} <= '0;

    end
    else begin
      //id <= fe;
      is <= id;
      flu <= flu_n;
      for (integer i=0; i<=1; i++)
        ld[i] <= ld_n[i];
      st <= st_n;
      fpu <= fpu_n;

      ex <= ex_n;
      ex_r <= ex;
      for (integer i=0; i<=3; i++)
        wb_r[i] <= wb[i];
      {issue_en_r, issue_pointer_r} <= {issue_en_i, issue_pointer_q_i};
    end
  end

  always_comb begin

    filler = '0;
    filler.is_busy |= 1'b1;

    //Frontend
    id = '0;
    id.fe_wait |= fe_bubble_i;
    id.br_miss |= branch_mispredict_i;
    id.amo_flush |= flush_amo_i;
    id.csr_flush |= flush_csr_i;
    id.exception |= exception_i;

    //Issue stage
    ex_n = is;
    ex_n.mul_haz  |= mul_haz_li;
    ex_n.csr_haz  |= csr_haz_li;
    ex_n.flu_busy |= flu_busy_li;
    ex_n.lsu_busy |= lsu_busy_li;
    ex_n.fpu_busy |= fpu_busy_li;
    ex_n.waw_haz  |= waw_haz_li;
    ex_n.sb_full  |= sb_full_li;
    ex_n.br_haz   |= br_haz_li;
    ex_n.br_miss |= branch_mispredict_i;
    ex_n.amo_flush |= flush_amo_i;
    ex_n.csr_flush |= flush_csr_i;
    ex_n.exception |= exception_i;

    //FLU pipe
    flu_n = (is_valid_i & ~(is_ro_fu_i inside {ALU, CTRL_FLOW, CSR, MULT})) ? filler : ex_n;
    wb[3] = flu;
    wb[3].mul_haz = mul_haz_li;
    wb[3].flu_busy |= ~flu_ready_i;

    //Load pipe
    ld_n[0] = (is_valid_i & ~(is_ro_fu_i inside {LOAD})) ? filler : ex_n;
    ld_n[1] = ld[0];
    ld_n[1].amo_flush |= flush_amo_i;
    ld_n[1].csr_flush |= flush_csr_i;
    ld_n[1].exception |= exception_i;
    ld_n[1].lsu_tl |= load_valid_i & pop_ld_i;
    ld_n[1].lsu_wait |= ((ld_cntr != '0) & ~load_done_i) | (load_valid_i & ~pop_ld_i);
    wb[2] = ld[1];

    //Store pipe
    st_n = (is_valid_i & ~(is_ro_fu_i inside {STORE})) ? filler : ex_n;
    wb[1] = st;
    wb[1].lsu_tl |= store_valid_i & pop_st_i;
    wb[1].lsu_wait |= ((st_cntr != '0) & ~store_done_i) | (store_valid_i & ~pop_st_i);

    //FPU pipe
    fpu_n = (is_valid_i & ~(is_ro_fu_i inside {FPU, FPU_VEC})) ? filler : ex_n;
    wb[0] = fpu;
    wb[0].fpu_busy |= fpu_busy_i;

    for (integer i=0; i<=3; i++) begin
      wb[i].amo_flush |= flush_amo_i;
      wb[i].csr_flush |= flush_csr_i;
      wb[i].exception |= exception_i;
    end

    //Scoreboard WB
    //If this instruction is issued and was not issued in the prev cycle
    if(commit_issued_q_i && !(issue_en_r && (issue_pointer_r == commit_pointer_q_i))) begin
      unique case(commit_fu_q_i)
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

    commit.cmt_haz |= commit_haz_i;

  end

  wire store_bad_state = ~(store_state_i inside {2'd0, 2'd1});
  wire load_bad_state = ~(load_state_i inside {4'd0, 4'd2});
  wire unknown_lo = ~commit_ack_i & ~(|commit);
  wire extra_lo = commit_ack_i & (|commit);

  logic [$bits(stall_reason_e)-1:0] stall_reason_lo;
  stall_reason_e stall_reason_enum;
  logic stall_reason_v;
  bsg_priority_encode
   #(.width_p($bits(stall_reason_s)), .lo_to_hi_p(1))
   stall_encode
    (.i(commit)
     ,.addr_o(stall_reason_lo)
     ,.v_o(stall_reason_v)
     );
  assign stall_reason_enum = stall_reason_e'(stall_reason_lo);

  wire stall_v = ~commit_ack_i;

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   fe_wait_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == fe_wait))
   ,.count_o(fe_wait_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   is_busy_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == is_busy))
   ,.count_o(is_busy_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   sb_full_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == sb_full))
   ,.count_o(sb_full_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   br_haz_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == br_haz))
   ,.count_o(br_haz_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   waw_haz_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == waw_haz))
   ,.count_o(waw_haz_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   csr_haz_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == csr_haz))
   ,.count_o(csr_haz_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   mul_haz_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == mul_haz))
   ,.count_o(mul_haz_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   flu_busy_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == flu_busy))
   ,.count_o(flu_busy_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   lsu_busy_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == lsu_busy))
   ,.count_o(lsu_busy_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   fpu_busy_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == fpu_busy))
   ,.count_o(fpu_busy_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   br_miss_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == br_miss))
   ,.count_o(br_miss_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   lsu_tl_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == lsu_tl))
   ,.count_o(lsu_tl_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   lsu_wait_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == lsu_wait))
   ,.count_o(lsu_wait_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   amo_flush_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == amo_flush))
   ,.count_o(amo_flush_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   csr_flush_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == csr_flush))
   ,.count_o(csr_flush_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   exception_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == exception))
   ,.count_o(exception_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   cmt_haz_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & (stall_reason_enum == cmt_haz))
   ,.count_o(cmt_haz_o)
   );

  bsg_counter_clear_up
   #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
   unknown_cnt
   (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.clear_i(reset_i)
   ,.up_i(stall_v & ((stall_reason_enum == unknown) | ~(|commit)))
   ,.count_o(unknown_o)
   );



endmodule

