
`include "bsg_defines.sv"

module bsg_cover_realign
 #(parameter `BSG_INV_PARAM(id_p)
  ,parameter `BSG_INV_PARAM(num_p)
  ,parameter `BSG_INV_PARAM(num_chain_p)
  ,parameter `BSG_INV_PARAM(chain_offset_arr_p)
  ,parameter `BSG_INV_PARAM(chain_depth_arr_p)
  ,parameter `BSG_INV_PARAM(step_p)
  ,parameter `BSG_INV_PARAM(debug_p)
  )
  (input clk_i
  ,input v_i
  ,input [num_p-1:0] data_i
  ,output logic [num_p-1:0] data_o
  );

  for(genvar i = 0; i < num_chain_p; i++) begin: rof  
    localparam lsb_idx_lp = chain_offset_arr_p[(i * step_p) +: step_p];
    localparam msb_idx_lp = (i == (num_chain_p - 1)) ? (num_p - 1) : (chain_offset_arr_p[((i+1) * step_p) +: step_p] - 1);
    localparam width_lp = msb_idx_lp - lsb_idx_lp + 1;
    localparam depth_lp = chain_depth_arr_p[(i * step_p) +: step_p];

    wire [width_lp-1 : 0] chain_data_li = data_i[msb_idx_lp : lsb_idx_lp];
    logic [width_lp-1 : 0] chain_data_lo;
    bsg_dff_chain
     #(.width_p(width_lp)
      ,.num_stages_p(depth_lp)
      )
     chain
      (.clk_i(clk_i)
      ,.data_i(chain_data_li)
      ,.data_o(chain_data_lo)
      );

    assign data_o[msb_idx_lp : lsb_idx_lp] = chain_data_lo;
  end

   // synopsys translate_off
   if(debug_p) begin: debug
     integer file;
     string fname;
     initial begin
       fname = $sformatf("%0d.noalign.ctrace", id_p);
       file = $fopen(fname, "w");
     end

     always_ff @(negedge clk_i) begin
       if(v_i) begin
         $fwrite(file, "%x\n", data_i);
       end
     end
   end
   // synopsys translate_on

endmodule

