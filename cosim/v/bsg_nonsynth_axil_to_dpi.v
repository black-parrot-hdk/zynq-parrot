
`include "bsg_defines.v"

module bsg_nonsynth_axil_to_dpi
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   )
  (output logic                      aclk_o
   , output logic                    aresetn_o

   , input [addr_width_p-1:0]        awaddr_i
   , input [2:0]                     awprot_i
   , input                           awvalid_i
   , output logic                    awready_o

   , input [data_width_p-1:0]        wdata_i
   , input [(data_width_p/8)-1:0]    wstrb_i
   , input                           wvalid_i
   , output logic                    wready_o

   , output logic [1:0]              bresp_o
   , output logic                    bvalid_o
   , input                           bready_i

   , input [addr_width_p-1:0]        araddr_i
   , input [2:0]                     arprot_i
   , input                           arvalid_i
   , output logic                    arready_o

   , output logic [data_width_p-1:0] rdata_o
   , output logic [1:0]              rresp_o
   , output logic                    rvalid_o
   , input                           rready_i
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
     #(.width_p(1), .use_output_p(1))
     aclk_gpio
      (.gpio_i(aclk_o), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     aresetn_gpio
      (.gpio_i(areset), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(addr_width_p), .use_input_p(1))
     awaddr_gpio
      (.gpio_i(awaddr_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(3), .use_input_p(1))
     awprot_gpio
      (.gpio_i(awprot_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     awvalid_gpio
      (.gpio_i(awvalid_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     awready_gpio
      (.gpio_i(), .gpio_o(awready_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p), .use_input_p(1))
     wdata_gpio
      (.gpio_i(wdata_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p/8), .use_input_p(1))
     wstrb_gpio
      (.gpio_i(wstrb_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     wvalid_gpio
      (.gpio_i(wvalid_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     wready_gpio
      (.gpio_i(), .gpio_o(wready_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(2), .use_input_p(1))
     bresp_gpio
      (.gpio_i(), .gpio_o(bresp_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     bvalid_gpio
      (.gpio_i(), .gpio_o(bvalid_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     bready_gpio
      (.gpio_i(bready_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(addr_width_p), .use_input_p(1))
     araddr_gpio
      (.gpio_i(araddr_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(3), .use_input_p(1))
     arprot_gpio
      (.gpio_i(arprot_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     arvalid_gpio
      (.gpio_i(arvalid_i), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     arready_gpio
      (.gpio_i(), .gpio_o(arready_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(data_width_p), .use_input_p(1))
     rdata_gpio
      (.gpio_i(), .gpio_o(rdata_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(2), .use_input_p(1))
     rresp_gpio
      (.gpio_i(), .gpio_o(rresp_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     rvalid_gpio
      (.gpio_i(), .gpio_o(rvalid_o));

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     rready_gpio
      (.gpio_i(rready_i), .gpio_o());

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_axil_to_dpi)

