

`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_me_fifos_to_axil
 import bp_common_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p)
   , parameter `BSG_INV_PARAM(fifo_width_p)
   , parameter `BSG_INV_PARAM(axil_data_width_p)
   , parameter `BSG_INV_PARAM(axil_addr_width_p)
   )
  (input                                        clk_i
   , input                                      reset_i

   , input [fifo_width_p-1:0]                   fifo_i
   , input                                      fifo_v_i
   , output logic                               fifo_ready_and_o

   , output logic [fifo_width_p-1:0]            fifo_o
   , output logic                               fifo_v_o
   , input                                      fifo_ready_and_i

   //====================== AXI-4 LITE =========================
   // WRITE ADDRESS CHANNEL SIGNALS
   , output logic [axil_addr_width_p-1:0]       m_axil_awaddr_o
   , output logic [2:0]                         m_axil_awprot_o
   , output logic                               m_axil_awvalid_o
   , input                                      m_axil_awready_i

   // WRITE DATA CHANNEL SIGNALS
   , output logic [axil_data_width_p-1:0]       m_axil_wdata_o
   , output logic [(axil_data_width_p>>3)-1:0]  m_axil_wstrb_o
   , output logic                               m_axil_wvalid_o
   , input                                      m_axil_wready_i

   // WRITE RESPONSE CHANNEL SIGNALS
   , input [1:0]                                m_axil_bresp_i
   , input                                      m_axil_bvalid_i
   , output logic                               m_axil_bready_o

   // READ ADDRESS CHANNEL SIGNALS
   , output logic [axil_addr_width_p-1:0]       m_axil_araddr_o
   , output logic [2:0]                         m_axil_arprot_o
   , output logic                               m_axil_arvalid_o
   , input                                      m_axil_arready_i

   // READ DATA CHANNEL SIGNALS
   , input [axil_data_width_p-1:0]              m_axil_rdata_i
   , input [1:0]                                m_axil_rresp_i
   , input                                      m_axil_rvalid_i
   , output logic                               m_axil_rready_o
   );

  typedef struct packed
  {
    logic [7:0] padding;
    logic [7:0] state;
    logic [7:0] way_id;
    logic [7:0] lce_id;
    logic [7:0] did;
    logic [7:0] prefetch;
    logic [7:0] uncached;
    logic [7:0] speculative;
  }  bp_bedrock_payload_aligned_s;
  bp_bedrock_payload_aligned_s aligned_fwd_payload;
  bp_bedrock_payload_aligned_s aligned_rev_payload;

  typedef struct packed
  {
    logic [7:0]  padding;
    logic [31:0] data;
    logic [63:0] payload;
    logic [7:0]  size;
    logic [63:0] addr;
    logic [7:0]  subop;
    logic [7:0]  msg_type;
  }  bp_bedrock_msg_aligned_s;
  bp_bedrock_msg_aligned_s aligned_fwd_lo;
  logic aligned_fwd_v_lo, aligned_fwd_ready_and_li;
  bp_bedrock_msg_aligned_s aligned_rev_li;
  logic aligned_rev_v_li, aligned_rev_ready_and_lo;


  bsg_serial_in_parallel_out_full
   #(.width_p(fifo_width_p), .els_p($bits(bp_bedrock_msg_aligned_s)/fifo_width_p))
   sipo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(fifo_i)
     ,.v_i(fifo_v_i)
     ,.ready_o(fifo_ready_and_o)

     ,.data_o(aligned_fwd_lo)
     ,.v_o(aligned_fwd_v_lo)
     ,.yumi_i(aligned_fwd_ready_and_li & aligned_fwd_v_lo)
     );
  assign aligned_fwd_payload = aligned_fwd_lo.payload;

  bsg_parallel_in_serial_out
   #(.width_p(fifo_width_p), .els_p($bits(bp_bedrock_msg_aligned_s)/fifo_width_p))
   piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(aligned_rev_li)
     ,.valid_i(aligned_rev_v_li)
     ,.ready_and_o(aligned_rev_ready_and_lo)

     ,.data_o(fifo_o)
     ,.valid_o(fifo_v_o)
     ,.yumi_i(fifo_ready_and_i & fifo_v_o)
     );
  assign aligned_rev_li.payload = aligned_rev_payload;

  `declare_bp_bedrock_mem_if(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p);
  bp_bedrock_mem_fwd_header_s mem_fwd_header_lo;
  logic [dword_width_gp-1:0] mem_fwd_data_lo;
  logic mem_fwd_v_lo, mem_fwd_ready_and_li, mem_fwd_last_lo;
  bp_bedrock_mem_rev_header_s mem_rev_header_li;
  logic [dword_width_gp-1:0] mem_rev_data_li;
  logic mem_rev_v_li, mem_rev_ready_and_lo, mem_rev_last_li;

  assign mem_fwd_header_lo.msg_type = aligned_fwd_lo.msg_type;
  assign mem_fwd_header_lo.subop    = bp_bedrock_wr_subop_e'(aligned_fwd_lo.subop);
  assign mem_fwd_header_lo.addr     = aligned_fwd_lo.addr;
  assign mem_fwd_header_lo.size     = bp_bedrock_msg_size_e'(aligned_fwd_lo.size);
  assign mem_fwd_header_lo.payload  = '{state        : bp_coh_states_e'(aligned_fwd_payload.state)
                                        ,way_id      : aligned_fwd_payload.way_id
                                        ,lce_id      : aligned_fwd_payload.lce_id
                                        ,did         : aligned_fwd_payload.did
                                        ,prefetch    : aligned_fwd_payload.prefetch
                                        ,uncached    : aligned_fwd_payload.uncached
                                        ,speculative : aligned_fwd_payload.speculative
                                        };
  assign mem_fwd_data_lo            = {2{aligned_fwd_lo.data}};
  assign mem_fwd_v_lo               = aligned_fwd_v_lo;
  assign mem_fwd_last_lo            = 1'b1; // Theroetically we can support burst transactions
  assign aligned_fwd_ready_and_li   = mem_fwd_ready_and_li;

  assign aligned_rev_li.msg_type    = mem_rev_header_li.msg_type;
  assign aligned_rev_li.subop       = mem_rev_header_li.subop;
  assign aligned_rev_li.addr        = mem_rev_header_li.addr;
  assign aligned_rev_li.size        = mem_rev_header_li.size;
  assign aligned_rev_payload        = '{state        : mem_rev_header_li.payload.state
                                        ,way_id      : mem_rev_header_li.payload.way_id
                                        ,lce_id      : mem_rev_header_li.payload.lce_id
                                        ,did         : mem_rev_header_li.payload.did
                                        ,prefetch    : mem_rev_header_li.payload.prefetch
                                        ,uncached    : mem_rev_header_li.payload.uncached
                                        ,speculative : mem_rev_header_li.payload.speculative
                                        ,padding     : '0
                                        };
  assign aligned_rev_li.data        = mem_rev_data_li;
  assign aligned_rev_li.padding     = '0;
  // Suppress reverse acks, instead just maintain with creates
  assign aligned_rev_v_li           = mem_rev_v_li & mem_rev_header_li.msg_type inside {e_bedrock_mem_uc_rd, e_bedrock_mem_rd, e_bedrock_mem_amo};
  wire   unused                     = mem_rev_last_li;
  assign mem_rev_ready_and_lo       = aligned_rev_ready_and_lo;

  bp_me_axil_master
   #(.bp_params_p(bp_params_p)
     ,.axil_data_width_p(axil_data_width_p)
     ,.axil_addr_width_p(axil_addr_width_p)
     )
   io2axil
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.mem_fwd_header_i(mem_fwd_header_lo)
     ,.mem_fwd_data_i(mem_fwd_data_lo)
     ,.mem_fwd_v_i(mem_fwd_v_lo)
     ,.mem_fwd_last_i(mem_fwd_last_lo)
     ,.mem_fwd_ready_and_o(mem_fwd_ready_and_li)

     ,.mem_rev_header_o(mem_rev_header_li)
     ,.mem_rev_data_o(mem_rev_data_li)
     ,.mem_rev_v_o(mem_rev_v_li)
     ,.mem_rev_last_o(mem_rev_last_li)
     ,.mem_rev_ready_and_i(mem_rev_ready_and_lo)

     ,.*
     );

  // TODO:
  //bsg_flow_counter

endmodule

