
`timescale 1 ps / 1 ps

`include "bp_common_defines.svh"
`include "bp_be_defines.svh"
`include "bp_me_defines.svh"

module top_zynq
 import bp_common_pkg::*;
 import bp_be_pkg::*;
 import bp_me_pkg::*;
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
   , parameter integer C_M00_AXI_DATA_WIDTH   = 64
   , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
   , parameter integer C_M01_AXI_DATA_WIDTH   = 32
   , parameter integer C_M01_AXI_ADDR_WIDTH   = 32
   )
  (input wire                                    rt_clk
   
   // Ports of Axi Slave Bus Interface S00_AXI
   , input wire                                  s00_axi_aclk
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

   , (* gated_clock = "true" *) input wire       s01_axi_aclk
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


  localparam bp_axil_addr_width_lp = 32;
  localparam bp_axil_data_width_lp = 32;
  localparam bp_axi_addr_width_lp  = 32;
  localparam bp_axi_data_width_lp  = 64;

  localparam debug_lp = 0;
  localparam memory_upper_limit_lp = 120*1024*1024;


  // gate computation
  logic [31:0] gate_en_li; // csr writeable from PS
  reg gate_r;
  always @(posedge s01_axi_aclk)
    if(~s01_axi_aresetn)
      gate_r <= '0;
    else
      if(~gate_r & (~commit_fifo_ready_async_li | ~ird_async_ready_li | ~frd_async_ready_li) & gate_en_li[0])
        gate_r <= '1;
      else if(gate_r & (~commit_fifo_v_lo & ~pl2ps_ird_v_lo & ~pl2ps_ird_v_lo) | ~gate_en_li[0])
        gate_r <= '0;

  (* gated_clock = "true" *) wire s01_gated_aclk;

`ifdef VERILATOR
   assign s01_gated_aclk = s01_axi_aclk & ~gate_r;
`else
  // xilinx macro replacement for FPGA
  bsg_clkgate_optional
    gate_macro
    (  
       .clk_i(s01_axi_aclk)
      ,.en_i(~gate_r)
      ,.gated_clock_o(s01_gated_aclk)
    );
`endif

  logic s01_gated_aresetn;
  bsg_sync_sync #(.width_p(1)) gated_reset
   (.oclk_i(s01_gated_aclk)
    ,.iclk_data_i(s01_axi_aresetn)
    ,.oclk_data_o(s01_gated_aresetn)
    );

  // commit info gathering -- gated domain
  `define   UC   blackparrot.u.unicore.unicore_lite.core_minimal
  `declare_bp_be_internal_if_structs(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  bp_be_commit_pkt_s commit_pkt_li;
  assign commit_pkt_li = `UC.be.calculator.commit_pkt_cast_o;

  bp_be_decode_s decode_r;
  bsg_dff_chain
  #(.width_p($bits(bp_be_decode_s)), .num_stages_p(4))
  reservation_pipe
    (.clk_i(s01_gated_aclk)
     ,.data_i(`UC.be.calculator.reservation_n.decode)
     ,.data_o(decode_r)
     );

  bp_be_commit_pkt_s commit_pkt_r;
  logic is_debug_mode_r;
  bsg_dff_chain
  #(.width_p(1+$bits(commit_pkt_li)), .num_stages_p(1))
  commit_pkt_reg
    (.clk_i(s01_gated_aclk)

     ,.data_i({`UC.be.calculator.pipe_sys.csr.is_debug_mode, commit_pkt_li})
     ,.data_o({is_debug_mode_r, commit_pkt_r})
     );


  // commit info gathering -- gated to ungated
  wire                      commit_fifo_async_v_li    = instret_v_li | trap_v_li;
  wire                      commit_fifo_async_full_lo;

  wire                      instret_v_li        = commit_pkt_r.instret;
  wire [vaddr_width_p-1:0]  commit_pc_li        = commit_pkt_r.pc;
  wire [instr_width_gp-1:0] commit_instr_li     = commit_pkt_r.instr;
  wire                      commit_ird_w_v_li   = instret_v_li & (decode_r.irf_w_v | decode_r.late_iwb_v);
  wire                      commit_frd_w_v_li   = instret_v_li & (decode_r.frf_w_v | decode_r.late_fwb_v);
  wire                      trap_v_li           = commit_pkt_r.exception | commit_pkt_r._interrupt;
  wire [dword_width_gp-1:0] cause_li            = (`UC.be.calculator.pipe_sys.csr.priv_mode_r == `PRIV_MODE_M) 
                                                  ? `UC.be.calculator.pipe_sys.csr.mcause_lo : `UC.be.calculator.pipe_sys.csr.scause_lo;
  wire [vaddr_width_p-1:0]  epc_li              = (`UC.be.calculator.pipe_sys.csr.priv_mode_r == `PRIV_MODE_M)
                                                  ? `UC.be.calculator.pipe_sys.csr.mepc_lo : `UC.be.calculator.pipe_sys.csr.sepc_lo;
  wire [dword_width_gp-1:0] mstatus_li          = `UC.be.calculator.pipe_sys.csr.mstatus_lo;

  wire                      commit_debug_async_lo;
  wire                      instret_v_async_lo;
  wire                      trap_v_async_lo;
  wire [vaddr_width_p-1:0]  commit_pc_async_lo;
  wire [vaddr_width_p-1:0]  epc_async_lo;
  rv64_instr_fmatype_s      commit_instr_async_lo;
  wire                      commit_ird_w_v_async_lo;
  wire                      commit_frd_w_v_async_lo;
  wire [dword_width_gp-1:0] cause_async_lo, mstatus_async_lo;

  wire                      commit_fifo_ready_async_li;
  wire                      commit_fifo_v_async_lo;;

  wire                      commit_debug_r;
  wire                      instret_v_r;
  wire                      trap_v_r;
  wire [vaddr_width_p-1:0]  commit_pc_r;
  wire [vaddr_width_p-1:0]  epc_r;
  rv64_instr_fmatype_s      commit_instr_r;
  wire                      commit_ird_w_v_r;
  wire                      commit_frd_w_v_r;
  wire [dword_width_gp-1:0] cause_r, mstatus_r;

  wire                      commit_fifo_v_lo, commit_fifo_yumi_li;

  bsg_async_fifo
  #(.width_p(3+2*vaddr_width_p+instr_width_gp+2+2*dword_width_gp), .lg_size_p(5))
  commit_fifo_async
    (.w_clk_i(s01_gated_aclk)
     ,.w_reset_i(~s01_gated_aresetn)

     ,.w_enq_i(commit_fifo_async_v_li & ~commit_fifo_async_full_lo)
     ,.w_data_i({is_debug_mode_r, instret_v_li, trap_v_li, commit_pc_li, 
                  commit_instr_li, commit_ird_w_v_li, commit_frd_w_v_li, 
                  cause_li, epc_li, mstatus_li})
     ,.w_full_o(commit_fifo_async_full_lo)

     ,.r_clk_i(s00_axi_aclk)
     ,.r_reset_i(~s00_axi_aresetn)

     ,.r_deq_i(commit_fifo_ready_async_li & commit_fifo_v_async_lo)
     ,.r_data_o({commit_debug_async_lo, instret_v_async_lo, trap_v_async_lo,
                  commit_pc_async_lo, commit_instr_async_lo, commit_ird_w_v_async_lo, 
                  commit_frd_w_v_async_lo, cause_async_lo, epc_async_lo, mstatus_async_lo})
     ,.r_valid_o(commit_fifo_v_async_lo)
     );

  // it's the sync fifo's full signal that contributes to gate; 
  // the async before also serves to act as a buffer to next commits
  bsg_fifo_1r1w_small 
    #(
        .width_p(3+2*vaddr_width_p+instr_width_gp+2+2*dword_width_gp)
      , .els_p(16)
    )
    commit_fifo_sync
    (
        .clk_i(s00_axi_aclk)
      , .reset_i(~s00_axi_aresetn)

      , .v_i(commit_fifo_v_async_lo)
      , .ready_o(commit_fifo_ready_async_li)
      , .data_i({commit_debug_async_lo, instret_v_async_lo, trap_v_async_lo, 
                  commit_pc_async_lo, commit_instr_async_lo, commit_ird_w_v_async_lo, 
                  commit_frd_w_v_async_lo, cause_async_lo, epc_async_lo, mstatus_async_lo})

      , .v_o(commit_fifo_v_lo)
      , .data_o({commit_debug_r, instret_v_r, trap_v_r, commit_pc_r, commit_instr_r, 
                  commit_ird_w_v_r, commit_frd_w_v_r, cause_r, epc_r, mstatus_r})
      , .yumi_i(commit_fifo_yumi_li & commit_fifo_v_lo)
    );

  logic [9:0] pl2ps_commit_readies_lo; // for pl_to_ps_fifos
  assign commit_fifo_yumi_li = &pl2ps_commit_readies_lo;

  wire pl2ps_commit_v_lo  = commit_fifo_v_lo & ~commit_debug_r & instret_v_r & &pl2ps_commit_readies_lo;
  wire pl2ps_xcpt_v_lo    = commit_fifo_v_lo & ~commit_debug_r & trap_v_r & &pl2ps_commit_readies_lo;

  wire [31:0] metadata_lo;
  assign metadata_lo = {
                        25'b0    
                        , commit_instr_r.rd_addr[4:0]
                        , commit_frd_w_v_r 
                        , commit_ird_w_v_r  
                      };

  wire [63:0] pc_lo = `BSG_SIGN_EXTEND(commit_pc_r, dword_width_gp);
  wire [63:0] epc_lo = `BSG_SIGN_EXTEND(epc_r, dword_width_gp);
  logic [63:0] minstret_lo = `UC.be.calculator.pipe_sys.csr.minstret_lo;

  // ird and frd -- gated to ungated domain

  localparam                 rf_els_lp = 2**reg_addr_width_gp;

  logic [dword_width_gp-1:0] ird_data_r, ird_data_async_lo;
  bp_be_fp_reg_s             frd_data_r, frd_data_async_lo;
  logic [dword_width_gp-1:0] frd_conv_r;

  logic [4:0]                ird_addr_r, ird_addr_async_lo, frd_addr_r, frd_addr_async_lo;
  logic                      ird_async_v_lo, ird_async_ready_li, frd_async_v_lo, frd_async_ready_li;
  logic                      frd_fifo_full_lo, ird_fifo_full_lo;

  logic [2:0]                pl2ps_frd_readies_lo, pl2ps_ird_readies_lo;
  logic                      pl2ps_ird_v_lo, pl2ps_frd_v_lo;

  // because we aren't stitching commit_pkt and the corresponding register write (done in SW),
  //   the need to store register writes is obviated (it's done in SW)
  bsg_async_fifo
   #(.width_p(dword_width_gp+5), .lg_size_p(5))
   ird_fifo_async
    (.w_clk_i(s01_gated_aclk)
     ,.w_reset_i(~s01_gated_aresetn)
     ,.w_enq_i( `UC.be.scheduler.iwb_pkt_cast_i.ird_w_v & ~ird_fifo_full_lo)
     ,.w_data_i({`UC.be.scheduler.iwb_pkt_cast_i.rd_addr, `UC.be.scheduler.iwb_pkt_cast_i.rd_data[0+:dword_width_gp]})
     ,.w_full_o(ird_fifo_full_lo)

     ,.r_clk_i(s00_axi_aclk)
     ,.r_reset_i(~s00_axi_aresetn)
     ,.r_deq_i(ird_async_ready_li & ird_async_v_lo)
     ,.r_data_o({ird_addr_async_lo, ird_data_async_lo})
     ,.r_valid_o(ird_async_v_lo)
     );

  bsg_fifo_1r1w_small
    #(
        .width_p(5+dword_width_gp)
      , .els_p(16)
    )
    ird_fifo_sync
    (
        .clk_i(s00_axi_aclk)
      , .reset_i(~s00_axi_aresetn)

      , .v_i(ird_async_v_lo)
      , .ready_o(ird_async_ready_li)
      , .data_i({ird_addr_async_lo, ird_data_async_lo})

      , .v_o(pl2ps_ird_v_lo)
      , .data_o({ird_addr_r, ird_data_r})
      , .yumi_i(&pl2ps_ird_readies_lo & pl2ps_ird_v_lo)
    );

  bsg_async_fifo
   #(.width_p(dpath_width_gp+5), .lg_size_p(5))
   frd_fifo_async
    (.w_clk_i(s01_gated_aclk)
     ,.w_reset_i(~s01_gated_aresetn)                                                                                                                                
     ,.w_enq_i(`UC.be.scheduler.fwb_pkt_cast_i.frd_w_v)
     ,.w_data_i({`UC.be.scheduler.fwb_pkt_cast_i.rd_addr, `UC.be.scheduler.fwb_pkt_cast_i.rd_data})
     ,.w_full_o(frd_fifo_full_lo)

     ,.r_clk_i(s00_axi_aclk)
     ,.r_reset_i(~s00_axi_aresetn)
     ,.r_deq_i(frd_async_ready_li & frd_async_v_lo)
     ,.r_data_o({frd_addr_async_lo, frd_data_async_lo})
     ,.r_valid_o(frd_async_v_lo)
     );
    
  bsg_fifo_1r1w_small
    #(
        .width_p(5+dpath_width_gp)
      , .els_p(16)
    )
    frd_fifo_sync
    (
        .clk_i(s00_axi_aclk)
      , .reset_i(~s00_axi_aresetn)

      , .v_i(frd_async_v_lo)
      , .ready_o(frd_async_ready_li)
      , .data_i({frd_addr_async_lo, frd_data_async_lo})

      , .v_o(pl2ps_frd_v_lo)
      , .data_o({frd_addr_r, frd_data_r})
      , .yumi_i(&pl2ps_frd_readies_lo & pl2ps_frd_v_lo)
    );

  bp_be_reg_to_fp
   #(.bp_params_p(bp_params_p))
   debug_fp
    (.reg_i(frd_data_r)
     ,.raw_o(frd_conv_r)
     ,.fflags_o()
     );

  // rest of the code
  logic [2:0][C_S00_AXI_DATA_WIDTH-1:0]        csr_data_lo;
  logic [C_S00_AXI_DATA_WIDTH-1:0]             pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
  logic                                        pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
  logic                                        ps_to_pl_fifo_v_lo, ps_to_pl_fifo_ready_li;

  reg end_r;
  always@(posedge s01_axi_aclk)
    if(~s01_axi_aresetn)
      end_r <= 1'b0;
    else 
      if(pl_to_ps_fifo_v_li & pl_to_ps_fifo_ready_lo) begin
        $display("Device communication %x\n", pl_to_ps_fifo_data_li);
        if(pl_to_ps_fifo_data_li == 32'h90200000) begin
          $display("End of cosimulation\n");
          end_r <= 1'b1;
        end
      end
  // Connect Shell to AXI Bus Interface S00_AXI
  bsg_zynq_pl_shell #
     (
      // standard memory map for all blackparrot instances should be
      //
      // 0: reset for bp (low true); note: it is only legal to assert reset if you are
      //    finished with all AXI transactions (fixme: potential improvement to detect this)
      // 4: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
      // 8: the base register for the allocated dram
      //

      // need to update C_S00_AXI_ADDR_WIDTH accordingly
      .num_regs_ps_to_pl_p (4)
      ,.num_fifo_ps_to_pl_p(1)
      ,.num_fifo_pl_to_ps_p(17)
      ,.num_regs_pl_to_ps_p(1)
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_o({
                      gate_en_li
                    , csr_data_lo
                    })

        ,.csr_data_i({gate_r  /* gate_r needs to be with minstret for debuggability */
                        , minstret_lo[30:0]})

        ,.pl_to_ps_fifo_data_i ({
                                  pl2ps_xcpt_v_lo ? epc_lo[63:32] : '1
                                , pl2ps_xcpt_v_lo ? epc_lo[31:0]  : '1

                                , pl2ps_xcpt_v_lo ? cause_r[63:32] : '1
                                , pl2ps_xcpt_v_lo ? cause_r[31:0]  : '1

                                , frd_conv_r[63:32]
                                , frd_conv_r[31:0]
                                , {27'b0, frd_addr_r[4:0]}

                                , ird_data_r[63:32]
                                , ird_data_r[31:0]
                                , {27'b0, ird_addr_r[4:0]}

                                , mstatus_r[63:32]
                                , mstatus_r[31:0]
                                , pc_lo[63:32]
                                , pc_lo[31:0]
                                , metadata_lo[31:0]
                                , commit_instr_r[31:0]

                                , pl_to_ps_fifo_data_li[31:0]
                                })

        ,.pl_to_ps_fifo_v_i    ({  
                                  pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo 
                                , pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo

                                , pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo 
                                , pl2ps_xcpt_v_lo & &pl2ps_commit_readies_lo

                                , pl2ps_frd_v_lo & &pl2ps_frd_readies_lo
                                , pl2ps_frd_v_lo & &pl2ps_frd_readies_lo
                                , pl2ps_frd_v_lo & &pl2ps_frd_readies_lo

                                , pl2ps_ird_v_lo & &pl2ps_ird_readies_lo
                                , pl2ps_ird_v_lo & &pl2ps_ird_readies_lo
                                , pl2ps_ird_v_lo & &pl2ps_ird_readies_lo

                                , pl2ps_commit_v_lo & &pl2ps_commit_readies_lo  
                                , pl2ps_commit_v_lo & &pl2ps_commit_readies_lo
                                , pl2ps_commit_v_lo & &pl2ps_commit_readies_lo
                                , pl2ps_commit_v_lo & &pl2ps_commit_readies_lo
                                , pl2ps_commit_v_lo & &pl2ps_commit_readies_lo
                                , pl2ps_commit_v_lo & &pl2ps_commit_readies_lo

                                , pl_to_ps_fifo_v_li
                                })

        ,.pl_to_ps_fifo_ready_o({
                                  pl2ps_commit_readies_lo[9]
                                , pl2ps_commit_readies_lo[8]

                                , pl2ps_commit_readies_lo[7]
                                , pl2ps_commit_readies_lo[6]

                                , pl2ps_frd_readies_lo[2]
                                , pl2ps_frd_readies_lo[1]
                                , pl2ps_frd_readies_lo[0]

                                , pl2ps_ird_readies_lo[2]
                                , pl2ps_ird_readies_lo[1]
                                , pl2ps_ird_readies_lo[0]
                                
                                , pl2ps_commit_readies_lo[5]
                                , pl2ps_commit_readies_lo[4]
                                , pl2ps_commit_readies_lo[3]
                                , pl2ps_commit_readies_lo[2]
                                , pl2ps_commit_readies_lo[1]
                                , pl2ps_commit_readies_lo[0]

                                , pl_to_ps_fifo_ready_lo
                                })

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

  `declare_bsg_cache_dma_pkt_s(caddr_width_p, l2_block_size_in_words_p);
  bsg_cache_dma_pkt_s dma_pkt_lo;
  logic                       dma_pkt_v_lo, dma_pkt_yumi_li;
  logic [l2_fill_width_p-1:0] dma_data_lo;
  logic                       dma_data_v_lo, dma_data_yumi_li;
  logic [l2_fill_width_p-1:0] dma_data_li;
  logic                       dma_data_v_li, dma_data_ready_and_lo;

  logic [bp_axil_addr_width_lp-1:0] waddr_translated_lo, raddr_translated_lo;

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
     // BP host address space is below this
     ,.split_addr_p(32'h0020_0000)
     )
  axil_demux
    (.clk_i(s01_axi_aclk)
     ,.reset_i(~s01_axi_aresetn)

     ,.s00_axil_awaddr(bp_axi_awaddr)
     ,.s00_axil_awprot(bp_axi_awprot)
     ,.s00_axil_awvalid(bp_axi_awvalid)
     ,.s00_axil_awready(bp_axi_awready)
     ,.s00_axil_wdata(bp_axi_wdata)
     ,.s00_axil_wstrb(bp_axi_wstrb)
     ,.s00_axil_wvalid(bp_axi_wvalid)
     ,.s00_axil_wready(bp_axi_wready)
     ,.s00_axil_bresp(bp_axi_bresp)
     ,.s00_axil_bvalid(bp_axi_bvalid)
     ,.s00_axil_bready(bp_axi_bready)
     ,.s00_axil_araddr(bp_axi_araddr)
     ,.s00_axil_arprot(bp_axi_arprot)
     ,.s00_axil_arvalid(bp_axi_arvalid)
     ,.s00_axil_arready(bp_axi_arready)
     ,.s00_axil_rdata(bp_axi_rdata)
     ,.s00_axil_rresp(bp_axi_rresp)
     ,.s00_axil_rvalid(bp_axi_rvalid)
     ,.s00_axil_rready(bp_axi_rready)

     ,.m00_axil_awaddr(s02_axi_awaddr)
     ,.m00_axil_awprot(s02_axi_awprot)
     ,.m00_axil_awvalid(s02_axi_awvalid)
     ,.m00_axil_awready(s02_axi_awready)
     ,.m00_axil_wdata(s02_axi_wdata)
     ,.m00_axil_wstrb(s02_axi_wstrb)
     ,.m00_axil_wvalid(s02_axi_wvalid)
     ,.m00_axil_wready(s02_axi_wready)
     ,.m00_axil_bresp(s02_axi_bresp)
     ,.m00_axil_bvalid(s02_axi_bvalid)
     ,.m00_axil_bready(s02_axi_bready)
     ,.m00_axil_araddr(s02_axi_araddr)
     ,.m00_axil_arprot(s02_axi_arprot)
     ,.m00_axil_arvalid(s02_axi_arvalid)
     ,.m00_axil_arready(s02_axi_arready)
     ,.m00_axil_rdata(s02_axi_rdata)
     ,.m00_axil_rresp(s02_axi_rresp)
     ,.m00_axil_rvalid(s02_axi_rvalid)
     ,.m00_axil_rready(s02_axi_rready)

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

  wire bp_reset_gated_li = (~csr_data_lo[0][0]) || (~s01_gated_aresetn);
  wire bp_reset_li       = (~csr_data_lo[0][0]) || (~s01_axi_aresetn);
  wire [31:0] csr_data_lo_00_gated;
  
  logic [bp_axil_addr_width_lp-1:0]            bp_axi_awaddr;
  logic [2:0]                                  bp_axi_awprot;
  logic                                        bp_axi_awvalid;
  logic                                        bp_axi_awready;
  logic [bp_axil_data_width_lp-1:0]            bp_axi_wdata;
  logic [(bp_axil_data_width_lp/8)-1:0]        bp_axi_wstrb;
  logic                                        bp_axi_wvalid;
  logic                                        bp_axi_wready;
  logic [1:0]                                  bp_axi_bresp;
  logic                                        bp_axi_bvalid;
  logic                                        bp_axi_bready;
  logic [bp_axil_addr_width_lp-1:0]            bp_axi_araddr;
  logic [2:0]                                  bp_axi_arprot;
  logic                                        bp_axi_arvalid;
  logic                                        bp_axi_arready;
  logic [bp_axil_data_width_lp-1:0]            bp_axi_rdata;
  logic [1:0]                                  bp_axi_rresp;
  logic                                        bp_axi_rvalid;
  logic                                        bp_axi_rready;

  bp_axi_top #
     (.bp_params_p(bp_params_p)
      ,.axil_addr_width_p(bp_axil_addr_width_lp)
      ,.axil_data_width_p(bp_axil_data_width_lp)
      ,.axi_addr_width_p(bp_axi_addr_width_lp)
      ,.axi_data_width_p(bp_axi_data_width_lp)
      ,.axi_async_p(1) // enable async clock for BP -- supplied with s01_gated_aclk
      )
  blackparrot
     (
      .clk_i            (s01_gated_aclk)
      ,.reset_i         (bp_reset_gated_li)
      ,.aclk_i          (s01_axi_aclk)
      ,.areset_i        (bp_reset_li)
      ,.rt_clk_i(rt_clk)

      // these are reads/write from BlackParrot
      ,.m_axil_awaddr_o (bp_axi_awaddr)
      ,.m_axil_awprot_o (bp_axi_awprot)
      ,.m_axil_awvalid_o(bp_axi_awvalid)
      ,.m_axil_awready_i(bp_axi_awready)

      ,.m_axil_wdata_o  (bp_axi_wdata)
      ,.m_axil_wstrb_o  (bp_axi_wstrb)
      ,.m_axil_wvalid_o (bp_axi_wvalid)
      ,.m_axil_wready_i (bp_axi_wready)

      ,.m_axil_bresp_i  (bp_axi_bresp)
      ,.m_axil_bvalid_i (bp_axi_bvalid)
      ,.m_axil_bready_o (bp_axi_bready)

      ,.m_axil_araddr_o (bp_axi_araddr)
      ,.m_axil_arprot_o (bp_axi_arprot)
      ,.m_axil_arvalid_o(bp_axi_arvalid)
      ,.m_axil_arready_i(bp_axi_arready)

      ,.m_axil_rdata_i  (bp_axi_rdata)
      ,.m_axil_rresp_i  (bp_axi_rresp)
      ,.m_axil_rvalid_i (bp_axi_rvalid)
      ,.m_axil_rready_o (bp_axi_rready)

      // these are reads/writes into BlackParrot
      // from the Zynq PS ARM core
      ,.s_axil_awaddr_i (waddr_translated_lo)
      ,.s_axil_awprot_i (s01_axi_awprot)
      ,.s_axil_awvalid_i(s01_axi_awvalid)
      ,.s_axil_awready_o(s01_axi_awready)

      ,.s_axil_wdata_i  (s01_axi_wdata)
      ,.s_axil_wstrb_i  (s01_axi_wstrb)
      ,.s_axil_wvalid_i (s01_axi_wvalid)
      ,.s_axil_wready_o (s01_axi_wready)

      ,.s_axil_bresp_o  (s01_axi_bresp)
      ,.s_axil_bvalid_o (s01_axi_bvalid)
      ,.s_axil_bready_i (s01_axi_bready)

      ,.s_axil_araddr_i (raddr_translated_lo)
      ,.s_axil_arprot_i (s01_axi_arprot)
      ,.s_axil_arvalid_i(s01_axi_arvalid)
      ,.s_axil_arready_o(s01_axi_arready)

      ,.s_axil_rdata_o  (s01_axi_rdata)
      ,.s_axil_rresp_o  (s01_axi_rresp)
      ,.s_axil_rvalid_o (s01_axi_rvalid)
      ,.s_axil_rready_i (s01_axi_rready)

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
  always @(negedge s01_gated_aclk) //TODO
    if (s01_axi_awvalid & s01_axi_awready)
      if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,waddr_translated_lo);

  always @(negedge s01_gated_aclk) //TODO
    if (s01_axi_arvalid & s01_axi_arready)
      if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,raddr_translated_lo);
  // synopsys translate_on

//COVERAGE_MACRO
endmodule

