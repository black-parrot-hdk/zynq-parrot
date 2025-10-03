
`include "bsg_defines.sv"

module bsg_nonsynth_dpi_to_axis
 #(parameter `BSG_INV_PARAM(data_width_p), localparam strb_width_lp = data_width_p >> 3)
  (input                                 aclk_i
   , input                               aresetn_i

   , output logic [data_width_p-1:0]     tdata_o
   , output logic                        tlast_o
   , output logic                        tvalid_o
   , input                               tready_i
   );

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   aclk_gpio
    (.gpio_i(aclk_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   aresetn_gpio
    (.gpio_i(aresetn_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(data_width_p), .use_output_p(1))
   tdata_gpio
    (.gpio_i(), .gpio_o(tdata_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   tlast_gpio
    (.gpio_i(), .gpio_o(tlast_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   tvalid_gpio
    (.gpio_i(), .gpio_o(tvalid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   tready_gpio
    (.gpio_i(tready_i), .gpio_o());

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_dpi_to_axis)

