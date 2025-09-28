
`include "bsg_manycore_defines.svh"
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
 import bsg_manycore_network_cfg_pkg::*;
 import bsg_bladerunner_pkg::*;
 import bsg_blackparrot_pkg::*;
 #(parameter bp_params_e bp_params_p = bp_cfg_gp
   `declare_bp_proc_params(bp_params_p)
   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_GP0_AXI_DATA_WIDTH = 32
   , parameter integer C_GP0_AXI_ADDR_WIDTH = 10
   , parameter integer C_GP1_AXI_DATA_WIDTH = 32
   , parameter integer C_GP1_AXI_ADDR_WIDTH = 30
   , parameter integer C_HP0_AXI_DATA_WIDTH = 32
   , parameter integer C_HP0_AXI_ADDR_WIDTH = 32
   , parameter integer C_HP1_AXI_DATA_WIDTH = 32
   , parameter integer C_HP1_AXI_ADDR_WIDTH = 32
   )
  (  input wire                                  aclk
   , input wire                                  aresetn
   , input wire                                  rt_clk
   
   // Ports of Axi Slave Bus Interface S00_AXI
   , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_awaddr
   , input wire [2 : 0]                          gp0_axi_awprot
   , input wire                                  gp0_axi_awvalid
   , output wire                                 gp0_axi_awready
   , input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     gp0_axi_wdata
   , input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp0_axi_wstrb
   , input wire                                  gp0_axi_wvalid
   , output wire                                 gp0_axi_wready
   , output wire [1 : 0]                         gp0_axi_bresp
   , output wire                                 gp0_axi_bvalid
   , input wire                                  gp0_axi_bready
   , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_araddr
   , input wire [2 : 0]                          gp0_axi_arprot
   , input wire                                  gp0_axi_arvalid
   , output wire                                 gp0_axi_arready
   , output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    gp0_axi_rdata
   , output wire [1 : 0]                         gp0_axi_rresp
   , output wire                                 gp0_axi_rvalid
   , input wire                                  gp0_axi_rready

   , input wire [C_GP1_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_awaddr
   , input wire [2 : 0]                          gp1_axi_awprot
   , input wire                                  gp1_axi_awvalid
   , output wire                                 gp1_axi_awready
   , input wire [C_GP1_AXI_DATA_WIDTH-1 : 0]     gp1_axi_wdata
   , input wire [(C_GP1_AXI_DATA_WIDTH/8)-1 : 0] gp1_axi_wstrb
   , input wire                                  gp1_axi_wvalid
   , output wire                                 gp1_axi_wready
   , output wire [1 : 0]                         gp1_axi_bresp
   , output wire                                 gp1_axi_bvalid
   , input wire                                  gp1_axi_bready
   , input wire [C_GP1_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_araddr
   , input wire [2 : 0]                          gp1_axi_arprot
   , input wire                                  gp1_axi_arvalid
   , output wire                                 gp1_axi_arready
   , output wire [C_GP1_AXI_DATA_WIDTH-1 : 0]    gp1_axi_rdata
   , output wire [1 : 0]                         gp1_axi_rresp
   , output wire                                 gp1_axi_rvalid
   , input wire                                  gp1_axi_rready

   , output wire [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_awaddr
   , output wire                                 hp0_axi_awvalid
   , input wire                                  hp0_axi_awready
   , output wire [5:0]                           hp0_axi_awid
   , output wire                                 hp0_axi_awlock
   , output wire [3:0]                           hp0_axi_awcache
   , output wire [2:0]                           hp0_axi_awprot
   , output wire [7:0]                           hp0_axi_awlen
   , output wire [2:0]                           hp0_axi_awsize
   , output wire [1:0]                           hp0_axi_awburst
   , output wire [3:0]                           hp0_axi_awqos

   , output wire [C_HP0_AXI_DATA_WIDTH-1:0]      hp0_axi_wdata
   , output wire                                 hp0_axi_wvalid
   , input wire                                  hp0_axi_wready
   , output wire [5:0]                           hp0_axi_wid
   , output wire                                 hp0_axi_wlast
   , output wire [(C_HP0_AXI_DATA_WIDTH/8)-1:0]  hp0_axi_wstrb

   , input wire                                  hp0_axi_bvalid
   , output wire                                 hp0_axi_bready
   , input wire [5:0]                            hp0_axi_bid
   , input wire [1:0]                            hp0_axi_bresp

   , output wire [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_araddr
   , output wire                                 hp0_axi_arvalid
   , input wire                                  hp0_axi_arready
   , output wire [5:0]                           hp0_axi_arid
   , output wire                                 hp0_axi_arlock
   , output wire [3:0]                           hp0_axi_arcache
   , output wire [2:0]                           hp0_axi_arprot
   , output wire [7:0]                           hp0_axi_arlen
   , output wire [2:0]                           hp0_axi_arsize
   , output wire [1:0]                           hp0_axi_arburst
   , output wire [3:0]                           hp0_axi_arqos

   , input wire [C_HP0_AXI_DATA_WIDTH-1:0]       hp0_axi_rdata
   , input wire                                  hp0_axi_rvalid
   , output wire                                 hp0_axi_rready
   , input wire [5:0]                            hp0_axi_rid
   , input wire                                  hp0_axi_rlast
   , input wire [1:0]                            hp0_axi_rresp

   , output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]    hp1_axi_awaddr
   , output wire [2 : 0]                         hp1_axi_awprot
   , output wire                                 hp1_axi_awvalid
   , input wire                                  hp1_axi_awready
   , output wire [C_HP1_AXI_DATA_WIDTH-1 : 0]    hp1_axi_wdata
   , output wire [(C_HP1_AXI_DATA_WIDTH/8)-1:0]  hp1_axi_wstrb
   , output wire                                 hp1_axi_wvalid
   , input wire                                  hp1_axi_wready
   , input wire [1 : 0]                          hp1_axi_bresp
   , input wire                                  hp1_axi_bvalid
   , output wire                                 hp1_axi_bready
   , output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]    hp1_axi_araddr
   , output wire [2 : 0]                         hp1_axi_arprot
   , output wire                                 hp1_axi_arvalid
   , input wire                                  hp1_axi_arready
   , input wire [C_HP1_AXI_DATA_WIDTH-1 : 0]     hp1_axi_rdata
   , input wire [1 : 0]                          hp1_axi_rresp
   , input wire                                  hp1_axi_rvalid
   , output wire                                 hp1_axi_rready
   );

  localparam num_regs_ps_to_pl_lp = 7;
  localparam num_regs_pl_to_ps_lp = 2;
  localparam num_fifos_ps_to_pl_lp = 2;
  localparam num_fifos_pl_to_ps_lp = 2;

  logic [num_regs_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0]       csr_data_li;
  logic [num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0]       csr_data_lo;
  logic [num_regs_ps_to_pl_lp-1:0]                                 csr_data_new_lo;
  logic [num_fifos_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0]      pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
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
     ,.C_S_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH)
     ,.C_S_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
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
       ,.S_AXI_AWADDR (gp0_axi_awaddr)
       ,.S_AXI_AWPROT (gp0_axi_awprot)
       ,.S_AXI_AWVALID(gp0_axi_awvalid)
       ,.S_AXI_AWREADY(gp0_axi_awready)
       ,.S_AXI_WDATA  (gp0_axi_wdata)
       ,.S_AXI_WSTRB  (gp0_axi_wstrb)
       ,.S_AXI_WVALID (gp0_axi_wvalid)
       ,.S_AXI_WREADY (gp0_axi_wready)
       ,.S_AXI_BRESP  (gp0_axi_bresp)
       ,.S_AXI_BVALID (gp0_axi_bvalid)
       ,.S_AXI_BREADY (gp0_axi_bready)
       ,.S_AXI_ARADDR (gp0_axi_araddr)
       ,.S_AXI_ARPROT (gp0_axi_arprot)
       ,.S_AXI_ARVALID(gp0_axi_arvalid)
       ,.S_AXI_ARREADY(gp0_axi_arready)
       ,.S_AXI_RDATA  (gp0_axi_rdata)
       ,.S_AXI_RRESP  (gp0_axi_rresp)
       ,.S_AXI_RVALID (gp0_axi_rvalid)
       ,.S_AXI_RREADY (gp0_axi_rready)
       );

  ///////////////////////////////////////////////////////////////////////////////////////
  // TODO: User code goes here
  ///////////////////////////////////////////////////////////////////////////////////////

  logic sys_resetn;
  logic bb_data_li, bb_v_li;
  logic dram_init_li;
  logic [C_HP0_AXI_ADDR_WIDTH-1:0] dram_base_li;
  logic [`BSG_WIDTH(max_credits_gp)-1:0] credits_used_lo;
  logic [`BSG_SAFE_CLOG2(bsg_machine_rom_els_gp)-1:0] rom_addr_lo;
  logic [bsg_machine_rom_width_gp-1:0] rom_data_li;
  logic [bsg_machine_noc_coord_x_width_gp-1:0] gp1_dst_x_lo;
  logic [bsg_machine_noc_coord_y_width_gp-1:0] gp1_dst_y_lo;

  assign sys_resetn   = csr_data_lo[0][0]; // active-low
  assign bb_data_li   = csr_data_lo[1][0]; assign bb_v_li = csr_data_new_lo[1];
  assign dram_init_li = csr_data_lo[2];
  assign dram_base_li = csr_data_lo[3];
  assign rom_addr_lo  = csr_data_lo[4];
  assign gp1_dst_x_lo = csr_data_lo[5];
  assign gp1_dst_y_lo = csr_data_lo[6];

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
  localparam bsg_machine_wh_cid_width_lp = `BSG_SAFE_CLOG2(bsg_machine_wh_ruche_factor_gp*2);
  localparam bsg_machine_wh_len_width_lp = `BSG_SAFE_CLOG2(1 + ((bsg_machine_llcache_line_words_gp * bsg_machine_llcache_data_width_lp) / bsg_machine_llcache_channel_width_gp));
  localparam bsg_machine_wh_cord_width_lp = bsg_machine_noc_coord_x_width_gp;
  localparam lg_wh_ruche_factor_lp = `BSG_SAFE_CLOG2(bsg_machine_wh_ruche_factor_gp);
  
  localparam num_vcaches_per_link_lp = (2*bsg_machine_pods_x_gp*bsg_machine_pod_tiles_x_gp)/bsg_machine_wh_ruche_factor_gp/2;
  localparam num_dma_lp = 2*bsg_machine_pods_y_gp*2*bsg_machine_wh_ruche_factor_gp*num_vcaches_per_link_lp;
  localparam lg_num_vcaches_per_link_lp = `BSG_SAFE_CLOG2(num_vcaches_per_link_lp);
  localparam lg_num_dma_lp = `BSG_SAFE_CLOG2(num_dma_lp);

  `declare_bsg_manycore_link_sif_s(bsg_machine_noc_epa_width_gp,bsg_machine_noc_data_width_gp,bsg_machine_noc_coord_x_width_gp,bsg_machine_noc_coord_y_width_gp);
  `declare_bsg_manycore_ruche_x_link_sif_s(bsg_machine_noc_epa_width_gp,bsg_machine_noc_data_width_gp,bsg_machine_noc_coord_x_width_gp,bsg_machine_noc_coord_y_width_gp);
  `declare_bsg_ready_and_link_sif_s(bsg_machine_wh_flit_width_lp, wh_link_sif_s);
  bsg_manycore_link_sif_s io_link_sif_li, io_link_sif_lo;
  wh_link_sif_s [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0] wh_link_sif_li, wh_link_sif_lo;
; 

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
   #(.width_p(1)
     ,.num_stages_p(reset_depth_gp)
     )
   reset_dff
    (.clk_i(aclk)
     ,.data_i(reset_n)
     ,.data_o(reset_r)
     );

  bsg_hammerblade
   #(.bp_params_p(bp_params_p)
     ,.scratchpad_els_p(scratchpad_els_gp)

     ,.num_tiles_x_p(bsg_machine_pod_tiles_x_gp)
     ,.num_tiles_y_p(bsg_machine_pod_tiles_y_gp)
     ,.pod_x_cord_width_p(bsg_machine_noc_pod_coord_x_width_gp)
     ,.pod_y_cord_width_p(bsg_machine_noc_pod_coord_y_width_gp)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     ,.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)

     ,.bsg_manycore_network_cfg_p(bsg_machine_noc_cfg_gp)
     ,.ruche_factor_X_p(bsg_machine_noc_ruche_factor_X_gp)
     ,.barrier_ruche_factor_X_p(bsg_machine_barrier_ruche_factor_X_gp)
     ,.num_subarray_x_p(bsg_machine_pod_tiles_subarray_x_gp)
     ,.num_subarray_y_p(bsg_machine_pod_tiles_subarray_y_gp)

     ,.dmem_size_p(bsg_machine_core_dmem_words_gp)
     ,.mc_icache_entries_p(bsg_machine_core_icache_entries_gp)
     ,.mc_icache_tag_width_p(bsg_machine_core_icache_tag_width_gp)
     ,.mc_icache_block_size_in_words_p(bsg_machine_core_icache_line_words_gp)

     ,.vcache_addr_width_p(bsg_machine_llcache_addr_width_lp)
     ,.vcache_data_width_p(bsg_machine_llcache_data_width_lp)
     ,.vcache_ways_p(bsg_machine_llcache_ways_gp)
     ,.vcache_sets_p(bsg_machine_llcache_sets_gp)
     ,.vcache_block_size_in_words_p(bsg_machine_llcache_line_words_gp)
     ,.vcache_size_p(bsg_machine_llcache_words_gp)
     ,.vcache_dma_data_width_p(bsg_machine_llcache_channel_width_gp)
     ,.vcache_word_tracking_p(bsg_machine_llcache_word_tracking_gp)
     ,.ipoly_hashing_p(0)

     ,.wh_ruche_factor_p(bsg_machine_wh_ruche_factor_gp)
     ,.wh_cid_width_p(bsg_machine_wh_cid_width_lp)
     ,.wh_flit_width_p(bsg_machine_wh_flit_width_lp)
     ,.wh_cord_width_p(bsg_machine_wh_cord_width_lp)
     ,.wh_len_width_p(bsg_machine_wh_len_width_lp)

     ,.num_pods_y_p(bsg_machine_pods_y_gp)
     ,.num_pods_x_p(bsg_machine_pods_x_gp)

     ,.reset_depth_p(reset_depth_gp)

     ,.rev_use_credits_p(rev_use_credits_gp)
     )
   hammerblade
    (.clk_i(aclk)
     ,.reset_i(reset_r)
     ,.rt_clk_i(rt_clk)

     ,.io_link_sif_i(io_link_sif_li)
     ,.io_link_sif_o(io_link_sif_lo)

     ,.wh_link_sif_i(wh_link_sif_li)
     ,.wh_link_sif_o(wh_link_sif_lo)

     ,.pod_tags_i(tag_lines_lo) 
     );

  bsg_manycore_link_sif_s host_link_sif_li, host_link_sif_lo;
  bsg_manycore_link_sif_s axil_link_sif_li, axil_link_sif_lo;
  bsg_manycore_switch_1x2
   #(.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     // MC host address space is below this
     ,.split_addr_p(32'h200000)
     )
   mc_switch
    (.clk_i(aclk)
     ,.reset_i(reset_r)

     ,.multi_fwd_link_sif_i(io_link_sif_lo.fwd)
     ,.multi_fwd_link_sif_o(io_link_sif_li.fwd)
     ,.multi_rev_link_sif_o(io_link_sif_li.rev)
     ,.multi_rev_link_sif_i(io_link_sif_lo.rev)

     ,.fwd_link_sif_o({axil_link_sif_li.fwd, host_link_sif_li.fwd})
     ,.fwd_link_sif_i({axil_link_sif_lo.fwd, host_link_sif_lo.fwd})
     ,.rev_link_sif_i({axil_link_sif_lo.rev, host_link_sif_lo.rev})
     ,.rev_link_sif_o({axil_link_sif_li.rev, host_link_sif_li.rev})
     );

  // Hardcoded to the normal coordinate
  wire [bsg_machine_noc_coord_x_width_gp-1:0] io_global_x_li = bsg_machine_pod_tiles_x_gp;
  wire [bsg_machine_noc_coord_y_width_gp-1:0] io_global_y_li = 0;
  bsg_manycore_axil_bridge
   #(.addr_width_p(bsg_machine_noc_epa_width_gp)
     ,.data_width_p(bsg_machine_noc_data_width_gp)
     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
     ,.icache_block_size_in_words_p(bsg_machine_core_icache_line_words_gp)
     ,.s_axil_addr_width_p(C_GP1_AXI_ADDR_WIDTH)
     ,.s_axil_data_width_p(C_GP1_AXI_DATA_WIDTH)
     ,.m_axil_addr_width_p(C_HP1_AXI_ADDR_WIDTH)
     ,.m_axil_data_width_p(C_HP1_AXI_DATA_WIDTH)
     )
   mc_bridge
    (.clk_i(aclk)
     ,.reset_i(reset_r)

     ,.link_sif_i(axil_link_sif_li)
     ,.link_sif_o(axil_link_sif_lo)

     ,.my_x_i(io_global_x_li)
     ,.my_y_i(io_global_y_li)

     ,.dest_x_i(gp1_dst_x_lo)
     ,.dest_y_i(gp1_dst_y_lo)

     ,.s_axil_awaddr_i(gp1_axi_awaddr)
     ,.s_axil_awprot_i(gp1_axi_awprot)
     ,.s_axil_awvalid_i(gp1_axi_awvalid)
     ,.s_axil_awready_o(gp1_axi_awready)
     ,.s_axil_wdata_i(gp1_axi_wdata)
     ,.s_axil_wstrb_i(gp1_axi_wstrb)
     ,.s_axil_wvalid_i(gp1_axi_wvalid)
     ,.s_axil_wready_o(gp1_axi_wready)
     ,.s_axil_bresp_o(gp1_axi_bresp)
     ,.s_axil_bvalid_o(gp1_axi_bvalid)
     ,.s_axil_bready_i(gp1_axi_bready)
     ,.s_axil_araddr_i(gp1_axi_araddr)
     ,.s_axil_arprot_i(gp1_axi_arprot)
     ,.s_axil_arvalid_i(gp1_axi_arvalid)
     ,.s_axil_arready_o(gp1_axi_arready)
     ,.s_axil_rdata_o(gp1_axi_rdata)
     ,.s_axil_rresp_o(gp1_axi_rresp)
     ,.s_axil_rvalid_o(gp1_axi_rvalid)
     ,.s_axil_rready_i(gp1_axi_rready)

     ,.m_axil_awaddr_o(hp1_axi_awaddr)
     ,.m_axil_awprot_o(hp1_axi_awprot)
     ,.m_axil_awvalid_o(hp1_axi_awvalid)
     ,.m_axil_awready_i(hp1_axi_awready)
     ,.m_axil_wdata_o(hp1_axi_wdata)
     ,.m_axil_wstrb_o(hp1_axi_wstrb)
     ,.m_axil_wvalid_o(hp1_axi_wvalid)
     ,.m_axil_wready_i(hp1_axi_wready)
     ,.m_axil_bresp_i(hp1_axi_bresp)
     ,.m_axil_bvalid_i(hp1_axi_bvalid)
     ,.m_axil_bready_o(hp1_axi_bready)
     ,.m_axil_araddr_o(hp1_axi_araddr)
     ,.m_axil_arprot_o(hp1_axi_arprot)
     ,.m_axil_arvalid_o(hp1_axi_arvalid)
     ,.m_axil_arready_i(hp1_axi_arready)
     ,.m_axil_rdata_i(hp1_axi_rdata)
     ,.m_axil_rresp_i(hp1_axi_rresp)
     ,.m_axil_rvalid_i(hp1_axi_rvalid)
     ,.m_axil_rready_o(hp1_axi_rready)
     );

  logic [C_GP0_AXI_DATA_WIDTH-1:0] mc_req_lo;
  logic mc_req_v_lo, mc_req_ready_li;
  logic [C_GP0_AXI_DATA_WIDTH-1:0] mc_rsp_lo;
  logic mc_rsp_v_lo, mc_rsp_ready_li;
  logic [C_GP0_AXI_DATA_WIDTH-1:0] host_req_li;
  logic host_req_v_li, host_req_ready_lo;
  logic [C_GP0_AXI_DATA_WIDTH-1:0] host_rsp_li;
  logic host_rsp_v_li, host_rsp_ready_lo;
  bsg_manycore_endpoint_to_fifos
   #(.fifo_width_p(4*C_GP0_AXI_DATA_WIDTH)
     ,.host_width_p(C_GP0_AXI_DATA_WIDTH)
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
     ,.link_sif_i(host_link_sif_li)
     ,.link_sif_o(host_link_sif_lo)

     // Parameterize
     ,.global_y_i(io_global_y_li)
     ,.global_x_i(io_global_x_li)

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

  bsg_cache_dma_pkt_s [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_lo;
  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_v_lo;
  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_pkt_yumi_li;

  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0][bsg_machine_llcache_channel_width_gp-1:0] dma_data_li;
  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_li;
  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_ready_lo;

  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0][bsg_machine_llcache_channel_width_gp-1:0] dma_data_lo;
  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_v_lo;
  logic [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0][num_vcaches_per_link_lp-1:0] dma_data_yumi_li;

  wh_link_sif_s [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0] buffered_wh_link_sif_li;
  wh_link_sif_s [E:W][S:N][bsg_machine_wh_ruche_factor_gp-1:0] buffered_wh_link_sif_lo;

  `declare_bsg_cache_wh_header_flit_s(bsg_machine_wh_flit_width_lp, bsg_machine_wh_cord_width_lp, bsg_machine_wh_len_width_lp, bsg_machine_wh_cid_width_lp);
  for (genvar i = W; i <= E; i++)
    begin : hs
      for (genvar k = N; k <= S; k++)
        begin : py
          for (genvar r = 0; r < bsg_machine_wh_ruche_factor_gp; r++)
            begin : rf
              if (r == 0)
                begin : ninvert
                  assign wh_link_sif_li[i][k][r] = buffered_wh_link_sif_li[i][k][r];
                  assign buffered_wh_link_sif_lo[i][k][r] = wh_link_sif_lo[i][k][r];
                end
              else
                begin : invert
                  assign wh_link_sif_li[i][k][r] = ~buffered_wh_link_sif_li[i][k][r];
                  assign buffered_wh_link_sif_lo[i][k][r] = ~wh_link_sif_lo[i][k][r];
                end

              bsg_cache_wh_header_flit_s header_flit_in;
              assign header_flit_in = buffered_wh_link_sif_lo[i][k][r].data;

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
  
                 ,.wh_link_sif_i(buffered_wh_link_sif_lo[i][k][r])
                 ,.wh_dma_id_i(dma_id_li)
                 ,.wh_link_sif_o(buffered_wh_link_sif_li[i][k][r])

                 ,.dma_pkt_o(dma_pkt_lo[i][k][r])
                 ,.dma_pkt_v_o(dma_pkt_v_lo[i][k][r])
                 ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i][k][r])

                 ,.dma_data_i(dma_data_li[i][k][r])
                 ,.dma_data_v_i(dma_data_v_li[i][k][r])
                 ,.dma_data_ready_and_o(dma_data_ready_lo[i][k][r])

                 ,.dma_data_o(dma_data_lo[i][k][r])
                 ,.dma_data_v_o(dma_data_v_lo[i][k][r])
                 ,.dma_data_yumi_i(dma_data_yumi_li[i][k][r])
                 );
            end
        end
    end

  logic [bsg_machine_llcache_addr_width_lp-1:0] axi_awaddr, axi_araddr;
  logic [lg_num_dma_lp-1:0] axi_awaddr_cache_id, axi_araddr_cache_id;
  bsg_cache_to_axi
   #(.addr_width_p(bsg_machine_llcache_addr_width_lp)
     ,.mask_width_p(bsg_machine_llcache_line_words_gp)
     ,.data_width_p(bsg_machine_llcache_channel_width_gp)
     ,.block_size_in_words_p(bsg_machine_llcache_line_words_gp)
     ,.num_cache_p(num_dma_lp)
     ,.axi_data_width_p(bsg_machine_llcache_channel_width_gp)
     ,.axi_id_width_p(6)
     ,.axi_burst_len_p(bsg_machine_llcache_line_words_gp)
     ,.axi_burst_type_p(e_axi_burst_incr)
     ,.ordering_en_p(1)
     )
   cache2axi
    (.clk_i(aclk)
     ,.reset_i(reset_r)

     ,.dma_pkt_i(dma_pkt_lo)
     ,.dma_pkt_v_i(dma_pkt_v_lo)
     ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

     ,.dma_data_o(dma_data_li)
     ,.dma_data_v_o(dma_data_v_li)
     ,.dma_data_ready_and_i(dma_data_ready_lo)

     ,.dma_data_i(dma_data_lo)
     ,.dma_data_v_i(dma_data_v_lo)
     ,.dma_data_yumi_o(dma_data_yumi_li)

     ,.axi_awid_o(hp0_axi_awid)
     ,.axi_awaddr_addr_o(axi_awaddr)
     ,.axi_awaddr_cache_id_o(axi_awaddr_cache_id)
     ,.axi_awlen_o(hp0_axi_awlen)
     ,.axi_awsize_o(hp0_axi_awsize)
     ,.axi_awburst_o(hp0_axi_awburst)
     ,.axi_awcache_o(hp0_axi_awcache)
     ,.axi_awprot_o(hp0_axi_awprot)
     ,.axi_awlock_o(hp0_axi_awlock)
     ,.axi_awvalid_o(hp0_axi_awvalid)
     ,.axi_awready_i(hp0_axi_awready)

     ,.axi_wdata_o(hp0_axi_wdata)
     ,.axi_wstrb_o(hp0_axi_wstrb)
     ,.axi_wlast_o(hp0_axi_wlast)
     ,.axi_wvalid_o(hp0_axi_wvalid)
     ,.axi_wready_i(hp0_axi_wready)

     ,.axi_bid_i(hp0_axi_bid)
     ,.axi_bresp_i(hp0_axi_bresp)
     ,.axi_bvalid_i(hp0_axi_bvalid)
     ,.axi_bready_o(hp0_axi_bready)

     ,.axi_arid_o(hp0_axi_arid)
     ,.axi_araddr_addr_o(axi_araddr)
     ,.axi_araddr_cache_id_o(axi_araddr_cache_id)
     ,.axi_arlen_o(hp0_axi_arlen)
     ,.axi_arsize_o(hp0_axi_arsize)
     ,.axi_arburst_o(hp0_axi_arburst)
     ,.axi_arcache_o(hp0_axi_arcache)
     ,.axi_arprot_o(hp0_axi_arprot)
     ,.axi_arlock_o(hp0_axi_arlock)
     ,.axi_arvalid_o(hp0_axi_arvalid)
     ,.axi_arready_i(hp0_axi_arready)

     ,.axi_rid_i(hp0_axi_rid)
     ,.axi_rdata_i(hp0_axi_rdata)
     ,.axi_rresp_i(hp0_axi_rresp)
     ,.axi_rlast_i(hp0_axi_rlast)
     ,.axi_rvalid_i(hp0_axi_rvalid)
     ,.axi_rready_o(hp0_axi_rready)
     );
  wire [C_HP0_AXI_ADDR_WIDTH-1:0] axi_awaddr_hash = {axi_awaddr_cache_id, axi_awaddr[0+:bsg_machine_llcache_addr_width_lp-lg_num_dma_lp]};
  wire [C_HP0_AXI_ADDR_WIDTH-1:0] axi_araddr_hash = {axi_araddr_cache_id, axi_araddr[0+:bsg_machine_llcache_addr_width_lp-lg_num_dma_lp]};

  assign hp0_axi_awaddr = axi_awaddr_hash + dram_base_li;
  assign hp0_axi_araddr = axi_araddr_hash + dram_base_li;

  // synopsys translate_off

  always @(negedge aclk)
    if (hp0_axi_awvalid & hp0_axi_awready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr_hash,hp0_axi_awaddr);

  always @(negedge aclk)
    if (hp0_axi_wvalid & hp0_axi_wready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Data %x (AXI HP0)",hp0_axi_wdata);

  always @(negedge aclk)
    if (hp0_axi_arvalid & hp0_axi_arready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Read Addr %x -> %x (AXI HP0)",axi_araddr_hash,hp0_axi_araddr);

  always @(negedge aclk)
    if (hp0_axi_rvalid & hp0_axi_rready)
      if (debug_lp) $display("top_zynq: (BP DRAM) AXI Read Data %x (AXI HP0)",hp0_axi_rdata);

  // synopsys translate_on

endmodule

