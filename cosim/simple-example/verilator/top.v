
`timescale 1 ns / 1 ps

	module top #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Ports of Axi Slave Bus Interface S00_AXI
`ifndef VERILATOR
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
`endif
	);

`ifdef VERILATOR
    logic s00_axi_aclk;
    bsg_nonsynth_dpi_clock_gen # (
        .cycle_time_p(1000)
    ) clock_gen (
        .o(s00_axi_aclk)
    );

    logic s00_axi_areset, s00_axi_aresetn;
    bsg_nonsynth_reset_gen # (
        .reset_cycles_lo_p(1),
        .reset_cycles_hi_p(10)
    ) reset_gen (
        .clk_i(s00_axi_aclk),
        .async_reset_o(s00_axi_areset)
    );
    assign s00_axi_aresetn = ~s00_axi_areset;

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_aclk_gpio
      (.gpio_i(s00_axi_aclk), .gpio_o());

    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_aresetn_gpio
      (.gpio_i(s00_axi_aresetn), .gpio_o());

    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    bsg_nonsynth_dpi_gpio
     #(.width_p(C_S00_AXI_ADDR_WIDTH), .use_output_p(1))
     axi_awaddr_gpio
      (.gpio_i(), .gpio_o(s00_axi_awaddr));

    logic [2:0] s00_axi_awprot;
    bsg_nonsynth_dpi_gpio
     #(.width_p(3), .use_output_p(1))
     axi_awprot_gpio
      (.gpio_i(), .gpio_o(s00_axi_awprot));

    logic [0:0] s00_axi_awvalid;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     axi_awvalid_gpio
      (.gpio_i(), .gpio_o(s00_axi_awvalid));

    logic [0:0] s00_axi_awready;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_awready_gpio
      (.gpio_i(s00_axi_awready), .gpio_o());

    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    bsg_nonsynth_dpi_gpio
     #(.width_p(C_S00_AXI_DATA_WIDTH), .use_output_p(1))
     axi_wdata_gpio
      (.gpio_i(), .gpio_o(s00_axi_wdata));

    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    bsg_nonsynth_dpi_gpio
     #(.width_p(C_S00_AXI_DATA_WIDTH/8), .use_output_p(1))
     axi_wstrb_gpio
      (.gpio_i(), .gpio_o(s00_axi_wstrb));

    logic [0:0] s00_axi_wvalid;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     axi_wvalid_gpio
      (.gpio_i(), .gpio_o(s00_axi_wvalid));

    logic [0:0] s00_axi_wready;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_wready_gpio
      (.gpio_i(s00_axi_wready), .gpio_o());

    logic [1:0] s00_axi_bresp;
    bsg_nonsynth_dpi_gpio
     #(.width_p(2), .use_input_p(1))
     axi_bresp_gpio
      (.gpio_i(s00_axi_bresp), .gpio_o());

    logic [0:0] s00_axi_bvalid;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_bvalid_gpio
      (.gpio_i(s00_axi_bvalid), .gpio_o());

    logic [0:0] s00_axi_bready;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     axi_bready_gpio
      (.gpio_i(), .gpio_o(s00_axi_bready));

    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    bsg_nonsynth_dpi_gpio
     #(.width_p(C_S00_AXI_ADDR_WIDTH), .use_output_p(1))
     axi_araddr_gpio
      (.gpio_i(), .gpio_o(s00_axi_araddr));

    logic [2:0] s00_axi_arprot;
    bsg_nonsynth_dpi_gpio
     #(.width_p(3), .use_output_p(1))
     axi_arprot_gpio
      (.gpio_i(), .gpio_o(s00_axi_arprot));

    logic [0:0] s00_axi_arvalid;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     axi_arvalid_gpio
      (.gpio_i(), .gpio_o(s00_axi_arvalid));

    logic [0:0] s00_axi_arready;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_arready_gpio
      (.gpio_i(s00_axi_arready), .gpio_o());

    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    bsg_nonsynth_dpi_gpio
     #(.width_p(C_S00_AXI_DATA_WIDTH), .use_input_p(1))
     axi_rdata_gpio
      (.gpio_i(s00_axi_rdata), .gpio_o());

    logic [1:0] s00_axi_rresp;
    bsg_nonsynth_dpi_gpio
     #(.width_p(2), .use_input_p(1))
     axi_rresp_gpio
      (.gpio_i(s00_axi_rresp), .gpio_o());

    logic [0:0] s00_axi_rvalid;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_input_p(1))
     axi_rvalid_gpio
      (.gpio_i(s00_axi_rvalid), .gpio_o());

    logic [0:0] s00_axi_rready;
    bsg_nonsynth_dpi_gpio
     #(.width_p(1), .use_output_p(1))
     axi_rready_gpio
      (.gpio_i(), .gpio_o(s00_axi_rready));

`endif

// Instantiation of Axi Bus Interface S00_AXI
	example_axi_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) example_axi_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

   initial
     begin
	   if ($test$plusargs("bsg_trace") != 0) 
	     begin
                $display("[%0t] Tracing to trace.fst...\n", $time);
                $dumpfile("trace.fst");
                $dumpvars();
	     end
     end
   
 endmodule
