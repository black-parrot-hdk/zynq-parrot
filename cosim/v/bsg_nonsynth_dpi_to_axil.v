
`include "bsg_defines.v"

module bsg_nonsynth_dpi_to_axil
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   )
  (output logic                             aclk_o
   , output logic                           aresetn_o

   , output logic [addr_width_p-1:0]        awaddr_o
   , output logic [2:0]                     awprot_o
   , output logic                           awvalid_o
   , input                                  awready_i

   , output logic [data_width_p-1:0]        wdata_o
   , output logic [(data_width_p/8)-1:0]    wstrb_o
   , output logic                           wvalid_o
   , input                                  wready_i

   , input [1:0]                            bresp_i
   , input                                  bvalid_i
   , output logic                           bready_o

   , output logic [addr_width_p-1:0]        araddr_o
   , output logic [2:0]                     arprot_o
   , output logic                           arvalid_o
   , input                                  arready_i

   , input [data_width_p-1:0]               rdata_i
   , input [1:0]                            rresp_i
   , input                                  rvalid_i
   , output logic                           rready_o
   );

    bsg_nonsynth_clock_gen
     #(.cycle_time_p(1000))
     clock_gen
      (.o(aclk_o));

    logic areset;
    bsg_nonsynth_reset_gen
     #(.reset_cycles_lo_p(1), .reset_cycles_hi_p(10))
     reset_gen
      (.clk_i(aclk_o), .async_reset_o(areset));
    assign aresetn_o = ~areset;

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     aclk_gpio
      (.gpio_i(aclk_o), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     aresetn_gpio
      (.gpio_i(areset), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(addr_width_p), .use_output_p(1))
     awaddr_gpio
      (.gpio_i(), .gpio_o(awaddr_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(3), .use_output_p(1))
     awprot_gpio
      (.gpio_i(), .gpio_o(awprot_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     awvalid_gpio
      (.gpio_i(), .gpio_o(awvalid_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     awready_gpio
      (.gpio_i(awready_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p), .use_output_p(1))
     wdata_gpio
      (.gpio_i(), .gpio_o(wdata_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p/8), .use_output_p(1))
     wstrb_gpio
      (.gpio_i(), .gpio_o(wstrb_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     wvalid_gpio
      (.gpio_i(), .gpio_o(wvalid_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     wready_gpio
      (.gpio_i(wready_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(2), .use_input_p(1))
     bresp_gpio
      (.gpio_i(bresp_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     bvalid_gpio
      (.gpio_i(bvalid_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     bready_gpio
      (.gpio_i(), .gpio_o(bready_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(addr_width_p), .use_output_p(1))
     araddr_gpio
      (.gpio_i(), .gpio_o(araddr_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(3), .use_output_p(1))
     arprot_gpio
      (.gpio_i(), .gpio_o(arprot_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     arvalid_gpio
      (.gpio_i(), .gpio_o(arvalid_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     arready_gpio
      (.gpio_i(arready_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p), .use_input_p(1))
     rdata_gpio
      (.gpio_i(rdata_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(2), .use_input_p(1))
     rresp_gpio
      (.gpio_i(rresp_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     rvalid_gpio
      (.gpio_i(rvalid_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     rready_gpio
      (.gpio_i(), .gpio_o(rready_o));

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_dpi_to_axil)

