
`include "bsg_defines.sv"

module bsg_nonsynth_axis_to_dpi
 #(parameter `BSG_INV_PARAM(data_width_p))
  (input                             aclk_i
   , input                           aresetn_i

   , output logic                    tready_o
   , input                           tvalid_i
   , input [data_width_p-1:0]        tdata_i
   , input                           tlast_i
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
     #(.width_p(1), .use_output_p(1))
     tready_gpio
      (.gpio_i(), .gpio_o(tready_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     tvalid_gpio
      (.gpio_i(tvalid_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p), .use_input_p(1))
     tdata_gpio
      (.gpio_i(tdata_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     tlast_gpio
      (.gpio_i(tlast_i), .gpio_o());

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_axis_to_dpi)

