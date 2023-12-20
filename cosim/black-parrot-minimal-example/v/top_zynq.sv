
`timescale 1 ps / 1 ps

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

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 256*1024*1024;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      // need to update C_S00_AXI_ADDR_WIDTH accordingly
      .num_fifo_ps_to_pl_p(num_fifos_ps_to_pl_lp)
      ,.num_fifo_pl_to_ps_p(num_fifos_pl_to_ps_lp)
      ,.num_regs_ps_to_pl_p(num_regs_ps_to_pl_lp)
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
   logic [`BSG_WIDTH(bp_credits_lp)-1:0] bp_credits_used;
   logic [63:0] minstret_lo;
   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

   assign sys_resetn   = csr_data_lo[0][0]; // active-low
   assign dram_init_li = csr_data_lo[1];
   assign dram_base_li = csr_data_lo[2];

   assign csr_data_li[0] = |bp_credits_used;
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
   assign minstret_lo = blackparrot.u.unicore.unicore_lite.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;

   `declare_bp_bedrock_if(paddr_width_p, lce_id_width_p, cce_id_width_p, did_width_p, lce_assoc_p);
   bp_bedrock_mem_fwd_header_s mem_fwd_header_li;
   logic [bedrock_fill_width_p-1:0] mem_fwd_data_li;
   logic mem_fwd_v_li, mem_fwd_ready_and_lo;
   bp_bedrock_mem_rev_header_s mem_rev_header_lo;
   logic [bedrock_fill_width_p-1:0] mem_rev_data_lo;
   logic mem_rev_v_lo, mem_rev_ready_and_li;
   bp_bedrock_mem_fwd_header_s mem_fwd_header_lo;
   logic [bedrock_fill_width_p-1:0] mem_fwd_data_lo;
   logic mem_fwd_v_lo, mem_fwd_ready_and_li;
   bp_bedrock_mem_rev_header_s mem_rev_header_li;
   logic [bedrock_fill_width_p-1:0] mem_rev_data_li;
   logic mem_rev_v_li, mem_rev_ready_and_lo;
   bp_me_endpoint_to_fifos
    #(.bp_params_p(bp_params_p)
      ,.fifo_width_p(C_S00_AXI_DATA_WIDTH)
      ,.num_credits_p(bp_credits_lp)
      )
    f2b
     (.clk_i(aclk)
      ,.reset_i(~sys_resetn)

      ,.fwd_fifo_i(ps_to_pl_fifo_data_lo[0])
      ,.fwd_fifo_v_i(ps_to_pl_fifo_v_lo[0])
      ,.fwd_fifo_ready_and_o(ps_to_pl_fifo_ready_li[0])

      ,.rev_fifo_o(pl_to_ps_fifo_data_li[0])
      ,.rev_fifo_v_o(pl_to_ps_fifo_v_li[0])
      ,.rev_fifo_ready_and_i(pl_to_ps_fifo_ready_lo[0])

      ,.fwd_fifo_o(pl_to_ps_fifo_data_li[1])
      ,.fwd_fifo_v_o(pl_to_ps_fifo_v_li[1])
      ,.fwd_fifo_ready_and_i(pl_to_ps_fifo_ready_lo[1])

      ,.rev_fifo_i(ps_to_pl_fifo_data_lo[1])
      ,.rev_fifo_v_i(ps_to_pl_fifo_v_lo[1])
      ,.rev_fifo_ready_and_o(ps_to_pl_fifo_ready_li[1])

      ,.mem_fwd_header_o(mem_fwd_header_li)
      ,.mem_fwd_data_o(mem_fwd_data_li)
      ,.mem_fwd_v_o(mem_fwd_v_li)
      ,.mem_fwd_ready_and_i(mem_fwd_ready_and_lo)

      ,.mem_rev_header_i(mem_rev_header_lo)
      ,.mem_rev_data_i(mem_rev_data_lo)
      ,.mem_rev_v_i(mem_rev_v_lo)
      ,.mem_rev_ready_and_o(mem_rev_ready_and_li)

      ,.mem_fwd_header_i(mem_fwd_header_lo)
      ,.mem_fwd_data_i(mem_fwd_data_lo)
      ,.mem_fwd_v_i(mem_fwd_v_lo)
      ,.mem_fwd_ready_and_o(mem_fwd_ready_and_li)

      ,.mem_rev_header_o(mem_rev_header_li)
      ,.mem_rev_data_o(mem_rev_data_li)
      ,.mem_rev_v_o(mem_rev_v_li)
      ,.mem_rev_ready_and_i(mem_rev_ready_and_lo)

      ,.credits_used_o(bp_credits_used)
      );

   logic [C_M00_AXI_ADDR_WIDTH-1:0] axi_awaddr;
   logic [C_M00_AXI_ADDR_WIDTH-1:0] axi_araddr;

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

   `declare_bsg_cache_dma_pkt_s(daddr_width_p, l2_block_size_in_words_p);
   bsg_cache_dma_pkt_s [num_cce_p*l2_banks_p-1:0] dma_pkt_lo;
   logic [num_cce_p*l2_banks_p-1:0] dma_pkt_v_lo, dma_pkt_ready_and_li;
   logic [num_cce_p*l2_banks_p-1:0][l2_fill_width_p-1:0] dma_data_lo;
   logic [num_cce_p*l2_banks_p-1:0] dma_data_v_lo, dma_data_ready_and_li;
   logic [num_cce_p*l2_banks_p-1:0][l2_fill_width_p-1:0] dma_data_li;
   logic [num_cce_p*l2_banks_p-1:0] dma_data_v_li, dma_data_ready_and_lo;
   bp_processor
    #(.bp_params_p(bp_params_p))
    blackparrot
     (.clk_i(aclk)
      ,.rt_clk_i(rt_clk)
      ,.reset_i(~aresetn)
  
      ,.my_did_i('0)
      ,.host_did_i('0)
  
      ,.mem_fwd_header_o(mem_fwd_header_lo)
      ,.mem_fwd_data_o(mem_fwd_data_lo)
      ,.mem_fwd_v_o(mem_fwd_v_lo)
      ,.mem_fwd_ready_and_i(mem_fwd_ready_and_li)
  
      ,.mem_rev_header_i(mem_rev_header_li)
      ,.mem_rev_data_i(mem_rev_data_li)
      ,.mem_rev_v_i(mem_rev_v_li)
      ,.mem_rev_ready_and_o(mem_rev_ready_and_lo)
  
      ,.mem_fwd_header_i(mem_fwd_header_li)
      ,.mem_fwd_data_i(mem_fwd_data_li)
      ,.mem_fwd_v_i(mem_fwd_v_li)
      ,.mem_fwd_ready_and_o(mem_fwd_ready_and_lo)
  
      ,.mem_rev_header_o(mem_rev_header_lo)
      ,.mem_rev_data_o(mem_rev_data_lo)
      ,.mem_rev_v_o(mem_rev_v_lo)
      ,.mem_rev_ready_and_i(mem_rev_ready_and_li)
  
      ,.dma_pkt_o(dma_pkt_lo)
      ,.dma_pkt_v_o(dma_pkt_v_lo)
      ,.dma_pkt_ready_and_i(dma_pkt_ready_and_li)
  
      ,.dma_data_i(dma_data_li)
      ,.dma_data_v_i(dma_data_v_li)
      ,.dma_data_ready_and_o(dma_data_ready_and_lo)
  
      ,.dma_data_o(dma_data_lo)
      ,.dma_data_v_o(dma_data_v_lo)
      ,.dma_data_ready_and_i(dma_data_ready_and_li)
      );

  // If necessary, downsize to axi data width. This could be done in bsg_cache_to_axi,
  //   but punt for now
  logic [num_cce_p*l2_banks_p-1:0][C_M00_AXI_DATA_WIDTH-1:0] axi_dma_data_lo;
  logic [num_cce_p*l2_banks_p-1:0] axi_dma_data_v_lo, axi_dma_data_ready_and_li;
  logic [num_cce_p*l2_banks_p-1:0][C_M00_AXI_DATA_WIDTH-1:0] axi_dma_data_li;
  logic [num_cce_p*l2_banks_p-1:0] axi_dma_data_v_li, axi_dma_data_yumi_lo;
  for (genvar i = 0; i < num_cce_p*l2_banks_p; i++)
    begin : narrow
      bsg_serial_in_parallel_out_full
       #(.width_p(C_M00_AXI_DATA_WIDTH), .els_p(l2_fill_width_p/C_M00_AXI_DATA_WIDTH))
       dma_piso
        (.clk_i(aclk)
         ,.reset_i(~aresetn)

         ,.data_i(axi_dma_data_lo[i])
         ,.v_i(axi_dma_data_v_lo[i])
         ,.ready_and_o(axi_dma_data_ready_and_li[i])

         ,.data_o(dma_data_li[i])
         ,.v_o(dma_data_v_li[i])
         ,.yumi_i(dma_data_ready_and_lo[i] & dma_data_v_li[i])
         );

      bsg_parallel_in_serial_out
       #(.width_p(C_M00_AXI_DATA_WIDTH), .els_p(l2_fill_width_p/C_M00_AXI_DATA_WIDTH))
       dma_sipo
        (.clk_i(aclk)
         ,.reset_i(~aresetn)

         ,.data_i(dma_data_lo[i])
         ,.valid_i(dma_data_v_lo[i])
         ,.ready_and_o(dma_data_ready_and_li[i])

         ,.data_o(axi_dma_data_li[i])
         ,.valid_o(axi_dma_data_v_li[i])
         ,.yumi_i(axi_dma_data_yumi_lo[i])
         );
    end

   import bsg_axi_pkg::*;
   bsg_cache_to_axi
    #(.addr_width_p(daddr_width_p)
      ,.data_width_p(C_M00_AXI_DATA_WIDTH)
      ,.mask_width_p(l2_block_size_in_words_p)
      ,.block_size_in_words_p(l2_block_width_p/C_M00_AXI_DATA_WIDTH)
      ,.num_cache_p(num_cce_p*l2_banks_p)
      ,.axi_data_width_p(C_M00_AXI_DATA_WIDTH)
      ,.axi_id_width_p(6)
      ,.axi_burst_len_p(l2_block_width_p/C_M00_AXI_DATA_WIDTH)
      ,.axi_burst_type_p(e_axi_burst_incr)
      ,.ordering_en_p(1)
      )
    cache2axi
     (.clk_i(aclk)
      ,.reset_i(~aresetn)

      ,.dma_pkt_i(dma_pkt_lo)
      ,.dma_pkt_v_i(dma_pkt_v_lo)
      ,.dma_pkt_yumi_o(dma_pkt_ready_and_li)

      ,.dma_data_o(axi_dma_data_lo)
      ,.dma_data_v_o(axi_dma_data_v_lo)
      ,.dma_data_ready_and_i(axi_dma_data_ready_and_li)

      ,.dma_data_i(axi_dma_data_li)
      ,.dma_data_v_i(axi_dma_data_v_li)
      ,.dma_data_yumi_o(axi_dma_data_yumi_lo)

      ,.axi_awid_o(m00_axi_awid)
      ,.axi_awaddr_addr_o(axi_awaddr)
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

      // Unused
      ,.axi_awaddr_cache_id_o()
      ,.axi_araddr_cache_id_o()
      );

endmodule

