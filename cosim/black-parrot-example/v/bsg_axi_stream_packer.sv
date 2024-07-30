
`include "bsg_defines.sv"

module bsg_axi_stream_packer
 #(parameter `BSG_INV_PARAM(width_p)
  ,parameter `BSG_INV_PARAM(max_len_p)

  ,localparam lg_max_len_lp = `BSG_SAFE_CLOG2(max_len_p)
  )
  (input clk_i
  ,input reset_i

  ,input v_i
  ,input last_i
  ,input [width_p-1:0] data_i
  ,output logic ready_o

  ,output logic v_o
  ,output logic last_o
  ,output logic [width_p-1:0] data_o
  ,input ready_i
  );


  logic [lg_max_len_lp-1:0] cnt_lo;
  bsg_counter_clear_up
   #(.max_val_p(max_len_p-1), .init_val_p(0))
   cycle_cnt
    (.clk_i(clk)
    ,.reset_i(reset_i)
    ,.clear_i(v_o & ready_i & last_o)
    ,.up_i(v_o & ready_i & ~last_o)
    ,.count_o(cnt_lo)
    );

  logic safe_last;
  bsg_dff_reset_set_clear
   #(.width_p(1), .clear_over_set_p(1))
   safe_last_reg
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(v_o & ready_i & last_o)
    ,.set_i(v_i & ready_o & last_i)
    ,.data_o(safe_last)
    );

  wire critical_last = (cnt_lo == (max_len_p - 1));

  assign ready_o = ready_i & ~last_o;

  assign v_o = (v_i & ready_o) | last_o;
  assign last_o = safe_last | critical_last;
  assign data_o = last_o ? 32'hdeadbeef : data_i;

endmodule

