
`include "bsg_defines.sv"

(* keep_hierarchy = "yes" *)
module bsg_cover
 #(parameter `BSG_INV_PARAM(id_p)
  ,parameter `BSG_INV_PARAM(width_p)
  ,parameter `BSG_INV_PARAM(els_p)
  ,parameter `BSG_INV_PARAM(out_width_p)
  ,parameter `BSG_INV_PARAM(lg_afifo_size_p)
  ,parameter `BSG_INV_PARAM(debug_p)

  ,localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)
  )
  (input core_clk_i
  ,input core_reset_i

  ,input ds_clk_i
  ,input ds_reset_i

  ,input axi_clk_i
  ,input axi_reset_i

  // core domain
  ,input v_i
  ,input [width_p-1:0] data_i
  ,output logic ready_o

  // ungated domain
  ,output logic gate_o

  ,output logic [7:0] els_o
  ,output logic [7:0] len_o

  ,input ready_i
  ,output logic v_o
  ,output logic last_o
  ,output logic [out_width_p-1:0] data_o
  );

  // signal definition
  localparam piso_div_lp = `BSG_CDIV(width_p, out_width_p);
  enum logic [0:0] {FILL, DRAIN} state_r, state_n;

  logic in_full_lo, v_lo, deq_li;
  logic [width_p-1:0] data_lo;

  logic cam_set_not_clear_li, cam_r_v_li;
  logic [els_p-1:0] cam_w_v_li, cam_w_empty_lo, cam_r_match_lo;
  logic [width_p-1:0] cam_w_tag_li, cam_r_tag_li;
  logic [lg_els_lp-1:0] cam_snoop_addr_li;
  logic [width_p-1:0] cam_snoop_tag_lo;

  logic cam_idx_v_lo;
  logic [els_p-1:0] cam_encoh_li, cam_idx_oh_lo;
  logic [lg_els_lp-1:0] cam_idx_enc_lo;

  logic piso_v_li, piso_ready_and_lo, piso_last_li;
  logic [(out_width_p*piso_div_lp)-1:0] piso_data_li;

  // cross into ungated and downsampled domain
  // TODO: maybe replace with dff output & gate_i
  assign ready_o = ~in_full_lo;
  assign deq_li = v_lo & (state_r == FILL);
  bsg_async_fifo
   #(.lg_size_p(lg_afifo_size_p)
    ,.width_p(width_p)
    )
   in_afifo
    (.w_clk_i(core_clk_i)
    ,.w_reset_i(core_reset_i)

    ,.w_enq_i(v_i & ready_o)
    ,.w_data_i(data_i)
    ,.w_full_o(in_full_lo)

    ,.r_clk_i(ds_clk_i)
    ,.r_reset_i(ds_reset_i)

    ,.r_valid_o(v_lo)
    ,.r_data_o(data_lo)
    ,.r_deq_i(deq_li)
    );

  // store coverage data in a CAM tag-array
  // data is stored and drained in order from the CAM
  // async read is performed to avoid writing duplicate data
  // snoop port is used to drain data
  assign cam_r_v_li = deq_li;
  assign cam_r_tag_li = data_lo;

  assign cam_w_v_li = (state_r == FILL)
                      ? ({els_p{deq_li & ~(|cam_r_match_lo)}} & cam_idx_oh_lo)
                      : (state_r == DRAIN)
                        ? ({els_p{piso_v_li & piso_ready_and_lo}} & cam_idx_oh_lo)
                        : '0;
  assign cam_set_not_clear_li = (state_r == DRAIN) ? 1'b0 : 1'b1;
  assign cam_w_tag_li = data_lo;

  assign cam_snoop_addr_li = cam_idx_enc_lo;

  // output module configuration
  assign els_o = 8'(els_p);
  assign len_o = 8'(piso_div_lp);

  assign piso_v_li = (state_r == DRAIN) & cam_idx_v_lo;
  assign piso_data_li = {(out_width_p)'(0), cam_snoop_tag_lo};
  assign piso_last_li = (state_r == DRAIN) & (state_n == FILL);

  // count the unique coverage data written/drained into/from the CAM
  // gate the core clock when CAM fills up
  assign gate_o = (state_r != FILL);

  always_comb begin
    case(state_r)
      FILL  : state_n = cam_w_v_li[els_p-1] ? DRAIN : FILL;
      DRAIN : state_n = (piso_v_li & piso_ready_and_lo & cam_w_v_li[els_p-1]) ? FILL : DRAIN;
      default: state_n = FILL;
    endcase
  end

  always_ff @(posedge ds_clk_i) begin
    if(ds_reset_i)
      state_r <= FILL;
    else
      state_r <= state_n;
  end

  bsg_cam_1r1w_tag_array_snoop
   #(.width_p(width_p)
    ,.els_p(els_p)
    )
   cam
    (.clk_i(ds_clk_i)
    ,.reset_i(ds_reset_i)

    ,.w_v_i(cam_w_v_li)
    ,.w_set_not_clear_i(cam_set_not_clear_li)
    ,.w_tag_i(cam_w_tag_li)
    ,.w_empty_o(cam_w_empty_lo)

    ,.r_v_i(cam_r_v_li)
    ,.r_tag_i(cam_r_tag_li)
    ,.r_match_o(cam_r_match_lo)

    ,.snoop_addr_i(cam_snoop_addr_li)
    ,.snoop_tag_o(cam_snoop_tag_lo)
    );

  assign cam_encoh_li = (state_r == FILL) ? cam_w_empty_lo : ~cam_w_empty_lo;
  bsg_priority_encode_one_hot_out
   #(.width_p(els_p)
    ,.lo_to_hi_p(1)
    )
   encoh
    (.i(cam_encoh_li)
    ,.o(cam_idx_oh_lo)
    ,.v_o(cam_idx_v_lo)
    );

  bsg_encode_one_hot
   #(.width_p(els_p))
   enc
    (.i(cam_idx_oh_lo)
    ,.addr_o(cam_idx_enc_lo)
    ,.v_o()
    );

   if(width_p <= out_width_p) begin: pass
     assign v_o = piso_v_li;
     assign data_o = piso_data_li;
     assign last_o = piso_last_li;
     assign piso_ready_and_lo = ready_i;
   end
   else begin: piso
     assign last_o = piso_ready_and_lo & piso_last_li;
     bsg_parallel_in_serial_out_passthrough
      #(.width_p(out_width_p)
       ,.els_p(piso_div_lp)
       ,.hi_to_lo_p(1)
       )
      piso
       (.clk_i(ds_clk_i)
       ,.reset_i(ds_reset_i)

       ,.v_i(piso_v_li)
       ,.data_i(piso_data_li)
       ,.ready_and_o(piso_ready_and_lo)

       ,.v_o(v_o)
       ,.data_o(data_o)
       ,.ready_and_i(ready_i)
       );
   end

   // synopsys translate_off
   if(debug_p) begin: debug
     integer file;
     string fname;
     initial begin
       fname = $sformatf("%0d.ctrace", id_p);
       file = $fopen(fname, "w");
     end

     always_ff @(negedge core_clk_i) begin
       if(~core_reset_i & v_i & ready_o) begin
         $fwrite(file, "%x\n", data_i);
       end
     end

     always_ff @(negedge ds_clk_i) begin
       assert(((els_p * width_p) / out_width_p) <= 256)
         else $error("CAM too big for a single transaction: %0d\n", id_p);
     end
   end
   // synopsys translate_on

endmodule

