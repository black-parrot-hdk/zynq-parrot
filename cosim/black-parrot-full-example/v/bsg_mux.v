`include "bsg_defines.v"

(* KEEP_HIERARCHY = "TRUE" *)
module bsg_mux #(
    parameter `BSG_INV_PARAM(width_p)
  , els_p=1
  , harden_p = 0
  , balanced_p = 0
  , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
)
(
    input  [els_p-1:0][width_p-1:0] data_i
  , input  [lg_els_lp-1:0] sel_i
  , output [width_p-1:0] data_o
);

  if (els_p == 1) begin
    assign data_o = data_i;
    wire unused = sel_i;
  end
  else begin
    assign data_o = data_i[sel_i];
  end
endmodule

`BSG_ABSTRACT_MODULE(bsg_mux)
