
`include "bsg_defines.v"
`include "bsg_tag.vh"

/*
 *   This is a simple wrapper that joins 1 bsg_tag_bitbang, 1 bsg_tag_master
 * and els_p bsg_tag_clients. One bsg_tag_client for one reset generation.
 *
 */

module bsg_tag_reset_gen
    import bsg_tag_pkg::bsg_tag_s;
#(
    parameter `BSG_INV_PARAM(els_p)
)
(
    input tag_clk_i
  , input tag_reset_i
  , input tag_data_i
  , input tag_v_i

  // clock domains and their synced reset signals:
  , input        [els_p-1:0] clks_i
  , output logic [els_p-1:0] resets_o
);
  localparam width_lp = 1;
  localparam lg_width_lp = `BSG_WIDTH(width_lp);

  logic tag_clk_r_lo;
  logic tag_data_r_lo;

  `declare_bsg_tag_header_s(els_p, lg_width_lp)

  bsg_tag_s [els_p-1:0] tag;
  bsg_tag_bitbang bitbang (
     .clk_i(tag_clk_i)
    ,.reset_i(tag_reset_i)
    ,.data_i(tag_data_i)
    ,.v_i(tag_v_i)
    ,.ready_and_o() // UNUSED

    ,.tag_clk_r_o(tag_clk_r_lo)
    ,.tag_data_r_o(tag_data_r_lo)
  );

  bsg_tag_master #(
     .els_p(els_p)
    ,.lg_width_p(lg_width_lp)
  ) master (
     .clk_i(tag_clk_r_lo)
    ,.en_i(1'b1)
    ,.data_i(tag_data_r_lo)
    ,.clients_r_o(tag)
  );

  for(genvar i = 0;i < els_p;i++) begin: tag_client
  bsg_tag_client #(
     .width_p(width_lp)
  ) client (
     .bsg_tag_i(tag[i])
    ,.recv_clk_i(clks_i[i])
    ,.recv_new_r_o() // UNUSED
    ,.recv_data_r_o(resets_o[i])
  );
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_tag_reset_gen)
