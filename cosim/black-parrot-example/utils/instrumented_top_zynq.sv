
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
`ifdef COV_EN
   , parameter num_cov_p = `COV_NUM
`endif

   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   , parameter integer C_S00_AXI_DATA_WIDTH   = 32
   , parameter integer C_S00_AXI_ADDR_WIDTH   = 10
   , parameter integer C_S01_AXI_DATA_WIDTH   = 32
   // the ARM AXI S01 interface drops the top two bits
   , parameter integer C_S01_AXI_ADDR_WIDTH   = 30
   , parameter integer C_S02_AXI_DATA_WIDTH   = 32
   , parameter integer C_S02_AXI_ADDR_WIDTH   = 28
   , parameter integer C_M00_AXI_DATA_WIDTH   = 64
   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M01_AXI_DATA_WIDTH   = 32
   , parameter integer C_M01_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M02_AXI_DATA_WIDTH   = 32
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

   , input wire                                  m02_axis_tready
   , output wire                                 m02_axis_tvalid
   , output wire [C_M02_AXI_DATA_WIDTH-1 : 0]    m02_axis_tdata
   , output wire [(C_M02_AXI_DATA_WIDTH/8)-1:0]  m02_axis_tkeep
   , output wire                                 m02_axis_tlast
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
   localparam num_fifo_pl_to_ps_lp = 1;

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

`ifdef COV_EN
   logic cov_en_sync_li;
   logic [num_cov_p-1:0] cov_gate_lo;
   wire gate_lo = cov_en_sync_li & (|cov_gate_lo);
`else
   wire gate_lo = 1'b0;
`endif

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
`elsif 7SERIES
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
`else
   bsg_icg_pos
    clk_buf
     (.clk_i(ds_clk)
     ,.en_i(~gate_lo)
     ,.clk_o(bp_clk)
     );
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

      ,.data_o(pl_to_ps_fifo_data_li)
      ,.v_o(pl_to_ps_fifo_v_li)
      ,.ready_i(pl_to_ps_fifo_ready_lo)

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
   localparam cov_id_width_lp = 8;
   localparam cov_els_width_lp = 8;
   localparam cov_len_width_lp = 8;

   localparam cov_width_lp = 64;
   localparam cam_els_lp = 24;

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
   logic [num_cov_p-1:0] cov_v_lo, cov_ready_li, cov_id_v_lo, cov_last_lo;
   logic [num_cov_p-1:0][C_M02_AXI_DATA_WIDTH-1:0] cov_data_lo;
   logic [num_cov_p-1:0][cov_id_width_lp-1:0] cov_id_lo;
   logic [num_cov_p-1:0][cov_els_width_lp-1:0] cov_els_lo;
   logic [num_cov_p-1:0][cov_len_width_lp-1:0] cov_len_lo;

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
       ,.out_width_p(C_M02_AXI_DATA_WIDTH)
       ,.id_width_p(cov_id_width_lp)
       ,.len_width_p(cov_len_width_lp)
       ,.els_width_p(cov_els_width_lp)
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

       ,.drain_i(1'b0)
       ,.gate_o(cov_gate_lo[i])

       ,.id_v_o(cov_id_v_lo[i])
       ,.id_o(cov_id_lo[i])
       ,.els_o(cov_els_lo[i])
       ,.len_o(cov_len_lo[i])

       ,.ready_i(cov_ready_li[i])
       ,.v_o(cov_v_lo[i])
       ,.v_o(cov_last_lo[i])
       ,.data_o(cov_data_lo[i])
       );
   end
`else
  wire [24-1:0] cov_0_lo; 
  bsg_cover_realign 
    #(.num_p              (24) 
     ,.num_chain_p        (1) 
     ,.chain_offset_arr_p ({10'd0}) 
     ,.chain_depth_arr_p  ({10'd0}) 
     ,.step_p             (10)) 
   realign_0
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( `COREPATH.be.calculator.pipe_int_early.btaken_o )
				, ( `COREPATH.be.calculator.pipe_int_early.decode.compressed )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081272) ||  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081280) )
				, ( ((`COREPATH.be.calculator.pipe_int_early.bclzh.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_int_early.bclzh.pe0.b.i) == 718081800 )
				, ( ((`COREPATH.be.calculator.pipe_int_early.bclzl.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_int_early.bclzl.pe0.b.i) == 718081792 )
				, (  !  `COREPATH.be.calculator.pipe_int_early.clzh[5] )
				, ( (64 -  39) >  0 )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.src1_sel == 718081232) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.src1_sel == 718081200) & `COREPATH.be.calculator.pipe_int_early.decode.irs1_r_v )
				, ( `COREPATH.be.calculator.pipe_int_early.opw_v )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081320) ||  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081328) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081344) )
				, ( `COREPATH.be.calculator.pipe_int_early.decode.j_v |  `COREPATH.be.calculator.pipe_int_early.decode.jr_v )
				, (  ( `COREPATH.be.calculator.pipe_int_early.box.tag_i == 718081776) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081376) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.box.tag_i == 718081760) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081432) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.box.tag_i == 718081768) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081384) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081424) )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081392) ||  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081400) ||  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081408) ||  ( `COREPATH.be.calculator.pipe_int_early.decode.fu_op == 718081416) & `COREPATH.be.calculator.pipe_int_early.comp_result )
				, ( `COREPATH.be.calculator.pipe_int_early.decode.jr_v )
				, ( `COREPATH.be.calculator.pipe_int_early.decode.irs2_r_v )
				, (  ( `COREPATH.be.calculator.pipe_int_early.decode.src2_sel == 718081240) & `COREPATH.be.calculator.pipe_int_early.decode.irs2_r_v )
      }) 
    ,.data_o           (cov_0_lo) 
    );

  bsg_cover 
    #(.id_p            (0) 
     ,.width_p         (24) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_0
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_0_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[0]) 
    ,.id_v_o           (cov_id_v_lo[0]) 
    ,.id_o             (cov_id_lo[0]) 
    ,.els_o            (cov_els_lo[0]) 
    ,.len_o            (cov_len_lo[0]) 
    ,.ready_i          (cov_ready_li[0]) 
    ,.v_o              (cov_v_lo[0]) 
    ,.last_o           (cov_last_lo[0]) 
    ,.data_o           (cov_data_lo[0]) 
    );

  wire [144-1:0] cov_1_lo; 
  bsg_cover_realign 
    #(.num_p              (144) 
     ,.num_chain_p        (5) 
     ,.chain_offset_arr_p ({10'd143, 10'd121, 10'd99, 10'd66, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd4, 10'd3, 10'd2, 10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_1
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.exception_v_lo |  `COREPATH.be.calculator.pipe_sys.csr.interrupt_v_lo )
				, ( `COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.instret )
				, ( `COREPATH.be.calculator.pipe_sys.csr.enter_debug |  `COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.queue_v &  `COREPATH.be.calculator.pipe_sys.csr.dcsr_lo.step) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.s_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.sgie) & (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.mtvec_r.word_addr)) >  0 )
				, ( (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.dpc_r)) >  0 )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.stvec_r.word_addr)) >  0 )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.sepc_r.word_addr)) >  0 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131760 ,  929131768 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131200 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131272 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131448 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131424 }) )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131408 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131384 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131304 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131208 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131392 }) )
				, ( (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.mtval_r)) >  0 )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131360 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131344 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131216 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131328 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131400 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131488 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131248 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131512 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131320 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131256 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131264 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131440 }) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.is_debug_mode )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131464 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dret) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131480 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131296 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131336 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131232 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131288 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131416 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131224 }) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.mret )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131280 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131504 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131352 }) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.priv_mode_n == 929131192 )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131432 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131472 }) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.sret )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.mret) )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.mepc_r.word_addr)) >  0 )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131456 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131240 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131368 }) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.commit_pkt_cast_o.eret )
				, ( (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.stval_r)) >  0 )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131376 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131312 }) )
				, (  ( `COREPATH.be.calculator.pipe_sys.csr.csr_r_addr_i == {929131496 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131760 ,  929131768 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dret) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131728 ,  929131736 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.s_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.sgie) & (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131840 ,  929131848 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131664 ,  929131672 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131968 ,  929131976 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131984 ,  929131992 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131824 ,  929131832 }) )
				, ( ( ~  (`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li &  (`COREPATH.be.calculator.pipe_sys.csr.csr_addr_li inside { 929132096 ,  929132104 }))) )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.mcause_exception_enc.b.i -  1) &  `COREPATH.be.calculator.pipe_sys.csr.mcause_exception_enc.b.i) == 929134168 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131808 ,  929131816 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131552 ,  929131560 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) & `COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li == 2 )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.apc_r)) >  0 )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.s_interrupt_enc.b.i -  1) &  `COREPATH.be.calculator.pipe_sys.csr.s_interrupt_enc.b.i) == 929134832 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131920 ,  929131928 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929132064 ,  929132072 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131872 ,  929131880 }) )
				, ( `COREPATH.be.calculator.pipe_sys.retire_v_i )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131904 ,  929131912 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929132048 ,  929132056 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929132000 ,  929132008 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131568 ,  929131576 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.apc_r)) >  0 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131952 ,  929131960 }) )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_enc.b.i -  1) &  `COREPATH.be.calculator.pipe_sys.csr.m_interrupt_enc.b.i) == 929134176 )
				, ( `COREPATH.be.calculator.pipe_sys.instret_li )
				, ( (62 -  62) >  0 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131680 ,  929131688 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131888 ,  929131896 }) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.priv_mode_n == 929131192 )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.mret )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.s_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.sgie) & (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.sepc_r.word_addr)) >  0 )
				, ( `COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.instret )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.stvec_r.word_addr)) >  0 )
				, ( `COREPATH.be.calculator.pipe_sys.csr.exception_v_lo |  `COREPATH.be.calculator.pipe_sys.csr.interrupt_v_lo )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.queue_v &  `COREPATH.be.calculator.pipe_sys.csr.dcsr_lo.step) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.enter_debug |  `COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( `COREPATH.be.calculator.pipe_sys.csr.commit_pkt_cast_o.eret )
				, ( `COREPATH.be.calculator.pipe_sys.csr.is_debug_mode )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.mret) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dret) )
				, ( (62 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.mtvec_r.word_addr)) >  0 )
				, ( `COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.sret )
				, ( (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.dpc_r)) >  0 )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.apc_r)) >  0 )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.apc_r)) >  0 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131648 ,  929131656 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929132032 ,  929132040 }) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131776 ,  929131784 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (62 -  62) >  0 )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.mret) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.sret) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.queue_v &  `COREPATH.be.calculator.pipe_sys.csr.dcsr_lo.step) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.core_npc)) >  0 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131856 ,  929131864 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.queue_v &  `COREPATH.be.calculator.pipe_sys.csr.dcsr_lo.step) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.sret) & `COREPATH.be.calculator.pipe_sys.csr.priv_mode_n <  929132088 )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.s_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.sgie) & (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929132016 ,  929132024 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.dbreak) & ((`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt &  `COREPATH.be.calculator.pipe_sys.csr.d_interrupt_icode_v_li) &  `COREPATH.be.calculator.pipe_sys.csr.dgie) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.medeleg_lo[`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_li] &  ( ~  `COREPATH.be.calculator.pipe_sys.csr.is_m_mode)) & (`COREPATH.be.calculator.pipe_sys.csr.is_debug_mode) & (`COREPATH.be.calculator.pipe_sys.csr.exception_ecode_v_li) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.apc_r)) >  0 )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.s_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.sgie) & (`COREPATH.be.calculator.pipe_sys.csr.m_interrupt_icode_v_li &  `COREPATH.be.calculator.pipe_sys.csr.mgie) & (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.exception._interrupt) & (64 -  $bits(`COREPATH.be.calculator.pipe_sys.csr.apc_r)) >  0 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131696 ,  929131704 }) )
				, ( (`COREPATH.be.calculator.pipe_sys.csr.retire_pkt_cast_i.special.mret) & `COREPATH.be.calculator.pipe_sys.csr.priv_mode_n <  929132080 )
				, (  ( {`COREPATH.be.calculator.pipe_sys.csr.csr_w_v_li ,  `COREPATH.be.calculator.pipe_sys.csr.csr_addr_li } == {929131760 ,  929131768 }) )
      }) 
    ,.data_o           (cov_1_lo) 
    );

  bsg_cover 
    #(.id_p            (1) 
     ,.width_p         (144) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_1
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_1_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[1]) 
    ,.id_v_o           (cov_id_v_lo[1]) 
    ,.id_o             (cov_id_lo[1]) 
    ,.els_o            (cov_els_lo[1]) 
    ,.len_o            (cov_len_lo[1]) 
    ,.ready_i          (cov_ready_li[1]) 
    ,.v_o              (cov_v_lo[1]) 
    ,.last_o           (cov_last_lo[1]) 
    ,.data_o           (cov_data_lo[1]) 
    );

  wire [67-1:0] cov_2_lo; 
  bsg_cover_realign 
    #(.num_p              (67) 
     ,.num_chain_p        (1) 
     ,.chain_offset_arr_p ({10'd0}) 
     ,.chain_depth_arr_p  ({10'd1}) 
     ,.step_p             (10)) 
   realign_2
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( ((`COREPATH.be.calculator.pipe_aux.fp_box.in64_rec.clz.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_aux.fp_box.in64_rec.clz.pe0.b.i) == -887501344 )
				, ( `COREPATH.be.calculator.pipe_aux.invbox_frs2 )
				, ( `COREPATH.be.calculator.pipe_aux.invbox_frs1 )
				, ( `COREPATH.be.calculator.pipe_aux.fp_box.special )
				, ( `COREPATH.be.calculator.pipe_aux.fp_box.encode_as_sp )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.notNaN_isInfOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.pegMaxFiniteMagOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.pegMinNonzeroMagOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.recover.isNaN )
				, ( `COREPATH.be.calculator.pipe_aux.f2dw.sign )
				, ( `COREPATH.be.calculator.pipe_aux.fp_box.in64_rec.isZeroExpIn )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.isNaNOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.recover.isInf )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.tag_i == -887502816 )
				, ( (( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.isNaNOut) && ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.in_isZero)) && ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.common_totalUnderflow) )
				, (  ( `COREPATH.be.calculator.pipe_aux.int_box.tag_i == -887503416) )
				, ( (`COREPATH.be.calculator.pipe_aux.feq_lo) & (( ~  `COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan) &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  ( ~  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan)) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) & `COREPATH.be.calculator.pipe_aux.is_fmin_li ^  `COREPATH.be.calculator.pipe_aux.frs1_raw.sign )
				, (  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503792) )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.doShiftSigDown1 )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.recover.isZero )
				, (  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503752) ||  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503744) )
				, (  ( `COREPATH.be.calculator.pipe_aux.int_box.tag_i == -887503408) )
				, ( `COREPATH.be.calculator.pipe_aux.f2dw.roundIncr ^  `COREPATH.be.calculator.pipe_aux.f2dw.sign )
				, (  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503736) ||  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503728) ||  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503720) )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.isNaNOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.in_isZero || `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.common_totalUnderflow )
				, ( ((`COREPATH.be.calculator.pipe_aux.fp_box.in32_rec.clz.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_aux.fp_box.in32_rec.clz.pe0.b.i) == -887501352 )
				, (  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503760) )
				, (  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503768) )
				, ( (`COREPATH.be.calculator.pipe_aux.feq_lo) & (( ~  `COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan) &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  ( ~  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan)) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) & `COREPATH.be.calculator.pipe_aux.is_fmax_li ^  `COREPATH.be.calculator.pipe_aux.flt_lo )
				, ( `COREPATH.be.calculator.pipe_aux.opw_v )
				, ( `COREPATH.be.calculator.pipe_aux.f2dw.magGeOne )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.doShiftSigDown1 )
				, ( `COREPATH.be.calculator.pipe_aux.decode.fmove_v )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.iNToRawFN.sign )
				, ( ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.in_isZero) && ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.common_totalUnderflow) )
				, (  ( `COREPATH.be.calculator.pipe_aux.int_box.tag_i == -887503424) )
				, ( `COREPATH.be.calculator.pipe_aux.f2w.sign )
				, ( `COREPATH.be.calculator.pipe_aux.f2dw.invalidExc || `COREPATH.be.calculator.pipe_aux.f2dw.common_overflow )
				, ( `COREPATH.be.calculator.pipe_aux.f2w.invalidExc || `COREPATH.be.calculator.pipe_aux.f2w.common_overflow )
				, ( `COREPATH.be.calculator.pipe_aux.instr.t.fmatype.rm == -887503824 )
				, ( (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  ( ~  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan)) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.isNaNOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.notNaN_isInfOut )
				, ( (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) )
				, ( ( !  `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.in_isZero) && ( !  `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.common_totalUnderflow) )
				, ( (( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.isNaNOut) && ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.in_isZero)) && ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.common_totalUnderflow) )
				, ( (( !  `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.isNaNOut) && ( !  `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.in_isZero)) && ( !  `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.common_totalUnderflow) )
				, ( 1 )
				, ( (( ~  `COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan) &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  ( ~  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan)) & (`COREPATH.be.calculator.pipe_aux.frs1_raw.is_nan &  `COREPATH.be.calculator.pipe_aux.frs2_raw.is_nan) )
				, (  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503784) ||  ( `COREPATH.be.calculator.pipe_aux.decode.fu_op == -887503776) )
				, ( ((`COREPATH.be.calculator.pipe_aux.i2f.iNToRawFN.clz.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_aux.i2f.iNToRawFN.clz.pe0.b.i) == -887502480 )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.in_isZero || `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.common_totalUnderflow )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.pegMinNonzeroMagOut )
				, ( `COREPATH.be.calculator.pipe_aux.fp_box.in32_rec.isZeroExpIn )
				, ( `COREPATH.be.calculator.pipe_aux.decode.irf_w_v )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.pegMaxFiniteMagOut )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.notNaN_isInfOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.tag_i == -887502808 )
				, ( 0 )
				, ( `COREPATH.be.calculator.pipe_aux.f2w.magGeOne )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.doShiftSigDown1 )
				, ( `COREPATH.be.calculator.pipe_aux.f2w.roundIncr ^  `COREPATH.be.calculator.pipe_aux.f2w.sign )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.pegMaxFiniteMagOut )
				, ( `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.in_isZero || `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round32.common_totalUnderflow )
				, ( `COREPATH.be.calculator.pipe_aux.i2f.roundRawToOut.pegMinNonzeroMagOut )
				, ( ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.in_isZero) && ( !  `COREPATH.be.calculator.pipe_aux.rebox.round_mixed.round64.common_totalUnderflow) )
      }) 
    ,.data_o           (cov_2_lo) 
    );

  bsg_cover 
    #(.id_p            (2) 
     ,.width_p         (67) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_2
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_2_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[2]) 
    ,.id_v_o           (cov_id_v_lo[2]) 
    ,.id_o             (cov_id_lo[2]) 
    ,.els_o            (cov_els_lo[2]) 
    ,.len_o            (cov_len_lo[2]) 
    ,.ready_i          (cov_ready_li[2]) 
    ,.v_o              (cov_v_lo[2]) 
    ,.last_o           (cov_last_lo[2]) 
    ,.data_o           (cov_data_lo[2]) 
    );

  wire [166-1:0] cov_3_lo; 
  bsg_cover_realign 
    #(.num_p              (166) 
     ,.num_chain_p        (9) 
     ,.chain_offset_arr_p ({10'd160, 10'd153, 10'd138, 10'd132, 10'd105, 10'd70, 10'd60, 10'd32, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd8, 10'd7, 10'd6, 10'd5, 10'd4, 10'd3, 10'd2, 10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_3
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.bypass_n )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[3].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[5].data_mem.ram.ena) )
				, ( ((`COREPATH.be.calculator.pipe_mem.dcache.pe_invalid.b.i -  1) &  `COREPATH.be.calculator.pipe_mem.dcache.pe_invalid.b.i) == 139258992 )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.lru_encoder.lru.rank[1].nz.mux.sel_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.bypass_r )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.lru_encoder.lru.rank[2].nz.mux.sel_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf_data_in_mux.sel_one_hot_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[2].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.sc_success_tv )
				, (  ( `COREPATH.be.calculator.pipe_mem.int_box.tag_i == 139258592) )
				, (  ( `COREPATH.be.calculator.pipe_mem.int_box.tag_i == 182077584) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.ram.ram.enb) )
				, (  ( `COREPATH.be.calculator.pipe_mem.int_box.tag_i == 186781048) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.decode_tv_r.amo_op )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.llr.dff_bypass.en_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.sc_fail_tv )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[4].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[0].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.llr.dff_bypass.dff.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.ram.ram.enb) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[7].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.w_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.llr.dff_bypass.dff.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[6].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.w_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.bypass_n )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.metadata_hit_r )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.llr.dff_bypass.en_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.bypass_r )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.metadata_invalid_exist )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[1].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.bypass_n )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.ram.ram.enb) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.bypass_n )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.w_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.ram.ram.enb) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.write_regs.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.bypass_r )
				, ( ((`COREPATH.be.calculator.pipe_mem.dcache.store_hit_index_encoder.i -  1) &  `COREPATH.be.calculator.pipe_mem.dcache.store_hit_index_encoder.i) == 190807760 )
				, ( ((`COREPATH.be.calculator.pipe_mem.dcache.load_hit_index_encoder.i -  1) &  `COREPATH.be.calculator.pipe_mem.dcache.load_hit_index_encoder.i) == 190804760 )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.decode_tv_r.store_op )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.v_tv_r )
				, (  ( {`COREPATH.be.calculator.pipe_mem.dcache.v_tv_r ,  `COREPATH.be.calculator.pipe_mem.dcache.stat_mem_pkt_cast_i.opcode } == {185795920 ,  2 }) )
				, (  ( `COREPATH.be.calculator.pipe_mem.int_box.tag_i == 186781048) )
				, (  ( `COREPATH.be.calculator.pipe_mem.int_box.tag_i == 139258592) )
				, ( ((`COREPATH.be.calculator.pipe_mem.fp_box.in64_rec.clz.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_mem.fp_box.in64_rec.clz.pe0.b.i) == 168092248 )
				, ( ((`COREPATH.be.calculator.pipe_mem.fp_box.in32_rec.clz.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_mem.fp_box.in32_rec.clz.pe0.b.i) == 186073232 )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.sc_fail_tv )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.sc_success_tv )
				, ( `COREPATH.be.calculator.pipe_mem.fp_box.in32_rec.isZeroExpIn )
				, (  ( {`COREPATH.be.calculator.pipe_mem.dcache.v_tv_r ,  `COREPATH.be.calculator.pipe_mem.dcache.stat_mem_pkt_cast_i.opcode } == {185795632 ,  0 }) )
				, ( `COREPATH.be.calculator.pipe_mem.fp_box.special )
				, ( `COREPATH.be.calculator.pipe_mem.fp_box.encode_as_sp )
				, ( `COREPATH.be.calculator.pipe_mem.dcache_float )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.w_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.write_regs.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.int_box.tag_i == 182077584) )
				, ( `COREPATH.be.calculator.pipe_mem.fp_box.in64_rec.isZeroExpIn )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.bypass_r )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.write_regs.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.bypass_r )
				, (  ( {`COREPATH.be.calculator.pipe_mem.dcache.v_tv_r ,  `COREPATH.be.calculator.pipe_mem.dcache.stat_mem_pkt_cast_i.opcode } == {185795632 ,  0 }) )
				, ( ((`COREPATH.be.calculator.pipe_mem.dcache.is_primary &  `COREPATH.be.calculator.pipe_mem.dcache.v_tv_r) &  `COREPATH.be.calculator.pipe_mem.dcache.any_miss_tv) & (`COREPATH.be.calculator.pipe_mem.dcache.is_ready &  `COREPATH.be.calculator.pipe_mem.dcache.blocking_sent) & (( !  `COREPATH.be.calculator.pipe_mem.dcache.is_ready) &  `COREPATH.be.calculator.pipe_mem.dcache.complete_recv) )
				, ( (( !  `COREPATH.be.calculator.pipe_mem.dcache.is_ready) &  `COREPATH.be.calculator.pipe_mem.dcache.complete_recv) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.v_tv_r )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.stat_mem.from1r1w.ram.write_regs.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.is_ready &  `COREPATH.be.calculator.pipe_mem.dcache.blocking_sent) & (( !  `COREPATH.be.calculator.pipe_mem.dcache.is_ready) &  `COREPATH.be.calculator.pipe_mem.dcache.complete_recv) & ( !  185276208) |  `COREPATH.be.calculator.pipe_mem.dcache.decode_tv_r.cache_op )
				, (  ( {`COREPATH.be.calculator.pipe_mem.dcache.v_tv_r ,  `COREPATH.be.calculator.pipe_mem.dcache.stat_mem_pkt_cast_i.opcode } == {185795920 ,  2 }) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tag_mem.from1r1w.ram.bypass_r )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.mshr_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.ld_data_set_select_mux.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.dword_mux.sel_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf_data_mem_mask_in_mux.sel_one_hot_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[2].tag_r_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf_data_in_mux.sel_one_hot_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[7].tag_r_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_med.sel_one_hot_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.entry_reg.bypass.data_reg.dff.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.mem_array_4k[0].mem_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[1].tag_r_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[4].tag_r_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.tv_snoop_mux.sel_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[3].tag_r_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_high.sel_one_hot_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[5].tag_r_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[6].tag_r_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[3].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[6].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.mux1_sel )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_low.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.entry_reg.bypass.data_reg.en_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_4k.nz.tag_array[0].tag_r_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[1].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.trans_r )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.vtag_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[2].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[7].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[5].data_mem.ram.ena) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[4].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.decode_tv_r.double_op )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.decode_tv_r.amo_op )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.d[0].data_mem.ram.ena) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.bypass_mux_segmented.sel_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_1g.nz.tag_array[0].tag_r_reg.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 193499136) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 201439880) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_low.sel_one_hot_i )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186377784) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 158985976) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_2m.nz.tag_array[0].tag_r_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_1g.nz.tag_array[0].tag_r_reg.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185278432) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796312) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_high.sel_one_hot_i )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186074432) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185278424) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185278392) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185278384) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796368) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 164473216) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry1_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.w_v_i )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186779744) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 158986152) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796008) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796320) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796304) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796272) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 182082016) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796552) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185276408) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 139256800) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 158982768) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 189232912) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277504) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 188460824) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796608) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185276488) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796632) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796640) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277480) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 182078448) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796672) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796688) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277464) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186076024) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796704) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186778120) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796336) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796576) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186779616) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 164471336) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_med.sel_one_hot_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_2m.nz.tag_array[1].tag_r_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.mux_segmented_merge1.sel_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.mux_segmented_merge0.sel_i )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry0_reg.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796384) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186073352) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186073528) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796352) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.mshr_reg.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 201439880) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 193499136) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.tlb.tag_array_1g.nz.tag_array[0].tag_r_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.mux0_sel )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry0_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.entry_reg.bypass.data_reg.en_i )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_high.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_low.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.trans_r )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796576) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186779616) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 164471336) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.mshr_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dmmu.entry_reg.bypass.data_reg.dff.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 193499136) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 201439880) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry0_reg.en_i) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry1_reg.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 182082016) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796552) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185276408) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 139256800) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 158982768) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 189232912) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277504) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 188460824) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796608) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185276488) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796632) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796640) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277480) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 182078448) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796672) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796688) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277464) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186076024) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796704) )
				, ( 0 )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_med.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_high.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.hum.fill_v )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry0_reg.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_med.sel_one_hot_i )
				, ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.mux0_sel )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.l1_lrsc.load_reserved_addr.en_i) )
				, ( `COREPATH.be.calculator.pipe_mem.dmmu.tlb.one_hot_sel_low.sel_one_hot_i )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 193499136) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796576) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186779616) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 164471336) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.wbuf.num_els_r == 201439880) )
				, ( (`COREPATH.be.calculator.pipe_mem.dcache.wbuf.wbuf_entry0_reg.en_i) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 182082016) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796552) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185276408) )
				, (  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 139256800) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 158982768) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 189232912) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277504) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 188460824) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796608) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185276488) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796632) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796640) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277480) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 182078448) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796672) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796688) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185277464) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 186076024) ||  ( `COREPATH.be.calculator.pipe_mem.dcache.pkt_decoder.pkt_cast_i.opcode == 185796704) )
      }) 
    ,.data_o           (cov_3_lo) 
    );

  bsg_cover 
    #(.id_p            (3) 
     ,.width_p         (166) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_3
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_3_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[3]) 
    ,.id_v_o           (cov_id_v_lo[3]) 
    ,.id_o             (cov_id_lo[3]) 
    ,.els_o            (cov_els_lo[3]) 
    ,.len_o            (cov_len_lo[3]) 
    ,.ready_i          (cov_ready_li[3]) 
    ,.v_o              (cov_v_lo[3]) 
    ,.last_o           (cov_last_lo[3]) 
    ,.data_o           (cov_data_lo[3]) 
    );

  wire [47-1:0] cov_4_lo; 
  bsg_cover_realign 
    #(.num_p              (47) 
     ,.num_chain_p        (2) 
     ,.chain_offset_arr_p ({10'd16, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd3, 10'd2}) 
     ,.step_p             (10)) 
   realign_4
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_preMul.doSubMags )
				, ( (`COREPATH.be.calculator.pipe_fma.is_fmsub_li |  `COREPATH.be.calculator.pipe_fma.is_fsub_li) & ((`COREPATH.be.calculator.pipe_fma.is_fmadd_li |  `COREPATH.be.calculator.pipe_fma.is_fadd_li) |  `COREPATH.be.calculator.pipe_fma.is_fmul_li) )
				, ( (`COREPATH.be.calculator.pipe_fma.is_fnmadd_li) & (`COREPATH.be.calculator.pipe_fma.is_fnmsub_li) & (`COREPATH.be.calculator.pipe_fma.is_fmsub_li |  `COREPATH.be.calculator.pipe_fma.is_fsub_li) & ((`COREPATH.be.calculator.pipe_fma.is_fmadd_li |  `COREPATH.be.calculator.pipe_fma.is_fadd_li) |  `COREPATH.be.calculator.pipe_fma.is_fmul_li) )
				, ( ((`COREPATH.be.calculator.pipe_fma.is_fmadd_li |  `COREPATH.be.calculator.pipe_fma.is_fadd_li) |  `COREPATH.be.calculator.pipe_fma.is_fmul_li) )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_preMul.op[2] )
				, ( `COREPATH.be.calculator.pipe_fma.decode.irs2_r_v )
				, (  ( `COREPATH.be.calculator.pipe_fma.imul_box.tag_i == 152630168) )
				, ( `COREPATH.be.calculator.pipe_fma.decode.irs1_r_v )
				, ( `COREPATH.be.calculator.pipe_fma.negate_sign )
				, (  ( `COREPATH.be.calculator.pipe_fma.imul_box.tag_i == 152630184) )
				, ( `COREPATH.be.calculator.pipe_fma.is_faddsub_li )
				, ( (`COREPATH.be.calculator.pipe_fma.is_fnmsub_li) & (`COREPATH.be.calculator.pipe_fma.is_fmsub_li |  `COREPATH.be.calculator.pipe_fma.is_fsub_li) & ((`COREPATH.be.calculator.pipe_fma.is_fmadd_li |  `COREPATH.be.calculator.pipe_fma.is_fadd_li) |  `COREPATH.be.calculator.pipe_fma.is_fmul_li) )
				, (  ( `COREPATH.be.calculator.pipe_fma.imul_box.tag_i == 152630176) )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_preMul.isMinCAlign )
				, ( `COREPATH.be.calculator.pipe_fma.is_fmul_li )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_preMul.posNatCAlignDist <  (162 -  1) )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.notNaN_isInfOut )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.pegMinNonzeroMagOut )
				, ( ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.in_isZero) && ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.common_totalUnderflow) )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.notNaN_isInfOut )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.pegMaxFiniteMagOut )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.in_isZero || `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.common_totalUnderflow )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.doSubMags )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.tag_i == 152630504 )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.isNaNOut )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.CIsDominant )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.mulAddResult[106] )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.doShiftSigDown1 )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.notCDom_signSigSum )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_preMul.CIsDominant )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.pegMinNonzeroMagOut )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.notCDom_completeCancellation )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.recover.isZero )
				, ( 0 )
				, ( (( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.isNaNOut) && ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.in_isZero)) && ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.common_totalUnderflow) )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.in_isZero || `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.common_totalUnderflow )
				, ( ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.in_isZero) && ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.common_totalUnderflow) )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.tag_i == 152630496 )
				, ( ((`COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.clz.pe0.b.i -  1) &  `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_postMul.clz.pe0.b.i) == 152630512 )
				, ( `COREPATH.be.calculator.pipe_fma.instr.t.fmatype.rm == 152629872 )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.recover.isNaN )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.isNaNOut )
				, ( (( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.isNaNOut) && ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.in_isZero)) && ( !  `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.common_totalUnderflow) )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.recover.isInf )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round32.doShiftSigDown1 )
				, ( `COREPATH.be.calculator.pipe_fma.rebox.round_mixed.round64.pegMaxFiniteMagOut )
				, ( `COREPATH.be.calculator.pipe_fma.fma.mulAddToRaw_preMul.doSubMags )
      }) 
    ,.data_o           (cov_4_lo) 
    );

  bsg_cover 
    #(.id_p            (4) 
     ,.width_p         (47) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_4
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_4_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[4]) 
    ,.id_v_o           (cov_id_v_lo[4]) 
    ,.id_o             (cov_id_lo[4]) 
    ,.els_o            (cov_els_lo[4]) 
    ,.len_o            (cov_len_lo[4]) 
    ,.ready_i          (cov_ready_li[4]) 
    ,.v_o              (cov_v_lo[4]) 
    ,.last_o           (cov_last_lo[4]) 
    ,.data_o           (cov_data_lo[4]) 
    );

  wire [83-1:0] cov_5_lo; 
  bsg_cover_realign 
    #(.num_p              (83) 
     ,.num_chain_p        (3) 
     ,.chain_offset_arr_p ({10'd80, 10'd44, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd2, 10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_5
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( (`COREPATH.be.scheduler.int_regfile.bypass[1].rs_data_reg.en_i) )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[0].fwd_rs_r )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[1].zero_rs_r )
				, ( `COREPATH.be.scheduler.ptw.walk_start )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[1].zero_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[2].fwd_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[2].zero_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[1].fwd_rs_r )
				, ( (`COREPATH.be.scheduler.fp_regfile.bypass[2].rs_data_reg.en_i) )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[0].fwd_rs_r )
				, ( `COREPATH.be.scheduler.ptw_v_lo )
				, ( `COREPATH.be.scheduler.ptw.walk_en )
				, ( `COREPATH.be.scheduler.writeback_v )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[1].fwd_rs_r )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[0].zero_rs_r )
				, ( `COREPATH.be.scheduler.ptw.walk_done )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 215848288) ||  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 215848296) )
				, ( `COREPATH.be.scheduler.ptw.level_r >  2 )
				, ( (`COREPATH.be.scheduler.fp_regfile.bypass[1].rs_data_reg.en_i) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217156032) )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264176528) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153928) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153896) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217154224) )
				, ( (`COREPATH.be.scheduler.ptw.miss_reg.en_i) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 215850368) )
				, ( (`COREPATH.be.scheduler.int_regfile.bypass[0].rs_data_reg.en_i) )
				, ( `COREPATH.be.scheduler.issue_pkt_cast_o.partial )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[0].zero_rs_r )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264174576) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153928) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153928) )
				, ( `COREPATH.be.scheduler.ptw.level_r >  1 )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264176864) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153896) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 219520568) ||  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 219520576) )
				, ( (`COREPATH.be.scheduler.fp_regfile.bypass[0].rs_data_reg.en_i) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153608) )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264170736) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153896) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 215850952) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153808) )
				, (  &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 215850664) )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264176384) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153896) )
				, ( `COREPATH.be.scheduler.issue_queue.upper )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264176480) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153896) )
				, ( (`COREPATH.be.scheduler.ptw.walk_reg.en_i) )
				, ( `COREPATH.be.scheduler.ptw.level_r >  0 )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[1].fwd_rs_r )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[1].replace_rs )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[0].fwd_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[1].fwd_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[1].zero_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[1].replace_rs )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[2].fwd_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[2].zero_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[2].replace_rs )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[0].fwd_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[0].zero_rs_r )
				, ( `COREPATH.be.scheduler.fp_regfile.bypass[0].replace_rs )
				, ( `COREPATH.be.scheduler.issue_queue.upper )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[0].replace_rs )
				, ( `COREPATH.be.scheduler.issue_queue.deq_v_i )
				, ( `COREPATH.be.scheduler.issue_queue.deq_skip_i )
				, (  ( `COREPATH.be.scheduler.issue_queue.c1.expander.cinstr_i == 250738432) )
				, ( `COREPATH.be.scheduler.issue_queue.bypass_preissue )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[1].zero_rs_r )
				, (  ( `COREPATH.be.scheduler.ptw.state_r == 0) & `COREPATH.be.scheduler.ptw.walk_start )
				, (  ( `COREPATH.be.scheduler.ptw.state_r == 1) & `COREPATH.be.scheduler.ptw.walk_ready )
				, ( `COREPATH.be.scheduler.issue_queue.read_v_i )
				, (  ( `COREPATH.be.scheduler.ptw.state_r == 3) & `COREPATH.be.scheduler.ptw.walk_replay )
				, (  ( `COREPATH.be.scheduler.ptw.state_r == 2) & `COREPATH.be.scheduler.ptw.walk_send )
				, (  ( `COREPATH.be.scheduler.ptw.state_r == 3) & `COREPATH.be.scheduler.ptw.walk_done )
				, ( `COREPATH.be.scheduler.issue_queue.preissue_compressed )
				, ( `COREPATH.be.scheduler.issue_queue.clr )
				, ( `COREPATH.be.scheduler.issue_queue.ack )
				, ( `COREPATH.be.scheduler.issue_queue.read_skip_i )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264176480) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153896) )
				, ( `COREPATH.be.scheduler.issue_queue.c1.upper_n )
				, ( `COREPATH.be.scheduler.int_regfile.bypass[0].zero_rs_r )
				, ( `COREPATH.be.scheduler.issue_queue.roll )
				, (  ( `COREPATH.be.scheduler.issue_queue.c1.expander.cinstr_i == 250739616) )
				, ( `COREPATH.be.scheduler.ptw.walk_start )
				, (  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr == 264174576) &  ( `COREPATH.be.scheduler.issue_queue.instr_decoder.instr.opcode == 217153928) )
				, ( `COREPATH.be.scheduler.issue_queue.deq_v_i )
				, ( `COREPATH.be.scheduler.issue_queue.deq_skip_i )
				, ( `COREPATH.be.scheduler.issue_queue.clr )
      }) 
    ,.data_o           (cov_5_lo) 
    );

  bsg_cover 
    #(.id_p            (5) 
     ,.width_p         (83) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_5
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_5_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[5]) 
    ,.id_v_o           (cov_id_v_lo[5]) 
    ,.id_o             (cov_id_lo[5]) 
    ,.els_o            (cov_els_lo[5]) 
    ,.len_o            (cov_len_lo[5]) 
    ,.ready_i          (cov_ready_li[5]) 
    ,.v_o              (cov_v_lo[5]) 
    ,.last_o           (cov_last_lo[5]) 
    ,.data_o           (cov_data_lo[5]) 
    );

  wire [24-1:0] cov_6_lo; 
  bsg_cover_realign 
    #(.num_p              (24) 
     ,.num_chain_p        (3) 
     ,.chain_offset_arr_p ({10'd22, 10'd3, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd2, 10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_6
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( `COREPATH.be.director.commit_pkt_cast_i.npc_w_v )
				, ( `COREPATH.be.director.br_pkt_cast_i.bspec )
				, ( `COREPATH.be.director.npc_reg.en_i )
				, ( `COREPATH.be.director.fe_cmd_fifo.ft.wptr.add_i )
				, ( `COREPATH.be.director.fe_cmd_fifo.ft.rptr.add_i )
				, (  ( `COREPATH.be.director.state_r == 0) ||  ( `COREPATH.be.director.state_r == 1) ||  ( `COREPATH.be.director.state_r == 4) ||  ( `COREPATH.be.director.state_r == 3) ||  ( `COREPATH.be.director.state_r == 2) & `COREPATH.be.director.commit_pkt_cast_i.wfi )
				, (  ( `COREPATH.be.director.state_r == 0) ||  ( `COREPATH.be.director.state_r == 1) ||  ( `COREPATH.be.director.state_r == 4) ||  ( `COREPATH.be.director.state_r == 3) ||  ( `COREPATH.be.director.state_r == 2) & `COREPATH.be.director.commit_pkt_cast_i.fencei )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, (  ( `COREPATH.be.director.state_r == 0) ||  ( `COREPATH.be.director.state_r == 1) ||  ( `COREPATH.be.director.state_r == 4) ||  ( `COREPATH.be.director.state_r == 3) ||  ( `COREPATH.be.director.state_r == 2) & `COREPATH.be.director.freeze_li )
				, ( (`COREPATH.be.director.npc_mismatch_v) & (`COREPATH.be.director.commit_pkt_cast_i.exception |  `COREPATH.be.director.commit_pkt_cast_i._interrupt) & (`COREPATH.be.director.commit_pkt_cast_i.eret) & (`COREPATH.be.director.commit_pkt_cast_i.icache_miss) & (`COREPATH.be.director.commit_pkt_cast_i.fencei) & (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, (  ( `COREPATH.be.director.state_r == 0) ||  ( `COREPATH.be.director.state_r == 1) ||  ( `COREPATH.be.director.state_r == 4) ||  ( `COREPATH.be.director.state_r == 3) ||  ( `COREPATH.be.director.state_r == 2) & `COREPATH.be.director.clear_iss_o )
				, (  & `COREPATH.be.director.cmd_empty_r_lo )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.exception |  `COREPATH.be.director.commit_pkt_cast_i._interrupt) & (`COREPATH.be.director.commit_pkt_cast_i.eret) & (`COREPATH.be.director.commit_pkt_cast_i.icache_miss) & (`COREPATH.be.director.commit_pkt_cast_i.fencei) & (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.icache_miss) & (`COREPATH.be.director.commit_pkt_cast_i.fencei) & (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) & 1 &  `COREPATH.be.director.commit_pkt_cast_i.partial )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.fencei) & (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, (  ( `COREPATH.be.director.state_r == 0) ||  ( `COREPATH.be.director.state_r == 1) ||  ( `COREPATH.be.director.state_r == 4) ||  ( `COREPATH.be.director.state_r == 3) ||  ( `COREPATH.be.director.state_r == 2) & `COREPATH.be.director.commit_pkt_cast_i.resume |  `COREPATH.be.director.fe_cmd_nonattaboy_v )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, ( (`COREPATH.be.director.npc_match_v &  `COREPATH.be.director.last_instr_was_branch) & (`COREPATH.be.director.npc_mismatch_v) & (`COREPATH.be.director.commit_pkt_cast_i.exception |  `COREPATH.be.director.commit_pkt_cast_i._interrupt) & (`COREPATH.be.director.commit_pkt_cast_i.eret) & (`COREPATH.be.director.commit_pkt_cast_i.icache_miss) & (`COREPATH.be.director.commit_pkt_cast_i.fencei) & (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.eret) & (`COREPATH.be.director.commit_pkt_cast_i.icache_miss) & (`COREPATH.be.director.commit_pkt_cast_i.fencei) & (`COREPATH.be.director.commit_pkt_cast_i.wfi) & (`COREPATH.be.director.commit_pkt_cast_i.csrw) & (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.sfence) & (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.itlb_fill_v) & (`COREPATH.be.director.commit_pkt_cast_i.resume) & 1 &  `COREPATH.be.director.commit_pkt_cast_i.partial )
				, ( (`COREPATH.be.director.commit_pkt_cast_i.resume) & `COREPATH.be.director.is_freeze )
				, ( `COREPATH.be.director.fe_cmd_fifo.ft.rptr.add_i )
				, ( `COREPATH.be.director.fe_cmd_fifo.ft.wptr.add_i )
      }) 
    ,.data_o           (cov_6_lo) 
    );

  bsg_cover 
    #(.id_p            (6) 
     ,.width_p         (24) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_6
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_6_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[6]) 
    ,.id_v_o           (cov_id_v_lo[6]) 
    ,.id_o             (cov_id_lo[6]) 
    ,.els_o            (cov_els_lo[6]) 
    ,.len_o            (cov_len_lo[6]) 
    ,.ready_i          (cov_ready_li[6]) 
    ,.v_o              (cov_v_lo[6]) 
    ,.last_o           (cov_last_lo[6]) 
    ,.data_o           (cov_data_lo[6]) 
    );

  wire [28-1:0] cov_7_lo; 
  bsg_cover_realign 
    #(.num_p              (28) 
     ,.num_chain_p        (3) 
     ,.chain_offset_arr_p ({10'd20, 10'd10, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd2, 10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_7
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( (`COREPATH.fe.pc_gen.fetch_instr_v_i) )
				, ( `COREPATH.fe.pc_gen.redirect_br_v_i )
				, ( `COREPATH.fe.pc_gen.metadata_if1.site_br &  ( ~  `COREPATH.fe.pc_gen.ovr_o) )
				, ( (`COREPATH.fe.pc_gen.redirect_v_i) )
				, ( (`COREPATH.fe.pc_gen.ovr_o) & (`COREPATH.fe.pc_gen.redirect_v_i) & `COREPATH.fe.pc_gen.ovr_ret )
				, ( (`COREPATH.fe.pc_gen.ovr_o) & (`COREPATH.fe.pc_gen.redirect_v_i) & `COREPATH.fe.pc_gen.ovr_btaken |  `COREPATH.fe.pc_gen.ovr_jmp )
				, ( `COREPATH.fe.pc_gen.fetch_instr_scan.chigh )
				, ( (`COREPATH.fe.pc_gen.ovr_o) & (`COREPATH.fe.pc_gen.redirect_v_i) & `COREPATH.fe.pc_gen.btb_taken )
				, ( `COREPATH.fe.pc_gen.bht.is_clear )
				, ( (`COREPATH.fe.pc_gen.btb.tag_mem.ram.enb) )
				, (  ( `COREPATH.fe.pc_gen.bht.state_r == 2) )
				, (  ( `COREPATH.fe.pc_gen.btb.state_r == 2) )
				, (  ( `COREPATH.fe.pc_gen.btb.state_r == 1) & `COREPATH.fe.pc_gen.btb.finished_init )
				, (  ( `COREPATH.fe.pc_gen.bht.state_r == 1) & `COREPATH.fe.pc_gen.bht.finished_init )
				, ( (`COREPATH.fe.pc_gen.redirect_v_i) )
				, ( `COREPATH.fe.pc_gen.fetch_linear_i &  ( ~  `COREPATH.fe.pc_gen.fetch_instr_v_i) )
				, ( `COREPATH.fe.pc_gen.fetch_scan_i )
				, ( (`COREPATH.fe.pc_gen.ovr_o) & (`COREPATH.fe.pc_gen.redirect_v_i) )
				, ( (`COREPATH.fe.pc_gen.bht.bht_mem.ram.enb) )
				, ( (`COREPATH.fe.pc_gen.btb.tag_mem.ram.enb) )
				, (  ( `COREPATH.fe.pc_gen.bht.state_r == 2) )
				, (  ( `COREPATH.fe.pc_gen.bht.state_r == 1) & `COREPATH.fe.pc_gen.bht.finished_init )
				, ( `COREPATH.fe.pc_gen.metadata_if1.site_br &  ( ~  `COREPATH.fe.pc_gen.ovr_o) )
				, ( `COREPATH.fe.pc_gen.ras.restore_i )
				, ( `COREPATH.fe.pc_gen.ras.return_i )
				, ( `COREPATH.fe.pc_gen.ras.call_i )
				, ( `COREPATH.fe.pc_gen.redirect_br_v_i )
				, ( (`COREPATH.fe.pc_gen.fetch_instr_v_i) )
      }) 
    ,.data_o           (cov_7_lo) 
    );

  bsg_cover 
    #(.id_p            (7) 
     ,.width_p         (28) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_7
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_7_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[7]) 
    ,.id_v_o           (cov_id_v_lo[7]) 
    ,.id_o             (cov_id_lo[7]) 
    ,.els_o            (cov_els_lo[7]) 
    ,.len_o            (cov_len_lo[7]) 
    ,.ready_i          (cov_ready_li[7]) 
    ,.v_o              (cov_v_lo[7]) 
    ,.last_o           (cov_last_lo[7]) 
    ,.data_o           (cov_data_lo[7]) 
    );

  wire [60-1:0] cov_8_lo; 
  bsg_cover_realign 
    #(.num_p              (60) 
     ,.num_chain_p        (3) 
     ,.chain_offset_arr_p ({10'd47, 10'd26, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd2, 10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_8
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.w_i )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.bypass_r )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.llr.dff_bypass.en_i )
				, ( (`COREPATH.fe.icache.data_mems[5].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[5].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[6].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[6].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.stat_mem.fromlutram.ram.v_i &  ( ~  `COREPATH.fe.icache.stat_mem.fromlutram.ram.w_i)) )
				, ( (`COREPATH.fe.icache.data_mems[2].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[2].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.tag_mem.from1r1w.ram.ram.ram.enb) )
				, ( `COREPATH.fe.icache.data_set_select_mux.sel_one_hot_i )
				, ( (`COREPATH.fe.icache.tag_mem.from1r1w.ram.llr.dff_bypass.dff.en_i) )
				, ( (`COREPATH.fe.icache.paddr_reg.en_i) )
				, ( `COREPATH.fe.icache.invalid_exist_tv )
				, ( (`COREPATH.fe.icache.data_mems[0].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[0].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[7].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[7].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[1].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[1].data_mem.ram.en) )
				, ( ((`COREPATH.fe.icache.pe_invalid.b.i -  1) &  `COREPATH.fe.icache.pe_invalid.b.i) == 1723493352 )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.bypass_n )
				, ( `COREPATH.fe.icache.metadata_hit_r )
				, ( `COREPATH.fe.icache.data_mem_pkt_cast_i.opcode == 2 )
				, ( `COREPATH.fe.icache.word_select_mux.sel_i )
				, ( `COREPATH.fe.icache.lru_encoder.lru.rank[2].nz.mux.sel_i )
				, ( `COREPATH.fe.icache.cached_req )
				, ( `COREPATH.fe.icache.lru_encoder.lru.rank[1].nz.mux.sel_i )
				, ( `COREPATH.fe.icache.uncached_req )
				, ( (`COREPATH.fe.icache.data_mems[3].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[3].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[4].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[4].data_mem.ram.en) )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.bypass_r )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.w_i )
				, ( (`COREPATH.fe.icache.tag_mem.from1r1w.ram.write_regs.en_i) )
				, ( (`COREPATH.fe.icache.data_mems[6].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[6].data_mem.ram.en) )
				, ( `COREPATH.fe.icache.hit_mux.sel_i )
				, ( (`COREPATH.fe.icache.data_mems[3].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[3].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[1].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[1].data_mem.ram.en) )
				, (  ( `COREPATH.fe.icache.state_r == 1) & `COREPATH.fe.icache.complete_recv )
				, ( `COREPATH.fe.icache.scan_i )
				, ( (`COREPATH.fe.icache.data_mems[2].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[2].data_mem.ram.en) )
				, ( ((`COREPATH.fe.icache.hit_index_encoder.i -  1) &  `COREPATH.fe.icache.hit_index_encoder.i) == 1723493336 )
				, ( (`COREPATH.fe.icache.data_mems[4].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[4].data_mem.ram.en) )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.bypass_n )
				, ( (`COREPATH.fe.icache.data_mems[5].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[5].data_mem.ram.en) )
				, (  ( `COREPATH.fe.icache.state_r == 0) & `COREPATH.fe.icache.cache_req_yumi_i )
				, ( (`COREPATH.fe.icache.data_mems[0].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[0].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[7].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[7].data_mem.ram.en) )
				, ( `COREPATH.fe.icache.data_mem_pkt_cast_i.opcode == 2 )
				, ( 0 )
				, ( (`COREPATH.fe.icache.tag_mem.from1r1w.ram.ram.ram.enb) )
				, ( `COREPATH.fe.icache.critical_recv )
				, ( `COREPATH.fe.icache.tag_mem.from1r1w.ram.bypass_r )
				, ( (`COREPATH.fe.icache.data_mems[6].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[6].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.tag_mem.from1r1w.ram.write_regs.en_i) )
				, ( (`COREPATH.fe.icache.data_mems[4].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[4].data_mem.ram.en) )
				, ( `COREPATH.fe.icache.data_mem_pkt_cast_i.opcode == 2 )
				, ( (`COREPATH.fe.icache.data_mems[3].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[3].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[1].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[1].data_mem.ram.en) )
				, (  ( `COREPATH.fe.icache.state_r == 0) & `COREPATH.fe.icache.cache_req_yumi_i )
				, (  ( `COREPATH.fe.icache.state_r == 1) & `COREPATH.fe.icache.complete_recv )
				, ( (`COREPATH.fe.icache.data_mems[0].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[0].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[2].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[2].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[5].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[5].data_mem.ram.en) )
				, ( (`COREPATH.fe.icache.data_mems[7].data_mem.ram.we) & (`COREPATH.fe.icache.data_mems[7].data_mem.ram.en) )
      }) 
    ,.data_o           (cov_8_lo) 
    );

  bsg_cover 
    #(.id_p            (8) 
     ,.width_p         (60) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_8
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_8_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[8]) 
    ,.id_v_o           (cov_id_v_lo[8]) 
    ,.id_o             (cov_id_lo[8]) 
    ,.els_o            (cov_els_lo[8]) 
    ,.len_o            (cov_len_lo[8]) 
    ,.ready_i          (cov_ready_li[8]) 
    ,.v_o              (cov_v_lo[8]) 
    ,.last_o           (cov_last_lo[8]) 
    ,.data_o           (cov_data_lo[8]) 
    );

  wire [11-1:0] cov_9_lo; 
  bsg_cover_realign 
    #(.num_p              (11) 
     ,.num_chain_p        (2) 
     ,.chain_offset_arr_p ({10'd4, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_9
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( `COREPATH.fe.controller.icache_fence_v )
				, (  ( `COREPATH.fe.controller.state_r == 1) ||  ( `COREPATH.fe.controller.state_r == 2) )
				, ( `COREPATH.fe.controller.itlb_fill_response_v )
				, (  ( `COREPATH.fe.controller.state_r == 3) )
				, (  ( `COREPATH.fe.controller.state_r == 0) & `COREPATH.fe.controller.state_reset_v && `COREPATH.fe.controller.pc_gen_init_done_i )
				, (  ( `COREPATH.fe.controller.state_r == 1) ||  ( `COREPATH.fe.controller.state_r == 2) & `COREPATH.fe.controller.cmd_complex_v )
				, (  ( `COREPATH.fe.controller.state_r == 1) ||  ( `COREPATH.fe.controller.state_r == 2) & `COREPATH.fe.controller.cmd_immediate_v )
				, (  ( `COREPATH.fe.controller.state_r == 1) ||  ( `COREPATH.fe.controller.state_r == 2) & `COREPATH.fe.controller.if2_exception_v_i )
				, (  ( `COREPATH.fe.controller.state_r == 1) ||  ( `COREPATH.fe.controller.state_r == 2) & `COREPATH.fe.controller.wait_v |  `COREPATH.fe.controller.icache_fence_v )
				, (  ( `COREPATH.fe.controller.state_r == 1) ||  ( `COREPATH.fe.controller.state_r == 2) & `COREPATH.fe.controller.if1_we_o )
				, (  ( `COREPATH.fe.controller.state_r == 3) & `COREPATH.fe.controller.if1_we_o )
      }) 
    ,.data_o           (cov_9_lo) 
    );

  bsg_cover 
    #(.id_p            (9) 
     ,.width_p         (11) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_9
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_9_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[9]) 
    ,.id_v_o           (cov_id_v_lo[9]) 
    ,.id_o             (cov_id_lo[9]) 
    ,.els_o            (cov_els_lo[9]) 
    ,.len_o            (cov_len_lo[9]) 
    ,.ready_i          (cov_ready_li[9]) 
    ,.v_o              (cov_v_lo[9]) 
    ,.last_o           (cov_last_lo[9]) 
    ,.data_o           (cov_data_lo[9]) 
    );

  wire [8-1:0] cov_10_lo; 
  bsg_cover_realign 
    #(.num_p              (8) 
     ,.num_chain_p        (2) 
     ,.chain_offset_arr_p ({10'd7, 10'd0}) 
     ,.chain_depth_arr_p  ({10'd1, 10'd0}) 
     ,.step_p             (10)) 
   realign_10
    (.clk_i            (bp_clk) 
    ,.data_i           ({
				  ( (`COREPATH.fe.immu.entry_reg.bypass.data_reg.dff.en_i) )
				, ( `COREPATH.fe.immu.tlb.one_hot_sel_high.sel_one_hot_i )
				, ( `COREPATH.fe.immu.tlb.one_hot_sel_low.sel_one_hot_i )
				, ( (`COREPATH.fe.immu.tlb.vtag_reg.en_i) )
				, ( `COREPATH.fe.immu.entry_reg.bypass.data_reg.en_i )
				, ( `COREPATH.fe.immu.tlb.one_hot_sel_med.sel_one_hot_i )
				, ( `COREPATH.fe.immu.trans_r )
				, ( `COREPATH.fe.immu.w_v_i )
      }) 
    ,.data_o           (cov_10_lo) 
    );

  bsg_cover 
    #(.id_p            (10) 
     ,.width_p         (8) 
     ,.els_p           (cam_els_lp) 
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) 
     ,.id_width_p      (cov_id_width_lp) 
     ,.els_width_p     (cov_len_width_lp) 
     ,.len_width_p     (cov_els_width_lp) 
     ,.lg_afifo_size_p (3) 
     ,.debug_p(0)) 
   cover_10
    (.core_clk_i       (bp_clk) 
    ,.core_reset_i     (bp_reset_li) 
    ,.ds_clk_i         (ds_clk) 
    ,.ds_reset_i       (ds_reset_li) 
    ,.axi_clk_i        (aclk) 
    ,.axi_reset_i      (bp_async_reset_li) 
    ,.v_i              (cov_en_sync_li) 
    ,.data_i           (cov_10_lo) 
    ,.ready_o          () 
    ,.drain_i          (1'b0) 
    ,.gate_o           (cov_gate_lo[10]) 
    ,.id_v_o           (cov_id_v_lo[10]) 
    ,.id_o             (cov_id_lo[10]) 
    ,.els_o            (cov_els_lo[10]) 
    ,.len_o            (cov_len_lo[10]) 
    ,.ready_i          (cov_ready_li[10]) 
    ,.v_o              (cov_v_lo[10]) 
    ,.last_o           (cov_last_lo[10]) 
    ,.data_o           (cov_data_lo[10]) 
    );

`endif

   // coverage stream construction
   typedef struct packed {
     logic [cov_len_width_lp-1:0] len;
     logic [cov_els_width_lp-1:0] els;
     logic [cov_id_width_lp-1:0] id;
   } cov_pkt_s;
   cov_pkt_s cov_pkt_lo;

   logic axis_packer_v_li, axis_packer_ready_lo, axis_packer_last_li;
   logic axis_packer_v_lo, axis_packer_ready_li, axis_packer_last_lo;
   logic [C_M02_AXI_DATA_WIDTH-1:0] axis_packer_data_li;
   logic [C_M02_AXI_DATA_WIDTH-1:0] axis_packer_data_lo;

   logic cov_afifo_enq_li, cov_afifo_last_li, cov_afifo_full_lo;
   logic cov_afifo_deq_li, cov_afifo_last_lo, cov_afifo_v_lo;
   logic [C_M02_AXI_DATA_WIDTH-1:0] cov_afifo_data_li, cov_afifo_data_lo;

   // pick first covergroup to drain
   logic cov_lock_r;
   logic [`BSG_SAFE_CLOG2(num_cov_p)-1:0] cov_way_lo, cov_way_li, cov_way_r;
   assign cov_way_lo = cov_lock_r ? cov_way_r : cov_way_li;
   bsg_priority_encode
    #(.width_p(num_cov_p)
     ,.lo_to_hi_p(1)
     )
    enc
     (.i(cov_gate_lo)
     ,.addr_o(cov_way_li)
     ,.v_o()
     );

   bsg_dff_reset_en
    #(.width_p(`BSG_SAFE_CLOG2(num_cov_p)))
    cov_way_reg
     (.clk_i(ds_clk)
     ,.reset_i(ds_reset_li)
     ,.en_i(axis_packer_v_li & axis_packer_ready_lo & cov_id_v_lo[cov_way_lo])
     ,.data_i(cov_way_li)
     ,.data_o(cov_way_r)
     );

   bsg_dff_reset_set_clear
    #(.width_p(1))
    cov_lock_reg
     (.clk_i(ds_clk)
     ,.reset_i(ds_reset_li)
     ,.clear_i(axis_packer_v_li & axis_packer_ready_lo & axis_packer_last_li)
     ,.set_i(axis_packer_v_li & axis_packer_ready_lo & cov_id_v_lo[cov_way_lo])
     ,.data_o(cov_lock_r)
     );

   assign cov_pkt_lo = '{len: cov_len_lo[cov_way_lo]
                        ,els: cov_els_lo[cov_way_lo]
                        ,id: cov_id_lo[cov_way_lo]
                        };

   assign axis_packer_v_li = cov_v_lo[cov_way_lo] | cov_id_v_lo[cov_way_lo];
   assign axis_packer_last_li = cov_id_v_lo[cov_way_lo] ? 1'b0 : cov_last_lo[cov_way_lo];
   assign axis_packer_data_li = cov_id_v_lo[cov_way_lo] ? cov_pkt_lo : cov_data_lo[cov_way_lo];

   assign axis_packer_ready_li = ~cov_afifo_full_lo;
   assign cov_afifo_enq_li = axis_packer_v_lo & axis_packer_ready_li;
   assign cov_afifo_data_li = axis_packer_data_lo;
   assign cov_afifo_last_li = axis_packer_last_lo;

   assign cov_afifo_deq_li = m02_axis_tvalid & m02_axis_tready;
   assign m02_axis_tvalid = cov_afifo_v_lo;
   assign m02_axis_tdata = cov_afifo_data_lo;
   assign m02_axis_tkeep = '1;
   assign m02_axis_tlast = cov_afifo_last_lo;

   bsg_axi_stream_packer
    #(.width_p(C_M02_AXI_DATA_WIDTH)
     ,.max_len_p(256)
     )
    axis_packer
     (.clk_i(ds_clk)
     ,.reset_i(ds_reset_li)

     ,.v_i(axis_packer_v_li)
     ,.last_i(axis_packer_last_li)
     ,.data_i(axis_packer_data_li)
     ,.ready_o(axis_packer_ready_lo)

     ,.v_o(axis_packer_v_lo)
     ,.last_o(axis_packer_last_lo)
     ,.data_o(axis_packer_data_lo)
     ,.ready_i(axis_packer_ready_li)
     );

   bsg_decode_with_v
    #(.num_out_p(num_cov_p))
    cov_demux
     (.i(cov_way_lo)
     ,.v_i(axis_packer_ready_lo)
     ,.o(cov_ready_li)
     );

   bsg_async_fifo
    #(.lg_size_p(3)
     ,.width_p(C_M02_AXI_DATA_WIDTH+1)
     )
    cov_afifo
     (.w_clk_i(ds_clk)
     ,.w_reset_i(ds_reset_li)

     ,.w_enq_i(cov_afifo_enq_li)
     ,.w_data_i({cov_afifo_last_li, cov_afifo_data_li})
     ,.w_full_o(cov_afifo_full_lo)

     ,.r_clk_i(aclk)
     ,.r_reset_i(bp_async_reset_li)

     ,.r_valid_o(cov_afifo_v_lo)
     ,.r_data_o({cov_afifo_last_lo, cov_afifo_data_lo})
     ,.r_deq_i(cov_afifo_deq_li)
     );
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
