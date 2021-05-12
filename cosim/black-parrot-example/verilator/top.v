
`timescale 1 ns / 1 ps

`include "bp_common_defines.svh"

	module top
	 import bp_common_pkg::*;
	 import bp_be_pkg::*;
	 import bp_me_pkg::*;
	 import bsg_noc_pkg::*;
	#(
		// Users to add parameters here
		parameter bp_params_e bp_params_p = e_bp_default_cfg
		`declare_bp_proc_params(bp_params_p)

		, localparam uce_mem_data_width_lp = `BSG_MAX(icache_fill_width_p, dcache_fill_width_p)
		`declare_bp_bedrock_mem_if_widths(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce)
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		, parameter integer C_S00_AXI_DATA_WIDTH	= 32
		, parameter integer C_S00_AXI_ADDR_WIDTH	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
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
		input wire  s00_axi_rready,

		input wire  s01_axi_aclk,
		input wire  s01_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s01_axi_awaddr,
		input wire [2 : 0] s01_axi_awprot,
		input wire  s01_axi_awvalid,
		output wire  s01_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s01_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb,
		input wire  s01_axi_wvalid,
		output wire  s01_axi_wready,
		output wire [1 : 0] s01_axi_bresp,
		output wire  s01_axi_bvalid,
		input wire  s01_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s01_axi_araddr,
		input wire [2 : 0] s01_axi_arprot,
		input wire  s01_axi_arvalid,
		output wire  s01_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s01_axi_rdata,
		output wire [1 : 0] s01_axi_rresp,
		output wire  s01_axi_rvalid,
		input wire  s01_axi_rready
	);

	//TODO: Parameterize
	logic [2:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
	logic [C_S00_AXI_DATA_WIDTH-1:0] out_fifo_data_li, in_fifo_data_lo;
	logic out_fifo_v_li, out_fifo_ready_lo;
	logic in_fifo_v_lo, in_fifo_yumi_li;
	wire [2:0][C_S00_AXI_DATA_WIDTH-1:0] unused = csr_data_lo;

// Instantiation of Axi Bus Interface S00_AXI
	example_axi_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) example_axi_v1_0_S00_AXI_inst (
		.csr_data_o(csr_data_lo),

		.out_fifo_data_i(out_fifo_data_li),
		.out_fifo_v_i(out_fifo_v_li),
		.out_fifo_ready_o(out_fifo_ready_lo),

		.in_fifo_data_o(in_fifo_data_lo),
		.in_fifo_v_o(in_fifo_v_lo),
		.in_fifo_yumi_i(in_fifo_yumi_li),
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

	`declare_bp_bedrock_mem_if(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce);
	bp_bedrock_uce_mem_msg_s io_cmd_lo, io_resp_li;
	logic io_cmd_v_lo, io_cmd_ready_and_li;
	logic io_resp_v_li, io_resp_yumi_lo;

	`declare_bsg_cache_dma_pkt_s(caddr_width_p);
	bsg_cache_dma_pkt_s dma_pkt_lo;
	logic dma_pkt_v_lo, dma_pkt_yumi_li;
	logic [l2_fill_width_p-1:0] dma_data_lo;
	logic dma_data_v_lo, dma_data_yumi_li;
	logic [l2_fill_width_p-1:0] dma_data_li;
	logic dma_data_v_li, dma_data_ready_and_lo;

	logic [C_S00_AXI_ADDR_WIDTH-1:0] waddr_translated_lo, raddr_translated_lo;
	always_comb
		begin
			if (s01_axi_awaddr < 32'hA0000000)
				waddr_translated_lo = s01_axi_awaddr - 32'h80000000;
			else
				waddr_translated_lo = s01_axi_awaddr - 32'h20000000;
		end

	always_comb
		begin
			if (s01_axi_araddr < 32'hA0000000)
				raddr_translated_lo = s01_axi_araddr - 32'h80000000;
			else
				raddr_translated_lo = s01_axi_araddr - 32'h20000000;
		end

	bp_to_axi_decoder
	 #(.bp_params_p(bp_params_p))
	 bp_out_data
		(.clk_i(s01_axi_aclk)
		 ,.reset_i(~s01_axi_aresetn)

		 ,.io_cmd_i(io_cmd_lo)
		 ,.io_cmd_v_i(io_cmd_v_lo)
		 ,.io_cmd_ready_and_o(io_cmd_ready_and_li)

		 ,.io_resp_o(io_resp_li)
		 ,.io_resp_v_o(io_resp_v_li)
		 ,.io_resp_yumi_i(io_resp_yumi_lo)

		 ,.data_o(out_fifo_data_li)
		 ,.v_o(out_fifo_v_li)
		 ,.ready_i(out_fifo_ready_lo)
		 );

	bp_unicore_axi_sim
	 #(.bp_params_p(bp_params_p))
	 blackparrot
	 (.clk_i(s01_axi_aclk)
		,.reset_i(~s01_axi_aresetn)

		,.io_cmd_o(io_cmd_lo)
		,.io_cmd_v_o(io_cmd_v_lo)
		,.io_cmd_ready_and_i(io_cmd_ready_and_li)

		,.io_resp_i(io_resp_li)
		,.io_resp_v_i(io_resp_v_li)
		,.io_resp_yumi_o(io_resp_yumi_lo)

		,.s_axi_lite_awaddr_i(waddr_translated_lo)
    ,.s_axi_lite_awprot_i(s01_axi_awprot)
    ,.s_axi_lite_awvalid_i(s01_axi_awvalid)
    ,.s_axi_lite_awready_o(s01_axi_awready)

    ,.s_axi_lite_wdata_i(s01_axi_wdata)
    ,.s_axi_lite_wstrb_i(s01_axi_wstrb)
    ,.s_axi_lite_wvalid_i(s01_axi_wvalid)
    ,.s_axi_lite_wready_o(s01_axi_wready)

    ,.s_axi_lite_bresp_o(s01_axi_bresp)
    ,.s_axi_lite_bvalid_o(s01_axi_bvalid)
    ,.s_axi_lite_bready_i(s01_axi_bready)

    ,.s_axi_lite_araddr_i(raddr_translated_lo)
    ,.s_axi_lite_arprot_i(s01_axi_arprot)
    ,.s_axi_lite_arvalid_i(s01_axi_arvalid)
    ,.s_axi_lite_arready_o(s01_axi_arready)

    ,.s_axi_lite_rdata_o(s01_axi_rdata)
    ,.s_axi_lite_rresp_o(s01_axi_rresp)
    ,.s_axi_lite_rvalid_o(s01_axi_rvalid)
    ,.s_axi_lite_rready_i(s01_axi_rready)

		,.dma_pkt_o(dma_pkt_lo)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_and_o(dma_data_ready_and_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
    );

	bp_nonsynth_dram
	 #(.bp_params_p(bp_params_p)
		 ,.num_dma_p(1)
		 ,.preload_mem_p(0)
		 ,.dram_type_p("axi")
		 ,.mem_els_p(2**28)
		 )
	 dram
		(.clk_i(s01_axi_aclk)
		 ,.reset_i(~s01_axi_aresetn)

		 ,.dma_pkt_i(dma_pkt_lo)
		 ,.dma_pkt_v_i(dma_pkt_v_lo)
     ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

     ,.dma_data_o(dma_data_li)
     ,.dma_data_v_o(dma_data_v_li)
     ,.dma_data_ready_and_i(dma_data_ready_and_lo)

     ,.dma_data_i(dma_data_lo)
     ,.dma_data_v_i(dma_data_v_lo)
     ,.dma_data_yumi_o(dma_data_yumi_li)

     ,.dram_clk_i(s01_axi_aclk)
     ,.dram_reset_i(~s01_axi_aresetn)
     );

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
