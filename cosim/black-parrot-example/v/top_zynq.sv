
`timescale 1 ps / 1 ps

`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 import bsg_axi_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p)

   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   , parameter integer C_S00_AXI_ADDR_WIDTH   = 10
   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_S00_AXI_DATA_WIDTH   = 32

   // the ARM AXI S01 interface drops the top two bits
   , parameter integer C_S01_AXI_ADDR_WIDTH   = 30
   , parameter integer C_S01_AXI_DATA_WIDTH   = 32

   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M00_AXI_DATA_WIDTH   = 64

   , parameter integer C_M01_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M01_AXI_DATA_WIDTH   = 32
   )
  (// Ports of Axi Slave Bus Interface S00_AXI
   input wire                                    s00_axi_aclk
   , input wire                                  s00_axi_aresetn
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

   , input wire                                  s01_axi_aclk
   , input wire                                  s01_axi_aresetn
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

   , input wire                                  m00_axi_aclk
   , input wire                                  m00_axi_aresetn
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

   , input wire                                  m01_axi_aclk
   , input wire                                  m01_axi_aresetn
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
   );

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 256*1024*1024;

   localparam bp_axil_addr_width_lp = 32;
   localparam bp_axil_data_width_lp = 32;
   localparam bp_axi_addr_width_lp  = 32;
   localparam bp_axi_data_width_lp  = 64;

   `ifdef MULTICORE
      `define COREPATH blackparrot.m.multicore.cc.y[0].x[0].tile_node.tile.core.core_minimal
   `else
      `define COREPATH blackparrot.u.unicore.unicore_lite.core_minimal
      `define L2PATH blackparrot.u.unicore.l2s
   `endif

   localparam counter_num_p = 76;
   logic [counter_num_p-1:0][64-1:0] csr_data_li;
   logic [3:0][C_S00_AXI_DATA_WIDTH-1:0]        csr_data_lo;
   logic [C_S00_AXI_DATA_WIDTH-1:0]             pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic                                        pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic                                        ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

   logic [bp_axil_addr_width_lp-1:0]            m_bp_axi_awaddr;
   logic [2:0]                                  m_bp_axi_awprot;
   logic                                        m_bp_axi_awvalid;
   logic                                        m_bp_axi_awready;
   logic [bp_axil_data_width_lp-1:0]            m_bp_axi_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0]        m_bp_axi_wstrb;
   logic                                        m_bp_axi_wvalid;
   logic                                        m_bp_axi_wready;
   logic [1:0]                                  m_bp_axi_bresp;
   logic                                        m_bp_axi_bvalid;
   logic                                        m_bp_axi_bready;
   logic [bp_axil_addr_width_lp-1:0]            m_bp_axi_araddr;
   logic [2:0]                                  m_bp_axi_arprot;
   logic                                        m_bp_axi_arvalid;
   logic                                        m_bp_axi_arready;
   logic [bp_axil_data_width_lp-1:0]            m_bp_axi_rdata;
   logic [1:0]                                  m_bp_axi_rresp;
   logic                                        m_bp_axi_rvalid;
   logic                                        m_bp_axi_rready;

   logic [bp_axil_addr_width_lp-1:0]            s_bp_axi_awaddr;
   logic [2:0]                                  s_bp_axi_awprot;
   logic                                        s_bp_axi_awvalid;
   logic                                        s_bp_axi_awready;
   logic [bp_axil_data_width_lp-1:0]            s_bp_axi_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0]        s_bp_axi_wstrb;
   logic                                        s_bp_axi_wvalid;
   logic                                        s_bp_axi_wready;
   logic [1:0]                                  s_bp_axi_bresp;
   logic                                        s_bp_axi_bvalid;
   logic                                        s_bp_axi_bready;
   logic [bp_axil_addr_width_lp-1:0]            s_bp_axi_araddr;
   logic [2:0]                                  s_bp_axi_arprot;
   logic                                        s_bp_axi_arvalid;
   logic                                        s_bp_axi_arready;
   logic [bp_axil_data_width_lp-1:0]            s_bp_axi_rdata;
   logic [1:0]                                  s_bp_axi_rresp;
   logic                                        s_bp_axi_rvalid;
   logic                                        s_bp_axi_rready;

   logic [bp_axil_addr_width_lp-1:0]            m02_axi_awaddr;
   logic [2:0]                                  m02_axi_awprot;
   logic                                        m02_axi_awvalid;
   logic                                        m02_axi_awready;
   logic [bp_axil_data_width_lp-1:0]            m02_axi_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0]        m02_axi_wstrb;
   logic                                        m02_axi_wvalid;
   logic                                        m02_axi_wready;
   logic [1:0]                                  m02_axi_bresp;
   logic                                        m02_axi_bvalid;
   logic                                        m02_axi_bready;
   logic [bp_axil_addr_width_lp-1:0]            m02_axi_araddr;
   logic [2:0]                                  m02_axi_arprot;
   logic                                        m02_axi_arvalid;
   logic                                        m02_axi_arready;
   logic [bp_axil_data_width_lp-1:0]            m02_axi_rdata;
   logic [1:0]                                  m02_axi_rresp;
   logic                                        m02_axi_rvalid;
   logic                                        m02_axi_rready;

   logic [bp_axil_addr_width_lp-1:0]            m03_axi_awaddr;
   logic [2:0]                                  m03_axi_awprot;
   logic                                        m03_axi_awvalid;
   logic                                        m03_axi_awready;
   logic [bp_axil_data_width_lp-1:0]            m03_axi_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0]        m03_axi_wstrb;
   logic                                        m03_axi_wvalid;
   logic                                        m03_axi_wready;
   logic [1:0]                                  m03_axi_bresp;
   logic                                        m03_axi_bvalid;
   logic                                        m03_axi_bready;
   logic [bp_axil_addr_width_lp-1:0]            m03_axi_araddr;
   logic [2:0]                                  m03_axi_arprot;
   logic                                        m03_axi_arvalid;
   logic                                        m03_axi_arready;
   logic [bp_axil_data_width_lp-1:0]            m03_axi_rdata;
   logic [1:0]                                  m03_axi_rresp;
   logic                                        m03_axi_rvalid;
   logic                                        m03_axi_rready;

   // BlackParrot reset signal is connected to a CSR (along with
   // the AXI interface reset) so that a regression can be launched
   // without having to reload the bitstream
   wire bp_reset_li = (~csr_data_lo[0][0]) || (~s01_axi_aresetn);
   wire counter_en_li = csr_data_lo[3][0];

   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      .num_regs_ps_to_pl_p (4)
      // standard memory map for all blackparrot instances should be
      //
      // 0: reset for bp (low true); note: it is only legal to assert reset if you are
      //    finished with all AXI transactions (fixme: potential improvement to detect this)
      // 4: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
      // 8: the base register for the allocated dram
      // C: stall counter enable

      // need to update C_S00_AXI_ADDR_WIDTH accordingly
      ,.num_fifo_ps_to_pl_p(1)
      ,.num_fifo_pl_to_ps_p(1)
      ,.num_regs_pl_to_ps_p(4+(2*counter_num_p))
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_o(csr_data_lo)

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
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_ready_li & ps_to_pl_fifo_v_lo)

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

   // Add user logic here

   logic [bp_axil_addr_width_lp-1:0] waddr_translated_lo, raddr_translated_lo;

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
   //assign waddr_translated_lo = {~s01_axi_awaddr[29], 3'b0, s01_axi_awaddr[0+:28]};

   // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
   // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF
   //assign raddr_translated_lo = {~s01_axi_araddr[29], 3'b0, s01_axi_araddr[0+:28]};
   assign waddr_translated_lo = (s01_axi_awaddr < 32'h20000000) ? (s01_axi_awaddr + 32'h80000000) : (s01_axi_awaddr - 32'h20000000);
   assign raddr_translated_lo = (s01_axi_araddr < 32'h20000000) ? (s01_axi_araddr + 32'h80000000) : (s01_axi_araddr - 32'h20000000);


   // TODO: The widths here are weird
   logic [C_S01_AXI_ADDR_WIDTH-1 : 0]           s02_axi_awaddr;
   logic [2 : 0]                                s02_axi_awprot;
   logic                                        s02_axi_awvalid;
   logic                                        s02_axi_awready;
   logic [C_S01_AXI_DATA_WIDTH-1 : 0]           s02_axi_wdata;
   logic [(C_S01_AXI_DATA_WIDTH/8)-1 : 0]       s02_axi_wstrb;
   logic                                        s02_axi_wvalid;
   logic                                        s02_axi_wready;
   logic  [1 : 0]                               s02_axi_bresp;
   logic                                        s02_axi_bvalid;
   logic                                        s02_axi_bready;
   logic [C_S01_AXI_ADDR_WIDTH-1 : 0]           s02_axi_araddr;
   logic [2 : 0]                                s02_axi_arprot;
   logic                                        s02_axi_arvalid;
   logic                                        s02_axi_arready;
   logic  [C_S01_AXI_DATA_WIDTH-1 : 0]          s02_axi_rdata;
   logic  [1 : 0]                               s02_axi_rresp;
   logic                                        s02_axi_rvalid;
   logic                                        s02_axi_rready;

   bsg_axil_store_packer
    #(.axil_addr_width_p(bp_axil_addr_width_lp)
      ,.axil_data_width_p(bp_axil_data_width_lp)
      ,.payload_data_width_p(8)
      )
    store_packer
     (.clk_i   (s01_axi_aclk)
      ,.reset_i(~s01_axi_aresetn)

      ,.s_axil_awaddr_i (s02_axi_awaddr)
      ,.s_axil_awprot_i (s02_axi_awprot)
      ,.s_axil_awvalid_i(s02_axi_awvalid)
      ,.s_axil_awready_o(s02_axi_awready)

      ,.s_axil_wdata_i  (s02_axi_wdata)
      ,.s_axil_wstrb_i  (s02_axi_wstrb)
      ,.s_axil_wvalid_i (s02_axi_wvalid)
      ,.s_axil_wready_o (s02_axi_wready)

      ,.s_axil_bresp_o  (s02_axi_bresp)
      ,.s_axil_bvalid_o (s02_axi_bvalid)
      ,.s_axil_bready_i (s02_axi_bready)

      ,.s_axil_araddr_i (s02_axi_araddr)
      ,.s_axil_arprot_i (s02_axi_arprot)
      ,.s_axil_arvalid_i(s02_axi_arvalid)
      ,.s_axil_arready_o(s02_axi_arready)

      ,.s_axil_rdata_o  (s02_axi_rdata)
      ,.s_axil_rresp_o  (s02_axi_rresp)
      ,.s_axil_rvalid_o (s02_axi_rvalid)
      ,.s_axil_rready_i (s02_axi_rready)

      ,.data_o (pl_to_ps_fifo_data_li)
      ,.v_o    (pl_to_ps_fifo_v_li)
      ,.ready_i(pl_to_ps_fifo_ready_lo)

      ,.data_i(ps_to_pl_fifo_data_lo)
      ,.v_i(ps_to_pl_fifo_v_lo)
      ,.ready_o(ps_to_pl_fifo_ready_li)
      );

  bsg_axil_demux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(32)
     // BP host address space is above this
     ,.split_addr_p(32'h0010_0000)
     )
   axil_demux_m
    (.clk_i(s01_axi_aclk)
     ,.reset_i(~s01_axi_aresetn)

     ,.s00_axil_awaddr(m_bp_axi_awaddr)
     ,.s00_axil_awprot(m_bp_axi_awprot)
     ,.s00_axil_awvalid(m_bp_axi_awvalid)
     ,.s00_axil_awready(m_bp_axi_awready)
     ,.s00_axil_wdata(m_bp_axi_wdata)
     ,.s00_axil_wstrb(m_bp_axi_wstrb)
     ,.s00_axil_wvalid(m_bp_axi_wvalid)
     ,.s00_axil_wready(m_bp_axi_wready)
     ,.s00_axil_bresp(m_bp_axi_bresp)
     ,.s00_axil_bvalid(m_bp_axi_bvalid)
     ,.s00_axil_bready(m_bp_axi_bready)
     ,.s00_axil_araddr(m_bp_axi_araddr)
     ,.s00_axil_arprot(m_bp_axi_arprot)
     ,.s00_axil_arvalid(m_bp_axi_arvalid)
     ,.s00_axil_arready(m_bp_axi_arready)
     ,.s00_axil_rdata(m_bp_axi_rdata)
     ,.s00_axil_rresp(m_bp_axi_rresp)
     ,.s00_axil_rvalid(m_bp_axi_rvalid)
     ,.s00_axil_rready(m_bp_axi_rready)

     ,.m00_axil_awaddr(m02_axi_awaddr)
     ,.m00_axil_awprot(m02_axi_awprot)
     ,.m00_axil_awvalid(m02_axi_awvalid)
     ,.m00_axil_awready(m02_axi_awready)
     ,.m00_axil_wdata(m02_axi_wdata)
     ,.m00_axil_wstrb(m02_axi_wstrb)
     ,.m00_axil_wvalid(m02_axi_wvalid)
     ,.m00_axil_wready(m02_axi_wready)
     ,.m00_axil_bresp(m02_axi_bresp)
     ,.m00_axil_bvalid(m02_axi_bvalid)
     ,.m00_axil_bready(m02_axi_bready)
     ,.m00_axil_araddr(m02_axi_araddr)
     ,.m00_axil_arprot(m02_axi_arprot)
     ,.m00_axil_arvalid(m02_axi_arvalid)
     ,.m00_axil_arready(m02_axi_arready)
     ,.m00_axil_rdata(m02_axi_rdata)
     ,.m00_axil_rresp(m02_axi_rresp)
     ,.m00_axil_rvalid(m02_axi_rvalid)
     ,.m00_axil_rready(m02_axi_rready)

     ,.m01_axil_awaddr(s02_axi_awaddr)
     ,.m01_axil_awprot(s02_axi_awprot)
     ,.m01_axil_awvalid(s02_axi_awvalid)
     ,.m01_axil_awready(s02_axi_awready)
     ,.m01_axil_wdata(s02_axi_wdata)
     ,.m01_axil_wstrb(s02_axi_wstrb)
     ,.m01_axil_wvalid(s02_axi_wvalid)
     ,.m01_axil_wready(s02_axi_wready)
     ,.m01_axil_bresp(s02_axi_bresp)
     ,.m01_axil_bvalid(s02_axi_bvalid)
     ,.m01_axil_bready(s02_axi_bready)
     ,.m01_axil_araddr(s02_axi_araddr)
     ,.m01_axil_arprot(s02_axi_arprot)
     ,.m01_axil_arvalid(s02_axi_arvalid)
     ,.m01_axil_arready(s02_axi_arready)
     ,.m01_axil_rdata(s02_axi_rdata)
     ,.m01_axil_rresp(s02_axi_rresp)
     ,.m01_axil_rvalid(s02_axi_rvalid)
     ,.m01_axil_rready(s02_axi_rready)
     );

  bsg_axil_demux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(32)
     // BP local address space is above this
     ,.split_addr_p(32'h0020_0000)
     )
   axil_demux_s
    (.clk_i(s01_axi_aclk)
     ,.reset_i(~s01_axi_aresetn)

     ,.s00_axil_awaddr(waddr_translated_lo)
     ,.s00_axil_awprot(s01_axi_awprot)
     ,.s00_axil_awvalid(s01_axi_awvalid)
     ,.s00_axil_awready(s01_axi_awready)
     ,.s00_axil_wdata(s01_axi_wdata)
     ,.s00_axil_wstrb(s01_axi_wstrb)
     ,.s00_axil_wvalid(s01_axi_wvalid)
     ,.s00_axil_wready(s01_axi_wready)
     ,.s00_axil_bresp(s01_axi_bresp)
     ,.s00_axil_bvalid(s01_axi_bvalid)
     ,.s00_axil_bready(s01_axi_bready)
     ,.s00_axil_araddr(raddr_translated_lo)
     ,.s00_axil_arprot(s01_axi_arprot)
     ,.s00_axil_arvalid(s01_axi_arvalid)
     ,.s00_axil_arready(s01_axi_arready)
     ,.s00_axil_rdata(s01_axi_rdata)
     ,.s00_axil_rresp(s01_axi_rresp)
     ,.s00_axil_rvalid(s01_axi_rvalid)
     ,.s00_axil_rready(s01_axi_rready)

     ,.m00_axil_awaddr(m03_axi_awaddr)
     ,.m00_axil_awprot(m03_axi_awprot)
     ,.m00_axil_awvalid(m03_axi_awvalid)
     ,.m00_axil_awready(m03_axi_awready)
     ,.m00_axil_wdata(m03_axi_wdata)
     ,.m00_axil_wstrb(m03_axi_wstrb)
     ,.m00_axil_wvalid(m03_axi_wvalid)
     ,.m00_axil_wready(m03_axi_wready)
     ,.m00_axil_bresp(m03_axi_bresp)
     ,.m00_axil_bvalid(m03_axi_bvalid)
     ,.m00_axil_bready(m03_axi_bready)
     ,.m00_axil_araddr(m03_axi_araddr)
     ,.m00_axil_arprot(m03_axi_arprot)
     ,.m00_axil_arvalid(m03_axi_arvalid)
     ,.m00_axil_arready(m03_axi_arready)
     ,.m00_axil_rdata(m03_axi_rdata)
     ,.m00_axil_rresp(m03_axi_rresp)
     ,.m00_axil_rvalid(m03_axi_rvalid)
     ,.m00_axil_rready(m03_axi_rready)

     ,.m01_axil_awaddr(s_bp_axi_awaddr)
     ,.m01_axil_awprot(s_bp_axi_awprot)
     ,.m01_axil_awvalid(s_bp_axi_awvalid)
     ,.m01_axil_awready(s_bp_axi_awready)
     ,.m01_axil_wdata(s_bp_axi_wdata)
     ,.m01_axil_wstrb(s_bp_axi_wstrb)
     ,.m01_axil_wvalid(s_bp_axi_wvalid)
     ,.m01_axil_wready(s_bp_axi_wready)
     ,.m01_axil_bresp(s_bp_axi_bresp)
     ,.m01_axil_bvalid(s_bp_axi_bvalid)
     ,.m01_axil_bready(s_bp_axi_bready)
     ,.m01_axil_araddr(s_bp_axi_araddr)
     ,.m01_axil_arprot(s_bp_axi_arprot)
     ,.m01_axil_arvalid(s_bp_axi_arvalid)
     ,.m01_axil_arready(s_bp_axi_arready)
     ,.m01_axil_rdata(s_bp_axi_rdata)
     ,.m01_axil_rresp(s_bp_axi_rresp)
     ,.m01_axil_rvalid(s_bp_axi_rvalid)
     ,.m01_axil_rready(s_bp_axi_rready)
     );

  bsg_axil_mux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(32)
     )
   axil_mux
    (.clk_i(s01_axi_aclk)
     ,.reset_i(~s01_axi_aresetn)

     ,.s00_axil_awaddr(m02_axi_awaddr)
     ,.s00_axil_awprot(m02_axi_awprot)
     ,.s00_axil_awvalid(m02_axi_awvalid)
     ,.s00_axil_awready(m02_axi_awready)
     ,.s00_axil_wdata(m02_axi_wdata)
     ,.s00_axil_wstrb(m02_axi_wstrb)
     ,.s00_axil_wvalid(m02_axi_wvalid)
     ,.s00_axil_wready(m02_axi_wready)
     ,.s00_axil_bresp(m02_axi_bresp)
     ,.s00_axil_bvalid(m02_axi_bvalid)
     ,.s00_axil_bready(m02_axi_bready)
     ,.s00_axil_araddr(m02_axi_araddr)
     ,.s00_axil_arprot(m02_axi_arprot)
     ,.s00_axil_arvalid(m02_axi_arvalid)
     ,.s00_axil_arready(m02_axi_arready)
     ,.s00_axil_rdata(m02_axi_rdata)
     ,.s00_axil_rresp(m02_axi_rresp)
     ,.s00_axil_rvalid(m02_axi_rvalid)
     ,.s00_axil_rready(m02_axi_rready)

     ,.s01_axil_awaddr(m03_axi_awaddr)
     ,.s01_axil_awprot(m03_axi_awprot)
     ,.s01_axil_awvalid(m03_axi_awvalid)
     ,.s01_axil_awready(m03_axi_awready)
     ,.s01_axil_wdata(m03_axi_wdata)
     ,.s01_axil_wstrb(m03_axi_wstrb)
     ,.s01_axil_wvalid(m03_axi_wvalid)
     ,.s01_axil_wready(m03_axi_wready)
     ,.s01_axil_bresp(m03_axi_bresp)
     ,.s01_axil_bvalid(m03_axi_bvalid)
     ,.s01_axil_bready(m03_axi_bready)
     ,.s01_axil_araddr(m03_axi_araddr)
     ,.s01_axil_arprot(m03_axi_arprot)
     ,.s01_axil_arvalid(m03_axi_arvalid)
     ,.s01_axil_arready(m03_axi_arready)
     ,.s01_axil_rdata(m03_axi_rdata)
     ,.s01_axil_rresp(m03_axi_rresp)
     ,.s01_axil_rvalid(m03_axi_rvalid)
     ,.s01_axil_rready(m03_axi_rready)

     ,.m00_axil_awaddr(m01_axi_awaddr)
     ,.m00_axil_awprot(m01_axi_awprot)
     ,.m00_axil_awvalid(m01_axi_awvalid)
     ,.m00_axil_awready(m01_axi_awready)
     ,.m00_axil_wdata(m01_axi_wdata)
     ,.m00_axil_wstrb(m01_axi_wstrb)
     ,.m00_axil_wvalid(m01_axi_wvalid)
     ,.m00_axil_wready(m01_axi_wready)
     ,.m00_axil_bresp(m01_axi_bresp)
     ,.m00_axil_bvalid(m01_axi_bvalid)
     ,.m00_axil_bready(m01_axi_bready)
     ,.m00_axil_araddr(m01_axi_araddr)
     ,.m00_axil_arprot(m01_axi_arprot)
     ,.m00_axil_arvalid(m01_axi_arvalid)
     ,.m00_axil_arready(m01_axi_arready)
     ,.m00_axil_rdata(m01_axi_rdata)
     ,.m00_axil_rresp(m01_axi_rresp)
     ,.m00_axil_rvalid(m01_axi_rvalid)
     ,.m00_axil_rready(m01_axi_rready)
     );

   localparam axi_addr_width_p = 32;
   localparam axi_data_width_p = 64;
   logic [axi_addr_width_p-1:0] axi_awaddr;
   logic [axi_addr_width_p-1:0] axi_araddr;

   // to translate from BP DRAM space to ARM PS DRAM space
   // we xor-subtract the BP DRAM base address (32'h8000_0000) and add the
   // ARM PS allocated memory space physical address.
   assign m00_axi_awaddr = (axi_awaddr ^ 32'h8000_0000) + csr_data_lo[2];
   assign m00_axi_araddr = (axi_araddr ^ 32'h8000_0000) + csr_data_lo[2];

   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(s01_axi_aclk)
      ,.reset_i(bp_reset_li)
      ,.data_i(mem_profiler_r
               | m00_axi_awvalid << (axi_awaddr[29-:7])
               | m00_axi_arvalid << (axi_araddr[29-:7])
               )
      ,.data_o(mem_profiler_r)
      );

   bp_axi_top #
     (.bp_params_p(bp_params_p)
      ,.axil_addr_width_p(bp_axil_addr_width_lp)
      ,.axil_data_width_p(bp_axil_data_width_lp)
      ,.axi_addr_width_p(bp_axi_addr_width_lp)
      ,.axi_data_width_p(bp_axi_data_width_lp)
      )
   blackparrot
     (.clk_i(s01_axi_aclk)
      ,.reset_i(bp_reset_li)

      // these are reads/write from BlackParrot
      ,.m_axil_awaddr_o (m_bp_axi_awaddr)
      ,.m_axil_awprot_o (m_bp_axi_awprot)
      ,.m_axil_awvalid_o(m_bp_axi_awvalid)
      ,.m_axil_awready_i(m_bp_axi_awready)

      ,.m_axil_wdata_o  (m_bp_axi_wdata)
      ,.m_axil_wstrb_o  (m_bp_axi_wstrb)
      ,.m_axil_wvalid_o (m_bp_axi_wvalid)
      ,.m_axil_wready_i (m_bp_axi_wready)

      ,.m_axil_bresp_i  (m_bp_axi_bresp)
      ,.m_axil_bvalid_i (m_bp_axi_bvalid)
      ,.m_axil_bready_o (m_bp_axi_bready)

      ,.m_axil_araddr_o (m_bp_axi_araddr)
      ,.m_axil_arprot_o (m_bp_axi_arprot)
      ,.m_axil_arvalid_o(m_bp_axi_arvalid)
      ,.m_axil_arready_i(m_bp_axi_arready)

      ,.m_axil_rdata_i  (m_bp_axi_rdata)
      ,.m_axil_rresp_i  (m_bp_axi_rresp)
      ,.m_axil_rvalid_i (m_bp_axi_rvalid)
      ,.m_axil_rready_o (m_bp_axi_rready)

      // these are reads/writes into BlackParrot
      // from the Zynq PS ARM core
      ,.s_axil_awaddr_i (s_bp_axi_awaddr)
      ,.s_axil_awprot_i (s_bp_axi_awprot)
      ,.s_axil_awvalid_i(s_bp_axi_awvalid)
      ,.s_axil_awready_o(s_bp_axi_awready)

      ,.s_axil_wdata_i  (s_bp_axi_wdata)
      ,.s_axil_wstrb_i  (s_bp_axi_wstrb)
      ,.s_axil_wvalid_i (s_bp_axi_wvalid)
      ,.s_axil_wready_o (s_bp_axi_wready)

      ,.s_axil_bresp_o  (s_bp_axi_bresp)
      ,.s_axil_bvalid_o (s_bp_axi_bvalid)
      ,.s_axil_bready_i (s_bp_axi_bready)

      ,.s_axil_araddr_i (s_bp_axi_araddr)
      ,.s_axil_arprot_i (s_bp_axi_arprot)
      ,.s_axil_arvalid_i(s_bp_axi_arvalid)
      ,.s_axil_arready_o(s_bp_axi_arready)

      ,.s_axil_rdata_o  (s_bp_axi_rdata)
      ,.s_axil_rresp_o  (s_bp_axi_rresp)
      ,.s_axil_rvalid_o (s_bp_axi_rvalid)
      ,.s_axil_rready_i (s_bp_axi_rready)

      ,.m_axi_awaddr_o   (axi_awaddr)
      ,.m_axi_awvalid_o  (m00_axi_awvalid)
      ,.m_axi_awready_i  (m00_axi_awready)
      ,.m_axi_awid_o     (m00_axi_awid)
      ,.m_axi_awlock_o   (m00_axi_awlock)
      ,.m_axi_awcache_o  (m00_axi_awcache)
      ,.m_axi_awprot_o   (m00_axi_awprot)
      ,.m_axi_awlen_o    (m00_axi_awlen)
      ,.m_axi_awsize_o   (m00_axi_awsize)
      ,.m_axi_awburst_o  (m00_axi_awburst)
      ,.m_axi_awqos_o    (m00_axi_awqos)

      ,.m_axi_wdata_o    (m00_axi_wdata)
      ,.m_axi_wvalid_o   (m00_axi_wvalid)
      ,.m_axi_wready_i   (m00_axi_wready)
      ,.m_axi_wid_o      (m00_axi_wid)
      ,.m_axi_wlast_o    (m00_axi_wlast)
      ,.m_axi_wstrb_o    (m00_axi_wstrb)

      ,.m_axi_bvalid_i   (m00_axi_bvalid)
      ,.m_axi_bready_o   (m00_axi_bready)
      ,.m_axi_bid_i      (m00_axi_bid)
      ,.m_axi_bresp_i    (m00_axi_bresp)

      ,.m_axi_araddr_o   (axi_araddr)
      ,.m_axi_arvalid_o  (m00_axi_arvalid)
      ,.m_axi_arready_i  (m00_axi_arready)
      ,.m_axi_arid_o     (m00_axi_arid)
      ,.m_axi_arlock_o   (m00_axi_arlock)
      ,.m_axi_arcache_o  (m00_axi_arcache)
      ,.m_axi_arprot_o   (m00_axi_arprot)
      ,.m_axi_arlen_o    (m00_axi_arlen)
      ,.m_axi_arsize_o   (m00_axi_arsize)
      ,.m_axi_arburst_o  (m00_axi_arburst)
      ,.m_axi_arqos_o    (m00_axi_arqos)

      ,.m_axi_rdata_i    (m00_axi_rdata)
      ,.m_axi_rvalid_i   (m00_axi_rvalid)
      ,.m_axi_rready_o   (m00_axi_rready)
      ,.m_axi_rid_i      (m00_axi_rid)
      ,.m_axi_rlast_i    (m00_axi_rlast)
      ,.m_axi_rresp_i    (m00_axi_rresp)
      );


   `declare_bp_bedrock_mem_if(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p);
   bp_bedrock_mem_header_s mem_cmd_header_li, mem_resp_header_li;
   assign mem_cmd_header_li = `L2PATH.mem_cmd_header_i;
   assign mem_resp_header_li = `L2PATH.mem_resp_header_o;

   logic l2_backlog_li, l2_serving_ic_li, l2_serving_dfetch_li, l2_serving_devict_li;
   logic [dma_els_p-1:0] l2_ready_li, l2_miss_done_li;
   logic [`BSG_SAFE_CLOG2(l2_banks_p)-1:0] l2_bank_li;

   logic mem_cmd_new_r;
   bsg_dff_reset_en
    #(.width_p(1), .reset_val_p(1))
    new_reg
     (.clk_i(s01_axi_aclk)
     ,.reset_i(bp_reset_li)
     ,.en_i(`L2PATH.mem_cmd_v_i & `L2PATH.mem_cmd_ready_and_o)
     ,.data_i(`L2PATH.mem_cmd_last_i)
     ,.data_o(mem_cmd_new_r)
     );

  wire mem_cmd_new_li = `L2PATH.mem_cmd_v_i & `L2PATH.mem_cmd_ready_and_o & mem_cmd_new_r;
  wire mem_resp_last_li = `L2PATH.mem_resp_v_o & `L2PATH.mem_resp_ready_and_i & `L2PATH.mem_resp_last_o;

  bsg_dff_reset_set_clear
   #(.width_p(1))
   ic_reg
    (.clk_i(s01_axi_aclk)
    ,.reset_i(bp_reset_li)
    ,.set_i(mem_cmd_new_li & ~mem_cmd_header_li.payload.lce_id[0])
    ,.clear_i(mem_resp_last_li & ~mem_resp_header_li.payload.lce_id[0])
    ,.data_o(l2_serving_ic_li)
    );

  bsg_dff_reset_set_clear
   #(.width_p(1))
   dfetch_reg
    (.clk_i(s01_axi_aclk)
    ,.reset_i(bp_reset_li)
    ,.set_i(mem_cmd_new_li & mem_cmd_header_li.payload.lce_id[0] & (mem_cmd_header_li.msg_type.mem != e_bedrock_mem_wr))
    ,.clear_i(mem_resp_last_li & mem_resp_header_li.payload.lce_id[0] & (mem_resp_header_li.msg_type.mem != e_bedrock_mem_wr))
    ,.data_o(l2_serving_dfetch_li)
    );

  bsg_dff_reset_set_clear
   #(.width_p(1))
   devict_reg
    (.clk_i(s01_axi_aclk)
    ,.reset_i(bp_reset_li)
    ,.set_i(mem_cmd_new_li & mem_cmd_header_li.payload.lce_id[0] & (mem_cmd_header_li.msg_type.mem == e_bedrock_mem_wr))
    ,.clear_i(mem_resp_last_li & mem_resp_header_li.payload.lce_id[0] & (mem_resp_header_li.msg_type.mem == e_bedrock_mem_wr))
    ,.data_o(l2_serving_devict_li)
    );

   logic [1:0] dma_sel_li;
   assign l2_backlog_li = `L2PATH.mem_cmd_v_i & ~`L2PATH.mem_cmd_ready_and_o;
   generate
     if(l2_en_p) begin
       assign dma_sel_li = `L2PATH.l2.cce_to_cache.mem_cmd_header_lo.payload.lce_id[0]
                           ? (`L2PATH.l2.cce_to_cache.mem_cmd_header_lo.msg_type.mem == e_bedrock_mem_wr)
                             ? 2'b10
                             : 2'b01
                           :2'b00;
       assign l2_bank_li = `L2PATH.l2.cce_to_cache.cache_cmd_bank_lo;
       for (genvar i = 0; i < l2_banks_p; i++) begin : bank_sel
         assign l2_ready_li[i] = `L2PATH.l2.bank[i].cache.v_i ? `L2PATH.l2.bank[i].cache.yumi_o : 1'b1;
         assign l2_miss_done_li[i] = `L2PATH.l2.bank[i].cache.miss_done_lo;
       end
     end
     else begin
       assign dma_sel_li = `L2PATH.nol2.cce_to_cache_dma.mem_cmd_header_lo.payload.lce_id[0]
                           ? (`L2PATH.nol2.cce_to_cache_dma.mem_cmd_header_lo.msg_type.mem == e_bedrock_mem_wr)
                             ? 2'b10
                             : 2'b01
                           :2'b00;
       assign l2_bank_li = '0;
       assign l2_ready_li = 1'b0;
       assign l2_miss_done_li = 1'b0;
     end
   endgenerate

   bp_commit_profiler
    #(.bp_params_p(bp_params_p)
     ,.width_p(64)
     )
     i_profiler
     (.clk_i(s01_axi_aclk)
     ,.reset_i(bp_reset_li)
     ,.freeze_i(`COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze)
     ,.en_i(counter_en_li)

     ,.fe_queue_ready_i(`COREPATH.fe.fe_queue_ready_i)
     ,.icache_ready_i(`COREPATH.fe.icache.ready_o)

     ,.if2_v_i(`COREPATH.fe.v_if2_r)
     ,.br_ovr_i(`COREPATH.fe.pc_gen.ovr_taken)
     ,.ret_ovr_i(`COREPATH.fe.pc_gen.ovr_ret)
     ,.icache_data_v_i(`COREPATH.fe.icache.data_v_o)

     ,.fe_cmd_yumi_i(`COREPATH.fe.fe_cmd_yumi_o)
     ,.fe_cmd_i(`COREPATH.fe.fe_cmd_cast_i)
     ,.fe_cmd_fence_i(`COREPATH.be.director.suppress_iss_o)
     ,.fe_queue_empty_i(~`COREPATH.be.scheduler.fe_queue_fifo.fe_queue_v_o)

     ,.mispredict_i(`COREPATH.be.director.npc_mismatch_v)
     ,.dcache_ready_i(`COREPATH.be.calculator.pipe_mem.dcache.ready_o)
     ,.long_haz_i(`COREPATH.be.detector.long_haz_v)
     ,.control_haz_i(`COREPATH.be.detector.control_haz_v)
     ,.data_haz_i(`COREPATH.be.detector.data_haz_v)
     ,.aux_dep_i((`COREPATH.be.detector.dep_status_r[0].aux_iwb_v
                | `COREPATH.be.detector.dep_status_r[0].aux_fwb_v
                ) & `COREPATH.be.detector.data_haz_v
               )
     ,.load_dep_i((`COREPATH.be.detector.dep_status_r[0].emem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[0].fmem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[1].fmem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[0].emem_fwb_v
                   | `COREPATH.be.detector.dep_status_r[0].fmem_fwb_v
                   | `COREPATH.be.detector.dep_status_r[1].fmem_fwb_v
                   ) & `COREPATH.be.detector.data_haz_v
                  )
     ,.mul_dep_i((`COREPATH.be.detector.dep_status_r[0].mul_iwb_v
                  | `COREPATH.be.detector.dep_status_r[1].mul_iwb_v
                  | `COREPATH.be.detector.dep_status_r[2].mul_iwb_v
                  ) & `COREPATH.be.detector.data_haz_v
                 )
     ,.fma_dep_i((`COREPATH.be.detector.dep_status_r[0].fma_fwb_v
                | `COREPATH.be.detector.dep_status_r[1].fma_fwb_v
                | `COREPATH.be.detector.dep_status_r[2].fma_fwb_v
                | `COREPATH.be.detector.dep_status_r[3].fma_fwb_v
                ) & `COREPATH.be.detector.data_haz_v
               )
     ,.sb_iraw_dep_i((`COREPATH.be.detector.irs1_sb_raw_haz_v
                    | `COREPATH.be.detector.irs2_sb_raw_haz_v
                    ) & `COREPATH.be.detector.data_haz_v
                   )
     ,.sb_fraw_dep_i((`COREPATH.be.detector.frs1_sb_raw_haz_v
                    | `COREPATH.be.detector.frs2_sb_raw_haz_v
                    | `COREPATH.be.detector.frs3_sb_raw_haz_v
                    ) & `COREPATH.be.detector.data_haz_v
                   )
     ,.sb_iwaw_dep_i(`COREPATH.be.detector.ird_sb_waw_haz_v & `COREPATH.be.detector.data_haz_v)
     ,.sb_fwaw_dep_i(`COREPATH.be.detector.frd_sb_waw_haz_v & `COREPATH.be.detector.data_haz_v)
     ,.struct_haz_i(`COREPATH.be.detector.struct_haz_v)
     ,.idiv_haz_i(~`COREPATH.be.detector.idiv_ready_i & `COREPATH.be.detector.isd_status_cast_i.long_v)
     ,.fdiv_haz_i(~`COREPATH.be.detector.fdiv_ready_i & `COREPATH.be.detector.isd_status_cast_i.long_v)
     ,.ptw_busy_i(`COREPATH.be.detector.ptw_busy_i)

     ,.sb_int_v_i(`COREPATH.be.detector.score_int_v_li)
     ,.sb_int_clr_i(`COREPATH.be.detector.clear_int_v_li)
     ,.sb_rs1_i(`COREPATH.be.detector.score_rs1_li)
     ,.sb_rs2_i(`COREPATH.be.detector.score_rs2_li)
     ,.sb_rd_i(`COREPATH.be.detector.score_rd_li)
     ,.sb_irs_match_i(`COREPATH.be.detector.irs_match_lo)

     ,.l2_bank_i(l2_bank_li)
     ,.l2_ready_i(l2_ready_li)
     ,.l2_miss_done_i(l2_miss_done_li)
     ,.l2_backlog_i(l2_backlog_li)
     ,.l2_serving_ic_i(l2_serving_ic_li)
     ,.l2_serving_dfetch_i(l2_serving_dfetch_li)
     ,.l2_serving_devict_i(l2_serving_devict_li)

     ,.dc_miss_i(`COREPATH.be.calculator.pipe_mem.dcache.is_miss)
     ,.dc_late_i(`COREPATH.be.calculator.pipe_mem.dcache.is_late)
     ,.dc_resume_i(`COREPATH.be.calculator.pipe_mem.dcache.is_resume)
     ,.dc_busy_i(`COREPATH.be.calculator.pipe_mem.dcache.is_ready & `COREPATH.be.calculator.pipe_mem.dcache.cache_req_busy_i)

     ,.m_arvalid_i(m00_axi_arvalid)
     ,.m_arready_i(m00_axi_arready)
     ,.m_rlast_i(m00_axi_rvalid & m00_axi_rlast)
     ,.m_rready_i(m00_axi_rready)
     ,.m_awvalid_i(m00_axi_awvalid)
     ,.m_awready_i(m00_axi_awready)
     ,.m_bvalid_i(m00_axi_bvalid)
     ,.m_bready_i(m00_axi_bready)
     ,.dma_sel_i(dma_sel_li)

     ,.icache_valid_i(`COREPATH.fe.icache.v_i)
     ,.dcache_valid_i(`COREPATH.be.calculator.pipe_mem.dcache.v_i)

     ,.flong_v_i(`COREPATH.be.calculator.pipe_long.fdiv_v_li | `COREPATH.be.calculator.pipe_long.fsqrt_v_li)
     ,.flong_ready_i(`COREPATH.be.calculator.pipe_long.fdiv_ready_lo)

     ,.ilong_v_i(`COREPATH.be.calculator.pipe_long.idiv_v_li | `COREPATH.be.calculator.pipe_long.irem_v_li)
     ,.ilong_ready_i(`COREPATH.be.calculator.pipe_long.idiv_ready_and_lo)

     ,.retire_pkt_i(`COREPATH.be.calculator.pipe_sys.retire_pkt)
     ,.commit_pkt_i(`COREPATH.be.calculator.pipe_sys.commit_pkt)
     ,.iwb_pkt_i(`COREPATH.be.calculator.pipe_sys.iwb_pkt)

     ,.data_o(csr_data_li[counter_num_p-1:0])
     );

   // synopsys translate_off
   integer f;
   initial begin
     f = $fopen("axi.txt","w");
   end

   always @(negedge s01_axi_aclk) begin
     if (debug_lp) begin
       if (s01_axi_awvalid & s01_axi_awready)
         $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,waddr_translated_lo);
       if (s01_axi_arvalid & s01_axi_arready)
         $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,raddr_translated_lo);
     end
       if (m00_axi_awvalid & m00_axi_awready)
         $fwrite(f, "top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)\n",axi_awaddr,m00_axi_awaddr);
       if (m00_axi_arvalid & m00_axi_arready)
         $fwrite(f, "top_zynq: (BP DRAM) AXI Read Addr %x -> %x (AXI HP0)\n",axi_araddr,m00_axi_araddr);

       if (m00_axi_wvalid & m00_axi_wready)
         $fwrite(f, "top_zynq: (BP DRAM) AXI Write Data %x (AXI HP0)\n",m00_axi_wdata);
       if (m00_axi_rvalid & m00_axi_rready)
         $fwrite(f, "top_zynq: (BP DRAM) AXI Read Data %x (AXI HP0)\n",m00_axi_rdata);

       if (s01_axi_awvalid & s01_axi_awready)
         $fwrite(f, "top_zynq: (BP HOST) AXI Write Addr %x\n",s01_axi_awaddr);
       if (s01_axi_arvalid & s01_axi_arready)
         $fwrite(f, "top_zynq: (BP HOST) AXI Read Addr %x\n",s01_axi_araddr);

       if (s01_axi_wvalid & s01_axi_wready)
         $fwrite(f, "top_zynq: (BP HOST) AXI Write Data %x\n",s01_axi_wdata);
       if (s01_axi_rvalid & s01_axi_rready)
         $fwrite(f, "top_zynq: (BP HOST) AXI Read Data %x\n",s01_axi_rdata);

       if (m01_axi_awvalid & m01_axi_awready)
         $fwrite(f, "top_zynq: (BP ROM) AXI Write Addr %x\n",m01_axi_awaddr);
       if (m01_axi_arvalid & m01_axi_arready)
         $fwrite(f, "top_zynq: (BP ROM) AXI Read Addr %x\n",m01_axi_araddr);

       if (m01_axi_wvalid & m01_axi_wready)
         $fwrite(f, "top_zynq: (BP ROM) AXI Write Data %x\n",m01_axi_wdata);
       if (m01_axi_rvalid & m01_axi_rready)
         $fwrite(f, "top_zynq: (BP ROM) AXI Read Data %x\n",m01_axi_rdata);

       if (m02_axi_awvalid & m02_axi_awready)
         $fwrite(f, "top_zynq: (BP MUX1) AXI Write Addr %x\n",m02_axi_awaddr);
       if (m02_axi_arvalid & m02_axi_arready)
         $fwrite(f, "top_zynq: (BP MUX1) AXI Read Addr %x\n",m02_axi_araddr);

       if (m02_axi_wvalid & m02_axi_wready)
         $fwrite(f, "top_zynq: (BP MUX1) AXI Write Data %x\n",m02_axi_wdata);
       if (m02_axi_rvalid & m02_axi_rready)
         $fwrite(f, "top_zynq: (BP MUX1) AXI Read Data %x\n",m02_axi_rdata);

       if (m03_axi_awvalid & m03_axi_awready)
         $fwrite(f, "top_zynq: (BP MUX2) AXI Write Addr %x\n",m03_axi_awaddr);
       if (m03_axi_arvalid & m03_axi_arready)
         $fwrite(f, "top_zynq: (BP MUX2) AXI Read Addr %x\n",m03_axi_araddr);

       if (m03_axi_wvalid & m03_axi_wready)
         $fwrite(f, "top_zynq: (BP MUX2) AXI Write Data %x\n",m03_axi_wdata);
       if (m03_axi_rvalid & m03_axi_rready)
         $fwrite(f, "top_zynq: (BP MUX2) AXI Read Data %x\n",m03_axi_rdata);

     if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
       $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
     if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
       $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
   end
   // synopsys translate_on

endmodule
