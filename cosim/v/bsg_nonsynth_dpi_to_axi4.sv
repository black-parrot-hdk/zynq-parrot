
`include "bsg_defines.sv"

module bsg_nonsynth_dpi_to_axi4
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , localparam strb_width_lp = data_width_p >> 3
   )
  (output logic                             aclk_o
   , output logic                           aresetn_o

   , output logic [addr_width_p-1:0]        awaddr_o
   , output logic [1:0]                     awburst_o
   , output logic [7:0]                     awlen_o
   , output logic                           awvalid_o
   , input                                  awready_i
   , output logic [0:0]                     awid_o

   , output logic [data_width_p-1:0]        wdata_o
   , output logic [strb_width_lp-1:0]       wstrb_o
   , output logic                           wlast_o
   , output logic                           wvalid_o
   , input                                  wready_i
   , output logic [0:0]                     wid_o

   , input                                  bvalid_i
   , output logic                           bready_o
   , input [0:0]                            bid_i
   , input [1:0]                            bresp_i

   , output logic [addr_width_p-1:0]        araddr_o
   , output logic [1:0]                     arburst_o
   , output logic [7:0]                     arlen_o
   , output logic                           arvalid_o
   , input                                  arready_i
   , output logic [0:0]                     arid_o

   , input [data_width_p-1:0]               rdata_i
   , input                                  rlast_i
   , input                                  rvalid_i
   , output logic                           rready_o
   , input [0:0]                            rid_i
   , input [1:0]                            rresp_i
   );

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   aclk_gpio
    (.gpio_i(aclk_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   aresetn_gpio
    (.gpio_i(aresetn_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(addr_width_p), .use_output_p(1))
   awaddr_gpio
    (.gpio_i(), .gpio_o(awaddr_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(2), .use_output_p(1))
   awburst_gpio
    (.gpio_i(), .gpio_o(awburst_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(8), .use_output_p(1))
   awlen_gpio
    (.gpio_i(), .gpio_o(awlen_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   awvalid_gpio
    (.gpio_i(), .gpio_o(awvalid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   awready_gpio
    (.gpio_i(awready_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   awid_gpio
    (.gpio_i(), .gpio_o(awid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(data_width_p), .use_output_p(1))
   wdata_gpio
    (.gpio_i(), .gpio_o(wdata_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(strb_width_lp), .use_output_p(1))
   wstrb_gpio
    (.gpio_i(), .gpio_o(wstrb_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   wlast_gpio
    (.gpio_i(), .gpio_o(wlast_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   wvalid_gpio
    (.gpio_i(), .gpio_o(wvalid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   wready_gpio
    (.gpio_i(wready_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   wid_gpio
    (.gpio_i(), .gpio_o(wid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   bvalid_gpio
    (.gpio_i(bvalid_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   bready_gpio
    (.gpio_i(), .gpio_o(bready_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   bid_gpio
    (.gpio_i(bid_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(2), .use_input_p(1))
   bresp_gpio
    (.gpio_i(bresp_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(addr_width_p), .use_output_p(1))
   araddr_gpio
    (.gpio_i(), .gpio_o(araddr_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(2), .use_output_p(1))
   arburst_gpio
    (.gpio_i(), .gpio_o(arburst_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(8), .use_output_p(1))
   arlen_gpio
    (.gpio_i(), .gpio_o(arlen_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   arvalid_gpio
    (.gpio_i(), .gpio_o(arvalid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   arready_gpio
    (.gpio_i(arready_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   arid_gpio
    (.gpio_i(), .gpio_o(arid_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(data_width_p), .use_input_p(1))
   rdata_gpio
    (.gpio_i(rdata_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   rvalid_gpio
    (.gpio_i(rvalid_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_output_p(1))
   rready_gpio
    (.gpio_i(), .gpio_o(rready_o));

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   rid_gpio
    (.gpio_i(rid_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(1), .use_input_p(1))
   rlast_gpio
    (.gpio_i(rlast_i), .gpio_o());

  bsg_nonsynth_dpi_gpio
   #(.width_p(2), .use_input_p(1))
   rresp_gpio
    (.gpio_i(rresp_i), .gpio_o());

endmodule

