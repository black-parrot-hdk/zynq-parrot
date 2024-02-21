
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
   , parameter integer C_M00_AXI_DATA_WIDTH   = 32
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
   localparam num_regs_ps_to_pl_lp  = 10;
   localparam num_regs_pl_to_ps_lp  = 4;
   localparam num_fifos_ps_to_pl_lp = 2;
   localparam num_fifos_pl_to_ps_lp = 2;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_lo:
   //
   // 0: System-wide reset (low true); note: it is only legal to assert reset if you are
   //    finished with all AXI transactions (fixme: potential improvement to detect this)
   // 4: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
   // 8: The base register for the allocated dram
   // c: bootrom addr
   //
   logic [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_li:
   //
   // 0 : bp i/o credits
   // 4 : minstret (64b)
   // 8 : bootrom data
   //
   logic [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

   ///////////////////////////////////////////////////////////////////////////////////////
   // pl_to_ps_fifo_data_li:
   //
   // 0: BlackParrot memory fwd fifo
   // 4: BlackParrot memory rev fifo
   logic [num_fifos_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   logic [num_fifos_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;


   ///////////////////////////////////////////////////////////////////////////////////////
   // ps_to_pl_fifo_data_li:
   //
   // 0: BlackParrot memory rev fifo
   // 4: BlackParrot memory fwd fifo
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
   localparam bootrom_data_lp = 32;
   localparam bootrom_addr_lp = 9;
   logic sys_resetn, dram_init_li;
   logic [C_M00_AXI_ADDR_WIDTH-1:0] dram_base_li;
   logic debug_irq_li, timer_irq_li, software_irq_li, m_external_irq_li, s_external_irq_li;
   logic freeze_li;
   logic [63:0] minstret_lo;
   logic [bootrom_data_lp-1:0] bootrom_data_li;
   logic [bootrom_addr_lp-1:0] bootrom_addr_lo;
   logic [`BSG_WIDTH(bp_credits_lp)-1:0] bp_credits_used;

   assign sys_resetn   = csr_data_lo[0][0]; // active-low
   assign dram_init_li = csr_data_lo[1];
   assign dram_base_li = csr_data_lo[2];
   assign bootrom_addr_lo = csr_data_lo[3];
   assign debug_irq_li = csr_data_lo[4];
   assign timer_irq_li = csr_data_lo[5];
   assign software_irq_li = csr_data_lo[6];
   assign m_external_irq_li = csr_data_lo[7];
   assign s_external_irq_li = csr_data_lo[8];
   assign freeze_li = csr_data_lo[9];

   assign csr_data_li[0] = |bp_credits_used;
   assign csr_data_li[1] = minstret_lo[31:0];
   assign csr_data_li[2] = minstret_lo[63:32];
   assign csr_data_li[3] = bootrom_data_li;

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
   assign minstret_lo = blackparrot.core_minimal.be.calculator.pipe_sys.csr.minstret_lo;

  bsg_bootrom
   #(.width_p(bootrom_data_lp), .addr_width_p(bootrom_addr_lp))
   bootrom
    (.addr_i(bootrom_addr_lo), .data_o(bootrom_data_li));

   `declare_bp_bedrock_if(paddr_width_p, lce_id_width_p, cce_id_width_p, did_width_p, lce_assoc_p);
   localparam icache_proc_id_lp =                     0;
   localparam dcache_proc_id_lp = icache_proc_id_lp + 1;
   localparam ep_proc_id_lp     = dcache_proc_id_lp + 1;
   localparam num_proc_lp       = ep_proc_id_lp     + 1;
   localparam lg_num_proc_lp    = `BSG_SAFE_CLOG2(num_proc_lp);

   localparam mem_dev_id_lp      =                      0;
   localparam ep_dev_id_lp       = mem_dev_id_lp      + 1;
   localparam num_dev_lp         = ep_dev_id_lp       + 1;
   localparam lg_num_dev_lp      = `BSG_SAFE_CLOG2(num_dev_lp);

   bp_bedrock_mem_fwd_header_s [num_proc_lp-1:0] proc_fwd_header_lo;
   logic [num_proc_lp-1:0][bedrock_fill_width_p-1:0] proc_fwd_data_lo;
   logic [num_proc_lp-1:0] proc_fwd_v_lo, proc_fwd_ready_and_li;
   bp_bedrock_mem_rev_header_s [num_proc_lp-1:0] proc_rev_header_li;
   logic [num_proc_lp-1:0][bedrock_fill_width_p-1:0] proc_rev_data_li;
   logic [num_proc_lp-1:0] proc_rev_v_li, proc_rev_ready_and_lo;

   bp_bedrock_mem_fwd_header_s [num_dev_lp-1:0] dev_fwd_header_li;
   logic [num_dev_lp-1:0][bedrock_fill_width_p-1:0] dev_fwd_data_li;
   logic [num_dev_lp-1:0] dev_fwd_v_li, dev_fwd_ready_and_lo;
   bp_bedrock_mem_rev_header_s [num_dev_lp-1:0] dev_rev_header_lo;
   logic [num_dev_lp-1:0][bedrock_fill_width_p-1:0] dev_rev_data_lo;
   logic [num_dev_lp-1:0] dev_rev_v_lo, dev_rev_ready_and_li;

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

      ,.mem_fwd_header_o(proc_fwd_header_lo[ep_proc_id_lp])
      ,.mem_fwd_data_o(proc_fwd_data_lo[ep_proc_id_lp])
      ,.mem_fwd_v_o(proc_fwd_v_lo[ep_proc_id_lp])
      ,.mem_fwd_ready_and_i(proc_fwd_ready_and_li[ep_proc_id_lp])

      ,.mem_rev_header_i(proc_rev_header_li[ep_proc_id_lp])
      ,.mem_rev_data_i(proc_rev_data_li[ep_proc_id_lp])
      ,.mem_rev_v_i(proc_rev_v_li[ep_proc_id_lp])
      ,.mem_rev_ready_and_o(proc_rev_ready_and_lo[ep_proc_id_lp])

      ,.mem_fwd_header_i(dev_fwd_header_li[ep_dev_id_lp])
      ,.mem_fwd_data_i(dev_fwd_data_li[ep_dev_id_lp])
      ,.mem_fwd_v_i(dev_fwd_v_li[ep_dev_id_lp])
      ,.mem_fwd_ready_and_o(dev_fwd_ready_and_lo[ep_dev_id_lp])

      ,.mem_rev_header_o(dev_rev_header_lo[ep_dev_id_lp])
      ,.mem_rev_data_o(dev_rev_data_lo[ep_dev_id_lp])
      ,.mem_rev_v_o(dev_rev_v_lo[ep_dev_id_lp])
      ,.mem_rev_ready_and_i(dev_rev_ready_and_li[ep_dev_id_lp])

      ,.credits_used_o(bp_credits_used)
      );

   logic [C_M00_AXI_ADDR_WIDTH-1:0] m_axil_awaddr;
   logic [2:0] m_axil_awprot;
   logic m_axil_awvalid, m_axil_awready;
   logic [C_M00_AXI_DATA_WIDTH-1:0] m_axil_wdata;
   logic [C_M00_AXI_DATA_WIDTH/8-1:0] m_axil_wstrb;
   logic m_axil_wvalid, m_axil_wready;
   logic [1:0] m_axil_bresp;
   logic m_axil_bvalid, m_axil_bready;
   logic [C_M00_AXI_ADDR_WIDTH-1:0] m_axil_araddr;
   logic [2:0] m_axil_arprot;
   logic m_axil_arvalid, m_axil_arready;
   logic [C_M00_AXI_DATA_WIDTH-1:0] m_axil_rdata;
   logic [1:0] m_axil_rresp;
   logic m_axil_rvalid, m_axil_rready;
   bp_me_axil_master
    #(.bp_params_p(bp_params_p)
      ,.axil_data_width_p(C_M00_AXI_DATA_WIDTH)
      ,.axil_addr_width_p(C_M00_AXI_ADDR_WIDTH)
      )
    mem2axil
     (.clk_i(aclk)
      ,.reset_i(~sys_resetn)

      ,.mem_fwd_header_i(dev_fwd_header_li[mem_dev_id_lp])
      ,.mem_fwd_data_i(dev_fwd_data_li[mem_dev_id_lp])
      ,.mem_fwd_v_i(dev_fwd_v_li[mem_dev_id_lp])
      ,.mem_fwd_ready_and_o(dev_fwd_ready_and_lo[mem_dev_id_lp])

      ,.mem_rev_header_o(dev_rev_header_lo[mem_dev_id_lp])
      ,.mem_rev_data_o(dev_rev_data_lo[mem_dev_id_lp])
      ,.mem_rev_v_o(dev_rev_v_lo[mem_dev_id_lp])
      ,.mem_rev_ready_and_i(dev_rev_ready_and_li[mem_dev_id_lp])

      ,.m_axil_awaddr_o(m_axil_awaddr)
      ,.m_axil_awprot_o(m_axil_awprot)
      ,.m_axil_awvalid_o(m_axil_awvalid)
      ,.m_axil_awready_i(m_axil_awready)

      ,.m_axil_wdata_o(m_axil_wdata)
      ,.m_axil_wstrb_o(m_axil_wstrb)
      ,.m_axil_wvalid_o(m_axil_wvalid)
      ,.m_axil_wready_i(m_axil_wready)

      ,.m_axil_bresp_i(m_axil_bresp)
      ,.m_axil_bvalid_i(m_axil_bvalid)
      ,.m_axil_bready_o(m_axil_bready)

      ,.m_axil_araddr_o(m_axil_araddr)
      ,.m_axil_arprot_o(m_axil_arprot)
      ,.m_axil_arvalid_o(m_axil_arvalid)
      ,.m_axil_arready_i(m_axil_arready)

      ,.m_axil_rdata_i(m_axil_rdata)
      ,.m_axil_rresp_i(m_axil_rresp)
      ,.m_axil_rvalid_i(m_axil_rvalid)
      ,.m_axil_rready_o(m_axil_rready)
      );

  // May want to make a config register
  `declare_bp_cfg_bus_s(vaddr_width_p, hio_width_p, core_id_width_p, cce_id_width_p, lce_id_width_p, did_width_p);
  wire [did_width_p-1:0] my_did_li = '0;
  bp_cfg_bus_s cfg_bus_li;
  assign cfg_bus_li =
    '{freeze      : freeze_li
      ,npc        : 32'h0110000
      ,core_id    : '0
      ,icache_id  : '0
      ,icache_mode: e_lce_mode_normal
      ,dcache_id  : 1'b1
      ,dcache_mode: e_lce_mode_normal
      ,cce_id     : '0
      ,cce_mode   : e_cce_mode_uncached
      ,hio_mask   : '1
      ,did        : my_did_li
      };

  bp_unicore_lite
   #(.bp_params_p(bp_params_p))
   blackparrot
    (.clk_i(aclk)
     ,.reset_i(~sys_resetn)
     ,.cfg_bus_i(cfg_bus_li) 
 
     ,.mem_fwd_header_o({proc_fwd_header_lo[dcache_proc_id_lp], proc_fwd_header_lo[icache_proc_id_lp]})
     ,.mem_fwd_data_o({proc_fwd_data_lo[dcache_proc_id_lp], proc_fwd_data_lo[icache_proc_id_lp]})
     ,.mem_fwd_v_o({proc_fwd_v_lo[dcache_proc_id_lp], proc_fwd_v_lo[icache_proc_id_lp]})
     ,.mem_fwd_ready_and_i({proc_fwd_ready_and_li[dcache_proc_id_lp], proc_fwd_ready_and_li[icache_proc_id_lp]})

     ,.mem_rev_header_i({proc_rev_header_li[dcache_proc_id_lp], proc_rev_header_li[icache_proc_id_lp]})
     ,.mem_rev_data_i({proc_rev_data_li[dcache_proc_id_lp], proc_rev_data_li[icache_proc_id_lp]})
     ,.mem_rev_v_i({proc_rev_v_li[dcache_proc_id_lp], proc_rev_v_li[icache_proc_id_lp]})
     ,.mem_rev_ready_and_o({proc_rev_ready_and_lo[dcache_proc_id_lp], proc_rev_ready_and_lo[icache_proc_id_lp]}) 
  
     ,.debug_irq_i(debug_irq_li)
     ,.timer_irq_i(timer_irq_li)
     ,.software_irq_i(software_irq_li)
     ,.m_external_irq_i(m_external_irq_li)
     ,.s_external_irq_i(s_external_irq_li)
     );

  `declare_bp_memory_map(paddr_width_p, daddr_width_p);
  logic [num_proc_lp-1:0][lg_num_dev_lp-1:0] proc_fwd_dst_lo;
  for (genvar i = 0; i < num_proc_lp; i++)
    begin : fwd_dest
      bp_local_addr_s local_addr;
      assign local_addr = proc_fwd_header_lo[i].addr;
      wire [dev_id_width_gp-1:0] device_fwd_li = local_addr.dev;
      wire is_local        = (proc_fwd_header_lo[i].addr < dram_base_addr_gp);
      wire is_my_core      = is_local & (local_addr.tile == cfg_bus_li.core_id);

      wire is_host_fwd = is_my_core & is_local & (device_fwd_li == host_dev_gp);

      assign proc_fwd_dst_lo[i] = is_host_fwd;
    end

  logic [num_dev_lp-1:0][lg_num_proc_lp-1:0] dev_rev_dst_lo;
  for (genvar i = 0; i < num_dev_lp; i++)
    begin : dev_lce_id
      wire [did_width_p-1:0] dev_rev_did_li = dev_rev_header_lo[i].payload.src_did;
      wire [lg_num_proc_lp-1:0] dev_rev_proc_id_li = dev_rev_header_lo[i].payload.lce_id;
      wire remote_did_li = (dev_rev_did_li > 0) && (dev_rev_did_li != my_did_li);
      assign dev_rev_dst_lo[i] = remote_did_li ? ep_proc_id_lp : dev_rev_proc_id_li;
    end

  bp_me_xbar_stream
   #(.bp_params_p(bp_params_p)
     ,.payload_width_p(mem_fwd_payload_width_lp)
     ,.stream_mask_p(mem_fwd_stream_mask_gp)
     ,.num_source_p(num_proc_lp)
     ,.num_sink_p(num_dev_lp)
     )
   fwd_xbar
    (.clk_i(aclk)
     ,.reset_i(~sys_resetn)

     ,.msg_header_i(proc_fwd_header_lo)
     ,.msg_data_i(proc_fwd_data_lo)
     ,.msg_v_i(proc_fwd_v_lo)
     ,.msg_ready_and_o(proc_fwd_ready_and_li)
     ,.msg_dst_i(proc_fwd_dst_lo)

     ,.msg_header_o(dev_fwd_header_li)
     ,.msg_data_o(dev_fwd_data_li)
     ,.msg_v_o(dev_fwd_v_li)
     ,.msg_ready_and_i(dev_fwd_ready_and_lo)
     );

  bp_me_xbar_stream
   #(.bp_params_p(bp_params_p)
     ,.payload_width_p(mem_rev_payload_width_lp)
     ,.stream_mask_p(mem_rev_stream_mask_gp)
     ,.num_source_p(num_dev_lp)
     ,.num_sink_p(num_proc_lp)
     )
   rev_xbar
    (.clk_i(aclk)
     ,.reset_i(~sys_resetn)

     ,.msg_header_i(dev_rev_header_lo)
     ,.msg_data_i(dev_rev_data_lo)
     ,.msg_v_i(dev_rev_v_lo)
     ,.msg_ready_and_o(dev_rev_ready_and_li)
     ,.msg_dst_i(dev_rev_dst_lo)

     ,.msg_header_o(proc_rev_header_li)
     ,.msg_data_o(proc_rev_data_li)
     ,.msg_v_o(proc_rev_v_li)
     ,.msg_ready_and_i(proc_rev_ready_and_lo)
     );

   // to translate from BP DRAM space to ARM PS DRAM space
   // we xor-subtract the BP DRAM base address (32'h8000_0000) and add the
   // ARM PS allocated memory space physical address.

   assign m00_axi_awaddr = (m_axil_awaddr ^ 32'h8000_0000) + dram_base_li;
   assign m00_axi_awvalid = m_axil_awvalid;
   assign m_axil_awready = m00_axi_awready;
   assign m00_axi_awid = '0;
   assign m00_axi_awlock = '0;
   assign m00_axi_awcache = '0;
   assign m00_axi_awprot = '0;
   assign m00_axi_awlen = '0;
   assign m00_axi_awsize = 3'b010; // 32b
   assign m00_axi_awburst = 2'b01; // incr
   assign m00_axi_awqos = '0;

   assign m00_axi_wdata = m_axil_wdata;
   assign m00_axi_wvalid = m_axil_wvalid;
   assign m_axil_wready = m00_axi_wready;
   assign m00_axi_wid = '0;
   assign m00_axi_wlast = 1'b1;
   assign m00_axi_wstrb = m_axil_wstrb;

   assign m_axil_bresp = m00_axi_bresp;
   assign m_axil_bvalid = m00_axi_bvalid;
   assign m00_axi_bready = m_axil_bready;

   assign m00_axi_araddr = (m_axil_araddr ^ 32'h8000_0000) + dram_base_li;
   assign m00_axi_arvalid = m_axil_arvalid;
   assign m_axil_arready = m00_axi_arready;
   assign m00_axi_arid = '0;
   assign m00_axi_arlock = '0;
   assign m00_axi_arcache = '0;
   assign m00_axi_arprot = '0;
   assign m00_axi_arlen = '0;
   assign m00_axi_arsize = 3'b010; // 32b
   assign m00_axi_arburst = 2'b01; // incr
   assign m00_axi_arqos = '0;

   assign m_axil_rdata = m00_axi_rdata;
   assign m_axil_rresp = m00_axi_rresp;
   assign m_axil_rvalid = m00_axi_rvalid;
   assign m00_axi_rready = m_axil_rvalid;

endmodule

