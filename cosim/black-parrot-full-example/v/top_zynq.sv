
`timescale 1 ps / 1 ps

`include "bsg_tag.vh"
`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 import bsg_tag_pkg::bsg_tag_s;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p)

   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   , parameter integer C_S00_AXI_DATA_WIDTH   = 32

   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_S00_AXI_ADDR_WIDTH   = 10
   , parameter integer C_S01_AXI_DATA_WIDTH   = 32
   // the ARM AXI S01 interface drops the top two bits
   , parameter integer C_S01_AXI_ADDR_WIDTH   = 30
   , parameter integer C_S02_AXI_DATA_WIDTH   = 32
   , parameter integer C_S02_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M00_AXI_DATA_WIDTH   = 64
   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M01_AXI_DATA_WIDTH   = 32
   , parameter integer C_M01_AXI_ADDR_WIDTH   = 32
   )
  (input wire                                    aclk
   , input wire                                  aresetn
   , input wire                                  rt_clk
   , input wire                                  clk250_i
   // Ethernet clocks
   , input wire                                  tx_clk_i
   , input wire                                  rx_clk_i
   // resets
   , output wire                                 sys_reset_o
   , output wire                                 clk250_reset_o
   , output wire                                 tx_clk_gen_reset_o
   , output wire                                 tx_reset_o
   , output wire                                 rx_reset_o

   // Ports of Axi Slave Bus Interface S00_AXI
   , input wire                                  s00_axi_aclk
   , output wire                                 s00_axi_aresetn
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
   , output wire                                 s01_axi_aresetn
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

   , input wire                                  s02_axi_aclk
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

   , input wire                                  m00_axi_aclk
   , output wire                                 m00_axi_aresetn
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

   localparam bp_axil_addr_width_lp = 32;
   localparam bp_axil_data_width_lp = 32;
   localparam bp_axi_addr_width_lp  = 32;
   localparam bp_axi_data_width_lp  = 64;

   logic [2:0]                                  csr_data_v_lo;
   logic [2:0]                                  csr_data_w_lo;
   logic [2:0][C_S00_AXI_DATA_WIDTH-1:0]        csr_data_lo;
   logic [C_S00_AXI_DATA_WIDTH-1:0]             pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic                                        pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic                                        ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

   logic [bp_axil_addr_width_lp-1:0]            bp_m_axil_awaddr;
   logic [2:0]                                  bp_m_axil_awprot;
   logic                                        bp_m_axil_awvalid;
   logic                                        bp_m_axil_awready;
   logic [bp_axil_data_width_lp-1:0]            bp_m_axil_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0]        bp_m_axil_wstrb;
   logic                                        bp_m_axil_wvalid;
   logic                                        bp_m_axil_wready;
   logic [1:0]                                  bp_m_axil_bresp;
   logic                                        bp_m_axil_bvalid;
   logic                                        bp_m_axil_bready;
   logic [bp_axil_addr_width_lp-1:0]            bp_m_axil_araddr;
   logic [2:0]                                  bp_m_axil_arprot;
   logic                                        bp_m_axil_arvalid;
   logic                                        bp_m_axil_arready;
   logic [bp_axil_data_width_lp-1:0]            bp_m_axil_rdata;
   logic [1:0]                                  bp_m_axil_rresp;
   logic                                        bp_m_axil_rvalid;
   logic                                        bp_m_axil_rready;

   logic [bp_axil_addr_width_lp-1:0]            bp_s_axil_awaddr;
   logic [2:0]                                  bp_s_axil_awprot;
   logic                                        bp_s_axil_awvalid;
   logic                                        bp_s_axil_awready;
   logic [bp_axil_data_width_lp-1:0]            bp_s_axil_wdata;
   logic [(bp_axil_data_width_lp/8)-1:0]        bp_s_axil_wstrb;
   logic                                        bp_s_axil_wvalid;
   logic                                        bp_s_axil_wready;
   logic [1:0]                                  bp_s_axil_bresp;
   logic                                        bp_s_axil_bvalid;
   logic                                        bp_s_axil_bready;
   logic [bp_axil_addr_width_lp-1:0]            bp_s_axil_araddr;
   logic [2:0]                                  bp_s_axil_arprot;
   logic                                        bp_s_axil_arvalid;
   logic                                        bp_s_axil_arready;
   logic [bp_axil_data_width_lp-1:0]            bp_s_axil_rdata;
   logic [1:0]                                  bp_s_axil_rresp;
   logic                                        bp_s_axil_rvalid;
   logic                                        bp_s_axil_rready;

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 256*1024*1024;

   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

   logic [63:0] minstret_lo;
   if (cce_type_p != e_cce_uce)
     assign minstret_lo = blackparrot.m.multicore.cc.y[0].x[0].tile_node.tile_node.tile.core.core_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;
   else
     assign minstret_lo = blackparrot.u.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;

   // Reset Generation Logic
   //
   assign s00_axi_aresetn    = aresetn;

   // Specify the number of generated resets here:
   localparam num_reset_lp = 5;
   // Specify the clocks the generated resets belong to here:
   wire [num_reset_lp-1:0] clks_li = {rx_clk_i, tx_clk_i, clk250_i, clk250_i, aclk};
   // Generated resets signals:
   logic [num_reset_lp-1:0] synced_resets_lo;


   `declare_bsg_tag_header_s(num_reset_lp, 1)
   logic tag_clk_r_lo;
   logic tag_data_r_lo;
   bsg_tag_s [num_reset_lp-1:0] tag;

   wire bb_v_li = csr_data_v_lo[0] & csr_data_w_lo[0];
   wire bb_ready_and_lo;

   bsg_tag_bitbang bb (
     .clk_i(aclk)
     ,.reset_i(~s00_axi_aresetn)
     ,.data_i(csr_data_lo[0][0])
     ,.v_i(bb_v_li)
     ,.ready_and_o(bb_ready_and_lo) // UNUSED

     ,.tag_clk_r_o(tag_clk_r_lo)
     ,.tag_data_r_o(tag_data_r_lo)
   );

   bsg_tag_master_decentralized #(
     .els_p(num_reset_lp)
     ,.local_els_p(num_reset_lp)
     ,.lg_width_p(1)
   ) master (
     .clk_i(tag_clk_r_lo)
     ,.data_i(tag_data_r_lo)
     ,.node_id_offset_i('0)
     ,.clients_o(tag)
   );

   for(genvar i = 0;i < num_reset_lp;i++) begin: tag_client
     bsg_tag_client #(
       .width_p(1)
     ) client (
       .bsg_tag_i(tag[i])
       ,.recv_clk_i(clks_li[i])
       ,.recv_new_r_o() // UNUSED
       ,.recv_data_r_o(synced_resets_lo[i]) // high-true
     );
   end

   assign sys_reset_o        = synced_resets_lo[0];
   assign clk250_reset_o     = synced_resets_lo[1];
   assign tx_clk_gen_reset_o = synced_resets_lo[2];
   assign tx_reset_o         = synced_resets_lo[3];
   assign rx_reset_o         = synced_resets_lo[4];
   wire   bp_reset_li        = sys_reset_o;
   assign s01_axi_aresetn    = ~sys_reset_o;
   assign m00_axi_aresetn    = ~sys_reset_o;


   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      .num_regs_ps_to_pl_p (3)
      // standard memory map for all blackparrot instances should be
      //
      // 0: reset for bp (low true); note: it is only legal to assert reset if you are
      //    finished with all AXI transactions (fixme: potential improvement to detect this)
      // 4: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
      // 8: the base register for the allocated dram
      //

      // need to update C_S00_AXI_ADDR_WIDTH accordingly
      ,.num_fifo_ps_to_pl_p(1)
      ,.num_fifo_pl_to_ps_p(1)
      ,.num_regs_pl_to_ps_p(2+4)
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_v_o(csr_data_v_lo)
        ,.csr_data_w_o(csr_data_w_lo)
        ,.csr_data_o(csr_data_lo)

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

        ,.csr_data_i({ mem_profiler_r[127:96]
                       , mem_profiler_r[95:64]
                       , mem_profiler_r[63:32]
                       , mem_profiler_r[31:0]
                       , minstret_lo[63:32]
                       , minstret_lo[31:0]}
                     )

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

   wire [bp_axil_addr_width_lp-1:0] waddr_translated_lo = {~s01_axi_awaddr[29], 3'b0, s01_axi_awaddr[0+:28]};

   // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
   // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF

   wire [bp_axil_addr_width_lp-1:0] raddr_translated_lo = {~s01_axi_araddr[29], 3'b0, s01_axi_araddr[0+:28]};


   // TODO: The widths here are weird
   logic [C_S01_AXI_ADDR_WIDTH-1 : 0]           spack_axi_awaddr;
   logic [2 : 0]                                spack_axi_awprot;
   logic                                        spack_axi_awvalid;
   logic                                        spack_axi_awready;
   logic [C_S01_AXI_DATA_WIDTH-1 : 0]           spack_axi_wdata;
   logic [(C_S01_AXI_DATA_WIDTH/8)-1 : 0]       spack_axi_wstrb;
   logic                                        spack_axi_wvalid;
   logic                                        spack_axi_wready;
   logic  [1 : 0]                               spack_axi_bresp;
   logic                                        spack_axi_bvalid;
   logic                                        spack_axi_bready;
   logic [C_S01_AXI_ADDR_WIDTH-1 : 0]           spack_axi_araddr;
   logic [2 : 0]                                spack_axi_arprot;
   logic                                        spack_axi_arvalid;
   logic                                        spack_axi_arready;
   logic  [C_S01_AXI_DATA_WIDTH-1 : 0]          spack_axi_rdata;
   logic  [1 : 0]                               spack_axi_rresp;
   logic                                        spack_axi_rvalid;
   logic                                        spack_axi_rready;

   bsg_axil_store_packer
    #(.axil_addr_width_p(bp_axil_addr_width_lp)
      ,.axil_data_width_p(bp_axil_data_width_lp)
      ,.payload_data_width_p(8)
      )
    store_packer
     (.clk_i   (s01_axi_aclk)
      ,.reset_i(sys_reset_o)

      ,.s_axil_awaddr_i (spack_axi_awaddr)
      ,.s_axil_awprot_i (spack_axi_awprot)
      ,.s_axil_awvalid_i(spack_axi_awvalid)
      ,.s_axil_awready_o(spack_axi_awready)

      ,.s_axil_wdata_i  (spack_axi_wdata)
      ,.s_axil_wstrb_i  (spack_axi_wstrb)
      ,.s_axil_wvalid_i (spack_axi_wvalid)
      ,.s_axil_wready_o (spack_axi_wready)

      ,.s_axil_bresp_o  (spack_axi_bresp)
      ,.s_axil_bvalid_o (spack_axi_bvalid)
      ,.s_axil_bready_i (spack_axi_bready)

      ,.s_axil_araddr_i (spack_axi_araddr)
      ,.s_axil_arprot_i (spack_axi_arprot)
      ,.s_axil_arvalid_i(spack_axi_arvalid)
      ,.s_axil_arready_o(spack_axi_arready)

      ,.s_axil_rdata_o  (spack_axi_rdata)
      ,.s_axil_rresp_o  (spack_axi_rresp)
      ,.s_axil_rvalid_o (spack_axi_rvalid)
      ,.s_axil_rready_i (spack_axi_rready)

      ,.data_o (pl_to_ps_fifo_data_li)
      ,.v_o    (pl_to_ps_fifo_v_li)
      ,.ready_i(pl_to_ps_fifo_ready_lo)

      ,.data_i(ps_to_pl_fifo_data_lo)
      ,.v_i(ps_to_pl_fifo_v_lo)
      ,.ready_o(ps_to_pl_fifo_ready_li)
      );

  bsg_axil_mux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(C_S01_AXI_DATA_WIDTH))
   axil_mux
    (.clk_i(s01_axi_aclk)
     ,.reset_i(sys_reset_o)
     ,.s00_axil_awaddr (waddr_translated_lo)
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
     ,.s00_axil_araddr (raddr_translated_lo)
     ,.s00_axil_arprot (s01_axi_arprot)
     ,.s00_axil_arvalid(s01_axi_arvalid)
     ,.s00_axil_arready(s01_axi_arready)
     ,.s00_axil_rdata  (s01_axi_rdata)
     ,.s00_axil_rresp  (s01_axi_rresp)
     ,.s00_axil_rvalid (s01_axi_rvalid)
     ,.s00_axil_rready (s01_axi_rready)

     ,.s01_axil_awaddr (s02_axi_awaddr )
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
     ,.s01_axil_araddr (s02_axi_araddr )
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

  bsg_axil_demux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(32)
     // BP host address space is below this
     ,.split_addr_p(32'h0020_0000)
     )
   axil_demux
    (.clk_i(s01_axi_aclk)
     ,.reset_i(sys_reset_o)

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

   localparam axi_addr_width_p = 32;
   localparam axi_data_width_p = 64;
   logic [axi_addr_width_p-1:0] axi_awaddr;
   logic [axi_addr_width_p-1:0] axi_araddr;

   // to translate from BP DRAM space to ARM PS DRAM space
   // we xor-subtract the BP DRAM base address (32'h8000_0000) and add the
   // ARM PS allocated memory space physical address.

   //always @(negedge s01_axi_aclk)
   //  begin
   //     if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
   //       $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
   //     if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
   //       $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
   //  end

   assign m00_axi_awaddr = (axi_awaddr ^ 32'h8000_0000) + csr_data_lo[2];
   assign m00_axi_araddr = (axi_araddr ^ 32'h8000_0000) + csr_data_lo[2];

   // synopsys translate_off

   always @(negedge m00_axi_aclk)
     if (m00_axi_awvalid & m00_axi_awready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

   always @(negedge s01_axi_aclk)
     if (m00_axi_arvalid & m00_axi_arready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);

   // synopsys translate_on

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
      ,.rt_clk_i(rt_clk)

      // these are reads/write from BlackParrot
      ,.m_axil_awaddr_o (bp_m_axil_awaddr)
      ,.m_axil_awprot_o (bp_m_axil_awprot)
      ,.m_axil_awvalid_o(bp_m_axil_awvalid)
      ,.m_axil_awready_i(bp_m_axil_awready)

      ,.m_axil_wdata_o  (bp_m_axil_wdata)
      ,.m_axil_wstrb_o  (bp_m_axil_wstrb)
      ,.m_axil_wvalid_o (bp_m_axil_wvalid)
      ,.m_axil_wready_i (bp_m_axil_wready)

      ,.m_axil_bresp_i  (bp_m_axil_bresp)
      ,.m_axil_bvalid_i (bp_m_axil_bvalid)
      ,.m_axil_bready_o (bp_m_axil_bready)

      ,.m_axil_araddr_o (bp_m_axil_araddr)
      ,.m_axil_arprot_o (bp_m_axil_arprot)
      ,.m_axil_arvalid_o(bp_m_axil_arvalid)
      ,.m_axil_arready_i(bp_m_axil_arready)

      ,.m_axil_rdata_i  (bp_m_axil_rdata)
      ,.m_axil_rresp_i  (bp_m_axil_rresp)
      ,.m_axil_rvalid_i (bp_m_axil_rvalid)
      ,.m_axil_rready_o (bp_m_axil_rready)

      // these are reads/writes into BlackParrot
      // from the Zynq PS ARM core
      ,.s_axil_awaddr_i (bp_s_axil_awaddr)
      ,.s_axil_awprot_i (bp_s_axil_awprot)
      ,.s_axil_awvalid_i(bp_s_axil_awvalid)
      ,.s_axil_awready_o(bp_s_axil_awready)

      ,.s_axil_wdata_i  (bp_s_axil_wdata)
      ,.s_axil_wstrb_i  (bp_s_axil_wstrb)
      ,.s_axil_wvalid_i (bp_s_axil_wvalid)
      ,.s_axil_wready_o (bp_s_axil_wready)

      ,.s_axil_bresp_o  (bp_s_axil_bresp)
      ,.s_axil_bvalid_o (bp_s_axil_bvalid)
      ,.s_axil_bready_i (bp_s_axil_bready)

      ,.s_axil_araddr_i (bp_s_axil_araddr)
      ,.s_axil_arprot_i (bp_s_axil_arprot)
      ,.s_axil_arvalid_i(bp_s_axil_arvalid)
      ,.s_axil_arready_o(bp_s_axil_arready)

      ,.s_axil_rdata_o  (bp_s_axil_rdata)
      ,.s_axil_rresp_o  (bp_s_axil_rresp)
      ,.s_axil_rvalid_o (bp_s_axil_rvalid)
      ,.s_axil_rready_i (bp_s_axil_rready)

      // BlackParrot DRAM memory system (output of bsg_cache_to_axi)
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

   // synopsys translate_off
   always @(negedge s00_axi_aclk) begin
     if(s00_axi_aresetn == 1'b1)
       if(bb_v_li & ~bb_ready_and_lo == 1'b1)
         $error("top_zynq: bitbang bit drop occurred");
   end

   always @(negedge s01_axi_aclk)
     if (s01_axi_awvalid & s01_axi_awready)
       if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,waddr_translated_lo);

   always @(negedge s01_axi_aclk)
     if (s01_axi_arvalid & s01_axi_arready)
       if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,raddr_translated_lo);
   // synopsys translate_on


endmodule

