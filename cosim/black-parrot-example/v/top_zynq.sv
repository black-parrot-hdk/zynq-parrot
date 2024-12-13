
`timescale 1 ps / 1 ps

`include "bsg_tag.svh"
`include "bsg_zynq_pl.vh"
`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import zynq_pkg::*;
 import bsg_blackparrot_pkg::*;
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 import bsg_tag_pkg::*;
 #(parameter bp_params_e bp_params_p = bp_cfg_gp
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_bedrock_if_widths(paddr_width_p, lce_id_width_p, cce_id_width_p, did_width_p, lce_assoc_p)
   `declare_bp_core_if_widths(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p)
   `declare_bp_be_if_widths(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p, fetch_ptr_p, issue_ptr_p)

`ifdef COV_EN
   , parameter num_cov_p = `COV_NUM
`endif

   , parameter `BSG_INV_PARAM(C_S00_AXI_DATA_WIDTH)
   , parameter `BSG_INV_PARAM(C_S00_AXI_ADDR_WIDTH)
   , parameter `BSG_INV_PARAM(C_S01_AXI_DATA_WIDTH)
   , parameter `BSG_INV_PARAM(C_S01_AXI_ADDR_WIDTH)
   , parameter `BSG_INV_PARAM(C_S02_AXI_DATA_WIDTH)
   , parameter `BSG_INV_PARAM(C_S02_AXI_ADDR_WIDTH)
   , parameter `BSG_INV_PARAM(C_M00_AXI_DATA_WIDTH)
   , parameter `BSG_INV_PARAM(C_M00_AXI_ADDR_WIDTH)
   , parameter `BSG_INV_PARAM(C_M01_AXI_DATA_WIDTH)
   , parameter `BSG_INV_PARAM(C_M01_AXI_ADDR_WIDTH)
   , parameter `BSG_INV_PARAM(C_DMA_AXIS_DATA_WIDTH)
   )
  (input wire                                    aclk
   , input wire                                  aresetn
   , input wire                                  ds_clk
   , input wire                                  rt_clk
   , output logic                                sys_resetn

   , output logic                                tag_ck
   , output logic                                tag_data

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

   , input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_awaddr
   , input wire [2 : 0]                          s01_axi_awprot
   , input wire                                  s01_axi_awvalid
   , output wire                                 s01_axi_awready
   , input wire [C_S01_AXI_DATA_WIDTH-1 : 0]     s01_axi_wdata
   , input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb
   , input wire                                  s01_axi_wvalid
   , output wire                                 s01_axi_wready
   , output wire [1 : 0]                         s01_axi_bresp
   , output wire                                 s01_axi_bvalid
   , input wire                                  s01_axi_bready
   , input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_araddr
   , input wire [2 : 0]                          s01_axi_arprot
   , input wire                                  s01_axi_arvalid
   , output wire                                 s01_axi_arready
   , output wire [C_S01_AXI_DATA_WIDTH-1 : 0]    s01_axi_rdata
   , output wire [1 : 0]                         s01_axi_rresp
   , output wire                                 s01_axi_rvalid
   , input wire                                  s01_axi_rready

   , input wire [C_S02_AXI_ADDR_WIDTH-1 : 0]     s02_axi_awaddr
   , input wire [2 : 0]                          s02_axi_awprot
   , input wire                                  s02_axi_awvalid
   , output wire                                 s02_axi_awready
   , input wire [C_S02_AXI_DATA_WIDTH-1 : 0]     s02_axi_wdata
   , input wire [(C_S02_AXI_DATA_WIDTH/8)-1 : 0] s02_axi_wstrb
   , input wire                                  s02_axi_wvalid
   , output wire                                 s02_axi_wready
   , output wire [1 : 0]                         s02_axi_bresp
   , output wire                                 s02_axi_bvalid
   , input wire                                  s02_axi_bready
   , input wire [C_S02_AXI_ADDR_WIDTH-1 : 0]     s02_axi_araddr
   , input wire [2 : 0]                          s02_axi_arprot
   , input wire                                  s02_axi_arvalid
   , output wire                                 s02_axi_arready
   , output wire [C_S02_AXI_DATA_WIDTH-1 : 0]    s02_axi_rdata
   , output wire [1 : 0]                         s02_axi_rresp
   , output wire                                 s02_axi_rvalid
   , input wire                                  s02_axi_rready

   , output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
   , output wire                                 m00_axi_awvalid
   , input wire                                  m00_axi_awready
   , output wire [5:0]                           m00_axi_awid
   , output wire                                 m00_axi_awlock
   , output wire [3:0]                           m00_axi_awcache
   , output wire [2:0]                           m00_axi_awprot
   , output wire [7:0]                           m00_axi_awlen
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
   , output wire                                 m00_axi_arlock
   , output wire [3:0]                           m00_axi_arcache
   , output wire [2:0]                           m00_axi_arprot
   , output wire [7:0]                           m00_axi_arlen
   , output wire [2:0]                           m00_axi_arsize
   , output wire [1:0]                           m00_axi_arburst
   , output wire [3:0]                           m00_axi_arqos

   , input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
   , input wire                                  m00_axi_rvalid
   , output wire                                 m00_axi_rready
   , input wire [5:0]                            m00_axi_rid
   , input wire                                  m00_axi_rlast
   , input wire [1:0]                            m00_axi_rresp

   , output wire [C_M01_AXI_ADDR_WIDTH-1 : 0]    m01_axi_awaddr
   , output wire [2 : 0]                         m01_axi_awprot
   , output wire                                 m01_axi_awvalid
   , input wire                                  m01_axi_awready
   , output wire [C_M01_AXI_DATA_WIDTH-1 : 0]    m01_axi_wdata
   , output wire [(C_M01_AXI_DATA_WIDTH/8)-1:0]  m01_axi_wstrb
   , output wire                                 m01_axi_wvalid
   , input wire                                  m01_axi_wready
   , input wire [1 : 0]                          m01_axi_bresp
   , input wire                                  m01_axi_bvalid
   , output wire                                 m01_axi_bready
   , output wire [C_M01_AXI_ADDR_WIDTH-1 : 0]    m01_axi_araddr
   , output wire [2 : 0]                         m01_axi_arprot
   , output wire                                 m01_axi_arvalid
   , input wire                                  m01_axi_arready
   , input wire [C_M01_AXI_DATA_WIDTH-1 : 0]     m01_axi_rdata
   , input wire [1 : 0]                          m01_axi_rresp
   , input wire                                  m01_axi_rvalid
   , output wire                                 m01_axi_rready

   , input wire                                  dma_axis_tready
   , output wire                                 dma_axis_tvalid
   , output wire [C_DMA_AXIS_DATA_WIDTH-1 : 0]   dma_axis_tdata
   , output wire [(C_DMA_AXIS_DATA_WIDTH/8)-1:0] dma_axis_tkeep
   , output wire                                 dma_axis_tlast
   );

  `define COREPATH blackparrot.processor.u.unicore.unicore_lite.core_minimal

   localparam debug_lp = 0;

   localparam bp_axil_addr_width_lp = 32;
   localparam bp_axil_data_width_lp = 32;
   localparam bp_axi_addr_width_lp  = 32;
   localparam bp_axi_data_width_lp  = 64;

`ifdef COV_EN
   localparam num_regs_ps_to_pl_lp  = 6;
`else
   localparam num_regs_ps_to_pl_lp  = 5;
`endif
   localparam num_regs_pl_to_ps_lp  = 11;

   localparam num_fifo_ps_to_pl_lp = 1;
`ifdef COEMU
   localparam num_fifo_pl_to_ps_lp = 24;
`else
   localparam num_fifo_pl_to_ps_lp = 1;
`endif


   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_lo:

   //    finished with all AXI transactions (fixme: potential improvement to detect this)
   // 1: Bit banging interface
   // 2: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
   // 3: The base register for the allocated dram
   // 4: The bootrom access address
   // 5: The coverage sampling enable
   //
   logic [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_li:
   //
   // 0-3: memory access profiler mask
   // 4: bootrom access data
   // 5-6: cycle
   // 7-8: mcycle
   // 9-10: minstret
   //
   logic [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

   ///////////////////////////////////////////////////////////////////////////////////////
   // pl_to_ps_fifo:
   //
   // 0: BP host IO access request
   //
   logic [num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   logic [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // ps_to_pl_fifo:
   //
   // 0: BP host IO access response
   //
   logic [num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   logic [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

   // BP ingoing and outgoing AXIL IO
   logic [bp_axil_addr_width_lp-1:0]     bp_m_axil_awaddr;
   logic [2:0]                           bp_m_axil_awprot;
   logic                                 bp_m_axil_awvalid;
   logic                                 bp_m_axil_awready;
   logic [bp_axil_data_width_lp-1:0]     bp_m_axil_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0] bp_m_axil_wstrb;
   logic                                 bp_m_axil_wvalid;
   logic                                 bp_m_axil_wready;
   logic [1:0]                           bp_m_axil_bresp;
   logic                                 bp_m_axil_bvalid;
   logic                                 bp_m_axil_bready;
   logic [bp_axil_addr_width_lp-1:0]     bp_m_axil_araddr;
   logic [2:0]                           bp_m_axil_arprot;
   logic                                 bp_m_axil_arvalid;
   logic                                 bp_m_axil_arready;
   logic [bp_axil_data_width_lp-1:0]     bp_m_axil_rdata;
   logic [1:0]                           bp_m_axil_rresp;
   logic                                 bp_m_axil_rvalid;
   logic                                 bp_m_axil_rready;

   logic [bp_axil_addr_width_lp-1:0]     bp_s_axil_awaddr;
   logic [2:0]                           bp_s_axil_awprot;
   logic                                 bp_s_axil_awvalid;
   logic                                 bp_s_axil_awready;
   logic [bp_axil_data_width_lp-1:0]     bp_s_axil_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0] bp_s_axil_wstrb;
   logic                                 bp_s_axil_wvalid;
   logic                                 bp_s_axil_wready;
   logic [1:0]                           bp_s_axil_bresp;
   logic                                 bp_s_axil_bvalid;
   logic                                 bp_s_axil_bready;
   logic [bp_axil_addr_width_lp-1:0]     bp_s_axil_araddr;
   logic [2:0]                           bp_s_axil_arprot;
   logic                                 bp_s_axil_arvalid;
   logic                                 bp_s_axil_arready;
   logic [bp_axil_data_width_lp-1:0]     bp_s_axil_rdata;
   logic [1:0]                           bp_s_axil_rresp;
   logic                                 bp_s_axil_rvalid;
   logic                                 bp_s_axil_rready;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
      ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
      ,.num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
      ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_new_o(csr_data_new_lo)
        ,.csr_data_o(csr_data_lo)
        ,.csr_data_i(csr_data_li)

        ,.pl_to_ps_fifo_data_i(pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i(pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o(ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o(ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i(ps_to_pl_fifo_ready_li & ps_to_pl_fifo_v_lo)

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
   // User code goes here
   ///////////////////////////////////////////////////////////////////////////////////////
   localparam bootrom_data_lp = 32;
   localparam bootrom_addr_lp = 9;

   logic bb_data_li, bb_v_li;
   logic dram_init_li;
   logic [C_M00_AXI_ADDR_WIDTH-1:0] dram_base_li;

   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;
   logic [63:0] cycle_lo, mcycle_lo, minstret_lo;

   logic [bootrom_addr_lp-1:0] bootrom_addr_lo;
   logic [bootrom_data_lp-1:0] bootrom_data_li;

   assign sys_resetn         = csr_data_lo[0][0]; // active-low
   assign bb_data_li         = csr_data_lo[1][0]; assign bb_v_li = csr_data_new_lo[1];
   assign dram_init_li       = csr_data_lo[2];
   assign dram_base_li       = csr_data_lo[3];
   assign bootrom_addr_lo    = csr_data_lo[4];
`ifdef COV_EN
   logic cov_en_li;
   assign cov_en_li          = csr_data_lo[5];
`endif

   bsg_counter_clear_up
    #(.max_val_p((65)'(2**64-1)), .init_val_p(0))
    cycle_cnt
     (.clk_i(ds_clk)
     ,.reset_i(ds_reset_li)
     ,.clear_i(`COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze)
     ,.up_i(1'b1)
     ,.count_o(cycle_lo)
     );

   bsg_counter_clear_up
    #(.max_val_p((65)'(2**64-1)), .init_val_p(0))
    mcycle_cnt
     (.clk_i(bp_clk)
     ,.reset_i(bp_reset_li)
     ,.clear_i(`COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze)
     ,.up_i(1'b1)
     ,.count_o(mcycle_lo)
     );

   assign minstret_lo = `COREPATH.be.calculator.pipe_sys.csr.minstret_lo;

   assign csr_data_li[0+:4] = mem_profiler_r;
   assign csr_data_li[4] = bootrom_data_li;
   assign csr_data_li[5+:2] = cycle_lo;
   assign csr_data_li[7+:2] = mcycle_lo;
   assign csr_data_li[9+:2] = minstret_lo;

   bsg_bootrom
    #(.width_p(bootrom_data_lp), .addr_width_p(bootrom_addr_lp))
    bootrom
     (.addr_i(bootrom_addr_lo), .data_o(bootrom_data_li));

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
   assign tag_ck = tag_clk_r_lo;
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

   logic tag_reset_li;
   bsg_tag_client
    #(.width_p(1))
    reset_client
     (.bsg_tag_i(tag_lines_lo.core_reset)
      ,.recv_clk_i(aclk)
      ,.recv_new_r_o() // UNUSED
      ,.recv_data_r_o(tag_reset_li)
      );

   // Reset BP during system reset or if bsg_tag says to
   wire bp_async_reset_li = ~sys_resetn | tag_reset_li;

   // Gating Logic
   (* gated_clock = "yes" *) wire bp_clk;

  logic coemu_gate_lo;

  wire cce_gate_lo;
`ifdef COV_EN
   logic cov_en_sync_li;
   logic [num_cov_p-1:0] cov_gate_lo;
   assign cce_gate_lo = cov_en_sync_li & (|cov_gate_lo);
`else
   assign cce_gate_lo = 1'b0;
`endif

  wire gate_lo = cce_gate_lo | coemu_gate_lo;
   // Clock Generation
`ifdef VIVADO
`ifdef ULTRASCALE
   // Ultrascale primitives
   BUFGCE #(
      .CE_TYPE("SYNC"),
      .IS_CE_INVERTED(1'b1),
      .IS_I_INVERTED(1'b0)
   )
   BUFGCE_inst (
      .I(ds_clk),
      .CE(gate_lo),
      .O(bp_clk)
   );
`elsif SERIES7
   // Zynq-7000 primitives
   BUFGCE BUFGCE_inst (
      .I(ds_clk),
      .CE(~gate_lo),
      .O(bp_clk)
   );
`else
  initial begin
    $error("Unknown device family!");
  end
`endif
`else // verilator
   bsg_icg_pos
    clk_buf
     (.clk_i(ds_clk)
     ,.en_i(~gate_lo)
     ,.clk_o(bp_clk)
     );
`endif

`ifdef COEMU
  /* start of Dromajo FPGA-synthesizable co-emulation */
  `declare_bp_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p, fetch_ptr_p, issue_ptr_p);
  bp_be_commit_pkt_s commit_pkt;
  assign commit_pkt = `COREPATH.be.calculator.commit_pkt_cast_o;

  bp_be_decode_s decode_r;
  bsg_dff_chain
   #(.width_p($bits(bp_be_decode_s)), .num_stages_p(4))
   reservation_pipe
    (.clk_i(bp_clk)
     ,.data_i(`COREPATH.be.calculator.dispatch_pkt_cast_i.decode)
     ,.data_o(decode_r)
     );

  bp_be_commit_pkt_s commit_pkt_r;
  logic is_debug_mode_r;
  bsg_dff_chain
   #(.width_p(1+$bits(commit_pkt)), .num_stages_p(1))
   commit_pkt_reg
    (.clk_i(bp_clk)

     ,.data_i({`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode, commit_pkt})
     ,.data_o({is_debug_mode_r, commit_pkt_r})
     );

  logic cache_req_complete_r, cache_req_v_r;
  wire cache_req_v_li = `COREPATH.be.calculator.pipe_mem.dcache.cache_req_yumi_i
                        & ~`COREPATH.be.calculator.pipe_mem.dcache.nonblocking_req;
  bsg_dff_chain
   #(.width_p(2), .num_stages_p(2))
   cache_req_reg
    (.clk_i(bp_clk)

     ,.data_i({`COREPATH.be.calculator.pipe_mem.dcache.complete_recv, cache_req_v_li})
     ,.data_o({cache_req_complete_r, cache_req_v_r})
     );

  wire                      freeze_li           = `COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze;
  wire                      instret_v_li        = commit_pkt_r.instret;
  wire                      trap_v_li           = commit_pkt_r.exception | commit_pkt_r._interrupt;
  wire                      end_li              = '0; // TODO should be triggered when 24'h902000 is written to some special address -- pull this out from BP
  wire [vaddr_width_p-1:0]  commit_pc_li        = commit_pkt_r.pc;
  wire [instr_width_gp-1:0] commit_instr_li     = commit_pkt_r.instr;
  wire                      commit_ird_w_v_li   = instret_v_li & decode_r.irf_w_v;
  wire                      commit_frd_w_v_li   = instret_v_li & decode_r.frf_w_v;
  wire                      commit_req_v_li     = instret_v_li & cache_req_v_r;
  wire [dword_width_gp-1:0] cause_li            = (`COREPATH.be.calculator.pipe_sys.csr.priv_mode_r == `PRIV_MODE_M)
                                                  ? `COREPATH.be.calculator.pipe_sys.csr.mcause_lo : `COREPATH.be.calculator.pipe_sys.csr.scause_lo;
  wire [dword_width_gp-1:0] mstatus_li          = `COREPATH.be.calculator.pipe_sys.csr.mstatus_lo;
  wire [dword_width_gp-1:0] minstret_li         = `COREPATH.be.calculator.pipe_sys.csr.minstret_lo;
  wire [dword_width_gp-1:0] epc_li              = (`COREPATH.be.calculator.pipe_sys.csr.priv_mode_r == `PRIV_MODE_M)
                                                  ? `COREPATH.be.calculator.pipe_sys.csr.mepc_lo : `COREPATH.be.calculator.pipe_sys.csr.sepc_lo;
  wire [dword_width_gp-1:0] mcycle_li           = `COREPATH.be.calculator.pipe_sys.csr.mcycle_lo;
  wire                      commit_fifo_async_v_li    = (instret_v_li | trap_v_li) & ~end_li;
  wire                      commit_fifo_async_full_lo;

  wire                      freeze_async_lo;
  wire                      commit_debug_async_lo;
  wire                      instret_v_async_lo;
  wire                      trap_v_async_lo;
  wire [vaddr_width_p-1:0]  commit_pc_async_lo;
  rv64_instr_fmatype_s      commit_instr_async_lo;
  wire                      commit_ird_w_v_async_lo;
  wire                      commit_frd_w_v_async_lo;
  wire                      commit_req_v_async_lo;
  wire [dword_width_gp-1:0] cause_async_lo, mstatus_async_lo, minstret_async_lo, mcycle_async_lo;
  wire [dword_width_gp-1:0] epc_async_lo;
  wire                      commit_fifo_v_sync_lo;
  wire                      commit_fifo_ready_sync_li;

  bsg_async_fifo
  #(.width_p(4 + vaddr_width_p + instr_width_gp + 3 + 5*dword_width_gp), .lg_size_p(5))
  commit_fifo_async
    (.w_clk_i(bp_clk)
     ,.w_reset_i(bp_async_reset_li) // TODO
     ,.w_enq_i(commit_fifo_async_v_li & ~commit_fifo_async_full_lo)
     ,.w_data_i({freeze_li
                 , is_debug_mode_r
                 , instret_v_li
                 , trap_v_li
                 , commit_pc_li
                 , commit_instr_li
                 , commit_ird_w_v_li
                 , commit_frd_w_v_li
                 , commit_req_v_li
                 , cause_li
                 , mstatus_li
                 , minstret_li
                 , epc_li
                 , mcycle_li})
     ,.w_full_o(commit_fifo_async_full_lo)

     ,.r_clk_i(aclk)
     ,.r_reset_i(~aresetn)
     ,.r_deq_i(commit_fifo_ready_sync_li & commit_fifo_v_sync_lo)
     ,.r_data_o({freeze_async_lo
                , commit_debug_async_lo
                , instret_v_async_lo
                , trap_v_async_lo
                , commit_pc_async_lo
                , commit_instr_async_lo
                , commit_ird_w_v_async_lo
                , commit_frd_w_v_async_lo
                , commit_req_v_async_lo
                , cause_async_lo
                , mstatus_async_lo
                , minstret_async_lo
                , epc_async_lo
                , mcycle_async_lo})
     ,.r_valid_o(commit_fifo_v_sync_lo)
     );


  wire                      freeze_r;
  wire                      commit_debug_r;
  wire                      instret_v_r;
  wire                      trap_v_r;
  wire [vaddr_width_p-1:0]  commit_pc_r;
  rv64_instr_fmatype_s      commit_instr_r;
  wire                      commit_ird_w_v_r;
  wire                      commit_frd_w_v_r;
  wire                      commit_req_v_r;
  wire [dword_width_gp-1:0] cause_r, mstatus_r, minstret_r, mcycle_r;
  wire [dword_width_gp-1:0] epc_r;

  wire                      commit_fifo_v_lo;
  wire [11:0]               pl2ps_commit_readies_lo;

  // sync fifo's full signal OR-asserts gate;
  // prev async also serves to act as buffer to subsequent commits
  bsg_fifo_1r1w_small
  #(.width_p(4 + vaddr_width_p + instr_width_gp + 3 + 5*dword_width_gp), .els_p(16))
    commit_fifo_sync
    (.clk_i(aclk)
     , .reset_i(~aresetn)

     , .v_i(commit_fifo_v_sync_lo)
     , .ready_param_o(commit_fifo_ready_sync_li)
     , .data_i({freeze_async_lo
                , commit_debug_async_lo
                , instret_v_async_lo
                , trap_v_async_lo
                , commit_pc_async_lo
                , commit_instr_async_lo
                , commit_ird_w_v_async_lo
                , commit_frd_w_v_async_lo
                , commit_req_v_async_lo
                , cause_async_lo
                , mstatus_async_lo
                , minstret_async_lo
                , epc_async_lo
                , mcycle_async_lo})

     , .v_o(commit_fifo_v_lo)
     , .data_o({freeze_r
                , commit_debug_r
                , instret_v_r
                , trap_v_r
                , commit_pc_r
                , commit_instr_r
                , commit_ird_w_v_r
                , commit_frd_w_v_r
                , commit_req_v_r // TODO not used currently -- analyze if you need it?
                , cause_r
                , mstatus_r
                , minstret_r
                , epc_r
                , mcycle_r})
     , .yumi_i(&pl2ps_commit_readies_lo & commit_fifo_v_lo)
    );

  wire pl2ps_commit_v_lo  = commit_fifo_v_lo & &pl2ps_commit_readies_lo &
                              ~commit_debug_r & ~freeze_r & instret_v_r;
  wire pl2ps_xcpt_v_lo    = commit_fifo_v_lo & &pl2ps_commit_readies_lo &
                              ~commit_debug_r & ~freeze_r & trap_v_r;

  wire [31:0] metadata_lo; // TODO redundant (dromajo API should provide this)
  reg end_r;
  assign metadata_lo = {
                         mcycle_r[23:0]
                        , end_r
                        , commit_instr_r.rd_addr[4:0]
                        , commit_frd_w_v_r
                        , commit_ird_w_v_r
                      };

  wire [63:0] pc_lo = `BSG_SIGN_EXTEND(commit_pc_r, dword_width_gp);
  wire [63:0] epc_lo = `BSG_SIGN_EXTEND(epc_r, dword_width_gp);


  // because we aren't stitching commit_pkt and the corresponding register write,
  //   the need to store register writes is obviated (it's done in SW)
  localparam                 rf_els_lp = 2**reg_addr_width_gp;
  bp_be_int_reg_s            ird_data_r, ird_data_async_lo;
  bp_be_fp_reg_s             frd_data_r, frd_data_async_lo;
  logic [reg_addr_width_gp-1:0] ird_addr_r, ird_addr_async_lo, frd_addr_r, frd_addr_async_lo;
  logic                      ird_sync_ready_li, frd_sync_ready_li;
  logic                      ird_async_v_lo, frd_async_v_lo;
  logic                      frd_fifo_full_lo, ird_fifo_full_lo;
  logic [2:0]                pl2ps_ird_readies_lo, pl2ps_frd_readies_lo;
  wire                       pl2ps_ird_v_lo, pl2ps_frd_v_lo;
  logic [int_rec_width_gp-1:0] ird_raw_li;
  logic [dp_rec_width_gp-1:0]  frd_raw_li;

  bsg_async_fifo
   #(.width_p($bits(bp_be_int_reg_s) + reg_addr_width_gp), .lg_size_p(5))
   ird_fifo_async
    (.w_clk_i(bp_clk)
     ,.w_reset_i(bp_async_reset_li) //TODO
     ,.w_enq_i( `COREPATH.be.scheduler.iwb_pkt_cast_i.ird_w_v & ~ird_fifo_full_lo)
     ,.w_data_i({`COREPATH.be.scheduler.iwb_pkt_cast_i.rd_addr, `COREPATH.be.scheduler.iwb_pkt_cast_i.rd_data[0+:$bits(bp_be_fp_reg_s)]})
     ,.w_full_o(ird_fifo_full_lo)

     ,.r_clk_i(aclk)
     ,.r_reset_i(~aresetn)
     ,.r_deq_i(ird_sync_ready_li & ird_async_v_lo)
     ,.r_data_o({ird_addr_async_lo, ird_data_async_lo})
     ,.r_valid_o(ird_async_v_lo)
     );

  bsg_fifo_1r1w_small
    #(.width_p($bits(bp_be_int_reg_s) + reg_addr_width_gp), .els_p(16))
    ird_fifo_sync
    (.clk_i(aclk)
      , .reset_i(~aresetn)
      , .v_i(ird_async_v_lo)
      , .ready_param_o(ird_sync_ready_li)
      , .data_i({ird_addr_async_lo, ird_data_async_lo})
      , .v_o(pl2ps_ird_v_lo)
      , .data_o({ird_addr_r, ird_data_r})
      , .yumi_i(&pl2ps_ird_readies_lo & pl2ps_ird_v_lo)
    );

  bp_be_int_unbox
   #(.bp_params_p(bp_params_p))
   int_unbox
    (.reg_i(ird_data_r)
     ,.tag_i(e_int_dword)
     ,.unsigned_i(1'b0)
     ,.val_o(ird_raw_li)
     );

  bsg_async_fifo
   #(.width_p($bits(bp_be_fp_reg_s) + reg_addr_width_gp), .lg_size_p(5))
   frd_fifo_async
    (.w_clk_i(bp_clk)
     ,.w_reset_i(bp_async_reset_li) //TODO
     ,.w_enq_i(`COREPATH.be.scheduler.fwb_pkt_cast_i.frd_w_v)
     ,.w_data_i({`COREPATH.be.scheduler.fwb_pkt_cast_i.rd_addr, `COREPATH.be.scheduler.fwb_pkt_cast_i.rd_data})
     ,.w_full_o(frd_fifo_full_lo)

     ,.r_clk_i(aclk)
     ,.r_reset_i(~aresetn)
     ,.r_deq_i(frd_sync_ready_li & frd_async_v_lo)
     ,.r_data_o({frd_addr_async_lo, frd_data_async_lo})
     ,.r_valid_o(frd_async_v_lo)
     );

  bsg_fifo_1r1w_small
    #(.width_p($bits(bp_be_fp_reg_s) + reg_addr_width_gp), .els_p(16))
    frd_fifo_sync
    (.clk_i(aclk)
      , .reset_i(~aresetn)
      , .v_i(frd_async_v_lo)
      , .ready_param_o(frd_sync_ready_li)
      , .data_i({frd_addr_async_lo, frd_data_async_lo})
      , .v_o(pl2ps_frd_v_lo)
      , .data_o({frd_addr_r, frd_data_r})
      , .yumi_i(&pl2ps_frd_readies_lo & pl2ps_frd_v_lo)
    );

  bp_be_fp_unbox
   #(.bp_params_p(bp_params_p))
   fp_unbox
    (.reg_i(frd_data_r)
     ,.tag_i(frd_data_r.tag)
     ,.raw_i(1'b1)
     ,.val_o(frd_raw_li)
     );


  // gating contribution
  reg coemu_gate_r;
  always @(negedge aclk)
    if(~aresetn)
      coemu_gate_r <= '0;
    else
      if(~coemu_gate_r & (~commit_fifo_ready_sync_li | ~ird_sync_ready_li | ~frd_sync_ready_li) & cov_en_li) // gate when sync fifos are full & gating enabled(=coverage collection enabled)
        coemu_gate_r <= '1;
      else if(coemu_gate_r & (~commit_fifo_v_lo & ~pl2ps_ird_v_lo & ~pl2ps_frd_v_lo) | ~cov_en_li) // ungate after sync fifos are fully drained
        coemu_gate_r <= '0;

  // ungated_aclk domain
  bsg_sync_sync
   #(.width_p(1))
   gate_cross
   (.oclk_i(ds_clk)
   ,.iclk_data_i(coemu_gate_r)
   ,.oclk_data_o(coemu_gate_lo)
   );

  // pl_to_ps_fifo valids
  assign pl_to_ps_fifo_v_li[23] = pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[22] = pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[21] = pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[20] = pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo;

  assign pl_to_ps_fifo_v_li[19] = pl2ps_frd_v_lo & &pl2ps_frd_readies_lo;
  assign pl_to_ps_fifo_v_li[18] = pl2ps_frd_v_lo & &pl2ps_frd_readies_lo;
  assign pl_to_ps_fifo_v_li[17] = pl2ps_frd_v_lo & &pl2ps_frd_readies_lo;
  assign pl_to_ps_fifo_v_li[16] = pl2ps_frd_v_lo & &pl2ps_frd_readies_lo;

  assign pl_to_ps_fifo_v_li[15] = pl2ps_ird_v_lo & &pl2ps_ird_readies_lo;
  assign pl_to_ps_fifo_v_li[14] = pl2ps_ird_v_lo & &pl2ps_ird_readies_lo;
  assign pl_to_ps_fifo_v_li[13] = pl2ps_ird_v_lo & &pl2ps_ird_readies_lo;
  assign pl_to_ps_fifo_v_li[12] = pl2ps_ird_v_lo & &pl2ps_ird_readies_lo;

  assign pl_to_ps_fifo_v_li[11] = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[10] = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[9]  = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[8]  = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;

  assign pl_to_ps_fifo_v_li[7]  = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[6]  = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[5]  = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;
  assign pl_to_ps_fifo_v_li[4]  = pl2ps_commit_v_lo & &pl2ps_commit_readies_lo;

  // spacer for ARM NEON vector loads
  assign pl_to_ps_fifo_v_li[3] = pl_to_ps_fifo_v_li[0];
  assign pl_to_ps_fifo_v_li[2] = pl_to_ps_fifo_v_li[0];
  assign pl_to_ps_fifo_v_li[1] = pl_to_ps_fifo_v_li[0];

  // datas
  assign pl_to_ps_fifo_data_li[23] = pl2ps_xcpt_v_lo ? epc_lo[63:32] : '1;
  assign pl_to_ps_fifo_data_li[22] = pl2ps_xcpt_v_lo ? epc_lo[31:0]  : '1;
  assign pl_to_ps_fifo_data_li[21] = pl2ps_xcpt_v_lo ? cause_r[63:32] : '1;
  assign pl_to_ps_fifo_data_li[20] = pl2ps_xcpt_v_lo ? cause_r[31:0]  : '1;

  assign pl_to_ps_fifo_data_li[19] = 32'b0;
  assign pl_to_ps_fifo_data_li[18] = frd_raw_li[63:32];
  assign pl_to_ps_fifo_data_li[17] = frd_raw_li[31:0];
  assign pl_to_ps_fifo_data_li[16] = {mcycle_r[23:0], 3'b0, frd_addr_r[4:0]}; // last 27b for synchronizing to mcycle

  assign pl_to_ps_fifo_data_li[15] = 32'b0;
  assign pl_to_ps_fifo_data_li[14] = ird_raw_li[63:32];
  assign pl_to_ps_fifo_data_li[13] = ird_raw_li[31:0];
  assign pl_to_ps_fifo_data_li[12] = {mcycle_r[23:0], 3'b0, ird_addr_r[4:0]};

  assign pl_to_ps_fifo_data_li[11] = minstret_r[63:32];
  assign pl_to_ps_fifo_data_li[10] = minstret_r[31:0];
  assign pl_to_ps_fifo_data_li[9]  = mstatus_r[63:32];
  assign pl_to_ps_fifo_data_li[8]  = mstatus_r[31:0];

  assign pl_to_ps_fifo_data_li[7]  = pc_lo[63:32];
  assign pl_to_ps_fifo_data_li[6]  = pc_lo[31:0];
  assign pl_to_ps_fifo_data_li[5]  = metadata_lo[31:0]; // has partial mcycle_r for syncing with ird/frd TODO end_r
  assign pl_to_ps_fifo_data_li[4]  = commit_instr_r[31:0];

  // pl_to_ps_fifo readies
  assign pl2ps_commit_readies_lo[11] = pl_to_ps_fifo_ready_lo[23];
  assign pl2ps_commit_readies_lo[10] = pl_to_ps_fifo_ready_lo[22];
  assign pl2ps_commit_readies_lo[9] =  pl_to_ps_fifo_ready_lo[21];
  assign pl2ps_commit_readies_lo[8] =  pl_to_ps_fifo_ready_lo[20];
                                                                 ;
  assign pl2ps_frd_readies_lo[2] =     pl_to_ps_fifo_ready_lo[18];
  assign pl2ps_frd_readies_lo[1] =     pl_to_ps_fifo_ready_lo[17];
  assign pl2ps_frd_readies_lo[0] =     pl_to_ps_fifo_ready_lo[16];
                                                                 ;
  assign pl2ps_ird_readies_lo[2] =     pl_to_ps_fifo_ready_lo[14];
  assign pl2ps_ird_readies_lo[1] =     pl_to_ps_fifo_ready_lo[13];
  assign pl2ps_ird_readies_lo[0] =     pl_to_ps_fifo_ready_lo[12];
                                                                 ;
  assign pl2ps_commit_readies_lo[7] =  pl_to_ps_fifo_ready_lo[11];
  assign pl2ps_commit_readies_lo[6] =  pl_to_ps_fifo_ready_lo[10];
  assign pl2ps_commit_readies_lo[5] =  pl_to_ps_fifo_ready_lo[9];
  assign pl2ps_commit_readies_lo[4] =  pl_to_ps_fifo_ready_lo[8];
                                                                ;
  assign pl2ps_commit_readies_lo[3] =  pl_to_ps_fifo_ready_lo[7];
  assign pl2ps_commit_readies_lo[2] =  pl_to_ps_fifo_ready_lo[6];
  assign pl2ps_commit_readies_lo[1] =  pl_to_ps_fifo_ready_lo[5];
  assign pl2ps_commit_readies_lo[0] =  pl_to_ps_fifo_ready_lo[4];

  /* end of Dromajo co-emulation */
`else
  assign coemu_gate_lo = 1'b0;
`endif

   // Address Translation (MBT):
   //
   // The Zynq PS Physical address space looks like this:
   //
   // 0x0000_0000 - 0x0003_FFFF  +256 KB On-chip memory (optional), else DDR DRAM
   // 0x0004_0000 - 0x1FFF_FFFF  +512 MB DDR DRAM for Zynq P2 board
   // 0x2000_0000 - 0x3FFF_FFFF  Another 512 MB DDR DRAM, if the board had it, it does not
   // 0x4000_0000 - 0x7FFF_FFFF  1 GB Mapped to PL via M_AXI_GP0
   // 0x8000_0000 - 0xBFFF_FFFF  1 GB Mapped to PL via M_AXI_GP1
   // 0xFFFC_0000 - 0xFFFF_FFFF  Alternate location for OCM
   //
   // BlackParrot's Physical address space looks like this:
   //    (see github.com/black-parrot/black-parrot/blob/master/docs/platform_guide.md)
   //
   // 0x00_0000_0000 - 0x00_7FFF_FFFF local addresses; 2GB: < 9'b0, 7b tile, 4b device, 20b 1MB space>
   // 0x00_8000_0000 - 0x00_9FFF_FFFF cached dram (up to 512 MB, mapped to Zynq)
   // 0x00_A000_0000 - 0x00_FFFF_FFFF cached dram that does not exist on Zynq board (another 1.5 GB)
   // 0x01_0000_0000 - 0x0F_FFFF_FFFF cached dram that does not exist on Zynq board (another 60 GB)
   // 0x10_0000_0000 - 0x1F_FFFF_FFFF on-chip address space for streaming accelerators
   // 0x20_0000_0000 - 0xFF_FFFF_FFFF off-chip address space
   //
   // Currently, we allocate the Zynq M_AXI_GP0 address space to handle management of the shell
   // that interfaces Zynq to external "accelerators" like BP.
   //
   // So the M_AXI_GP1 address space remains to map BP. A straight-forward translation is to
   // map 0x8000_0000 - 0x8FFF_FFFF of Zynq Physical Address Space (PA) to the same addresses in BP
   //  providing 256 MB of DRAM, leaving 256 MB for the Zynq PS system.
   //
   // Then we can map 0xA000_0000-0xAFFF_FFFF of ARM PA to 0x00_0000_0000 - 0x00_0FFF_FFFF of BP,
   // handling up to tiles 0..15. (This is 256 MB of address space.)
   //
   // since these addresses are going to pop out of the M_AXI_GP1 port, they will already have
   // 0x8000_0000 subtracted, it will ironically have to be added back in by this module
   //
   // M_AXI_GP1: 0x0000_0000 - 0x1000_0000 -> add      0x8000_0000.
   //            0x2000_0000 - 0x3000_0000 -> subtract 0x2000_0000.

   // Life of an address (FPGA):
   //
   //                NBF Loader                 mmap                  Xilinx IPI Switch         This Module
   //  NBF (0x8000_0000) -> ARM VA (0x8000_0000) -> ARM PA (0x8000_0000) -> M_AXI_GP1 (0x0000_0000) -> BP (0x8000_0000)
   //  NBF (0x0000_0000) -> ARM VA (0xA000_0000) -> ARM PA (0xA000_0000) -> M_AXI_GP1 (0x2000_0000) -> BP (0x0000_0000)
   //
   // Life of an address (Verilator):
   //                  NBF Loader              bp_zynq_pl          Verilator Bit Truncation     This Module
   //  NBF (0x8000_0000) -> ARM VA (x8000_0000) ->  ARM PA (0x8000_0000) -> M_AXI_GP1 (0x0000_0000) -> BP (0x8000_0000)
   //  NBF (0x0000_0000) -> ARM VA (xA000_0000) ->  ARM PA (0xA000_0000) -> M_AXI_GP1 (0x2000_0000) -> BP (0x0000_0000)
   //
   //

   // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
   // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF
   logic [bp_axil_addr_width_lp-1:0] s01_awaddr_translated_lo, s01_araddr_translated_lo;
   assign s01_awaddr_translated_lo = (s01_axi_awaddr < 32'h20000000) ? (s01_axi_awaddr + 32'h80000000) : {4'b0, s01_axi_awaddr[0+:28]};
   assign s01_araddr_translated_lo = (s01_axi_araddr < 32'h20000000) ? (s01_axi_araddr + 32'h80000000) : {4'b0, s01_axi_araddr[0+:28]};


   logic [bp_axil_addr_width_lp-1 : 0]          spack_axi_awaddr;
   logic [2 : 0]                                spack_axi_awprot;
   logic                                        spack_axi_awvalid;
   logic                                        spack_axi_awready;
   logic [bp_axil_data_width_lp-1 : 0]          spack_axi_wdata;
   logic [(bp_axil_data_width_lp/8)-1 : 0]      spack_axi_wstrb;
   logic                                        spack_axi_wvalid;
   logic                                        spack_axi_wready;
   logic  [1 : 0]                               spack_axi_bresp;
   logic                                        spack_axi_bvalid;
   logic                                        spack_axi_bready;
   logic [bp_axil_data_width_lp-1 : 0]          spack_axi_araddr;
   logic [2 : 0]                                spack_axi_arprot;
   logic                                        spack_axi_arvalid;
   logic                                        spack_axi_arready;
   logic  [bp_axil_data_width_lp-1 : 0]         spack_axi_rdata;
   logic  [1 : 0]                               spack_axi_rresp;
   logic                                        spack_axi_rvalid;
   logic                                        spack_axi_rready;

   bsg_axil_store_packer
    #(.axil_addr_width_p(bp_axil_addr_width_lp)
      ,.axil_data_width_p(bp_axil_data_width_lp)
      ,.payload_data_width_p(8)
      )
    store_packer
     (.clk_i(aclk)
      ,.reset_i(~aresetn)

      ,.s_axil_awaddr_i(spack_axi_awaddr)
      ,.s_axil_awprot_i(spack_axi_awprot)
      ,.s_axil_awvalid_i(spack_axi_awvalid)
      ,.s_axil_awready_o(spack_axi_awready)

      ,.s_axil_wdata_i(spack_axi_wdata)
      ,.s_axil_wstrb_i(spack_axi_wstrb)
      ,.s_axil_wvalid_i(spack_axi_wvalid)
      ,.s_axil_wready_o(spack_axi_wready)

      ,.s_axil_bresp_o(spack_axi_bresp)
      ,.s_axil_bvalid_o(spack_axi_bvalid)
      ,.s_axil_bready_i(spack_axi_bready)

      ,.s_axil_araddr_i(spack_axi_araddr)
      ,.s_axil_arprot_i(spack_axi_arprot)
      ,.s_axil_arvalid_i(spack_axi_arvalid)
      ,.s_axil_arready_o(spack_axi_arready)

      ,.s_axil_rdata_o(spack_axi_rdata)
      ,.s_axil_rresp_o(spack_axi_rresp)
      ,.s_axil_rvalid_o(spack_axi_rvalid)
      ,.s_axil_rready_i(spack_axi_rready)

      ,.data_o(pl_to_ps_fifo_data_li[0])
      ,.v_o(pl_to_ps_fifo_v_li[0])
      ,.ready_i(pl_to_ps_fifo_ready_lo[0])

      ,.data_i(ps_to_pl_fifo_data_lo)
      ,.v_i(ps_to_pl_fifo_v_lo)
      ,.ready_o(ps_to_pl_fifo_ready_li)
      );

  bsg_axil_demux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(bp_axil_data_width_lp)
     // BP host address space is below this
     ,.split_addr_p(32'h0020_0000)
     )
   axil_demux
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.s00_axil_awaddr(bp_m_axil_awaddr)
     ,.s00_axil_awprot(bp_m_axil_awprot)
     ,.s00_axil_awvalid(bp_m_axil_awvalid)
     ,.s00_axil_awready(bp_m_axil_awready)
     ,.s00_axil_wdata(bp_m_axil_wdata)
     ,.s00_axil_wstrb(bp_m_axil_wstrb)
     ,.s00_axil_wvalid(bp_m_axil_wvalid)
     ,.s00_axil_wready(bp_m_axil_wready)
     ,.s00_axil_bresp(bp_m_axil_bresp)
     ,.s00_axil_bvalid(bp_m_axil_bvalid)
     ,.s00_axil_bready(bp_m_axil_bready)
     ,.s00_axil_araddr(bp_m_axil_araddr)
     ,.s00_axil_arprot(bp_m_axil_arprot)
     ,.s00_axil_arvalid(bp_m_axil_arvalid)
     ,.s00_axil_arready(bp_m_axil_arready)
     ,.s00_axil_rdata(bp_m_axil_rdata)
     ,.s00_axil_rresp(bp_m_axil_rresp)
     ,.s00_axil_rvalid(bp_m_axil_rvalid)
     ,.s00_axil_rready(bp_m_axil_rready)

     ,.m00_axil_awaddr(spack_axi_awaddr)
     ,.m00_axil_awprot(spack_axi_awprot)
     ,.m00_axil_awvalid(spack_axi_awvalid)
     ,.m00_axil_awready(spack_axi_awready)
     ,.m00_axil_wdata(spack_axi_wdata)
     ,.m00_axil_wstrb(spack_axi_wstrb)
     ,.m00_axil_wvalid(spack_axi_wvalid)
     ,.m00_axil_wready(spack_axi_wready)
     ,.m00_axil_bresp(spack_axi_bresp)
     ,.m00_axil_bvalid(spack_axi_bvalid)
     ,.m00_axil_bready(spack_axi_bready)
     ,.m00_axil_araddr(spack_axi_araddr)
     ,.m00_axil_arprot(spack_axi_arprot)
     ,.m00_axil_arvalid(spack_axi_arvalid)
     ,.m00_axil_arready(spack_axi_arready)
     ,.m00_axil_rdata(spack_axi_rdata)
     ,.m00_axil_rresp(spack_axi_rresp)
     ,.m00_axil_rvalid(spack_axi_rvalid)
     ,.m00_axil_rready(spack_axi_rready)

     ,.m01_axil_awaddr(m01_axi_awaddr)
     ,.m01_axil_awprot(m01_axi_awprot)
     ,.m01_axil_awvalid(m01_axi_awvalid)
     ,.m01_axil_awready(m01_axi_awready)
     ,.m01_axil_wdata(m01_axi_wdata)
     ,.m01_axil_wstrb(m01_axi_wstrb)
     ,.m01_axil_wvalid(m01_axi_wvalid)
     ,.m01_axil_wready(m01_axi_wready)
     ,.m01_axil_bresp(m01_axi_bresp)
     ,.m01_axil_bvalid(m01_axi_bvalid)
     ,.m01_axil_bready(m01_axi_bready)
     ,.m01_axil_araddr(m01_axi_araddr)
     ,.m01_axil_arprot(m01_axi_arprot)
     ,.m01_axil_arvalid(m01_axi_arvalid)
     ,.m01_axil_arready(m01_axi_arready)
     ,.m01_axil_rdata(m01_axi_rdata)
     ,.m01_axil_rresp(m01_axi_rresp)
     ,.m01_axil_rvalid(m01_axi_rvalid)
     ,.m01_axil_rready(m01_axi_rready)
     );


  // TODO: Bug in zero-extension of Xcelium 21.09
  wire [bp_axil_addr_width_lp-1:0] s02_awaddr_translated_lo = s02_axi_awaddr;
  wire [bp_axil_addr_width_lp-1:0] s02_araddr_translated_lo = s02_axi_araddr;

  bsg_axil_mux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(bp_axil_data_width_lp)
     )
   axil_mux
    (.clk_i(aclk)
     ,.reset_i(~aresetn)
     ,.s00_axil_awaddr (s01_awaddr_translated_lo)
     ,.s00_axil_awprot (s01_axi_awprot)
     ,.s00_axil_awvalid(s01_axi_awvalid)
     ,.s00_axil_awready(s01_axi_awready)
     ,.s00_axil_wdata  (s01_axi_wdata)
     ,.s00_axil_wstrb  (s01_axi_wstrb)
     ,.s00_axil_wvalid (s01_axi_wvalid)
     ,.s00_axil_wready (s01_axi_wready)
     ,.s00_axil_bresp  (s01_axi_bresp)
     ,.s00_axil_bvalid (s01_axi_bvalid)
     ,.s00_axil_bready (s01_axi_bready)
     ,.s00_axil_araddr (s01_araddr_translated_lo)
     ,.s00_axil_arprot (s01_axi_arprot)
     ,.s00_axil_arvalid(s01_axi_arvalid)
     ,.s00_axil_arready(s01_axi_arready)
     ,.s00_axil_rdata  (s01_axi_rdata)
     ,.s00_axil_rresp  (s01_axi_rresp)
     ,.s00_axil_rvalid (s01_axi_rvalid)
     ,.s00_axil_rready (s01_axi_rready)

     ,.s01_axil_awaddr (s02_awaddr_translated_lo)
     ,.s01_axil_awprot (s02_axi_awprot )
     ,.s01_axil_awvalid(s02_axi_awvalid)
     ,.s01_axil_awready(s02_axi_awready)
     ,.s01_axil_wdata  (s02_axi_wdata  )
     ,.s01_axil_wstrb  (s02_axi_wstrb  )
     ,.s01_axil_wvalid (s02_axi_wvalid )
     ,.s01_axil_wready (s02_axi_wready )
     ,.s01_axil_bresp  (s02_axi_bresp  )
     ,.s01_axil_bvalid (s02_axi_bvalid )
     ,.s01_axil_bready (s02_axi_bready )
     ,.s01_axil_araddr (s02_araddr_translated_lo)
     ,.s01_axil_arprot (s02_axi_arprot )
     ,.s01_axil_arvalid(s02_axi_arvalid)
     ,.s01_axil_arready(s02_axi_arready)
     ,.s01_axil_rdata  (s02_axi_rdata  )
     ,.s01_axil_rresp  (s02_axi_rresp  )
     ,.s01_axil_rvalid (s02_axi_rvalid )
     ,.s01_axil_rready (s02_axi_rready )

     ,.m00_axil_awaddr (bp_s_axil_awaddr)
     ,.m00_axil_awprot (bp_s_axil_awprot)
     ,.m00_axil_awvalid(bp_s_axil_awvalid)
     ,.m00_axil_awready(bp_s_axil_awready)
     ,.m00_axil_wdata  (bp_s_axil_wdata)
     ,.m00_axil_wstrb  (bp_s_axil_wstrb)
     ,.m00_axil_wvalid (bp_s_axil_wvalid)
     ,.m00_axil_wready (bp_s_axil_wready)
     ,.m00_axil_bresp  (bp_s_axil_bresp)
     ,.m00_axil_bvalid (bp_s_axil_bvalid)
     ,.m00_axil_bready (bp_s_axil_bready)
     ,.m00_axil_araddr (bp_s_axil_araddr)
     ,.m00_axil_arprot (bp_s_axil_arprot)
     ,.m00_axil_arvalid(bp_s_axil_arvalid)
     ,.m00_axil_arready(bp_s_axil_arready)
     ,.m00_axil_rdata  (bp_s_axil_rdata)
     ,.m00_axil_rresp  (bp_s_axil_rresp)
     ,.m00_axil_rvalid (bp_s_axil_rvalid)
     ,.m00_axil_rready (bp_s_axil_rready)
     );


   logic [bp_axi_addr_width_lp-1:0] axi_awaddr;
   logic [bp_axi_addr_width_lp-1:0] axi_araddr;

   // to translate from BP DRAM space to ARM PS DRAM space
   // we xor-subtract the BP DRAM base address (32'h8000_0000) and add the
   // ARM PS allocated memory space physical address.

   //always @(negedge aclk)
   //  begin
   //     if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
   //       $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
   //     if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
   //       $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
   //  end

   assign m00_axi_awaddr = (axi_awaddr ^ 32'h8000_0000) + dram_base_li;
   assign m00_axi_araddr = (axi_araddr ^ 32'h8000_0000) + dram_base_li;

   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(aclk)
      ,.reset_i(~aresetn)
      ,.data_i(mem_profiler_r
               | m00_axi_awvalid << (axi_awaddr[29-:7])
               | m00_axi_arvalid << (axi_araddr[29-:7])
               )
      ,.data_o(mem_profiler_r)
      );

   bp_axi_top #
     (.bp_params_p(bp_params_p)
      ,.m_axil_addr_width_p(bp_axil_addr_width_lp)
      ,.m_axil_data_width_p(bp_axil_data_width_lp)
      ,.s_axil_addr_width_p(bp_axil_addr_width_lp)
      ,.s_axil_data_width_p(bp_axil_data_width_lp)
      ,.axi_addr_width_p(bp_axi_addr_width_lp)
      ,.axi_data_width_p(bp_axi_data_width_lp)
      ,.axi_id_width_p(6)
      ,.axi_core_clk_async_p(1)
      )
   blackparrot
     (.axi_clk_i(aclk)
      ,.core_clk_i(bp_clk)
      ,.rt_clk_i(rt_clk)
      ,.async_reset_i(bp_async_reset_li)

      // these are reads/write from BlackParrot
      ,.m_axil_awaddr_o(bp_m_axil_awaddr)
      ,.m_axil_awprot_o(bp_m_axil_awprot)
      ,.m_axil_awvalid_o(bp_m_axil_awvalid)
      ,.m_axil_awready_i(bp_m_axil_awready)

      ,.m_axil_wdata_o(bp_m_axil_wdata)
      ,.m_axil_wstrb_o(bp_m_axil_wstrb)
      ,.m_axil_wvalid_o(bp_m_axil_wvalid)
      ,.m_axil_wready_i(bp_m_axil_wready)

      ,.m_axil_bresp_i(bp_m_axil_bresp)
      ,.m_axil_bvalid_i(bp_m_axil_bvalid)
      ,.m_axil_bready_o(bp_m_axil_bready)

      ,.m_axil_araddr_o(bp_m_axil_araddr)
      ,.m_axil_arprot_o(bp_m_axil_arprot)
      ,.m_axil_arvalid_o(bp_m_axil_arvalid)
      ,.m_axil_arready_i(bp_m_axil_arready)

      ,.m_axil_rdata_i(bp_m_axil_rdata)
      ,.m_axil_rresp_i(bp_m_axil_rresp)
      ,.m_axil_rvalid_i(bp_m_axil_rvalid)
      ,.m_axil_rready_o(bp_m_axil_rready)

      // these are reads/writes into BlackParrot
      // from the Zynq PS ARM core
      ,.s_axil_awaddr_i(bp_s_axil_awaddr)
      ,.s_axil_awprot_i(bp_s_axil_awprot)
      ,.s_axil_awvalid_i(bp_s_axil_awvalid)
      ,.s_axil_awready_o(bp_s_axil_awready)

      ,.s_axil_wdata_i(bp_s_axil_wdata)
      ,.s_axil_wstrb_i(bp_s_axil_wstrb)
      ,.s_axil_wvalid_i(bp_s_axil_wvalid)
      ,.s_axil_wready_o(bp_s_axil_wready)

      ,.s_axil_bresp_o(bp_s_axil_bresp)
      ,.s_axil_bvalid_o(bp_s_axil_bvalid)
      ,.s_axil_bready_i(bp_s_axil_bready)

      ,.s_axil_araddr_i(bp_s_axil_araddr)
      ,.s_axil_arprot_i(bp_s_axil_arprot)
      ,.s_axil_arvalid_i(bp_s_axil_arvalid)
      ,.s_axil_arready_o(bp_s_axil_arready)

      ,.s_axil_rdata_o(bp_s_axil_rdata)
      ,.s_axil_rresp_o(bp_s_axil_rresp)
      ,.s_axil_rvalid_o(bp_s_axil_rvalid)
      ,.s_axil_rready_i(bp_s_axil_rready)

      // BlackParrot DRAM memory system (output of bsg_cache_to_axi)
      ,.m_axi_awaddr_o(axi_awaddr)
      ,.m_axi_awvalid_o(m00_axi_awvalid)
      ,.m_axi_awready_i(m00_axi_awready)
      ,.m_axi_awid_o(m00_axi_awid)
      ,.m_axi_awlock_o(m00_axi_awlock)
      ,.m_axi_awcache_o(m00_axi_awcache)
      ,.m_axi_awprot_o(m00_axi_awprot)
      ,.m_axi_awlen_o(m00_axi_awlen)
      ,.m_axi_awsize_o(m00_axi_awsize)
      ,.m_axi_awburst_o(m00_axi_awburst)
      ,.m_axi_awqos_o(m00_axi_awqos)

      ,.m_axi_wdata_o(m00_axi_wdata)
      ,.m_axi_wvalid_o(m00_axi_wvalid)
      ,.m_axi_wready_i(m00_axi_wready)
      ,.m_axi_wid_o(m00_axi_wid)
      ,.m_axi_wlast_o(m00_axi_wlast)
      ,.m_axi_wstrb_o(m00_axi_wstrb)

      ,.m_axi_bvalid_i(m00_axi_bvalid)
      ,.m_axi_bready_o(m00_axi_bready)
      ,.m_axi_bid_i(m00_axi_bid)
      ,.m_axi_bresp_i(m00_axi_bresp)

      ,.m_axi_araddr_o(axi_araddr)
      ,.m_axi_arvalid_o(m00_axi_arvalid)
      ,.m_axi_arready_i(m00_axi_arready)
      ,.m_axi_arid_o(m00_axi_arid)
      ,.m_axi_arlock_o(m00_axi_arlock)
      ,.m_axi_arcache_o(m00_axi_arcache)
      ,.m_axi_arprot_o(m00_axi_arprot)
      ,.m_axi_arlen_o(m00_axi_arlen)
      ,.m_axi_arsize_o(m00_axi_arsize)
      ,.m_axi_arburst_o(m00_axi_arburst)
      ,.m_axi_arqos_o(m00_axi_arqos)

      ,.m_axi_rdata_i(m00_axi_rdata)
      ,.m_axi_rvalid_i(m00_axi_rvalid)
      ,.m_axi_rready_o(m00_axi_rready)
      ,.m_axi_rid_i(m00_axi_rid)
      ,.m_axi_rlast_i(m00_axi_rlast)
      ,.m_axi_rresp_i(m00_axi_rresp)
      );

`ifdef COV_EN
   // Coverage
   localparam cov_width_lp = 64;
   localparam cam_els_lp = 16;

   // reset generation
   logic bp_reset_li, ds_reset_li;
   bsg_sync_sync
    #(.width_p(1))
    bp_reset_bss
     (.oclk_i(bp_clk)
     ,.iclk_data_i(bp_async_reset_li)
     ,.oclk_data_o(bp_reset_li)
     );

   bsg_sync_sync
    #(.width_p(1))
    ds_reset_bss
     (.oclk_i(ds_clk)
     ,.iclk_data_i(bp_async_reset_li)
     ,.oclk_data_o(ds_reset_li)
     );

   // coverage valid when enabled
   bsg_sync_sync
    #(.width_p(1))
    cov_en_ds_bss
     (.oclk_i(ds_clk)
     ,.iclk_data_i(cov_en_li)
     ,.oclk_data_o(cov_en_sync_li)
     );

   // covergroup instances
   logic [num_cov_p-1:0][cov_width_lp-1:0] cov_li;
   logic [num_cov_p-1:0] cov_v_lo, cov_ready_li, cov_last_lo;
   logic [num_cov_p-1:0][C_DMA_AXIS_DATA_WIDTH-1:0] cov_data_lo;
   logic [num_cov_p-1:0][7:0] cov_els_lo;
   logic [num_cov_p-1:0][7:0] cov_len_lo;

`ifdef RAND_COV
   for(genvar i = 0; i < num_cov_p; i++) begin: rof
     // random covergroup input for testing
     bsg_lfsr
      #(.width_p(cov_width_lp))
      i_rand
       (.clk(bp_clk)
       ,.reset_i(bp_reset_li)
       ,.yumi_i(1'b1)
       ,.o(cov_li[i])
       );

     bsg_cover
      #(.id_p(i)
       ,.width_p(cov_width_lp)
       ,.els_p(cam_els_lp)
       ,.out_width_p(C_DMA_AXIS_DATA_WIDTH)
       ,.lg_afifo_size_p(3)
       ,.debug_p(1)
       )
      i_cov
       (.core_clk_i(bp_clk)
       ,.core_reset_i(bp_reset_li)

       ,.ds_clk_i(ds_clk)
       ,.ds_reset_i(ds_reset_li)

       ,.axi_clk_i(aclk)
       ,.axi_reset_i(bp_async_reset_li)

       ,.v_i(cov_en_sync_li)
       ,.data_i(cov_li[i])
       ,.ready_o()

       ,.gate_o(cov_gate_lo[i])

       ,.els_o(cov_els_lo[i])
       ,.len_o(cov_len_lo[i])

       ,.ready_i(cov_ready_li[i])
       ,.v_o(cov_v_lo[i])
       ,.last_o(cov_last_lo[i])
       ,.data_o(cov_data_lo[i])
       );
   end
`else
   // COVERAGE_MACRO
`endif

   bsg_cover_axis_packer
    #(.num_p(num_cov_p)
     ,.data_width_p(C_DMA_AXIS_DATA_WIDTH)
     )
    axis_packer
     (.ds_clk_i(ds_clk)
     ,.ds_reset_i(ds_reset_li)

     ,.axi_clk_i(aclk)
     ,.axi_reset_i(~aresetn)

     ,.els_i(cov_els_lo)
     ,.len_i(cov_len_lo)

     ,.gate_i(cov_gate_lo)

     ,.ready_o(cov_ready_li)
     ,.v_i(cov_v_lo)
     ,.last_i(cov_last_lo)
     ,.data_i(cov_data_lo)

     ,.tready_i(dma_axis_tready)
     ,.tvalid_o(dma_axis_tvalid)
     ,.tlast_o(dma_axis_tlast)
     ,.tdata_o(dma_axis_tdata)
     ,.tkeep_o(dma_axis_tkeep)
     );
`else
   assign dma_axis_tvalid = 1'b0;
   assign dma_axis_tlast = 1'b0;
   assign dma_axis_tdata = '0;
   assign dma_axis_tkeep = '0;
`endif

   // synopsys translate_off
   always @(negedge aclk)
     if (aresetn !== '0 & bb_v_li & ~bb_ready_and_lo == 1'b1)
       $error("top_zynq: bitbang bit drop occurred");

   always @(negedge aclk)
     if (s01_axi_awvalid & s01_axi_awready)
       if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,s01_awaddr_translated_lo);

   always @(negedge aclk)
     if (s01_axi_arvalid & s01_axi_arready)
       if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,s01_araddr_translated_lo);

   always @(negedge aclk)
     if (m00_axi_awvalid & m00_axi_awready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

   always @(negedge aclk)
     if (m00_axi_arvalid & m00_axi_arready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);
   // synopsys translate_on

endmodule
