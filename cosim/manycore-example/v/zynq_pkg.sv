
`include "bsg_defines.v"

package zynq_pkg;

  localparam reset_depth_gp = 3;
  localparam rev_use_credits_gp = 5'b00001;
  localparam int rev_fifo_els_gp[4:0] = '{2,2,2,2,3};
  localparam ep_fifo_els_gp = 4;
  localparam max_credits_gp = 32;

  import bsg_tag_pkg::*;

  // Total number of tag clients in the whole system
  localparam tag_els_gp = 16;
  localparam tag_lg_els_gp = `BSG_SAFE_CLOG2(tag_els_gp);

  // Maximum payload width in the whole design
  localparam tag_max_payload_width_gp = 1;

  // The number of bits required to represent the max payload width
  localparam tag_lg_width_gp = `BSG_SAFE_CLOG2(tag_max_payload_width_gp + 1);

  typedef struct packed
  {
    bsg_tag_s core_reset;
  }  zynq_pl_tag_lines_s;
  localparam tag_pl_local_els_gp = $bits(zynq_pl_tag_lines_s)/$bits(bsg_tag_s);

  // Warning: Danger Zone
  // Setting parameters below incorrectly may result in chip failure
  //
  //
  // // Struct for reference only
  // typedef struct packed {
  //   zynq_pl_tag_lines_s mc;
  // } bsg_chip

  localparam [tag_lg_els_gp-1:0] tag_pl_offset_gp = 0;

endpackage

