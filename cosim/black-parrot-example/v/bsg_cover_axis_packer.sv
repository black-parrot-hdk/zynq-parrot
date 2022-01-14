
`include "bsg_defines.sv"

module bsg_cover_axis_packer
 #(parameter `BSG_INV_PARAM(num_p)
  ,parameter `BSG_INV_PARAM(data_width_p)
  )
  (input axi_clk_i
  ,input axi_reset_i

  ,input ds_clk_i
  ,input ds_reset_i

  ,input [num_p-1:0][7:0] els_i
  ,input [num_p-1:0][7:0] len_i

  ,input [num_p-1:0] gate_i

  ,output logic [num_p-1:0] ready_o
  ,input [num_p-1:0] v_i
  ,input [num_p-1:0] last_i
  ,input [num_p-1:0][data_width_p-1:0] data_i
  
  ,input tready_i
  ,output logic tvalid_o
  ,output logic tlast_o
  ,output logic [data_width_p-1:0] tdata_o
  ,output logic [(data_width_p/8)-1:0] tkeep_o
  );

  // signals
  logic ready_lo;
  logic afifo_full_lo;

  logic way_lock_r;
  logic [`BSG_SAFE_CLOG2(num_p)-1:0] way_lo, way_li, way_r; 

  logic tvalid_li, tlast_li, tready_lo;
  logic [data_width_p-1:0] tdata_li;

  typedef struct packed {
    logic [7:0] len;
    logic [7:0] els;
    logic [7:0] id;
  } header_s;
  header_s header_li;

  // lock picked covergroup to drain
  assign way_lo = way_lock_r ? way_r : way_li;
  always_ff @(posedge ds_clk_i) begin
    if(ds_reset_i) begin
      way_lock_r <= 1'b0;
      way_r <= '0;
    end
    else begin
      if(tvalid_li & tready_lo)
        way_lock_r <= ~tlast_li;

      if(~way_lock_r)
        way_r <= way_li;
    end
  end

  bsg_priority_encode
   #(.width_p(num_p)
    ,.lo_to_hi_p(1)
    )
   enc
    (.i(gate_i)
    ,.addr_o(way_li)
    ,.v_o()
    );

  assign ready_lo = tready_lo & way_lock_r;
  bsg_decode_with_v
   #(.num_out_p(num_p))
   cov_demux
    (.i(way_lo)
    ,.v_i(ready_lo)
    ,.o(ready_o)
    );

  // assemble AXI stream
  assign header_li = '{len: len_i[way_lo]
                      ,els: els_i[way_lo]
                      ,id: way_lo
                      };

  assign tready_lo = ~afifo_full_lo;
  assign tvalid_li = v_i[way_lo];
  assign tlast_li = last_i[way_lo];
  assign tdata_li = way_lock_r ? data_i[way_lo] : header_li;

  // AXI clock crossing
  assign tkeep_o = '1;
  bsg_async_fifo
   #(.lg_size_p(3)
    ,.width_p(data_width_p+1)
    )
   cov_afifo
    (.w_clk_i(ds_clk_i)
    ,.w_reset_i(ds_reset_i)

    ,.w_enq_i(tvalid_li & tready_lo)
    ,.w_data_i({tlast_li, tdata_li})
    ,.w_full_o(afifo_full_lo)

    ,.r_clk_i(axi_clk_i)
    ,.r_reset_i(axi_reset_i)

    ,.r_valid_o(tvalid_o)
    ,.r_data_o({tlast_o, tdata_o})
    ,.r_deq_i(tvalid_o & tready_i)
    );

endmodule

