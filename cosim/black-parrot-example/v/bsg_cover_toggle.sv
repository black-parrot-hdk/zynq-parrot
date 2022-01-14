
`include "bsg_defines.sv"

(* dont_touch = "yes" *)
module bsg_cover_toggle
 #(parameter `BSG_INV_PARAM(id_p)
  ,parameter `BSG_INV_PARAM(width_p)
  ,parameter `BSG_INV_PARAM(lg_afifo_size_p)
  ,parameter `BSG_INV_PARAM(debug_p)

  ,localparam pwidth_lp = 128
  ,localparam [pwidth_lp-1:0] map_width_lp = (2 ** width_p)
  )
  (input core_clk_i
  ,input core_reset_i

  ,input ds_clk_i
  ,input ds_reset_i

  // core domain
  ,input v_i
  ,input [width_p-1:0] data_i
  ,output logic ready_o

  ,output logic [width_p-1:0] data_o
  );

  // signal definition
  logic in_full_lo, v_lo, deq_li;
  logic [width_p-1:0] data_lo;

  // cross into ungated and downsampled domain
  // TODO: maybe replace with dff output & gate_i
  assign ready_o = ~in_full_lo;
  assign deq_li = v_lo;
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

  localparam mem_width_lp = 64;
  localparam lg_mem_width_lp = `BSG_SAFE_CLOG2(mem_width_lp);
  localparam [pwidth_lp-1:0] mem_els_lp = (map_width_lp / mem_width_lp);
  localparam [pwidth_lp-1:0] lg_mem_els_lp = `BSG_SAFE_CLOG2(mem_els_lp);

  logic [lg_mem_els_lp-1:0] addr_li;
  logic [mem_width_lp-1:0] data_li, mask_li;

  assign addr_li = data_lo[width_p-1:lg_mem_width_lp];
  assign data_li = '1;

  bsg_decode
   #(.num_out_p(mem_width_lp))
   dec
    (.i(data_lo[lg_mem_width_lp-1:0])
    ,.o(mask_li)
    );

  bsg_mem_1rw_sync_mask_write_bit_from_1r1w
   #(.width_p(mem_width_lp)
    ,.els_p(mem_els_lp)
    )
   bram
    (.clk_i(ds_clk_i)
    ,.reset_i(ds_reset_i)

    ,.v_i(deq_li)
    ,.w_i(data_lo[0])
    ,.addr_i(addr_li)
    ,.data_i(data_li)
    ,.w_mask_i(mask_li)

    ,.data_o(data_o)
    );

endmodule

