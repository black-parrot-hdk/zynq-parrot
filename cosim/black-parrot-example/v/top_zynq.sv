
`timescale 1 ns / 1 ps

`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)

   , localparam uce_mem_data_width_lp = `BSG_MAX(icache_fill_width_p, dcache_fill_width_p)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce)

   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   , parameter integer C_S00_AXI_DATA_WIDTH   = 32

   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_S00_AXI_ADDR_WIDTH   = 6
   , parameter integer C_S01_AXI_DATA_WIDTH   = 32
   // the ARM AXI S01 interface drops the top two bits
   , parameter integer C_S01_AXI_ADDR_WIDTH   = 30
   , parameter integer C_M00_AXI_DATA_WIDTH   = 64
   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
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
   );

   logic [2:0][C_S00_AXI_DATA_WIDTH-1:0]        csr_data_lo;
   logic [C_S00_AXI_DATA_WIDTH-1:0]             pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic                                        pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic                                        ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

   logic [C_S01_AXI_ADDR_WIDTH-1 : 0]           m01_axi_awaddr;
   logic [2 : 0]                                m01_axi_awprot;
   logic                                        m01_axi_awvalid;
   logic                                        m01_axi_awready;
   logic [C_S01_AXI_DATA_WIDTH-1 : 0]           m01_axi_wdata;
   logic [(C_S01_AXI_DATA_WIDTH/8)-1 : 0]       m01_axi_wstrb;
   logic                                        m01_axi_wvalid;
   logic                                        m01_axi_wready;
   logic  [1 : 0]                               m01_axi_bresp;
   logic                                        m01_axi_bvalid;
   logic                                        m01_axi_bready;
   logic [C_S01_AXI_ADDR_WIDTH-1 : 0]           m01_axi_araddr;
   logic [2 : 0]                                m01_axi_arprot;
   logic                                        m01_axi_arvalid;
   logic                                        m01_axi_arready;
   logic  [C_S01_AXI_DATA_WIDTH-1 : 0]          m01_axi_rdata;
   logic  [1 : 0]                               m01_axi_rresp;
   logic                                        m01_axi_rvalid;
   logic                                        m01_axi_rready;

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 120*1024*1024;

   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

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

        ,.csr_data_i({ mem_profiler_r[127:96]
                       , mem_profiler_r[95:64]
                       , mem_profiler_r[63:32]
                       , mem_profiler_r[31:0]
                       , blackparrot.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo[63:32]
                       , blackparrot.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo[31:0]}
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

   // Add user logic here

   //`declare_bp_bedrock_mem_if(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce);

   //bp_bedrock_uce_mem_msg_s   io_cmd_lo, io_resp_li;
   //logic                      io_cmd_v_lo, io_cmd_ready_and_li;
   //logic                      io_resp_v_li, io_resp_yumi_lo;

   `declare_bsg_cache_dma_pkt_s(caddr_width_p);
   bsg_cache_dma_pkt_s dma_pkt_lo;
   logic                       dma_pkt_v_lo, dma_pkt_yumi_li;
   logic [l2_fill_width_p-1:0] dma_data_lo;
   logic                       dma_data_v_lo, dma_data_yumi_li;
   logic [l2_fill_width_p-1:0] dma_data_li;
   logic                       dma_data_v_li, dma_data_ready_and_lo;

   localparam bp_axi_lite_addr_width_lp = 32;

   logic [bp_axi_lite_addr_width_lp-1:0] waddr_translated_lo, raddr_translated_lo;

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

   logic [31:0] waddr_offset, raddr_offset;

   always_comb
     begin
        // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
        // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF

        waddr_translated_lo = {~s01_axi_awaddr[29], 3'b0, s01_axi_awaddr[0+:28]};
     end

   always_comb
     begin
        // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
        // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF

        raddr_translated_lo = {~s01_axi_araddr[29], 3'b0, s01_axi_araddr[0+:28]};
     end

   axil_store_packer
    #(.axi_addr_width_p(bp_axi_lite_addr_width_lp)
      ,.axi_data_width_p(32)
      )
    store_packer
     (.clk_i   (s01_axi_aclk)
      ,.reset_i(~s01_axi_aresetn)

      ,.s_axi_awaddr_i (m01_axi_awaddr)
      ,.s_axi_awprot_i (m01_axi_awprot)
      ,.s_axi_awvalid_i(m01_axi_awvalid)
      ,.s_axi_awready_o(m01_axi_awready)

      ,.s_axi_wdata_i  (m01_axi_wdata)
      ,.s_axi_wstrb_i  (m01_axi_wstrb)
      ,.s_axi_wvalid_i (m01_axi_wvalid)
      ,.s_axi_wready_o (m01_axi_wready)

      ,.s_axi_bresp_o  (m01_axi_bresp)
      ,.s_axi_bvalid_o (m01_axi_bvalid)
      ,.s_axi_bready_i (m01_axi_bready)

      ,.s_axi_araddr_i (m01_axi_araddr)
      ,.s_axi_arprot_i (m01_axi_arprot)
      ,.s_axi_arvalid_i(m01_axi_arvalid)
      ,.s_axi_arready_o(m01_axi_arready)

      ,.s_axi_rdata_o  (m01_axi_rdata)
      ,.s_axi_rresp_o  (m01_axi_rresp)
      ,.s_axi_rvalid_o (m01_axi_rvalid)
      ,.s_axi_rready_i (m01_axi_rready)

      ,.data_o (pl_to_ps_fifo_data_li)
      ,.v_o    (pl_to_ps_fifo_v_li)
      ,.ready_i(pl_to_ps_fifo_ready_lo)

      ,.data_i(ps_to_pl_fifo_data_lo)
      ,.v_i(ps_to_pl_fifo_v_lo)
      ,.ready_o(ps_to_pl_fifo_ready_li)
      );

   localparam axi_addr_width_p = 32;
   localparam axi_data_width_p = 64;

   wire [axi_addr_width_p-1:0] axi_awaddr;
   wire [axi_addr_width_p-1:0] axi_araddr;

   // to translate from BP DRAM space to ARM PS DRAM space
   // we xor-subtract the BP DRAM base address (32'h8000_0000) and add the
   // ARM PS allocated memory space physical address.

   always @(negedge s01_axi_aclk)
     begin
        if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
        if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
     end

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
   // BlackParrot reset signal is connected to a CSR (along with
   // the AXI interface reset) so that a regression can be launched
   // without having to reload the bitstream
   wire bp_reset_li = (~csr_data_lo[0][0]) || (~s01_axi_aresetn);


   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(s01_axi_aclk)
      ,.reset_i(bp_reset_li)
      ,.data_i(mem_profiler_r
               | m00_axi_awvalid << (axi_awaddr[29-:7])
               | m00_axi_arvalid << (axi_araddr[29-:7])
               )
      ,.data_o(mem_profiler_r)
      );

   bp_unicore_axi_sim #
     (.bp_params_p(bp_params_p)
      ,.axi_lite_addr_width_p(bp_axi_lite_addr_width_lp)
      )
   blackparrot
     (.clk_i(s01_axi_aclk)
      ,.reset_i(bp_reset_li)

      // these are reads/write from BlackParrot
      ,.m_axi_lite_awaddr_o (m01_axi_awaddr)
      ,.m_axi_lite_awprot_o (m01_axi_awprot)
      ,.m_axi_lite_awvalid_o(m01_axi_awvalid)
      ,.m_axi_lite_awready_i(m01_axi_awready)

      ,.m_axi_lite_wdata_o  (m01_axi_wdata)
      ,.m_axi_lite_wstrb_o  (m01_axi_wstrb)
      ,.m_axi_lite_wvalid_o (m01_axi_wvalid)
      ,.m_axi_lite_wready_i (m01_axi_wready)

      ,.m_axi_lite_bresp_i  (m01_axi_bresp)
      ,.m_axi_lite_bvalid_i (m01_axi_bvalid)
      ,.m_axi_lite_bready_o (m01_axi_bready)

      ,.m_axi_lite_araddr_o (m01_axi_araddr)
      ,.m_axi_lite_arprot_o (m01_axi_arprot)
      ,.m_axi_lite_arvalid_o(m01_axi_arvalid)
      ,.m_axi_lite_arready_i(m01_axi_arready)

      ,.m_axi_lite_rdata_i  (m01_axi_rdata)
      ,.m_axi_lite_rresp_i  (m01_axi_rresp)
      ,.m_axi_lite_rvalid_i (m01_axi_rvalid)
      ,.m_axi_lite_rready_o (m01_axi_rready)

      // these are reads/writes into BlackParrot
      // from the Zynq PS ARM core
      ,.s_axi_lite_awaddr_i (waddr_translated_lo)
      ,.s_axi_lite_awprot_i (s01_axi_awprot)
      ,.s_axi_lite_awvalid_i(s01_axi_awvalid)
      ,.s_axi_lite_awready_o(s01_axi_awready)

      ,.s_axi_lite_wdata_i  (s01_axi_wdata)
      ,.s_axi_lite_wstrb_i  (s01_axi_wstrb)
      ,.s_axi_lite_wvalid_i (s01_axi_wvalid)
      ,.s_axi_lite_wready_o (s01_axi_wready)

      ,.s_axi_lite_bresp_o  (s01_axi_bresp)
      ,.s_axi_lite_bvalid_o (s01_axi_bvalid)
      ,.s_axi_lite_bready_i (s01_axi_bready)

      ,.s_axi_lite_araddr_i (raddr_translated_lo)
      ,.s_axi_lite_arprot_i (s01_axi_arprot)
      ,.s_axi_lite_arvalid_i(s01_axi_arvalid)
      ,.s_axi_lite_arready_o(s01_axi_arready)

      ,.s_axi_lite_rdata_o  (s01_axi_rdata)
      ,.s_axi_lite_rresp_o  (s01_axi_rresp)
      ,.s_axi_lite_rvalid_o (s01_axi_rvalid)
      ,.s_axi_lite_rready_i (s01_axi_rready)

      ,.m_axi_awaddr_o   (m00_axi_awaddr)
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

      ,.m_axi_araddr_o   (m00_axi_araddr)
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
   always @(negedge s01_axi_aclk)
     if (s01_axi_awvalid & s01_axi_awready)
       if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,waddr_translated_lo);

   always @(negedge s01_axi_aclk)
     if (s01_axi_arvalid & s01_axi_arready)
       if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,raddr_translated_lo);
   // synopsys translate_on


endmodule

