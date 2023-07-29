
`timescale 1 ps / 1 ps

`include "bsg_manycore_defines.vh"
`include "bsg_cache.vh"

module top_zynq
import zynq_pkg::*;
import bsg_manycore_pkg::*;
import bsg_bladerunner_pkg::*;
import bsg_axi_pkg::*;
import bsg_cache_pkg::*;
import bsg_noc_pkg::*;
import bsg_tag_pkg::*;
#(
  // NOTE these parameters are usually overridden by the parent module (top.v)
  // but we set them to make expectations consistent

  // Parameters of Axi Slave Bus Interface S00_AXI
  // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
    parameter integer C_S00_AXI_DATA_WIDTH   = 32
  , parameter integer C_S00_AXI_ADDR_WIDTH   = 10
  , parameter integer C_M00_AXI_DATA_WIDTH   = 64
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
  localparam memory_upper_limit_lp = 128*1024*1024;

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
  logic [`BSG_WIDTH(max_credits_gp)-1:0] credits_used_lo;
  logic [`BSG_SAFE_CLOG2(bsg_machine_rom_els_gp)-1:0] rom_addr_lo;
  logic [bsg_machine_rom_width_gp-1:0] rom_data_li;

  assign sys_resetn   = csr_data_lo[0][0]; // active-low
  assign bb_data_li   = csr_data_lo[1][0]; assign bb_v_li = csr_data_new_lo[1];
  assign dram_init_li = csr_data_lo[2];
  assign dram_base_li = csr_data_lo[3];
  assign rom_addr_lo  = csr_data_lo[4];

  assign csr_data_li[0] = credits_used_lo;
  assign csr_data_li[1] = rom_data_li;

  bsg_bladerunner_configuration
   #(.width_p(bsg_machine_rom_width_gp), .addr_width_p(`BSG_SAFE_CLOG2(bsg_machine_rom_els_gp)))
   configuration_rom
    (.addr_i(rom_addr_lo), .data_o(rom_data_li));

  // instantiate manycore
  localparam bsg_machine_llcache_data_width_lp = bsg_machine_noc_data_width_gp;
  localparam bsg_machine_llcache_addr_width_lp = (bsg_machine_noc_epa_width_gp-1+`BSG_SAFE_CLOG2(bsg_machine_noc_data_width_gp>>3));

  localparam bsg_machine_wh_flit_width_lp = bsg_machine_llcache_channel_width_gp;
  localparam bsg_machine_wh_cid_width_lp  = `BSG_SAFE_CLOG2(bsg_machine_wh_ruche_factor_gp*2);
  localparam bsg_machine_wh_len_width_lp  = `BSG_SAFE_CLOG2(1 + ((bsg_machine_llcache_line_words_gp * bsg_machine_llcache_data_width_lp) / bsg_machine_llcache_channel_width_gp));
  localparam bsg_machine_wh_cord_width_lp = bsg_machine_noc_coord_x_width_gp;
  localparam lg_wh_ruche_factor_lp = `BSG_SAFE_CLOG2(bsg_machine_wh_ruche_factor_gp);

  localparam num_vcaches_per_link_lp = (2*bsg_machine_pods_x_gp*bsg_machine_pod_tiles_x_gp)/bsg_machine_wh_ruche_factor_gp/2;
  localparam num_dma_lp              = 2*bsg_machine_pods_y_gp*2*bsg_machine_pod_llcache_rows_gp*bsg_machine_wh_ruche_factor_gp*num_vcaches_per_link_lp;
  localparam lg_num_dma_lp = `BSG_SAFE_CLOG2(num_dma_lp);
  localparam lg_num_vcaches_per_link_lp = `BSG_SAFE_CLOG2(num_vcaches_per_link_lp);

  `declare_bsg_manycore_link_sif_s(bsg_machine_noc_epa_width_gp,bsg_machine_noc_data_width_gp,bsg_machine_noc_coord_x_width_gp,bsg_machine_noc_coord_y_width_gp);
  `declare_bsg_manycore_ruche_x_link_sif_s(bsg_machine_noc_epa_width_gp,bsg_machine_noc_data_width_gp,bsg_machine_noc_coord_x_width_gp,bsg_machine_noc_coord_y_width_gp);
  `declare_bsg_ready_and_link_sif_s(bsg_machine_wh_flit_width_lp, wh_link_sif_s);
  bsg_manycore_link_sif_s [S:N][bsg_machine_pod_tiles_x_gp-1:0] ver_link_sif_li, ver_link_sif_lo;
  wh_link_sif_s [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0] wh_link_sif_li, wh_link_sif_lo;
  bsg_manycore_link_sif_s [E:W][bsg_machine_pod_tiles_y_gp-1:0] hor_link_sif_li, hor_link_sif_lo;

  // BSG TAG MASTER
  logic tag_done_lo;
  bsg_tag_s pod_tags_lo;
 
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
  bsg_dff_chain
   #(.width_p(1), .num_stages_p(reset_depth_gp))
   reset_dff
    (.clk_i(aclk)
     ,.data_i(reset_n)
     ,.data_o(reset_r)
     );

  bsg_manycore_pod_mesh_array
   #(.num_tiles_x_p(bsg_machine_pod_tiles_x_gp)
     ,.num_tiles_y_p(bsg_machine_pod_tiles_y_gp)
     ,.pod_x_cord_width_p(bsg_machine_noc_pod_coord_x_width_gp)
     ,.pod_y_cord_width_p(bsg_machine_noc_pod_coord_y_width_gp)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     ,.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)
     ,.barrier_ruche_factor_X_p(bsg_machine_barrier_ruche_factor_X_gp)
     ,.num_subarray_x_p(bsg_machine_pod_tiles_subarray_x_gp)
     ,.num_subarray_y_p(bsg_machine_pod_tiles_subarray_y_gp)

     ,.dmem_size_p(bsg_machine_core_dmem_words_gp)
     ,.icache_entries_p(bsg_machine_core_icache_entries_gp)
     ,.icache_tag_width_p(bsg_machine_core_icache_tag_width_gp)
     ,.icache_block_size_in_words_p(bsg_machine_core_icache_line_words_gp)

     ,.num_vcache_rows_p(bsg_machine_pod_llcache_rows_gp)
     ,.vcache_addr_width_p(bsg_machine_llcache_addr_width_lp)
     ,.vcache_data_width_p(bsg_machine_llcache_data_width_lp)
     ,.vcache_ways_p(bsg_machine_llcache_ways_gp)
     ,.vcache_sets_p(bsg_machine_llcache_sets_gp)
     ,.vcache_block_size_in_words_p(bsg_machine_llcache_line_words_gp)
     ,.vcache_size_p(bsg_machine_llcache_words_gp)
     ,.vcache_dma_data_width_p(bsg_machine_llcache_channel_width_gp)
     ,.vcache_word_tracking_p(bsg_machine_llcache_word_tracking_gp)

     ,.wh_ruche_factor_p(bsg_machine_wh_ruche_factor_gp)
     ,.wh_cid_width_p(bsg_machine_wh_cid_width_lp)
     ,.wh_flit_width_p(bsg_machine_wh_flit_width_lp)
     ,.wh_cord_width_p(bsg_machine_wh_cord_width_lp)
     ,.wh_len_width_p(bsg_machine_wh_len_width_lp)

     ,.num_pods_y_p(bsg_machine_pods_y_gp)
     ,.num_pods_x_p(bsg_machine_pods_x_gp)

     ,.reset_depth_p(reset_depth_gp)
     )
   DUT
    (.clk_i(aclk)

     ,.ver_link_sif_i(ver_link_sif_li)
     ,.ver_link_sif_o(ver_link_sif_lo)

     ,.wh_link_sif_i(wh_link_sif_li)
     ,.wh_link_sif_o(wh_link_sif_lo)

     ,.hor_link_sif_i(hor_link_sif_li)
     ,.hor_link_sif_o(hor_link_sif_lo)

     ,.pod_tags_i(tag_lines_lo) 
     );

  // IO ROUTER
  bsg_manycore_link_sif_s [bsg_machine_pod_tiles_x_gp-1:0][S:P] io_link_sif_li;
  bsg_manycore_link_sif_s [bsg_machine_pod_tiles_x_gp-1:0][S:P] io_link_sif_lo;

  for (genvar x = 0; x < bsg_machine_pod_tiles_x_gp; x++)
    begin : io_rtr_x
      bsg_manycore_mesh_node
       #(.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
         ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
         ,.addr_width_p(bsg_machine_noc_epa_width_gp)
         ,.data_width_p(bsg_machine_noc_data_width_gp)
         ,.stub_p(4'b0100) // stub north
         ,.rev_use_credits_p(rev_use_credits_gp)
         ,.rev_fifo_els_p(rev_fifo_els_gp)
         )
       io_rtr
        (.clk_i(aclk)
         ,.reset_i(reset_r)

         ,.links_sif_i(io_link_sif_li[x][S:W])
         ,.links_sif_o(io_link_sif_lo[x][S:W])

         ,.proc_link_sif_i(io_link_sif_li[x][P])
         ,.proc_link_sif_o(io_link_sif_lo[x][P])

         ,.global_x_i(bsg_machine_noc_coord_x_width_gp'(bsg_machine_pod_tiles_x_gp+x))
         ,.global_y_i(bsg_machine_noc_coord_y_width_gp'(0))
         );

      // connect to pod array
      assign ver_link_sif_li[N][x] = io_link_sif_lo[x][S];
      assign io_link_sif_li[x][S] = ver_link_sif_lo[N][x];

      // connect between io rtr
      if (x < bsg_machine_pod_tiles_x_gp-1)
        begin
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
  wire [bsg_machine_noc_coord_y_width_gp-1:0] global_y_li = 0;
  wire [bsg_machine_noc_coord_x_width_gp-1:0] global_x_li = bsg_machine_pod_tiles_x_gp;
  bsg_manycore_endpoint_to_fifos
   #(.fifo_width_p(4*C_S00_AXI_DATA_WIDTH)
     ,.axil_width_p(C_S00_AXI_DATA_WIDTH)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     ,.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)
     ,.ep_fifo_els_p(ep_fifo_els_gp)
     ,.credit_counter_width_p(`BSG_WIDTH(max_credits_gp))
     ,.rev_fifo_els_p(rev_fifo_els_gp[0])
     ,.icache_block_size_in_words_p(bsg_machine_core_icache_line_words_gp)
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
     ,.global_y_i(global_y_li)
     ,.global_x_i(global_x_li)

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
  `declare_bsg_cache_dma_pkt_s(bsg_machine_llcache_addr_width_lp, bsg_machine_llcache_line_words_gp);

  bsg_cache_dma_pkt_s [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_lo;
  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_v_lo;
  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_yumi_li;

  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0][bsg_machine_llcache_channel_width_gp-1:0] dma_data_li;
  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_li;
  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_ready_lo;

  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0][bsg_machine_llcache_channel_width_gp-1:0] dma_data_lo;
  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_lo;
  logic [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_yumi_li;

  wh_link_sif_s [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0] buffered_wh_link_sif_li;
  wh_link_sif_s [E:W][S:N][bsg_machine_pod_llcache_rows_gp-1:0][bsg_machine_wh_ruche_factor_gp-1:0] buffered_wh_link_sif_lo;

  `declare_bsg_cache_wh_header_flit_s(bsg_machine_wh_flit_width_lp, bsg_machine_wh_cord_width_lp, bsg_machine_wh_len_width_lp, bsg_machine_wh_cid_width_lp);
  for (genvar i = W; i <= E; i++)
    begin : hs
      for (genvar k = N; k <= S; k++)
        begin : py
          for (genvar n = 0; n < bsg_machine_pod_llcache_rows_gp; n++)
            begin : row
              for (genvar r = 0; r < bsg_machine_wh_ruche_factor_gp; r++)
                begin : rf
                  if (r == 0)
                    begin : ninvert
                      assign wh_link_sif_li[i][k][n][r] = buffered_wh_link_sif_li[i][k][n][r];
                      assign buffered_wh_link_sif_lo[i][k][n][r] = wh_link_sif_lo[i][k][n][r];
                    end
                  else
                    begin : invert
                      assign wh_link_sif_li[i][k][n][r] = ~buffered_wh_link_sif_li[i][k][n][r];
                      assign buffered_wh_link_sif_lo[i][k][n][r] = ~wh_link_sif_lo[i][k][n][r];
                    end
                    
                  bsg_cache_wh_header_flit_s header_flit_in;
                  assign header_flit_in = buffered_wh_link_sif_lo[i][k][n][r].data;

                  wire [lg_num_vcaches_per_link_lp-1:0] dma_id_li = (num_vcaches_per_link_lp == 1)
                    ? 1'b0
                    : header_flit_in.src_cord[lg_wh_ruche_factor_lp+:lg_num_vcaches_per_link_lp];


                  bsg_wormhole_to_cache_dma_fanout
                   #(.num_dma_p(num_vcaches_per_link_lp)
                     ,.dma_addr_width_p(bsg_machine_llcache_addr_width_lp)
                     ,.dma_mask_width_p(bsg_machine_llcache_line_words_gp)
                     ,.dma_burst_len_p(bsg_machine_llcache_line_words_gp*bsg_machine_llcache_data_width_lp/bsg_machine_llcache_channel_width_gp)

                     ,.wh_flit_width_p(bsg_machine_wh_flit_width_lp)
                     ,.wh_cid_width_p(bsg_machine_wh_cid_width_lp)
                     ,.wh_len_width_p(bsg_machine_wh_len_width_lp)
                     ,.wh_cord_width_p(bsg_machine_wh_cord_width_lp)
                     )
                   wh_to_dma
                    (.clk_i(aclk)
                     ,.reset_i(reset_r)
  
                     ,.wh_link_sif_i(buffered_wh_link_sif_lo[i][k][n][r])
                     ,.wh_dma_id_i(dma_id_li)
                     ,.wh_link_sif_o(buffered_wh_link_sif_li[i][k][n][r])

                     ,.dma_pkt_o(dma_pkt_lo[i][k][n][r])
                     ,.dma_pkt_v_o(dma_pkt_v_lo[i][k][n][r])
                     ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i][k][n][r])

                     ,.dma_data_i(dma_data_li[i][k][n][r])
                     ,.dma_data_v_i(dma_data_v_li[i][k][n][r])
                     ,.dma_data_ready_and_o(dma_data_ready_lo[i][k][n][r])

                     ,.dma_data_o(dma_data_lo[i][k][n][r])
                     ,.dma_data_v_o(dma_data_v_lo[i][k][n][r])
                     ,.dma_data_yumi_i(dma_data_yumi_li[i][k][n][r])
                     );
                end
            end
        end
    end

  logic [C_M00_AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;
  logic [`BSG_SAFE_CLOG2(num_dma_lp)-1:0] axi_awaddr_cache_id, axi_araddr_cache_id;
  bsg_cache_to_axi
   #(.addr_width_p(bsg_machine_llcache_addr_width_lp)
     ,.mask_width_p(bsg_machine_llcache_line_words_gp)
     ,.data_width_p(bsg_machine_llcache_channel_width_gp)
     ,.block_size_in_words_p(bsg_machine_llcache_line_words_gp)
     ,.num_cache_p(num_dma_lp)
     ,.axi_data_width_p(C_M00_AXI_DATA_WIDTH)
     ,.axi_id_width_p(6)
     ,.axi_burst_len_p(bsg_machine_llcache_channel_width_gp*bsg_machine_llcache_line_words_gp/C_M00_AXI_DATA_WIDTH)
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
     ,.axi_awaddr_cache_id_o(axi_awaddr_cache_id)
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
     ,.axi_araddr_cache_id_o(axi_araddr_cache_id)
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
     );
  localparam dram_addr_width_lp = `BSG_SAFE_CLOG2(memory_upper_limit_lp);
  wire [C_M00_AXI_ADDR_WIDTH-1:0] axi_awaddr_hash = {axi_awaddr_cache_id, axi_awaddr[0+:dram_addr_width_lp-lg_num_dma_lp]};
  wire [C_M00_AXI_ADDR_WIDTH-1:0] axi_araddr_hash = {axi_araddr_cache_id, axi_araddr[0+:dram_addr_width_lp-lg_num_dma_lp]};

  // IO P tie off
  for (genvar i = 1; i < bsg_machine_pod_tiles_x_gp; i++)
    begin : io_p
     bsg_manycore_link_sif_tieoff
      #(.addr_width_p(bsg_machine_noc_epa_width_gp)
        ,.data_width_p(bsg_machine_noc_data_width_gp)
        ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
        ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
        )
      tieoff
       (.clk_i(aclk)
        ,.reset_i(reset_r)
        ,.link_sif_i(io_link_sif_lo[i][P])
        ,.link_sif_o(io_link_sif_li[i][P])
        );
    end

  // IO west end tieoff
  bsg_manycore_link_sif_tieoff
   #(.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     )
   io_w_tieoff
    (.clk_i(aclk)
     ,.reset_i(reset_r)
     ,.link_sif_i(io_link_sif_lo[0][W])
     ,.link_sif_o(io_link_sif_li[0][W])
     );

  // IO east end tieoff
  bsg_manycore_link_sif_tieoff
   #(.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     )
   io_e_tieoff
    (.clk_i(aclk)
     ,.reset_i(reset_r)
     ,.link_sif_i(io_link_sif_lo[bsg_machine_pod_tiles_x_gp-1][E])
     ,.link_sif_o(io_link_sif_li[bsg_machine_pod_tiles_x_gp-1][E])
     );

  // SOUTH VER LINK TIE OFFS
  for (genvar i = 0; i < bsg_machine_pod_tiles_x_gp; i++)
    begin : mc_s
      bsg_manycore_link_sif_tieoff
       #(.addr_width_p(bsg_machine_noc_epa_width_gp)
         ,.data_width_p(bsg_machine_noc_data_width_gp)
         ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
         ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
         )
       ver_s_tieoff
        (.clk_i(aclk)
         ,.reset_i(reset_r)
         ,.link_sif_i(ver_link_sif_lo[S][i])
         ,.link_sif_o(ver_link_sif_li[S][i])
         );
    end

  // HOR TIEOFF (local link)
  for (genvar i = W; i <= E; i++)
    begin : mc
      for (genvar k = 0; k < bsg_machine_pod_tiles_y_gp; k++)
        begin : e_w
          bsg_manycore_link_sif_tieoff
           #(.addr_width_p(bsg_machine_noc_epa_width_gp)
             ,.data_width_p(bsg_machine_noc_data_width_gp)
             ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
             ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
             )
           hor_tieoff
            (.clk_i(aclk)
             ,.reset_i(reset_r)
             ,.link_sif_i(hor_link_sif_lo[i][k])
             ,.link_sif_o(hor_link_sif_li[i][k])
             );
        end
    end

  assign m00_axi_awaddr = axi_awaddr_hash + dram_base_li;
  assign m00_axi_araddr = axi_araddr_hash + dram_base_li;

  // synopsys translate_off

  always @(negedge aclk)
    if (m00_axi_awvalid & m00_axi_awready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

  always @(negedge aclk)
    if (m00_axi_arvalid & m00_axi_arready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Read Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);

  // synopsys translate_on

endmodule

