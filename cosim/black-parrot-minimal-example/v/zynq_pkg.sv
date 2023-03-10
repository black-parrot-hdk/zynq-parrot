
package zynq_pkg;

  `include "bsg_defines.v"
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

  typedef struct packed
  {
    bsg_tag_s core_reset;
  }  zynq_wd_tag_lines_s;
  localparam tag_wd_local_els_gp = $bits(zynq_wd_tag_lines_s)/$bits(bsg_tag_s);

  // Warning: Danger Zone
  // Setting parameters below incorrectly may result in chip failure
  //
  //
  // // Struct for reference only
  // typedef struct packed {
  //   zynq_wd_tag_lines_s wd;
  //   zynq_pl_tag_lines_s pl;
  // } bsg_chip

  localparam [tag_lg_width_gp-1:0] tag_pl_offset_gp = 0;
  localparam [tag_lg_width_gp-1:0] tag_wd_offset_gp = tag_pl_offset_gp + tag_pl_local_els_gp;

endpackage

