

`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_me_endpoint_to_fifos
 import bp_common_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_bedrock_if_widths(paddr_width_p, lce_id_width_p, cce_id_width_p, did_width_p, lce_assoc_p)
   , parameter `BSG_INV_PARAM(fifo_width_p)
   , parameter `BSG_INV_PARAM(num_credits_p)

   , localparam credit_counter_width_lp = `BSG_WIDTH(num_credits_p)
   )
  (input                                        clk_i
   , input                                      reset_i

   , input [fifo_width_p-1:0]                   fwd_fifo_i
   , input                                      fwd_fifo_v_i
   , output logic                               fwd_fifo_ready_and_o

   , output logic [fifo_width_p-1:0]            rev_fifo_o
   , output logic                               rev_fifo_v_o
   , input                                      rev_fifo_ready_and_i

   , output logic [fifo_width_p-1:0]            fwd_fifo_o
   , output logic                               fwd_fifo_v_o
   , input                                      fwd_fifo_ready_and_i

   , input [fifo_width_p-1:0]                   rev_fifo_i
   , input                                      rev_fifo_v_i
   , output logic                               rev_fifo_ready_and_o

   // Outgoing I/O
   , output logic [mem_fwd_header_width_lp-1:0] mem_fwd_header_o
   , output logic [bedrock_fill_width_p-1:0]    mem_fwd_data_o
   , output logic                               mem_fwd_v_o
   , input                                      mem_fwd_ready_and_i
   
   , input [mem_rev_header_width_lp-1:0]        mem_rev_header_i
   , input [bedrock_fill_width_p-1:0]           mem_rev_data_i
   , input                                      mem_rev_v_i
   , output logic                               mem_rev_ready_and_o
   
   // Incoming I/O
   , input [mem_fwd_header_width_lp-1:0]        mem_fwd_header_i
   , input [bedrock_fill_width_p-1:0]           mem_fwd_data_i
   , input                                      mem_fwd_v_i
   , output logic                               mem_fwd_ready_and_o
   
   , output logic [mem_rev_header_width_lp-1:0] mem_rev_header_o
   , output logic [bedrock_fill_width_p-1:0]    mem_rev_data_o
   , output logic                               mem_rev_v_o
   , input                                      mem_rev_ready_and_i

   , output logic [credit_counter_width_lp-1:0] credits_used_o
   );

  typedef struct packed
  {
    logic [7:0] padding;
    logic [7:0] state;
    logic [7:0] way_id;
    logic [7:0] lce_id;
    logic [7:0] src_did;
    logic [7:0] prefetch;
    logic [7:0] uncached;
    logic [7:0] speculative;
  }  bp_bedrock_payload_aligned_s;

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
  bp_bedrock_payload_aligned_s aligned_fwd_payload_lo;
  logic aligned_fwd_v_lo, aligned_fwd_ready_and_li;
  bp_bedrock_msg_aligned_s aligned_rev_li;
  bp_bedrock_payload_aligned_s aligned_rev_payload_li;
  logic aligned_rev_v_li, aligned_rev_ready_and_lo;

  bsg_serial_in_parallel_out_full
   #(.width_p(fifo_width_p), .els_p($bits(bp_bedrock_msg_aligned_s)/fifo_width_p))
   fwd_sipo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(fwd_fifo_i)
     ,.v_i(fwd_fifo_v_i)
     ,.ready_and_o(fwd_fifo_ready_and_o)

     ,.data_o(aligned_fwd_lo)
     ,.v_o(aligned_fwd_v_lo)
     ,.yumi_i(aligned_fwd_ready_and_li & aligned_fwd_v_lo)
     );
  assign aligned_fwd_payload_lo = aligned_fwd_lo.payload;

  bsg_parallel_in_serial_out
   #(.width_p(fifo_width_p), .els_p($bits(bp_bedrock_msg_aligned_s)/fifo_width_p))
   rev_piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(aligned_rev_li)
     ,.valid_i(aligned_rev_v_li)
     ,.ready_and_o(aligned_rev_ready_and_lo)

     ,.data_o(rev_fifo_o)
     ,.valid_o(rev_fifo_v_o)
     ,.yumi_i(rev_fifo_ready_and_i & rev_fifo_v_o)
     );
  assign aligned_rev_li.payload = aligned_rev_payload_li;

  `declare_bp_bedrock_if(paddr_width_p, lce_id_width_p, cce_id_width_p, did_width_p, lce_assoc_p);
  `bp_cast_i(bp_bedrock_mem_fwd_header_s, mem_fwd_header);
  `bp_cast_o(bp_bedrock_mem_rev_header_s, mem_rev_header);
  `bp_cast_o(bp_bedrock_mem_fwd_header_s, mem_fwd_header);
  `bp_cast_i(bp_bedrock_mem_rev_header_s, mem_rev_header);

  assign mem_fwd_header_cast_o.msg_type = aligned_fwd_lo.msg_type;
  assign mem_fwd_header_cast_o.subop    = bp_bedrock_wr_subop_e'(aligned_fwd_lo.subop);
  assign mem_fwd_header_cast_o.addr     = aligned_fwd_lo.addr;
  assign mem_fwd_header_cast_o.size     = bp_bedrock_msg_size_e'(aligned_fwd_lo.size);
  assign mem_fwd_header_cast_o.payload  = '{state        : bp_coh_states_e'(aligned_fwd_payload_lo.state)
                                            ,way_id      : aligned_fwd_payload_lo.way_id
                                            ,lce_id      : aligned_fwd_payload_lo.lce_id
                                            ,src_did     : aligned_fwd_payload_lo.src_did
                                            ,prefetch    : aligned_fwd_payload_lo.prefetch
                                            ,uncached    : aligned_fwd_payload_lo.uncached
                                            ,speculative : aligned_fwd_payload_lo.speculative
                                            };
  assign mem_fwd_data_o           = {bedrock_fill_width_p/32{aligned_fwd_lo.data}};
  assign mem_fwd_v_o              = aligned_fwd_v_lo;
  assign aligned_fwd_ready_and_li = mem_fwd_ready_and_i;

  assign aligned_rev_li.msg_type = mem_rev_header_cast_i.msg_type;
  assign aligned_rev_li.subop    = mem_rev_header_cast_i.subop;
  assign aligned_rev_li.addr     = mem_rev_header_cast_i.addr;
  assign aligned_rev_li.size     = mem_rev_header_cast_i.size;
  assign aligned_rev_payload_li  = '{state        : mem_rev_header_cast_i.payload.state
                                     ,way_id      : mem_rev_header_cast_i.payload.way_id
                                     ,lce_id      : mem_rev_header_cast_i.payload.lce_id
                                     ,src_did     : mem_rev_header_cast_i.payload.src_did
                                     ,prefetch    : mem_rev_header_cast_i.payload.prefetch
                                     ,uncached    : mem_rev_header_cast_i.payload.uncached
                                     ,speculative : mem_rev_header_cast_i.payload.speculative
                                     ,padding     : '0
                                     };
  assign aligned_rev_li.data     = mem_rev_data_i;
  assign aligned_rev_li.padding  = '0;
  // Suppress reverse acks, instead just maintain with credits
  // This prevents the AXIL from dequeueing packets just for credit returns
  assign aligned_rev_v_li        = mem_rev_v_i & mem_rev_header_cast_i.msg_type inside {e_bedrock_mem_uc_rd, e_bedrock_mem_rd, e_bedrock_mem_amo};
  assign mem_rev_ready_and_o     = aligned_rev_ready_and_lo;

  bp_bedrock_msg_aligned_s aligned_fwd_li;
  bp_bedrock_payload_aligned_s aligned_fwd_payload_li;
  logic aligned_fwd_v_li, aligned_fwd_ready_and_lo;
  logic rev_fifo_ready_lo;
  bsg_parallel_in_serial_out
   #(.width_p(fifo_width_p), .els_p($bits(bp_bedrock_msg_aligned_s)/fifo_width_p))
   fwd_piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(aligned_fwd_li)
     ,.valid_i(aligned_fwd_v_li)
     ,.ready_and_o(aligned_fwd_ready_and_lo)

     ,.data_o(fwd_fifo_o)
     ,.valid_o(fwd_fifo_v_o)
     ,.yumi_i(fwd_fifo_ready_and_i & fwd_fifo_v_o)
     );
  assign aligned_fwd_li.payload = aligned_fwd_payload_li;

  assign aligned_fwd_li.msg_type = mem_fwd_header_cast_i.msg_type;
  assign aligned_fwd_li.subop    = mem_fwd_header_cast_i.subop;
  assign aligned_fwd_li.addr     = mem_fwd_header_cast_i.addr;
  assign aligned_fwd_li.size     = mem_fwd_header_cast_i.size;
  assign aligned_fwd_payload_li  = '{state        : mem_fwd_header_cast_i.payload.state
                                     ,way_id      : mem_fwd_header_cast_i.payload.way_id
                                     ,lce_id      : mem_fwd_header_cast_i.payload.lce_id
                                     ,src_did     : mem_fwd_header_cast_i.payload.src_did
                                     ,prefetch    : mem_fwd_header_cast_i.payload.prefetch
                                     ,uncached    : mem_fwd_header_cast_i.payload.uncached
                                     ,speculative : mem_fwd_header_cast_i.payload.speculative
                                     ,padding     : '0
                                     };
  assign aligned_fwd_li.data     = mem_fwd_data_i;
  assign aligned_fwd_li.padding  = '0;
  assign aligned_fwd_v_li        = mem_fwd_v_i;
  // We're autoacking stores, so we require the reverse fifo to be ready
  assign mem_fwd_ready_and_o     = aligned_fwd_ready_and_lo & rev_fifo_ready_lo;

  bsg_two_fifo
   #(.width_p($bits(bp_bedrock_mem_fwd_header_s)))
   rev_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(mem_fwd_header_cast_i)
     ,.v_i(mem_fwd_ready_and_o & mem_fwd_v_i)
     ,.ready_param_o(rev_fifo_ready_lo)

     ,.data_o(mem_rev_header_cast_o)
     ,.v_o(mem_rev_v_o)
     ,.yumi_i(mem_rev_ready_and_i & mem_rev_v_o)
     );

  bsg_flow_counter
   #(.els_p(num_credits_p))
   fc
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(mem_fwd_v_o)
     ,.ready_param_i(mem_fwd_ready_and_i)
     ,.yumi_i(mem_rev_ready_and_o & mem_rev_v_i)

     ,.count_o(credits_used_o)
     );

endmodule

