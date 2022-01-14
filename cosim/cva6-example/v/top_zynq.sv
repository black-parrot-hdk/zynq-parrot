
`timescale 1 ns / 1 ps

module top_zynq
   #(
     // NOTE these parameters are usually overridden by the parent module (top.v)
     // but we set them to make expectations consistent

     parameter integer C_S00_AXI_ADDR_WIDTH     = 9
     , parameter integer C_S00_AXI_DATA_WIDTH   = 32

     , parameter integer C_S01_AXI_ADDR_WIDTH   = 32
     , parameter integer C_S01_AXI_DATA_WIDTH   = 64

     , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
     , parameter integer C_M00_AXI_DATA_WIDTH   = 64
     )
   (
    // AXI4-Lite Slave bus
    input wire                                   s00_axi_aclk
    ,input wire                                  s00_axi_aresetn
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
    ,input wire [2 : 0]                          s00_axi_awprot
    ,input wire                                  s00_axi_awvalid
    ,output wire                                 s00_axi_awready
    ,input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
    ,input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
    ,input wire                                  s00_axi_wvalid
    ,output wire                                 s00_axi_wready
    ,output wire [1 : 0]                         s00_axi_bresp
    ,output wire                                 s00_axi_bvalid
    ,input wire                                  s00_axi_bready
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
    ,input wire [2 : 0]                          s00_axi_arprot
    ,input wire                                  s00_axi_arvalid
    ,output wire                                 s00_axi_arready
    ,output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
    ,output wire [1 : 0]                         s00_axi_rresp
    ,output wire                                 s00_axi_rvalid
    ,input wire                                  s00_axi_rready

    // AXI4 Slave bus
    ,input wire                                  s01_axi_aclk
    ,input wire                                  s01_axi_aresetn
    ,input wire [C_S01_AXI_ADDR_WIDTH-1:0]       s01_axi_awaddr
    ,input wire                                  s01_axi_awvalid
    ,output wire                                 s01_axi_awready
    ,input wire [4:0]                            s01_axi_awid
    ,input wire                                  s01_axi_awlock
    ,input wire [3:0]                            s01_axi_awcache
    ,input wire [2:0]                            s01_axi_awprot
    ,input wire [7:0]                            s01_axi_awlen
    ,input wire [2:0]                            s01_axi_awsize
    ,input wire [1:0]                            s01_axi_awburst
    ,input wire [3:0]                            s01_axi_awqos
    ,input wire                                  s01_axi_awuser

    ,input wire [C_S01_AXI_DATA_WIDTH-1:0]       s01_axi_wdata
    ,input wire                                  s01_axi_wvalid
    ,output wire                                 s01_axi_wready
    ,input wire                                  s01_axi_wlast
    ,input wire [(C_S01_AXI_DATA_WIDTH/8)-1:0]   s01_axi_wstrb
    ,input wire                                  s01_axi_wuser

    ,output wire                                 s01_axi_bvalid
    ,input wire                                  s01_axi_bready
    ,output wire [4:0]                           s01_axi_bid
    ,output wire [1:0]                           s01_axi_bresp
    ,output wire                                 s01_axi_buser

    ,input wire [C_S01_AXI_ADDR_WIDTH-1:0]       s01_axi_araddr
    ,input wire                                  s01_axi_arvalid
    ,output wire                                 s01_axi_arready
    ,input wire [4:0]                            s01_axi_arid
    ,input wire                                  s01_axi_arlock
    ,input wire [3:0]                            s01_axi_arcache
    ,input wire [2:0]                            s01_axi_arprot
    ,input wire [7:0]                            s01_axi_arlen
    ,input wire [2:0]                            s01_axi_arsize
    ,input wire [1:0]                            s01_axi_arburst
    ,input wire [3:0]                            s01_axi_arqos
    ,input wire                                  s01_axi_aruser

    ,output wire [C_S01_AXI_DATA_WIDTH-1:0]      s01_axi_rdata
    ,output wire                                 s01_axi_rvalid
    ,input wire                                  s01_axi_rready
    ,output wire [4:0]                           s01_axi_rid
    ,output wire                                 s01_axi_rlast
    ,output wire [1:0]                           s01_axi_rresp
    ,output wire                                 s01_axi_ruser

    // AXI4 Master bus
    ,input wire                                  m00_axi_aclk
    ,input wire                                  m00_axi_aresetn
    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
    ,output wire                                 m00_axi_awvalid
    ,input wire                                  m00_axi_awready
    ,output wire [4:0]                           m00_axi_awid
    ,output wire                                 m00_axi_awlock
    ,output wire [3:0]                           m00_axi_awcache
    ,output wire [2:0]                           m00_axi_awprot
    ,output wire [7:0]                           m00_axi_awlen
    ,output wire [2:0]                           m00_axi_awsize
    ,output wire [1:0]                           m00_axi_awburst
    ,output wire [3:0]                           m00_axi_awqos
    ,output wire                                 m00_axi_awuser

    ,output wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata
    ,output wire                                 m00_axi_wvalid
    ,input wire                                  m00_axi_wready
    ,output wire                                 m00_axi_wlast
    ,output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb
    ,output wire                                 m00_axi_wuser

    ,input wire                                  m00_axi_bvalid
    ,output wire                                 m00_axi_bready
    ,input wire [4:0]                            m00_axi_bid
    ,input wire [1:0]                            m00_axi_bresp
    ,input wire                                  m00_axi_buser

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr
    ,output wire                                 m00_axi_arvalid
    ,input wire                                  m00_axi_arready
    ,output wire [4:0]                           m00_axi_arid
    ,output wire                                 m00_axi_arlock
    ,output wire [3:0]                           m00_axi_arcache
    ,output wire [2:0]                           m00_axi_arprot
    ,output wire [7:0]                           m00_axi_arlen
    ,output wire [2:0]                           m00_axi_arsize
    ,output wire [1:0]                           m00_axi_arburst
    ,output wire [3:0]                           m00_axi_arqos
    ,output wire [5:0]                           m00_axi_aruser

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
    ,input wire                                  m00_axi_rvalid
    ,output wire                                 m00_axi_rready
    ,input wire [4:0]                            m00_axi_rid
    ,input wire                                  m00_axi_rlast
    ,input wire [1:0]                            m00_axi_rresp
    ,input wire                                  m00_axi_ruser
    );

   logic [4:0][C_S00_AXI_DATA_WIDTH-1:0]        csr_data_lo;
   logic [C_S00_AXI_DATA_WIDTH-1:0]             pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic                                        pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic                                        ps_to_pl_fifo_v_lo, ps_to_pl_fifo_yumi_li;

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 241*1024*1024;

   wire resetn_li = csr_data_lo[0][0] & s01_axi_aresetn;
   wire core_resetn_li = csr_data_lo[3][0] & s01_axi_aresetn;
   wire counter_en_li = csr_data_lo[4][0];

   `define COREPATH ariane.i_ariane

   localparam csr_num_lp = 47;
   logic [csr_num_lp-1:0][64-1:0] csr_data_li;

  bsg_dff_reset_en #(
    .width_p(64)
  ) i_cycle (
    .clk_i(s01_axi_aclk),
    .reset_i(~core_resetn_li),
    .en_i(counter_en_li),
    .data_i(`COREPATH.csr_regfile_i.cycle_q[0+:64]),
    .data_o(csr_data_li[0])
  );

  bsg_dff_reset_en #(
    .width_p(64)
  ) i_instret (
    .clk_i(s01_axi_aclk),
    .reset_i(~core_resetn_li),
    .en_i(counter_en_li),
    .data_i(`COREPATH.csr_regfile_i.instret_q[0+:64]),
    .data_o(csr_data_li[1])
  );

  ariane_commit_profiler #(
    .width_p(64)
  ) i_profiler (
    .clk_i(s01_axi_aclk)
    ,.reset_i(~core_resetn_li)
    ,.en_i(counter_en_li)

    ,.instr_qeueu_valid_i(`COREPATH.i_frontend.fetch_entry_valid_o)
    ,.instr_queue_ready_i(`COREPATH.i_frontend.i_instr_queue.ready_o)
    ,.fe_bp_valid_i(`COREPATH.i_frontend.bp_valid)
    ,.fe_replay_i(`COREPATH.i_frontend.replay)
    ,.fe_realign_bubble_i(`COREPATH.i_frontend.icache_valid_q & ~(|`COREPATH.i_frontend.instruction_valid))

    ,.icache_valid_i(`COREPATH.i_frontend.icache_dreq_i.valid)
    ,.icache_ready_i(`COREPATH.i_frontend.icache_dreq_i.ready)
    ,.icache_flush_d_i(`COREPATH.i_cache_subsystem.i_cva6_icache_axi_wrapper.i_cva6_icache.flush_d)
    ,.icache_rtrn_vld_i(`COREPATH.i_cache_subsystem.i_cva6_icache_axi_wrapper.i_cva6_icache.mem_rtrn_vld_i)
    ,.icache_hit_i(`COREPATH.i_cache_subsystem.i_cva6_icache_axi_wrapper.i_cva6_icache.hit)
    ,.icache_state_q_i(`COREPATH.i_cache_subsystem.i_cva6_icache_axi_wrapper.i_cva6_icache.state_q)
    ,.icache_state_d_i(`COREPATH.i_cache_subsystem.i_cva6_icache_axi_wrapper.i_cva6_icache.state_d)

    ,.flush_unissued_instr_i(`COREPATH.controller_i.flush_unissued_instr_o)
    ,.flush_ex_i(`COREPATH.controller_i.flush_ex_o)
    ,.branch_mispredict_i(`COREPATH.controller_i.resolved_branch_i.is_mispredict)
    ,.flush_amo_i(`COREPATH.controller_i.flush_commit_i)
    ,.flush_csr_i(`COREPATH.controller_i.flush_csr_i)
    ,.exception_i(`COREPATH.controller_i.ex_valid_i | `COREPATH.controller_i.eret_i)

    ,.is_valid_i(`COREPATH.issue_stage_i.decoded_instr_valid_i)
    ,.is_ack_i(`COREPATH.issue_stage_i.decoded_instr_ack_o)
    ,.is_unresolved_branch_i(`COREPATH.issue_stage_i.i_scoreboard.unresolved_branch_i)
    ,.is_sb_full_i(`COREPATH.issue_stage_i.i_scoreboard.issue_full)
    ,.is_ro_mul_stall_i(`COREPATH.issue_stage_i.i_issue_read_operands.mult_valid_q 
                     & (`COREPATH.issue_stage_i.i_issue_read_operands.issue_instr_i.fu != ariane_pkg::MULT))
    ,.is_ro_stall_i(`COREPATH.issue_stage_i.i_issue_read_operands.stall)
    ,.is_ro_fubusy_i(`COREPATH.issue_stage_i.i_issue_read_operands.fu_busy)
    ,.is_instr_i(`COREPATH.issue_stage_i.i_issue_read_operands.issue_instr_i)
    ,.is_rd_clobber_gpr_i(`COREPATH.issue_stage_i.i_issue_read_operands.rd_clobber_gpr_i)
    ,.is_rd_clobber_fpr_i(`COREPATH.issue_stage_i.i_issue_read_operands.rd_clobber_fpr_i)
    ,.is_forward_rs1_i(`COREPATH.issue_stage_i.i_issue_read_operands.forward_rs1)
    ,.is_forward_rs2_i(`COREPATH.issue_stage_i.i_issue_read_operands.forward_rs2)
    ,.is_forward_rs3_i(`COREPATH.issue_stage_i.i_issue_read_operands.forward_rs3)
    ,.is_forward_rd_i(|`COREPATH.issue_stage_i.i_scoreboard.rd_fwd_req)

    ,.ex_csr_ready_i(`COREPATH.ex_stage_i.csr_ready)
    ,.ex_div_ready_i(`COREPATH.ex_stage_i.mult_ready)
    ,.ex_fpu_ready_i(`COREPATH.ex_stage_i.fpu_ready_o)

    ,.wb_flu_valid_i(`COREPATH.ex_stage_i.flu_valid_o)
    ,.wb_fpu_valid_i(`COREPATH.ex_stage_i.fpu_valid_o)
    ,.wb_ld_valid_i(`COREPATH.ex_stage_i.load_valid_o)
    ,.wb_st_valid_i(`COREPATH.ex_stage_i.store_valid_o)

    ,.lsu_ctrl_i(`COREPATH.ex_stage_i.lsu_i.lsu_ctrl)
    ,.pop_ld_i(`COREPATH.ex_stage_i.lsu_i.pop_ld)
    ,.ld_done_i(`COREPATH.ex_stage_i.lsu_i.i_load_unit.valid_o)
    ,.ld_state_q_i(`COREPATH.ex_stage_i.lsu_i.i_load_unit.state_q)
    ,.st_state_q_i(`COREPATH.ex_stage_i.lsu_i.i_store_unit.state_q)

    ,.issue_en_i(`COREPATH.issue_stage_i.i_scoreboard.issue_en)
    ,.issue_pointer_q_i(`COREPATH.issue_stage_i.i_scoreboard.issue_pointer_q)

    ,.cmt_ack_i(`COREPATH.commit_stage_i.commit_ack_o[1:0])
    ,.cmt_instr_i(`COREPATH.commit_stage_i.commit_instr_i[1:0])
    ,.cmt_issued_q_i(`COREPATH.issue_stage_i.i_scoreboard.mem_q_commit.issued)
    ,.cmt_lsu_ready_i(`COREPATH.commit_stage_i.commit_lsu_ready_i)
    ,.cmt_pointer_q_i(`COREPATH.issue_stage_i.i_scoreboard.commit_pointer_q[0])

    ,.m_arvalid_i(m00_axi_arvalid)
    ,.m_arready_i(m00_axi_arready)
    ,.m_arid_i(m00_axi_arid)
    ,.m_rlast_i(m00_axi_rvalid & m00_axi_rlast)

    ,.m_awvalid_i(m00_axi_awvalid)
    ,.m_awready_i(m00_axi_awready)
    ,.m_awid_i(m00_axi_awid)
    ,.m_bvalid_i(m00_axi_bvalid)

    ,.iq_full_o     (csr_data_li[2])
    ,.ic_invl_o     (csr_data_li[3])
    ,.ic_miss_o     (csr_data_li[4])
    ,.ic_dma_o      (csr_data_li[5])
    ,.ic_flush_o    (csr_data_li[6])
    ,.ic_atrans_o   (csr_data_li[7])
    ,.bp_haz_o      (csr_data_li[8])
    ,.ireplay_o     (csr_data_li[9])
    ,.realign_o     (csr_data_li[10])
    ,.sb_full_o     (csr_data_li[11])
    ,.waw_flu_o     (csr_data_li[12])
    ,.waw_lsu_o     (csr_data_li[13])
    ,.waw_fpu_o     (csr_data_li[14])
    ,.waw_reorder_o (csr_data_li[15])
    ,.raw_flu_o     (csr_data_li[16])
    ,.raw_lsu_o     (csr_data_li[17])
    ,.raw_fpu_o     (csr_data_li[18])
    ,.br_haz_o      (csr_data_li[19])
    ,.br_miss_o     (csr_data_li[20])
    ,.mul_haz_o     (csr_data_li[21])
    ,.csr_buf_o     (csr_data_li[22])
    ,.div_busy_o    (csr_data_li[23])
    ,.ld_pipe_o     (csr_data_li[24])
    ,.ld_grant_o    (csr_data_li[25])
    ,.ld_sbuf_o     (csr_data_li[26])
    ,.ld_dcache_o   (csr_data_li[27])
    ,.st_pipe_o     (csr_data_li[28])
    ,.sbuf_spec_o   (csr_data_li[29])
    ,.fpu_busy_o    (csr_data_li[30])
    ,.amo_flush_o   (csr_data_li[31])
    ,.csr_flush_o   (csr_data_li[32])
    ,.exception_o   (csr_data_li[33])
    ,.cmt_haz_o     (csr_data_li[34])
    ,.sbuf_cmt_o    (csr_data_li[35])
    ,.dc_dma_o      (csr_data_li[36])
    ,.unknown_o     (csr_data_li[37])
    ,.wdma_cnt_o    (csr_data_li[38])
    ,.rdma_cnt_o    (csr_data_li[39])
    ,.wdma_wait_o   (csr_data_li[40])
    ,.rdma_wait_o   (csr_data_li[41])
    ,.ilong_instr_o (csr_data_li[42])
    ,.flong_instr_o (csr_data_li[43])
    ,.fma_instr_o   (csr_data_li[44])
    ,.aux_instr_o   (csr_data_li[45])
    ,.mem_instr_o   (csr_data_li[46])
  );

   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      .num_regs_ps_to_pl_p (5)
      ,.num_fifo_ps_to_pl_p(1)
      ,.num_fifo_pl_to_ps_p(1)
      ,.num_regs_pl_to_ps_p(4 + (2*csr_num_lp))
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_o(csr_data_lo)

        ,.csr_data_i({ csr_data_li
                       , mem_profiler_r[127:96]
                       , mem_profiler_r[95:64]
                       , mem_profiler_r[63:32]
                       , mem_profiler_r[31:0]
                     })

        ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

        ,.S_AXI_ACLK   (s00_axi_aclk)
        ,.S_AXI_ARESETN(s00_axi_aresetn)
        ,.S_AXI_AWADDR (s00_axi_awaddr)
        ,.S_AXI_AWPROT (s00_axi_awprot)
        ,.S_AXI_AWVALID(s00_axi_awvalid)
        ,.S_AXI_AWREADY(s00_axi_awready)
        ,.S_AXI_WDATA  (s00_axi_wdata)
        ,.S_AXI_WSTRB  (s00_axi_wstrb)
        ,.S_AXI_WVALID (s00_axi_wvalid)
        ,.S_AXI_WREADY (s00_axi_wready)
        ,.S_AXI_BRESP  (s00_axi_bresp)
        ,.S_AXI_BVALID (s00_axi_bvalid)
        ,.S_AXI_BREADY (s00_axi_bready)
        ,.S_AXI_ARADDR (s00_axi_araddr)
        ,.S_AXI_ARPROT (s00_axi_arprot)
        ,.S_AXI_ARVALID(s00_axi_arvalid)
        ,.S_AXI_ARREADY(s00_axi_arready)
        ,.S_AXI_RDATA  (s00_axi_rdata)
        ,.S_AXI_RRESP  (s00_axi_rresp)
        ,.S_AXI_RVALID (s00_axi_rvalid)
        ,.S_AXI_RREADY (s00_axi_rready)
        );

   logic [64-1:0] io_awaddr;
   logic io_awvalid, io_awready;
   logic [64-1:0] io_wdata;
   logic [8-1:0] io_wstrb;
   logic io_wvalid, io_wready;
   logic [1:0] io_bresp;
   logic io_bvalid, io_bready;
   logic [64-1:0] io_araddr;
   logic io_arvalid, io_arready;
   logic [64-1:0] io_rdata;
   logic [1:0] io_rresp;
   logic io_rvalid, io_rready;

   logic io_v, io_we;
   logic [64-1:0] io_addr, io_data;

   logic [64-1:0] waddr_translated_lo, raddr_translated_lo;
   logic [64-1:0] axi_awaddr, axi_araddr;

   // AXI 0x0000_0000 .. 0x0FFF_FFFF -> Core 0x8000_0000 - 0x8FFF_FFFF
   // AXI 0x2000_0000 .. 0x2FFF_FFFF -> Core 0x0000_0000 - 0x0FFF_FFFF
   assign waddr_translated_lo = {32'b0, ~s01_axi_awaddr[29], 3'b0, s01_axi_awaddr[0+:28]};
   assign raddr_translated_lo = {32'b0, ~s01_axi_araddr[29], 3'b0, s01_axi_araddr[0+:28]};

   assign m00_axi_awaddr = (axi_awaddr[0+:32] ^ 32'h8000_0000) + csr_data_lo[2];
   assign m00_axi_araddr = (axi_araddr[0+:32] ^ 32'h8000_0000) + csr_data_lo[2];

   assign pl_to_ps_fifo_v_li    = io_v & io_we;
   assign pl_to_ps_fifo_data_li = {(io_v & io_we), io_addr[22:0], io_data[7:0]};

   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(s01_axi_aclk)
      ,.reset_i(~resetn_li)
      ,.data_i(mem_profiler_r
               | m00_axi_awvalid << (axi_awaddr[29-:7])
               | m00_axi_arvalid << (axi_araddr[29-:7])
               )
      ,.data_o(mem_profiler_r)
      );

   ariane_top
    #(.AXI_ADDR_WIDTH(64)
     ,.AXI_DATA_WIDTH(64)
     ,.AXI_USER_WIDTH(1)
     )
    ariane
     (.clk_i(s01_axi_aclk)
     ,.resetn_i(resetn_li)
     ,.core_resetn_i(core_resetn_li)

     ,.s_awvalid_i (s01_axi_awvalid)
     ,.s_awburst_i (s01_axi_awburst)
     ,.s_awaddr_i  (waddr_translated_lo)
     ,.s_awlen_i   (s01_axi_awlen)
     ,.s_awsize_i  (s01_axi_awsize)
     ,.s_awid_i    (s01_axi_awid)
     ,.s_awcache_i (s01_axi_awcache)
     ,.s_awprot_i  (s01_axi_awprot)
     ,.s_awqos_i   (s01_axi_awqos)
     ,.s_awuser_i  (s01_axi_awuser)
     ,.s_awlock_i  (s01_axi_awlock)
     ,.s_awready_o (s01_axi_awready)

     ,.s_wvalid_i  (s01_axi_wvalid)
     ,.s_wstrb_i   (s01_axi_wstrb)
     ,.s_wdata_i   (s01_axi_wdata)
     ,.s_wlast_i   (s01_axi_wlast)
     ,.s_wuser_i   (s01_axi_wuser)
     ,.s_wready_o  (s01_axi_wready)

     ,.s_bready_i  (s01_axi_bready)
     ,.s_bvalid_o  (s01_axi_bvalid)
     ,.s_bresp_o   (s01_axi_bresp)
     ,.s_bid_o     (s01_axi_bid)
     ,.s_buser_o   (s01_axi_buser)

     ,.s_arvalid_i (s01_axi_arvalid)
     ,.s_arburst_i (s01_axi_arburst)
     ,.s_araddr_i  (raddr_translated_lo)
     ,.s_arlen_i   (s01_axi_arlen)
     ,.s_arsize_i  (s01_axi_arsize)
     ,.s_arid_i    (s01_axi_arid)
     ,.s_arcache_i (s01_axi_arcache)
     ,.s_arprot_i  (s01_axi_arprot)
     ,.s_arqos_i   (s01_axi_arqos)
     ,.s_aruser_i  (s01_axi_aruser)
     ,.s_arlock_i  (s01_axi_arlock)
     ,.s_arready_o (s01_axi_arready)

     ,.s_rready_i  (s01_axi_rready)
     ,.s_rvalid_o  (s01_axi_rvalid)
     ,.s_rdata_o   (s01_axi_rdata)
     ,.s_rresp_o   (s01_axi_rresp)
     ,.s_rid_o     (s01_axi_rid)
     ,.s_rlast_o   (s01_axi_rlast)
     ,.s_ruser_o   (s01_axi_ruser)

     ,.m_awready_i (m00_axi_awready)
     ,.m_awvalid_o (m00_axi_awvalid)
     ,.m_awburst_o (m00_axi_awburst)
     ,.m_awaddr_o  (axi_awaddr)
     ,.m_awlen_o   (m00_axi_awlen)
     ,.m_awsize_o  (m00_axi_awsize)
     ,.m_awid_o    (m00_axi_awid)
     ,.m_awcache_o (m00_axi_awcache)
     ,.m_awprot_o  (m00_axi_awprot)
     ,.m_awqos_o   (m00_axi_awqos)
     ,.m_awuser_o  (m00_axi_awuser)
     ,.m_awlock_o  (m00_axi_awlock)

     ,.m_wready_i  (m00_axi_wready)
     ,.m_wvalid_o  (m00_axi_wvalid)
     ,.m_wstrb_o   (m00_axi_wstrb)
     ,.m_wdata_o   (m00_axi_wdata)
     ,.m_wlast_o   (m00_axi_wlast)
     ,.m_wuser_o   (m00_axi_wuser)

     ,.m_bvalid_i  (m00_axi_bvalid)
     ,.m_bresp_i   (m00_axi_bresp)
     ,.m_bid_i     (m00_axi_bid)
     ,.m_buser_i   (m00_axi_buser)
     ,.m_bready_o  (m00_axi_bready)

     ,.m_arready_i (m00_axi_arready)
     ,.m_arvalid_o (m00_axi_arvalid)
     ,.m_arburst_o (m00_axi_arburst)
     ,.m_araddr_o  (axi_araddr)
     ,.m_arlen_o   (m00_axi_arlen)
     ,.m_arsize_o  (m00_axi_arsize)
     ,.m_arid_o    (m00_axi_arid)
     ,.m_arcache_o (m00_axi_arcache)
     ,.m_arprot_o  (m00_axi_arprot)
     ,.m_arqos_o   (m00_axi_arqos)
     ,.m_aruser_o  (m00_axi_aruser)
     ,.m_arlock_o  (m00_axi_arlock)

     ,.m_rvalid_i  (m00_axi_rvalid)
     ,.m_rdata_i   (m00_axi_rdata)
     ,.m_rresp_i   (m00_axi_rresp)
     ,.m_rid_i     (m00_axi_rid)
     ,.m_rlast_i   (m00_axi_rlast)
     ,.m_ruser_i   (m00_axi_ruser)
     ,.m_rready_o  (m00_axi_rready)

     ,.io_awready_i(io_awready)
     ,.io_awvalid_o(io_awvalid)
     ,.io_awaddr_o (io_awaddr)

     ,.io_wready_i (io_wready)
     ,.io_wvalid_o (io_wvalid)
     ,.io_wstrb_o  (io_wstrb)
     ,.io_wdata_o  (io_wdata)

     ,.io_bvalid_i (io_bvalid)
     ,.io_bresp_i  (io_bresp)
     ,.io_bready_o (io_bready)

     ,.io_arready_i(io_arready)
     ,.io_arvalid_o(io_arvalid)
     ,.io_araddr_o (io_araddr)

     ,.io_rvalid_i (io_rvalid)
     ,.io_rdata_i  (io_rdata)
     ,.io_rresp_i  (io_rresp)
     ,.io_rready_o (io_rready)
     );

   axi_lite_to_dma
    #(.addr_width_p(64)
     ,.data_width_p(64)
     )
    i_axi_lite_converter
     (.clk_i(s01_axi_aclk)
     ,.reset_i(~resetn_li)

     ,.awready_o(io_awready)
     ,.awvalid_i(io_awvalid)
     ,.awaddr_i (io_awaddr)

     ,.wready_o (io_wready)
     ,.wvalid_i (io_wvalid)
     ,.wstrb_i  (io_wstrb)
     ,.wdata_i  (io_wdata)

     ,.bvalid_o (io_bvalid)
     ,.bresp_o  (io_bresp)
     ,.bready_i (io_bready)

     ,.arready_o(io_arready)
     ,.arvalid_i(io_arvalid)
     ,.araddr_i (io_araddr)

     ,.rvalid_o (io_rvalid)
     ,.rdata_o  (io_rdata)
     ,.rresp_o  (io_rresp)
     ,.rready_i (io_rready)

     ,.ready_i  (pl_to_ps_fifo_ready_lo)
     ,.v_o      (io_v)
     ,.we_o     (io_we)
     ,.addr_o   (io_addr)
     ,.data_o   (io_data)

     ,.ready_o  ()
     ,.v_i      ('0)
     ,.data_i   ('0)
     );

   // synopsys translate_off
   always @(negedge s01_axi_aclk)
     if (s01_axi_awvalid & s01_axi_awready)
       if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,waddr_translated_lo);

   always @(negedge s01_axi_aclk)
     if (s01_axi_arvalid & s01_axi_arready)
       if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,raddr_translated_lo);

   always @(negedge s01_axi_aclk)
     begin
        if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
        if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
     end

   always @(negedge m00_axi_aclk)
     if (m00_axi_awvalid & m00_axi_awready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

   always @(negedge s01_axi_aclk)
     if (m00_axi_arvalid & m00_axi_arready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Read Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);
   // synopsys translate_on

endmodule
