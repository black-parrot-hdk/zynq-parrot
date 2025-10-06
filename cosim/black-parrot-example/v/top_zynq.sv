
`include "bsg_tag.svh"
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

   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   , parameter integer C_GP0_AXI_DATA_WIDTH   = 32

   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_GP0_AXI_ADDR_WIDTH   = 10
   , parameter integer C_GP1_AXI_DATA_WIDTH   = 32
   // the ARM AXI S01 interface drops the top two bits
   , parameter integer C_GP1_AXI_ADDR_WIDTH   = 30
   , parameter integer C_GP2_AXI_DATA_WIDTH   = 32
   , parameter integer C_GP2_AXI_ADDR_WIDTH   = 28
   , parameter integer C_HP0_AXI_DATA_WIDTH   = 64
   , parameter integer C_HP0_AXI_ADDR_WIDTH   = 32
   , parameter integer C_HP1_AXI_DATA_WIDTH   = 32
   , parameter integer C_HP1_AXI_ADDR_WIDTH   = 32
   )
  (input wire                                    aclk
   , input wire                                  aresetn
   , input wire                                  rt_clk
   , output logic                                sys_resetn

   , output logic                                tag_ck
   , output logic                                tag_data

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

   , input wire [C_GP2_AXI_ADDR_WIDTH-1 : 0]     gp2_axi_awaddr
   , input wire [2 : 0]                          gp2_axi_awprot
   , input wire                                  gp2_axi_awvalid
   , output wire                                 gp2_axi_awready
   , input wire [C_GP2_AXI_DATA_WIDTH-1 : 0]     gp2_axi_wdata
   , input wire [(C_GP2_AXI_DATA_WIDTH/8)-1 : 0] gp2_axi_wstrb
   , input wire                                  gp2_axi_wvalid
   , output wire                                 gp2_axi_wready
   , output wire [1 : 0]                         gp2_axi_bresp
   , output wire                                 gp2_axi_bvalid
   , input wire                                  gp2_axi_bready
   , input wire [C_GP2_AXI_ADDR_WIDTH-1 : 0]     gp2_axi_araddr
   , input wire [2 : 0]                          gp2_axi_arprot
   , input wire                                  gp2_axi_arvalid
   , output wire                                 gp2_axi_arready
   , output wire [C_GP2_AXI_DATA_WIDTH-1 : 0]    gp2_axi_rdata
   , output wire [1 : 0]                         gp2_axi_rresp
   , output wire                                 gp2_axi_rvalid
   , input wire                                  gp2_axi_rready

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

   localparam bp_axil_addr_width_lp = 32;
   localparam bp_axil_data_width_lp = 32;
   localparam bp_axi_addr_width_lp  = 32;
   localparam bp_axi_data_width_lp  = 64;
   localparam num_regs_ps_to_pl_lp  = 5;
   localparam num_regs_pl_to_ps_lp  = 8;
   localparam num_fifos_ps_to_pl_lp = 1;
   localparam num_fifos_pl_to_ps_lp = 1;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_lo:
   //
   // 0: System-wide reset (low true); note: it is only legal to assert reset if you are
   //    finished with all AXI transactions (fixme: potential improvement to detect this)
   // 4: Bit banging interface
   // 8: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
   // C: The base register for the allocated dram
   //
   logic [num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_li:
   //
   // 0: minstret (64b)
   // 8: mem_profiler (128b)
   //
   logic [num_regs_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_li;

   logic [C_GP0_AXI_DATA_WIDTH-1:0]      pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic                                 pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic                                 ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

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

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 256*1024*1024;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      // need to update C_GP0_AXI_ADDR_WIDTH accordingly
      .num_fifo_ps_to_pl_p(num_fifos_ps_to_pl_lp)
      ,.num_fifo_pl_to_ps_p(num_fifos_pl_to_ps_lp)
      ,.num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
      ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
      ,.C_S_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
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
   localparam bootrom_data_lp = 32;
   localparam bootrom_addr_lp = 9;
   logic bb_data_li, bb_v_li;
   logic dram_init_li;
   logic [C_HP0_AXI_ADDR_WIDTH-1:0] dram_base_li;
   logic [63:0] minstret_lo;
   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;
   logic [bootrom_data_lp-1:0] bootrom_data_li;
   logic [bootrom_addr_lp-1:0] bootrom_addr_lo;

   assign sys_resetn   = csr_data_lo[0][0]; // active-low
   assign bb_data_li   = csr_data_lo[1][0]; assign bb_v_li = csr_data_new_lo[1];
   assign dram_init_li = csr_data_lo[2];
   assign dram_base_li = csr_data_lo[3];
   assign bootrom_addr_lo = csr_data_lo[4];

   assign csr_data_li[0+:2] = minstret_lo;
   assign csr_data_li[2+:4] = mem_profiler_r;
   assign csr_data_li[6+:1] = {<<8{bootrom_data_li}};

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
    client
     (.bsg_tag_i(tag_lines_lo.core_reset)
      ,.recv_clk_i(aclk)
      ,.recv_new_r_o() // UNUSED
      ,.recv_data_r_o(tag_reset_li)
      );

   // Reset BP during system reset or if bsg_tag says to
   wire bp_reset_li = ~sys_resetn | tag_reset_li;

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
   if (cce_type_p != e_cce_uce)
     assign minstret_lo = blackparrot.processor.m.multicore.cc.y[0].x[0].tile_node.tile.core.core_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;
   else
     assign minstret_lo = blackparrot.processor.u.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;

 `declare_bp_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p, fetch_ptr_p, issue_ptr_p);
  bp_be_commit_pkt_s commit_pkt;

  assign commit_pkt = blackparrot.processor.u.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.commit_pkt_cast_o;

  bsg_bootrom
   #(.width_p(bootrom_data_lp), .addr_width_p(bootrom_addr_lp))
   bootrom
    (.addr_i(bootrom_addr_lo), .data_o(bootrom_data_li));

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
   
   wire [bp_axil_addr_width_lp-1:0] gp1_awaddr_translated_lo = {~gp1_axi_awaddr[29], 3'b0, gp1_axi_awaddr[0+:28]};
   
   // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
   // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF
   
   wire [bp_axil_addr_width_lp-1:0] gp1_araddr_translated_lo = {~gp1_axi_araddr[29], 3'b0, gp1_axi_araddr[0+:28]};

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

     ,.m01_axil_awaddr(hp1_axi_awaddr)
     ,.m01_axil_awprot(hp1_axi_awprot)
     ,.m01_axil_awvalid(hp1_axi_awvalid)
     ,.m01_axil_awready(hp1_axi_awready)
     ,.m01_axil_wdata(hp1_axi_wdata)
     ,.m01_axil_wstrb(hp1_axi_wstrb)
     ,.m01_axil_wvalid(hp1_axi_wvalid)
     ,.m01_axil_wready(hp1_axi_wready)
     ,.m01_axil_bresp(hp1_axi_bresp)
     ,.m01_axil_bvalid(hp1_axi_bvalid)
     ,.m01_axil_bready(hp1_axi_bready)
     ,.m01_axil_araddr(hp1_axi_araddr)
     ,.m01_axil_arprot(hp1_axi_arprot)
     ,.m01_axil_arvalid(hp1_axi_arvalid)
     ,.m01_axil_arready(hp1_axi_arready)
     ,.m01_axil_rdata(hp1_axi_rdata)
     ,.m01_axil_rresp(hp1_axi_rresp)
     ,.m01_axil_rvalid(hp1_axi_rvalid)
     ,.m01_axil_rready(hp1_axi_rready)
     );

  // TODO: Bug in zero-extension of Xcelium 21.09
  wire [bp_axil_addr_width_lp-1:0] gp2_awaddr_translated_lo = gp2_axi_awaddr;
  wire [bp_axil_addr_width_lp-1:0] gp2_araddr_translated_lo = gp2_axi_araddr;

  bsg_axil_mux
   #(.addr_width_p(bp_axil_addr_width_lp)
     ,.data_width_p(bp_axil_data_width_lp)
     )
   axil_mux
    (.clk_i(aclk)
     ,.reset_i(~aresetn)
     ,.s00_axil_awaddr (gp1_awaddr_translated_lo)
     ,.s00_axil_awprot (gp1_axi_awprot)
     ,.s00_axil_awvalid(gp1_axi_awvalid)
     ,.s00_axil_awready(gp1_axi_awready)
     ,.s00_axil_wdata  (gp1_axi_wdata)
     ,.s00_axil_wstrb  (gp1_axi_wstrb)
     ,.s00_axil_wvalid (gp1_axi_wvalid)
     ,.s00_axil_wready (gp1_axi_wready)
     ,.s00_axil_bresp  (gp1_axi_bresp)
     ,.s00_axil_bvalid (gp1_axi_bvalid)
     ,.s00_axil_bready (gp1_axi_bready)
     ,.s00_axil_araddr (gp1_araddr_translated_lo)
     ,.s00_axil_arprot (gp1_axi_arprot)
     ,.s00_axil_arvalid(gp1_axi_arvalid)
     ,.s00_axil_arready(gp1_axi_arready)
     ,.s00_axil_rdata  (gp1_axi_rdata)
     ,.s00_axil_rresp  (gp1_axi_rresp)
     ,.s00_axil_rvalid (gp1_axi_rvalid)
     ,.s00_axil_rready (gp1_axi_rready)

     ,.s01_axil_awaddr (gp2_awaddr_translated_lo)
     ,.s01_axil_awprot (gp2_axi_awprot )
     ,.s01_axil_awvalid(gp2_axi_awvalid)
     ,.s01_axil_awready(gp2_axi_awready)
     ,.s01_axil_wdata  (gp2_axi_wdata  )
     ,.s01_axil_wstrb  (gp2_axi_wstrb  )
     ,.s01_axil_wvalid (gp2_axi_wvalid )
     ,.s01_axil_wready (gp2_axi_wready )
     ,.s01_axil_bresp  (gp2_axi_bresp  )
     ,.s01_axil_bvalid (gp2_axi_bvalid )
     ,.s01_axil_bready (gp2_axi_bready )
     ,.s01_axil_araddr (gp2_araddr_translated_lo)
     ,.s01_axil_arprot (gp2_axi_arprot )
     ,.s01_axil_arvalid(gp2_axi_arvalid)
     ,.s01_axil_arready(gp2_axi_arready)
     ,.s01_axil_rdata  (gp2_axi_rdata  )
     ,.s01_axil_rresp  (gp2_axi_rresp  )
     ,.s01_axil_rvalid (gp2_axi_rvalid )
     ,.s01_axil_rready (gp2_axi_rready )

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
   //     if (hp0_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
   //       $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
   //     if (hp0_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
   //       $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
   //  end

   assign hp0_axi_awaddr = (axi_awaddr ^ 32'h8000_0000) + dram_base_li;
   assign hp0_axi_araddr = (axi_araddr ^ 32'h8000_0000) + dram_base_li;

   // synopsys translate_off

   always @(negedge aclk)
     if (hp0_axi_awvalid & hp0_axi_awready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,hp0_axi_awaddr);

   always @(negedge aclk)
     if (hp0_axi_arvalid & hp0_axi_arready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,hp0_axi_araddr);

   // synopsys translate_on

   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(aclk)
      ,.reset_i(bp_reset_li)
      ,.data_i(mem_profiler_r
               | hp0_axi_awvalid << (axi_awaddr[29-:7])
               | hp0_axi_arvalid << (axi_araddr[29-:7])
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
      ,.axi_core_clk_async_p(0)
      )
   blackparrot
     (.axi_clk_i(aclk)
      ,.core_clk_i(aclk)
      ,.rt_clk_i(rt_clk)
      ,.async_reset_i(bp_reset_li)

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
      ,.m_axi_awvalid_o(hp0_axi_awvalid)
      ,.m_axi_awready_i(hp0_axi_awready)
      ,.m_axi_awid_o(hp0_axi_awid)
      ,.m_axi_awlock_o(hp0_axi_awlock)
      ,.m_axi_awcache_o(hp0_axi_awcache)
      ,.m_axi_awprot_o(hp0_axi_awprot)
      ,.m_axi_awlen_o(hp0_axi_awlen)
      ,.m_axi_awsize_o(hp0_axi_awsize)
      ,.m_axi_awburst_o(hp0_axi_awburst)
      ,.m_axi_awqos_o(hp0_axi_awqos)

      ,.m_axi_wdata_o(hp0_axi_wdata)
      ,.m_axi_wvalid_o(hp0_axi_wvalid)
      ,.m_axi_wready_i(hp0_axi_wready)
      ,.m_axi_wid_o(hp0_axi_wid)
      ,.m_axi_wlast_o(hp0_axi_wlast)
      ,.m_axi_wstrb_o(hp0_axi_wstrb)

      ,.m_axi_bvalid_i(hp0_axi_bvalid)
      ,.m_axi_bready_o(hp0_axi_bready)
      ,.m_axi_bid_i(hp0_axi_bid)
      ,.m_axi_bresp_i(hp0_axi_bresp)

      ,.m_axi_araddr_o(axi_araddr)
      ,.m_axi_arvalid_o(hp0_axi_arvalid)
      ,.m_axi_arready_i(hp0_axi_arready)
      ,.m_axi_arid_o(hp0_axi_arid)
      ,.m_axi_arlock_o(hp0_axi_arlock)
      ,.m_axi_arcache_o(hp0_axi_arcache)
      ,.m_axi_arprot_o(hp0_axi_arprot)
      ,.m_axi_arlen_o(hp0_axi_arlen)
      ,.m_axi_arsize_o(hp0_axi_arsize)
      ,.m_axi_arburst_o(hp0_axi_arburst)
      ,.m_axi_arqos_o(hp0_axi_arqos)

      ,.m_axi_rdata_i(hp0_axi_rdata)
      ,.m_axi_rvalid_i(hp0_axi_rvalid)
      ,.m_axi_rready_o(hp0_axi_rready)
      ,.m_axi_rid_i(hp0_axi_rid)
      ,.m_axi_rlast_i(hp0_axi_rlast)
      ,.m_axi_rresp_i(hp0_axi_rresp)
      );

   // synopsys translate_off
   always @(negedge aclk)
     if (aresetn !== '0 & bb_v_li & ~bb_ready_and_lo == 1'b1)
       $error("top_zynq: bitbang bit drop occurred");

   always @(negedge aclk)
     if (gp1_axi_awvalid & gp1_axi_awready)
       if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",gp1_axi_awaddr,gp1_awaddr_translated_lo);

   always @(negedge aclk)
     if (gp1_axi_arvalid & gp1_axi_arready)
       if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",gp1_axi_araddr,gp1_araddr_translated_lo);
   // synopsys translate_on


endmodule

