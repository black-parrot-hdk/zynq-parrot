
`timescale 1 ps / 1 ps

`include "bsg_tag.vh"
`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import zynq_pkg::*;
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
 import bsg_tag_pkg::*;
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
   , parameter integer C_M00_AXI_DATA_WIDTH   = 64
   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
   )
  (input wire                                    aclk
   , input wire                                  aresetn
   , input wire                                  rt_clk

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

   localparam bp_axil_addr_width_lp = 32;
   localparam bp_axil_data_width_lp = 32;
   localparam bp_axi_addr_width_lp  = 32;
   localparam bp_axi_data_width_lp  = 64;
   localparam bp_credits_lp         = 32;
   localparam num_regs_ps_to_pl_lp  = 3;
   localparam num_regs_pl_to_ps_lp  = 7;
   localparam num_fifos_ps_to_pl_lp = 2;
   localparam num_fifos_pl_to_ps_lp = 2;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_lo:
   //
   // 0: System-wide reset (low true); note: it is only legal to assert reset if you are
   //    finished with all AXI transactions (fixme: potential improvement to detect this)
   // 4: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
   // 8: The base register for the allocated dram
   //
   logic [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_li:
   //
   // 0: bp i/o credits
   // 4: minstret (64b)
   // c: mem_profiler (128b)
   //
   logic [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

   ///////////////////////////////////////////////////////////////////////////////////////
   // pl_to_ps_fifo_data_li:
   //
   // 0: BlackParrot memory fwd fifo
   // 4: BlackParrot store packer response
   logic [num_fifos_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   logic [num_fifos_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;


   ///////////////////////////////////////////////////////////////////////////////////////
   // ps_to_pl_fifo_data_li:
   //
   // 0: BlackParrot memory rev fifo
   // 4: BlackParrot store packer request
   logic [num_fifos_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   logic [num_fifos_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

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
   logic [`BSG_WIDTH(bp_credits_lp)-1:0] bp_s_credits_used;

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 256*1024*1024;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      // need to update C_S00_AXI_ADDR_WIDTH accordingly
      .num_fifo_ps_to_pl_p(num_fifos_ps_to_pl_lp)
      ,.num_fifo_pl_to_ps_p(num_fifos_pl_to_ps_lp)
      ,.num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
      ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_new_o(csr_data_new_lo)
        ,.csr_data_o(csr_data_lo)
        ,.csr_data_i(csr_data_li)

        ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_ready_li & ps_to_pl_fifo_v_lo)

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
   logic dram_init_li;
   logic [C_M00_AXI_ADDR_WIDTH-1:0] dram_base_li;
   logic [63:0] minstret_lo;
   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

   assign sys_resetn   = csr_data_lo[0][0]; // active-low
   assign dram_init_li = csr_data_lo[1];
   assign dram_base_li = csr_data_lo[2];

   assign csr_data_li[0] = bp_s_credits_used;
   assign csr_data_li[1] = minstret_lo[31:0];
   assign csr_data_li[2] = minstret_lo[63:32];
   assign csr_data_li[3] = mem_profiler_r[31:0];
   assign csr_data_li[4] = mem_profiler_r[63:32];
   assign csr_data_li[5] = mem_profiler_r[95:64];
   assign csr_data_li[6] = mem_profiler_r[127:96];

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
     assign minstret_lo = blackparrot.m.multicore.cc.y[0].x[0].tile_node.tile_node.tile.core.core_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;
   else
     assign minstret_lo = blackparrot.u.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;

  `declare_bp_bedrock_mem_if(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p);
  bp_bedrock_mem_fwd_header_s mem_fwd_header_lo;
  logic [dword_width_gp-1:0] mem_fwd_data_lo;
  logic mem_fwd_v_lo, mem_fwd_ready_and_li;
  bp_bedrock_mem_rev_header_s mem_rev_header_li;
  logic [dword_width_gp-1:0] mem_rev_data_li;
  logic mem_rev_v_li, mem_rev_ready_and_lo;
  bp_me_fifos_to_axil
   #(.bp_params_p(bp_params_p)
     ,.fifo_width_p(C_S00_AXI_DATA_WIDTH)
     ,.axil_data_width_p(bp_axil_data_width_lp)
     ,.axil_addr_width_p(bp_axil_addr_width_lp)
     ,.num_credits_p(bp_credits_lp)
     )
   f2b
    (.clk_i(aclk)
     ,.reset_i(~sys_resetn)

     ,.fifo_i(ps_to_pl_fifo_data_lo[0])
     ,.fifo_v_i(ps_to_pl_fifo_v_lo[0])
     ,.fifo_ready_and_o(ps_to_pl_fifo_ready_li[0])

     ,.fifo_o(pl_to_ps_fifo_data_li[0])
     ,.fifo_v_o(pl_to_ps_fifo_v_li[0])
     ,.fifo_ready_and_i(pl_to_ps_fifo_ready_lo[0])

     ,.m_axil_awaddr_o(bp_s_axil_awaddr)
     ,.m_axil_awprot_o(bp_s_axil_awprot)
     ,.m_axil_awvalid_o(bp_s_axil_awvalid)
     ,.m_axil_awready_i(bp_s_axil_awready)

     ,.m_axil_wdata_o(bp_s_axil_wdata)
     ,.m_axil_wstrb_o(bp_s_axil_wstrb)
     ,.m_axil_wvalid_o(bp_s_axil_wvalid)
     ,.m_axil_wready_i(bp_s_axil_wready)

     ,.m_axil_bresp_i(bp_s_axil_bresp)
     ,.m_axil_bvalid_i(bp_s_axil_bvalid)
     ,.m_axil_bready_o(bp_s_axil_bready)

     ,.m_axil_araddr_o(bp_s_axil_araddr)
     ,.m_axil_arprot_o(bp_s_axil_arprot)
     ,.m_axil_arvalid_o(bp_s_axil_arvalid)
     ,.m_axil_arready_i(bp_s_axil_arready)

     ,.m_axil_rdata_i(bp_s_axil_rdata)
     ,.m_axil_rresp_i(bp_s_axil_rresp)
     ,.m_axil_rvalid_i(bp_s_axil_rvalid)
     ,.m_axil_rready_o(bp_s_axil_rready)

     ,.credits_used_o(bp_s_credits_used)
     );

   bsg_axil_store_packer
    #(.axil_addr_width_p(bp_axil_addr_width_lp)
      ,.axil_data_width_p(bp_axil_data_width_lp)
      ,.payload_data_width_p(8)
      )
    store_packer
     (.clk_i   (aclk)
      ,.reset_i(~aresetn)

      ,.s_axil_awaddr_i (bp_m_axil_awaddr)
      ,.s_axil_awprot_i (bp_m_axil_awprot)
      ,.s_axil_awvalid_i(bp_m_axil_awvalid)
      ,.s_axil_awready_o(bp_m_axil_awready)

      ,.s_axil_wdata_i  (bp_m_axil_wdata)
      ,.s_axil_wstrb_i  (bp_m_axil_wstrb)
      ,.s_axil_wvalid_i (bp_m_axil_wvalid)
      ,.s_axil_wready_o (bp_m_axil_wready)

      ,.s_axil_bresp_o  (bp_m_axil_bresp)
      ,.s_axil_bvalid_o (bp_m_axil_bvalid)
      ,.s_axil_bready_i (bp_m_axil_bready)

      ,.s_axil_araddr_i (bp_m_axil_araddr)
      ,.s_axil_arprot_i (bp_m_axil_arprot)
      ,.s_axil_arvalid_i(bp_m_axil_arvalid)
      ,.s_axil_arready_o(bp_m_axil_arready)

      ,.s_axil_rdata_o  (bp_m_axil_rdata)
      ,.s_axil_rresp_o  (bp_m_axil_rresp)
      ,.s_axil_rvalid_o (bp_m_axil_rvalid)
      ,.s_axil_rready_i (bp_m_axil_rready)

      ,.data_o (pl_to_ps_fifo_data_li[1])
      ,.v_o    (pl_to_ps_fifo_v_li[1])
      ,.ready_i(pl_to_ps_fifo_ready_lo[1])

      ,.data_i(ps_to_pl_fifo_data_lo[1])
      ,.v_i(ps_to_pl_fifo_v_lo[1])
      ,.ready_o(ps_to_pl_fifo_ready_li[1])
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

   // synopsys translate_off

   always @(negedge aclk)
     if (m00_axi_awvalid & m00_axi_awready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

   always @(negedge aclk)
     if (m00_axi_arvalid & m00_axi_arready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);

   // synopsys translate_on

   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(aclk)
      ,.reset_i(~sys_resetn)
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
      )
   blackparrot
     (.clk_i(aclk)
      ,.reset_i(~sys_resetn)
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

endmodule

