
`include "bsg_defines.v"

package zynq_pkg;

  localparam addr_width_p = 28;
  localparam data_width_p = 32;
  localparam x_cord_width_p = 7;
  localparam y_cord_width_p = 7;
  localparam num_tiles_x_p = 2;
  localparam num_tiles_y_p = 2;
  localparam pod_x_cord_width_p = x_cord_width_p-`BSG_SAFE_CLOG2(num_tiles_x_p);
  localparam pod_y_cord_width_p = y_cord_width_p-`BSG_SAFE_CLOG2(num_tiles_y_p);
  localparam num_pods_x_p = 1;
  localparam num_pods_y_p = 1;
  localparam num_vcache_rows_p = 1;
  localparam vcache_data_width_p = 32;
  localparam vcache_dma_data_width_p = 32;
  localparam vcache_ways_p = 4;
  localparam vcache_sets_p = 64;
  localparam vcache_addr_width_p = (addr_width_p-1+`BSG_SAFE_CLOG2(data_width_p>>3));  // in bytes;
  localparam vcache_word_tracking_p = 0;
  localparam vcache_block_size_in_words_p = 8;
  localparam vcache_size_p = vcache_sets_p*vcache_ways_p*vcache_block_size_in_words_p;
  localparam barrier_ruche_factor_X_p = 1;
  localparam num_subarray_x_p = 1;
  localparam num_subarray_y_p = 1;
  localparam wh_ruche_factor_p = 1;
  localparam wh_flit_width_p = vcache_dma_data_width_p;
  localparam wh_cid_width_p = `BSG_SAFE_CLOG2(2*wh_ruche_factor_p);
  localparam wh_len_width_p = `BSG_SAFE_CLOG2(2+(vcache_block_size_in_words_p*vcache_data_width_p/vcache_dma_data_width_p));
  localparam wh_cord_width_p = x_cord_width_p;
  localparam icache_block_size_in_words_p = 4;
  localparam icache_entries_p = 1024;
  localparam icache_tag_width_p = 12;
  localparam dmem_size_p = 1024;
  localparam reset_depth_p = 3;
  localparam num_vcaches_per_link_lp = (num_tiles_x_p*num_pods_x_p)/wh_ruche_factor_p/2;
  localparam lg_wh_ruche_factor_lp = `BSG_SAFE_CLOG2(wh_ruche_factor_p);
  localparam lg_num_vcaches_per_link_lp = `BSG_SAFE_CLOG2(num_vcaches_per_link_lp);
  localparam num_dma_p = 2*num_pods_y_p*2*num_vcache_rows_p*wh_ruche_factor_p*num_vcaches_per_link_lp;
  localparam scratchpad_els_p = 1024;

  localparam ep_fifo_els_p = 4;
  localparam rev_use_credits_lp = 5'b00001;
  localparam int rev_fifo_els_lp[4:0] = '{2,2,2,2,3};
  localparam max_credits_p = 32;

  localparam bsg_machine_rom_width_gp = 32;
  localparam bsg_machine_rom_els_gp = 41;
  // Hardcoded for 2x2 configuration (pod_1x1_2X2Y) at the moment
  localparam [bsg_machine_rom_els_gp-1:0][bsg_machine_rom_width_gp-1:0] bsg_machine_rom_arr_gp = {32'b00000000000000000000000000000000, 32'b00000000000000000000000000000101, 32'b00000000000000000000000000011100, 32'b00000000000000000000000000011001, 32'b00000000000000000000000000001010, 32'b00000000000000000000000000000101, 32'b00000000000000000000000000000101, 32'b00000000000000000000000000000010, 32'b00000000000000000000000000000011, 32'b00000000000000000000000000001111, 32'b00100000000000000000000000000000, 32'b00000000000000000000000000000010, 32'b00110010010011010100001001001000, 32'b00010101110010100010000000100010, 32'b00000000000000000000000000000000, 32'b00000000000000000000000000100000, 32'b00000000000000000000000000100000, 32'b00000000000000000000000000100000, 32'b00000000000000000000000000001000, 32'b00000000000000000000000000001000, 32'b00000000000000000000000001000000, 32'b00000000000000000000000000000100, 32'b00011111100110110100100010001011, 32'b01110001001011101101111001000011, 32'b00110100110100101110100101101101, 32'b00000000000000000000000000000001, 32'b00000000000000000000000000000001, 32'b00000000000000000000000000000111, 32'b00000000000000000000000000000111, 32'b00000000000000000000000000000010, 32'b00000000000000000000000000000010, 32'b00000000000000000000000000000000, 32'b00000000000000000000000000000010, 32'b00000000000000000000000000000010, 32'b00000000000000000000000000000010, 32'b00000000000000000000000000000001, 32'b00000000000000000000000000000001, 32'b00000000000000000000000000100000, 32'b00000000000000000000000000011100, 32'b00000111000100110010000000100001, 32'b00000000000001100000000000000000};

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

