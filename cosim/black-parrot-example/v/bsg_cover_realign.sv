
`include "bsg_defines.sv"

(* keep_hierarchy = "yes" *)
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
  ,input reset_i
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
     wire [(8 * `BSG_CDIV(num_p,8))-1 : 0] data_li = {{8{1'b0}}, data_i};
     wire [(8 * `BSG_CDIV(num_p,8))-1 : 0] data_lo = {{8{1'b0}}, data_o};
     integer f_raw, f_align;
     string fn_raw, fn_align;
     initial begin
       fn_raw = $sformatf("%0d.raw", id_p);
       fn_align = $sformatf("%0d.align", id_p);
       f_raw = $fopen(fn_raw, "w");
       f_align = $fopen(fn_align, "w");
     end

     always_ff @(negedge clk_i) begin
       if(~reset_i & v_i) begin
         for(int i = `BSG_CDIV(num_p,8)-1; i >= 0; i--) begin: wr
           $fwrite(f_raw, "%02x", data_li[i*8 +: 8]);
           $fwrite(f_align, "%02x", data_lo[i*8 +: 8]);
         end
         $fwrite(f_raw, "\n");
         $fwrite(f_align, "\n");
         $fflush(f_raw);
         $fflush(f_align);
       end
     end
   end
   // synopsys translate_on

endmodule

