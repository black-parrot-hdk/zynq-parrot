
`timescale 1 ps / 1 ps

`include "bsg_manycore_defines.vh"
`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import zynq_pkg::*;
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 import bsg_manycore_pkg::*;
 import bsg_axi_pkg::*;
 import bsg_cache_pkg::*;
 import bsg_noc_pkg::*;
 import bsg_tag_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_unicore_hammerblade_cfg
   `declare_bp_proc_params(bp_params_p)
   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_S00_AXI_DATA_WIDTH   = 32
   , parameter integer C_S00_AXI_ADDR_WIDTH   = 10
   , parameter integer C_M00_AXI_DATA_WIDTH   = 32
   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
   )
  (  input wire                                  aclk
   , input wire                                  aresetn
   
   // Ports of Axi Slave Bus Interface S00_AXI
   , input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
   , input wire [2 : 0]                          s00_axi_awprot
   , input wire                                  s00_axi_awvalid
   , output wire                                 s00_axi_awready
   , input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
   , input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
   , input wire                                  s00_axi_wvalid
   , output wire                                 s00_axi_wready
   , output wire [1 : 0]                         s00_axi_bresp
   , output wire                                 s00_axi_bvalid
   , input wire                                  s00_axi_bready
   , input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
   , input wire [2 : 0]                          s00_axi_arprot
   , input wire                                  s00_axi_arvalid
   , output wire                                 s00_axi_arready
   , output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
   , output wire [1 : 0]                         s00_axi_rresp
   , output wire                                 s00_axi_rvalid
   , input wire                                  s00_axi_rready

   , output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
   , output wire                                 m00_axi_awvalid
   , input wire                                  m00_axi_awready
   , output wire [5:0]                           m00_axi_awid
   , output wire [1:0]                           m00_axi_awlock
   , output wire [3:0]                           m00_axi_awcache
   , output wire [2:0]                           m00_axi_awprot
   , output wire [3:0]                           m00_axi_awlen
   , output wire [2:0]                           m00_axi_awsize
   , output wire [1:0]                           m00_axi_awburst
   , output wire [3:0]                           m00_axi_awqos

   , output wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata
   , output wire                                 m00_axi_wvalid
   , input wire                                  m00_axi_wready
   , output wire [5:0]                           m00_axi_wid
   , output wire                                 m00_axi_wlast
   , output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb

   , input wire                                  m00_axi_bvalid
   , output wire                                 m00_axi_bready
   , input wire [5:0]                            m00_axi_bid
   , input wire [1:0]                            m00_axi_bresp

   , output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr
   , output wire                                 m00_axi_arvalid
   , input wire                                  m00_axi_arready
   , output wire [5:0]                           m00_axi_arid
   , output wire [1:0]                           m00_axi_arlock
   , output wire [3:0]                           m00_axi_arcache
   , output wire [2:0]                           m00_axi_arprot
   , output wire [3:0]                           m00_axi_arlen
   , output wire [2:0]                           m00_axi_arsize
   , output wire [1:0]                           m00_axi_arburst
   , output wire [3:0]                           m00_axi_arqos

   , input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
   , input wire                                  m00_axi_rvalid
   , output wire                                 m00_axi_rready
   , input wire [5:0]                            m00_axi_rid
   , input wire                                  m00_axi_rlast
   , input wire [1:0]                            m00_axi_rresp
   );

   localparam num_regs_ps_to_pl_lp = 5;
   localparam num_regs_pl_to_ps_lp = 2;
   localparam num_fifos_ps_to_pl_lp = 2;
   localparam num_fifos_pl_to_ps_lp = 2;

   logic [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0]       csr_data_li;
   logic [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0]       csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                                 csr_data_new_lo;
   logic [num_fifos_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0]      pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic [num_fifos_pl_to_ps_lp-1:0]                                pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic [num_fifos_ps_to_pl_lp-1:0]                                ps_to_pl_fifo_v_lo, ps_to_pl_fifo_yumi_li;

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 256*1024*1024;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      .num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
      ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
      ,.num_fifo_ps_to_pl_p(num_fifos_ps_to_pl_lp)
      ,.num_fifo_pl_to_ps_p(num_fifos_pl_to_ps_lp)
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_o(csr_data_lo)
        ,.csr_data_new_o(csr_data_new_lo)

        // (MBT)
        // note: this ability to probe into the core is not supported in ASIC toolflows but
        // is supported in Verilator, VCS, and Vivado Synthesis.

        // it is very helpful for adding instrumentation to a pre-existing design that you are
        // prototyping in FPGA, where you don't necessarily want to put the support into the ASIC version
        // or don't know yet if you want to.

        // in additional to this approach of poking down into pre-existing registers, you can also
        // instantiate counters, and then pull control signals out of the DUT in order to figure out when
        // to increment the counters.
        //

        ,.csr_data_i(csr_data_li)

        ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

        ,.S_AXI_ACLK   (aclk)
        ,.S_AXI_ARESETN(aresetn)
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

   ///////////////////////////////////////////////////////////////////////////////////////
   // TODO: User code goes here
   ///////////////////////////////////////////////////////////////////////////////////////
   logic sys_resetn;
   logic bb_data_li, bb_v_li;
   logic dram_init_li;
   logic [C_M00_AXI_ADDR_WIDTH-1:0] dram_base_li;
   logic [`BSG_WIDTH(max_credits_p)-1:0] credits_used_lo;
   logic [`BSG_SAFE_CLOG2(bsg_machine_rom_els_gp)-1:0] rom_addr_lo;
   logic [bsg_machine_rom_width_gp-1:0] rom_data_li;

   assign sys_resetn   = csr_data_lo[0][0]; // active-low
   assign bb_data_li   = csr_data_lo[1][0]; assign bb_v_li = csr_data_new_lo[1];
   assign dram_init_li = csr_data_lo[2];
   assign dram_base_li = csr_data_lo[3];
   assign rom_addr_lo  = csr_data_lo[4];

   assign csr_data_li[0] = |credits_used_lo;
   assign csr_data_li[1] = rom_data_li;

   bsg_rom_param
    #(.data_p(bsg_machine_rom_arr_gp)
      ,.data_width_p($bits(bsg_machine_rom_arr_gp))
      ,.width_p(bsg_machine_rom_width_gp)
      ,.els_p(bsg_machine_rom_els_gp)
      )
    rom
     (.addr_i(rom_addr_lo)
      ,.data_o(rom_data_li)
      );

   // instantiate manycore
   `declare_bsg_manycore_link_sif_s(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);
   `declare_bsg_manycore_ruche_x_link_sif_s(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p);
   `declare_bsg_ready_and_link_sif_s(wh_flit_width_p, wh_link_sif_s);
   bsg_manycore_link_sif_s [S:N][(num_pods_x_p*num_tiles_x_p)-1:0] ver_link_sif_li;
   bsg_manycore_link_sif_s [S:N][(num_pods_x_p*num_tiles_x_p)-1:0] ver_link_sif_lo;
   wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] wh_link_sif_li;
   wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] wh_link_sif_lo;
   bsg_manycore_link_sif_s [E:W][num_pods_y_p-1:0][num_tiles_y_p-1:0] hor_link_sif_li;
   bsg_manycore_link_sif_s [E:W][num_pods_y_p-1:0][num_tiles_y_p-1:0] hor_link_sif_lo;

   // BSG TAG MASTER
   logic tag_done_lo;
   bsg_tag_s [num_pods_y_p-1:0][num_pods_x_p-1:0] pod_tags_lo;
 
   // Tag bitbang
   logic tag_clk_r_lo, tag_data_r_lo;
   logic bb_ready_and_lo;
   bsg_tag_bitbang
    bb
     (.clk_i(aclk)
      ,.reset_i(~aresetn)
      ,.data_i(bb_data_li)
      ,.v_i(bb_v_li)
      ,.ready_and_o(bb_ready_and_lo) // UNUSED

      ,.tag_clk_r_o(tag_clk_r_lo)
      ,.tag_data_r_o(tag_data_r_lo)
      );
   assign tag_clk = tag_clk_r_lo;
   assign tag_data = tag_data_r_lo;

   // Tag master and clients for PL
   zynq_pl_tag_lines_s tag_lines_lo;
   bsg_tag_master_decentralized
    #(.els_p(tag_els_gp)
      ,.local_els_p(tag_pl_local_els_gp)
      ,.lg_width_p(tag_lg_width_gp)
      )
    master
     (.clk_i(tag_clk_r_lo)
      ,.data_i(tag_data_r_lo)
      ,.node_id_offset_i(tag_pl_offset_gp)
      ,.clients_o(tag_lines_lo)
      );

   logic reset_r;
   wire reset_n = ~sys_resetn;
   bsg_dff_chain #(
     .width_p(1)
     ,.num_stages_p(reset_depth_p)
   ) reset_dff (
     .clk_i(aclk)
     ,.data_i(reset_n)
     ,.data_o(reset_r)
   );

   bsg_manycore_pod_mesh_array #(
      .num_tiles_x_p(num_tiles_x_p)
      ,.num_tiles_y_p(num_tiles_y_p)
      ,.pod_x_cord_width_p(pod_x_cord_width_p)
      ,.pod_y_cord_width_p(pod_y_cord_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.barrier_ruche_factor_X_p(barrier_ruche_factor_X_p)
      ,.num_subarray_x_p(num_subarray_x_p)
      ,.num_subarray_y_p(num_subarray_y_p)

      ,.dmem_size_p(dmem_size_p)
      ,.icache_entries_p(icache_entries_p)
      ,.icache_tag_width_p(icache_tag_width_p)
      ,.icache_block_size_in_words_p(icache_block_size_in_words_p)

      ,.num_vcache_rows_p(num_vcache_rows_p)
      ,.vcache_addr_width_p(vcache_addr_width_p)
      ,.vcache_data_width_p(vcache_data_width_p)
      ,.vcache_ways_p(vcache_ways_p)
      ,.vcache_sets_p(vcache_sets_p)
      ,.vcache_block_size_in_words_p(vcache_block_size_in_words_p)
      ,.vcache_size_p(vcache_size_p)
      ,.vcache_dma_data_width_p(vcache_dma_data_width_p)
      ,.vcache_word_tracking_p(vcache_word_tracking_p)

      ,.wh_ruche_factor_p(wh_ruche_factor_p)
      ,.wh_cid_width_p(wh_cid_width_p)
      ,.wh_flit_width_p(wh_flit_width_p)
      ,.wh_cord_width_p(wh_cord_width_p)
      ,.wh_len_width_p(wh_len_width_p)

      ,.num_pods_y_p(num_pods_y_p)
      ,.num_pods_x_p(num_pods_x_p)

      ,.reset_depth_p(reset_depth_p)
    ) DUT (
      .clk_i(aclk)

      ,.ver_link_sif_i(ver_link_sif_li)
      ,.ver_link_sif_o(ver_link_sif_lo)

      ,.wh_link_sif_i(wh_link_sif_li)
      ,.wh_link_sif_o(wh_link_sif_lo)

      ,.hor_link_sif_i(hor_link_sif_li)
      ,.hor_link_sif_o(hor_link_sif_lo)

      ,.pod_tags_i(tag_lines_lo) 
    );

  // IO ROUTER
  bsg_manycore_link_sif_s [(num_pods_x_p*num_tiles_x_p)-1:0][S:P] io_link_sif_li;
  bsg_manycore_link_sif_s [(num_pods_x_p*num_tiles_x_p)-1:0][S:P] io_link_sif_lo;

  for (genvar x = 0; x < num_pods_x_p*num_tiles_x_p; x++) begin: io_rtr_x
    bsg_manycore_mesh_node #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.stub_p(4'b0100) // stub north
      ,.rev_use_credits_p(rev_use_credits_lp)
      ,.rev_fifo_els_p(rev_fifo_els_lp)
    ) io_rtr (
      .clk_i(aclk)
      ,.reset_i(reset_r)

      ,.links_sif_i(io_link_sif_li[x][S:W])
      ,.links_sif_o(io_link_sif_lo[x][S:W])

      ,.proc_link_sif_i(io_link_sif_li[x][P])
      ,.proc_link_sif_o(io_link_sif_lo[x][P])

      ,.global_x_i(x_cord_width_p'(num_tiles_x_p+x))
      ,.global_y_i(y_cord_width_p'(0))
    );

    // connect to pod array
    assign ver_link_sif_li[N][x] = io_link_sif_lo[x][S];
    assign io_link_sif_li[x][S] = ver_link_sif_lo[N][x];

    // connect between io rtr
    if (x < (num_pods_x_p*num_tiles_x_p)-1) begin
      assign io_link_sif_li[x][E] = io_link_sif_lo[x+1][W];
      assign io_link_sif_li[x+1][W] = io_link_sif_lo[x][E];
    end
  end

    logic [C_S00_AXI_DATA_WIDTH-1:0] mc_req_lo;
    logic mc_req_v_lo, mc_req_ready_li;
    logic [C_S00_AXI_DATA_WIDTH-1:0] mc_rsp_lo;
    logic mc_rsp_v_lo, mc_rsp_ready_li;
    logic [C_S00_AXI_DATA_WIDTH-1:0] host_req_li;
    logic host_req_v_li, host_req_ready_lo;
    logic [C_S00_AXI_DATA_WIDTH-1:0] host_rsp_li;
    logic host_rsp_v_li, host_rsp_ready_lo;
    wire [x_cord_width_p-1:0] io_global_x_li = 0;
    wire [y_cord_width_p-1:0] io_global_y_li = 0;
    bsg_manycore_endpoint_to_fifos
     #(.fifo_width_p(4*C_S00_AXI_DATA_WIDTH)
       ,.axil_width_p(C_S00_AXI_DATA_WIDTH)
       ,.x_cord_width_p(x_cord_width_p)
       ,.y_cord_width_p(y_cord_width_p)
       ,.addr_width_p(addr_width_p)
       ,.data_width_p(data_width_p)
       ,.ep_fifo_els_p(ep_fifo_els_p)
       ,.credit_counter_width_p(`BSG_WIDTH(max_credits_p))
       ,.rev_fifo_els_p(rev_fifo_els_lp[0])
       ,.icache_block_size_in_words_p(icache_block_size_in_words_p)
       )
     mc_ep_to_fifos
      (.clk_i(aclk)
       ,.reset_i(reset_r)

       // fifo interface
       ,.mc_req_o(mc_req_lo)
       ,.mc_req_v_o(mc_req_v_lo)
       ,.mc_req_ready_i(mc_req_ready_li)

       ,.endpoint_req_i(host_req_li)
       ,.endpoint_req_v_i(host_req_v_li)
       ,.endpoint_req_ready_o(host_req_ready_lo)

       ,.endpoint_rsp_i(host_rsp_li)
       ,.endpoint_rsp_v_i(host_rsp_v_li)
       ,.endpoint_rsp_ready_o(host_rsp_ready_lo)

       ,.mc_rsp_o(mc_rsp_lo)
       ,.mc_rsp_v_o(mc_rsp_v_lo)
       ,.mc_rsp_ready_i(mc_rsp_ready_li)

       // manycore link
       ,.link_sif_i(io_link_sif_lo[0][P])
       ,.link_sif_o(io_link_sif_li[0][P])

       // Parameterize
       ,.global_y_i(io_global_y_li)
       ,.global_x_i(io_global_x_li)

       /* Unused currently */
       ,.out_credits_used_o(credits_used_lo)
       );

     assign pl_to_ps_fifo_data_li[0+:1]  = mc_req_lo;
     assign pl_to_ps_fifo_v_li[0+:1]     = {1{mc_req_ready_li & mc_req_v_lo}};
     assign mc_req_ready_li              = &pl_to_ps_fifo_ready_lo[0+:1];

     assign pl_to_ps_fifo_data_li[1+:1]  = mc_rsp_lo;
     assign pl_to_ps_fifo_v_li[1+:1]     = {1{mc_rsp_ready_li & mc_rsp_v_lo}};
     assign mc_rsp_ready_li              = &pl_to_ps_fifo_ready_lo[1+:1];

     assign host_req_li                  = ps_to_pl_fifo_data_lo[0+:1];
     assign host_req_v_li                = &ps_to_pl_fifo_v_lo[0+:1];
     assign ps_to_pl_fifo_yumi_li[0+:1]  = {1{host_req_v_li & host_req_ready_lo}};

     assign host_rsp_li                  = ps_to_pl_fifo_data_lo[1+:1];
     assign host_rsp_v_li                = &ps_to_pl_fifo_v_lo[1+:1];
     assign ps_to_pl_fifo_yumi_li[1+:1]  = {1{host_rsp_v_li & host_rsp_ready_lo}};

      // WH to cache dma
      `declare_bsg_cache_dma_pkt_s(vcache_addr_width_p, vcache_block_size_in_words_p);
      bsg_cache_dma_pkt_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_lo;
      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_v_lo;
      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_yumi_li;

      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0][vcache_dma_data_width_p-1:0] dma_data_li;
      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_li;
      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_ready_lo;

      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0][vcache_dma_data_width_p-1:0] dma_data_lo;
      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_lo;
      logic [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0][num_vcaches_per_link_lp-1:0] dma_data_yumi_li;

    // Invert WH ruche links
    // hardcoded for ruche factor = 2
    wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] buffered_wh_link_sif_li;
    wh_link_sif_s [E:W][num_pods_y_p-1:0][S:N][num_vcache_rows_p-1:0][wh_ruche_factor_p-1:0] buffered_wh_link_sif_lo;
    for (genvar i = W; i <= E; i++) begin
      for (genvar j = 0; j < num_pods_y_p; j++) begin
        for (genvar k = N; k <= S; k++) begin
          for (genvar v = 0; v < num_vcache_rows_p; v++) begin
            for (genvar r = 0; r < wh_ruche_factor_p; r++) begin
              if (r == 0) begin
                assign wh_link_sif_li[i][j][k][v][r] = buffered_wh_link_sif_li[i][j][k][v][r];
                assign buffered_wh_link_sif_lo[i][j][k][v][r] = wh_link_sif_lo[i][j][k][v][r];
              end
              else begin
                assign wh_link_sif_li[i][j][k][v][r] = ~buffered_wh_link_sif_li[i][j][k][v][r];
                assign buffered_wh_link_sif_lo[i][j][k][v][r] = ~wh_link_sif_lo[i][j][k][v][r];
              end
            end
          end
        end
      end
    end

      for (genvar i = W; i <= E; i++) begin: hs
        for (genvar j = 0; j < num_pods_y_p; j++) begin: py
          for (genvar k = N; k <= S; k++) begin: py
            for (genvar n = 0; n < num_vcache_rows_p; n++) begin: row
              for (genvar r = 0; r < wh_ruche_factor_p; r++) begin: rf

                `declare_bsg_cache_wh_header_flit_s(wh_flit_width_p,wh_cord_width_p,wh_len_width_p,wh_cid_width_p);
                bsg_cache_wh_header_flit_s header_flit_in;
                assign header_flit_in = buffered_wh_link_sif_lo[i][j][k][n][r].data;

                wire [lg_num_vcaches_per_link_lp-1:0] dma_id_li = (num_vcaches_per_link_lp == 1)
                  ? 1'b0
                  : header_flit_in.src_cord[lg_wh_ruche_factor_lp+:lg_num_vcaches_per_link_lp];

                bsg_wormhole_to_cache_dma_fanout#(
                  .num_dma_p(num_vcaches_per_link_lp)
                  ,.dma_addr_width_p(vcache_addr_width_p)
                  ,.dma_mask_width_p(vcache_block_size_in_words_p)
                  ,.dma_burst_len_p(vcache_block_size_in_words_p*vcache_data_width_p/vcache_dma_data_width_p)

                  ,.wh_flit_width_p(wh_flit_width_p)
                  ,.wh_cid_width_p(wh_cid_width_p)
                  ,.wh_len_width_p(wh_len_width_p)
                  ,.wh_cord_width_p(wh_cord_width_p)
                ) wh_to_dma (
                  .clk_i(aclk)
                  ,.reset_i(reset_r)
      
                  ,.wh_link_sif_i     (buffered_wh_link_sif_lo[i][j][k][n][r])
                  ,.wh_dma_id_i       (dma_id_li)
                  ,.wh_link_sif_o     (buffered_wh_link_sif_li[i][j][k][n][r])

                  ,.dma_pkt_o         (dma_pkt_lo[i][j][k][n][r])
                  ,.dma_pkt_v_o       (dma_pkt_v_lo[i][j][k][n][r])
                  ,.dma_pkt_yumi_i    (dma_pkt_yumi_li[i][j][k][n][r])

                  ,.dma_data_i        (dma_data_li[i][j][k][n][r])
                  ,.dma_data_v_i      (dma_data_v_li[i][j][k][n][r])
                  ,.dma_data_ready_and_o (dma_data_ready_lo[i][j][k][n][r])

                  ,.dma_data_o        (dma_data_lo[i][j][k][n][r])
                  ,.dma_data_v_o      (dma_data_v_lo[i][j][k][n][r])
                  ,.dma_data_yumi_i   (dma_data_yumi_li[i][j][k][n][r])
                );
              end
            end
          end
        end
      end

     logic [C_M00_AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;
     bsg_cache_to_axi
      #(.addr_width_p(vcache_addr_width_p)
        ,.mask_width_p(vcache_block_size_in_words_p)
        ,.data_width_p(vcache_dma_data_width_p)
        ,.block_size_in_words_p(vcache_block_size_in_words_p)
        ,.num_cache_p(num_dma_p)
        ,.axi_data_width_p(vcache_dma_data_width_p)
        ,.axi_id_width_p(6)
        ,.axi_burst_len_p(vcache_block_size_in_words_p)
        ,.axi_burst_type_p(e_axi_burst_incr)
        )
      cache2axi
       (.clk_i(aclk)
        ,.reset_i(reset_r)

        ,.dma_pkt_i(dma_pkt_lo)
        ,.dma_pkt_v_i(dma_pkt_v_lo)
        ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

        ,.dma_data_o(dma_data_li)
        ,.dma_data_v_o(dma_data_v_li)
        ,.dma_data_ready_i(dma_data_ready_lo)

        ,.dma_data_i(dma_data_lo)
        ,.dma_data_v_i(dma_data_v_lo)
        ,.dma_data_yumi_o(dma_data_yumi_li)

        ,.axi_awid_o(m00_axi_awid)
        ,.axi_awaddr_addr_o(axi_awaddr)
        ,.axi_awlen_o(m00_axi_awlen)
        ,.axi_awsize_o(m00_axi_awsize)
        ,.axi_awburst_o(m00_axi_awburst)
        ,.axi_awcache_o(m00_axi_awcache)
        ,.axi_awprot_o(m00_axi_awprot)
        ,.axi_awlock_o(m00_axi_awlock)
        ,.axi_awvalid_o(m00_axi_awvalid)
        ,.axi_awready_i(m00_axi_awready)

        ,.axi_wdata_o(m00_axi_wdata)
        ,.axi_wstrb_o(m00_axi_wstrb)
        ,.axi_wlast_o(m00_axi_wlast)
        ,.axi_wvalid_o(m00_axi_wvalid)
        ,.axi_wready_i(m00_axi_wready)

        ,.axi_bid_i(m00_axi_bid)
        ,.axi_bresp_i(m00_axi_bresp)
        ,.axi_bvalid_i(m00_axi_bvalid)
        ,.axi_bready_o(m00_axi_bready)

        ,.axi_arid_o(m00_axi_arid)
        ,.axi_araddr_addr_o(axi_araddr)
        ,.axi_arlen_o(m00_axi_arlen)
        ,.axi_arsize_o(m00_axi_arsize)
        ,.axi_arburst_o(m00_axi_arburst)
        ,.axi_arcache_o(m00_axi_arcache)
        ,.axi_arprot_o(m00_axi_arprot)
        ,.axi_arlock_o(m00_axi_arlock)
        ,.axi_arvalid_o(m00_axi_arvalid)
        ,.axi_arready_i(m00_axi_arready)

        ,.axi_rid_i(m00_axi_rid)
        ,.axi_rdata_i(m00_axi_rdata)
        ,.axi_rresp_i(m00_axi_rresp)
        ,.axi_rlast_i(m00_axi_rlast)
        ,.axi_rvalid_i(m00_axi_rvalid)
        ,.axi_rready_o(m00_axi_rready)

        // Unused
        ,.axi_awaddr_cache_id_o()
        ,.axi_araddr_cache_id_o()
        );

  // IO P tie off all but first (host)
  for (genvar i = 1; i < num_pods_x_p*num_tiles_x_p; i++) begin
    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) io_p_tieoff (
      .clk_i(aclk)
      ,.reset_i(reset_r)
      ,.link_sif_i(io_link_sif_lo[i][P])
      ,.link_sif_o(io_link_sif_li[i][P])
    );
  end

  // IO west end tieoff
  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) io_w_tieoff (
    .clk_i(aclk)
    ,.reset_i(reset_r)
    ,.link_sif_i(io_link_sif_lo[0][W])
    ,.link_sif_o(io_link_sif_li[0][W])
  );

  // IO east end tieoff
  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) io_e_tieoff (
    .clk_i(aclk)
    ,.reset_i(reset_r)
    ,.link_sif_i(io_link_sif_lo[(num_pods_x_p*num_tiles_x_p)-1][E])
    ,.link_sif_o(io_link_sif_li[(num_pods_x_p*num_tiles_x_p)-1][E])
  );

  // SOUTH VER LINK TIE OFFS
  for (genvar i = 0; i < num_pods_x_p*num_tiles_x_p; i++) begin
    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) ver_s_tieoff (
      .clk_i(aclk)
      ,.reset_i(reset_r)
      ,.link_sif_i(ver_link_sif_lo[S][i])
      ,.link_sif_o(ver_link_sif_li[S][i])
    );
  end


  // HOR TIEOFF (local link) all except BP
  for (genvar i = W; i <= E; i++) begin
    for (genvar j = 0; j < num_pods_y_p; j++) begin
      for (genvar k = 0; k < num_tiles_y_p; k++) begin
        if (i == E || j != 0 || k > 3) begin
          bsg_manycore_link_sif_tieoff #(
            .addr_width_p(addr_width_p)
            ,.data_width_p(data_width_p)
            ,.x_cord_width_p(x_cord_width_p)
            ,.y_cord_width_p(y_cord_width_p)
          ) hor_tieoff (
            .clk_i(aclk)
            ,.reset_i(reset_r)
            ,.link_sif_i(hor_link_sif_lo[i][j][k])
            ,.link_sif_o(hor_link_sif_li[i][j][k])
          );
        end
      end
    end
  end

  wire [x_cord_width_p-1:0] bp_global_x_li = num_tiles_x_p;
  wire [y_cord_width_p-1:0] bp_global_y_li = 0;
  bsg_manycore_tile_blackparrot
   #(.bp_params_p(bp_params_p)
     ,.x_cord_width_p(x_cord_width_p)
     ,.y_cord_width_p(y_cord_width_p)
     ,.pod_x_cord_width_p(pod_x_cord_width_p)
     ,.pod_y_cord_width_p(pod_y_cord_width_p)
     ,.data_width_p(data_width_p)
     ,.addr_width_p(addr_width_p)
     ,.icache_block_size_in_words_p(icache_block_size_in_words_p)
     ,.num_vcache_rows_p(num_vcache_rows_p)
     ,.vcache_block_size_in_words_p(vcache_block_size_in_words_p)
     ,.vcache_size_p(vcache_size_p)
     ,.vcache_sets_p(vcache_sets_p)
     ,.num_tiles_x_p(num_tiles_x_p)
     ,.num_tiles_y_p(num_tiles_y_p)
     ,.scratchpad_els_p(scratchpad_els_p)
     )
   blackparrot
    (.clk_i(aclk)
     ,.rt_clk_i(aclk) // TODO: Replace with rt_clk
     ,.reset_i(reset_r)

     ,.global_x_i(bp_global_x_li)
     ,.global_y_i(bp_global_y_li)

     ,.link_sif_i(hor_link_sif_lo[W][0][0+:4])
     ,.link_sif_o(hor_link_sif_li[W][0][0+:4])
     );

  assign m00_axi_awaddr = axi_awaddr + dram_base_li;
  assign m00_axi_araddr = axi_araddr + dram_base_li;

  // synopsys translate_off

  always @(negedge aclk)
    if (m00_axi_awvalid & m00_axi_awready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

  always @(negedge aclk)
    if (m00_axi_arvalid & m00_axi_arready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);

  // synopsys translate_on

endmodule

