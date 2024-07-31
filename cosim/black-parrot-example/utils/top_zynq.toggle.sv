
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
   localparam cam_els_lp = 48;

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

   logic [num_cov_p-1:0][C_M02_AXI_DATA_WIDTH-1:0] cov_toggle_data_lo;

`ifdef RAND_COV
   //NOTE: num_cov_p = 36
   for(genvar i = 0; i < num_cov_p; i++) begin: rof
     // random covergroup input for testing

     localparam width_lp = 8 + (2*(i / 4));
     localparam els_lp = 8 * (2 ** (i % 4));

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
       ,.width_p(width_lp)
       ,.els_p(els_lp)
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
       ,.last_o(cov_last_lo[i])
       ,.data_o(cov_data_lo[i])
       );

     if((i % 4) == 0) begin: fi
       bsg_cover_toggle
        #(.id_p(i)
         ,.width_p(width_lp)
         ,.lg_afifo_size_p(3)
         ,.debug_p(1)
         )
        i_cov_toggle
         (.core_clk_i(bp_clk)
         ,.core_reset_i(bp_reset_li)

         ,.ds_clk_i(ds_clk)
         ,.ds_reset_i(ds_reset_li)

         ,.v_i(cov_en_sync_li)
         ,.data_i(cov_li[i])
         ,.ready_o()

         ,.data_o(cov_toggle_data_lo[i])
         );
     end
     else begin
       assign cov_toggle_data_lo[i] = 32'hdeadbeef;
     end
   end
`else
   // COVERAGE_MACRO
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
   assign axis_packer_data_li = cov_id_v_lo[cov_way_lo] ? cov_pkt_lo : (cov_data_lo[cov_way_lo] | cov_toggle_data_lo[cov_way_lo]);

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
