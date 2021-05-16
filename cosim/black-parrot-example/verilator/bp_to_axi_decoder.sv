`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_to_axi_decoder
 import bp_common_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   , localparam uce_mem_data_width_lp = `BSG_MAX(icache_fill_width_p, dcache_fill_width_p)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce)
   )
   (input clk_i
    ,input reset_i

    ,input [uce_mem_msg_width_lp-1:0]        io_cmd_i
    ,input                                   io_cmd_v_i
    ,output logic                            io_cmd_ready_and_o

    ,output logic [uce_mem_msg_width_lp-1:0] io_resp_o
    ,output logic                            io_resp_v_o
    ,input                                   io_resp_yumi_i

    ,output [31:0]                           data_o
    ,output                                  v_o
    ,input                                   ready_i
    );

   `declare_bp_bedrock_mem_if(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce);

   // io cmd and resp structure cast
   bp_bedrock_uce_mem_msg_s io_cmd_cast_i, io_resp_cast_o;

   assign io_cmd_cast_i = io_cmd_i;
   assign io_resp_o     = io_resp_cast_o;

   // storing io cmd header
   bp_bedrock_uce_mem_msg_header_s io_cmd_header_r;

   bsg_dff_reset_en
     #(.width_p(uce_mem_msg_header_width_lp))
   mem_header_reg
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i  (io_cmd_v_i)
      ,.data_i(io_cmd_cast_i.header)
      ,.data_o(io_cmd_header_r)
      );

   // io cmd read/write validity
   wire io_cmd_w_v = io_cmd_v_i & (io_cmd_cast_i.header.msg_type == e_bedrock_mem_uc_wr);
   wire io_cmd_r_v = io_cmd_v_i & (io_cmd_cast_i.header.msg_type == e_bedrock_mem_uc_rd);

   assign v_o = (io_cmd_w_v | io_cmd_r_v) & ready_i;
   assign io_cmd_ready_and_o = ready_i;

   wire write = (io_cmd_cast_i.header.msg_type == e_bedrock_mem_uc_wr);

   assign data_o = {write, io_cmd_cast_i.header.addr[22:0], io_cmd_cast_i.data[7:0]};

   bsg_dff_reset_set_clear
     #(.width_p(1))
   resp_v_reg
     (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.set_i(v_o)
      ,.clear_i(io_resp_yumi_i)
      ,.data_o(io_resp_v_o)
      );

   assign io_resp_cast_o = '{header: io_cmd_header_r, data: '0};

endmodule
