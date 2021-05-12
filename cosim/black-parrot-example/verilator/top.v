
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
				waddr_translated_lo = s01_axi_awaddr - csr_data_lo[0];
			else
				waddr_translated_lo = s01_axi_awaddr - csr_data_lo[1];
		end

	always_comb
		begin
			if (s01_axi_araddr < 32'hA0000000)
				raddr_translated_lo = s01_axi_araddr - csr_data_lo[0];
			else
				raddr_translated_lo = s01_axi_araddr - csr_data_lo[1];
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

	localparam axi_id_width_p = 6;
  localparam axi_addr_width_p = 33;
  localparam axi_data_width_p = 64;
  localparam axi_strb_width_p = axi_data_width_p >> 3;
  localparam axi_burst_len_p = 8;

  wire [axi_id_width_p-1:0] axi_awid;
  wire [axi_addr_width_p-1:0] axi_awaddr;
  wire [7:0] axi_awlen;
  wire [2:0] axi_awsize;
  wire [1:0] axi_awburst;
  wire [3:0] axi_awcache;
  wire [2:0] axi_awprot;
	wire [3:0] axi_awqos;
  wire axi_awlock, axi_awvalid, axi_awready;

  wire [axi_data_width_p-1:0] axi_wdata;
  wire [axi_strb_width_p-1:0] axi_wstrb;
  wire axi_wlast, axi_wvalid, axi_wready;

  wire [axi_id_width_p-1:0] axi_bid;
  wire [1:0] axi_bresp;
  wire axi_bvalid, axi_bready;

  wire [axi_id_width_p-1:0] axi_arid;
  wire [axi_addr_width_p-1:0] axi_araddr;
  wire [7:0] axi_arlen;
  wire [2:0] axi_arsize;
  wire [1:0] axi_arburst;
  wire [3:0] axi_arcache;
  wire [2:0] axi_arprot;
	wire [3:0] axi_arqos;
  wire axi_arlock, axi_arvalid, axi_arready;

  wire [axi_id_width_p-1:0] axi_rid;
  wire [axi_data_width_p-1:0] axi_rdata;
  wire [1:0] axi_rresp;
  wire axi_rlast, axi_rvalid, axi_rready;

	wire [C_S00_AXI_ADDR_WIDTH-1:0] waddr_dram_translated_lo = axi_awaddr -32'h80000000 + csr_data_lo[2];
	wire [C_S00_AXI_ADDR_WIDTH-1:0] raddr_dram_translated_lo = axi_araddr -32'h80000000 + csr_data_lo[2];

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

	bsg_cache_to_axi
    #(.addr_width_p(caddr_width_p)
      ,.data_width_p(l2_fill_width_p)
      ,.block_size_in_words_p(l2_block_size_in_fill_p)
      ,.num_cache_p(1)
      ,.axi_id_width_p(axi_id_width_p)
      ,.axi_addr_width_p(axi_addr_width_p)
      ,.axi_data_width_p(axi_data_width_p)
      ,.axi_burst_len_p(axi_burst_len_p)
      )
   cache2axi
     (.clk_i(s01_axi_aclk)
      ,.reset_i(~s01_axi_aresetn)

      ,.dma_pkt_i(dma_pkt_lo)
      ,.dma_pkt_v_i(dma_pkt_v_lo)
      ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

      ,.dma_data_o(dma_data_li)
      ,.dma_data_v_o(dma_data_v_li)
      ,.dma_data_ready_i(dma_data_ready_and_lo)

      ,.dma_data_i(dma_data_lo)
      ,.dma_data_v_i(dma_data_v_lo)
      ,.dma_data_yumi_o(dma_data_yumi_li)

      ,.axi_awid_o(axi_awid)
      ,.axi_awaddr_o(axi_awaddr)
      ,.axi_awlen_o(axi_awlen)
      ,.axi_awsize_o(axi_awsize)
      ,.axi_awburst_o(axi_awburst)
      ,.axi_awcache_o(axi_awcache)
      ,.axi_awprot_o(axi_awprot)
      ,.axi_awlock_o(axi_awlock)
      ,.axi_awvalid_o(axi_awvalid)
      ,.axi_awready_i(axi_awready)

      ,.axi_wdata_o(axi_wdata)
      ,.axi_wstrb_o(axi_wstrb)
      ,.axi_wlast_o(axi_wlast)
      ,.axi_wvalid_o(axi_wvalid)
      ,.axi_wready_i(axi_wready)

      ,.axi_bid_i(axi_bid)
      ,.axi_bresp_i(axi_bresp)
			,.axi_bvalid_i(axi_bvalid)
      ,.axi_bready_o(axi_bready)
      ,.axi_arid_o(axi_arid)
      ,.axi_araddr_o(axi_araddr)
      ,.axi_arlen_o(axi_arlen)
      ,.axi_arsize_o(axi_arsize)
      ,.axi_arburst_o(axi_arburst)
      ,.axi_arcache_o(axi_arcache)
      ,.axi_arprot_o(axi_arprot)
      ,.axi_arlock_o(axi_arlock)
      ,.axi_arvalid_o(axi_arvalid)
      ,.axi_arready_i(axi_arready)

      ,.axi_rid_i(axi_rid)
      ,.axi_rdata_i(axi_rdata)
      ,.axi_rresp_i(axi_rresp)
      ,.axi_rlast_i(axi_rlast)
      ,.axi_rvalid_i(axi_rvalid)
      ,.axi_rready_o(axi_rready)
      );

	bsg_nonsynth_axi_mem
   #(.axi_id_width_p(axi_id_width_p)
     ,.axi_addr_width_p(axi_addr_width_p)
     ,.axi_data_width_p(axi_data_width_p)
     ,.axi_burst_len_p(axi_burst_len_p)
     ,.mem_els_p(2**28)
     ,.init_data_p('0)
     )
   axi_mem
    (.clk_i(s01_axi_aclk)
     ,.reset_i(~s01_axi_aresetn)

     ,.axi_awid_i(axi_awid)
     ,.axi_awaddr_i(waddr_dram_translated_lo)
     ,.axi_awvalid_i(axi_awvalid)
     ,.axi_awready_o(axi_awready)

     ,.axi_wdata_i(axi_wdata)
     ,.axi_wstrb_i(axi_wstrb)
     ,.axi_wlast_i(axi_wlast)
     ,.axi_wvalid_i(axi_wvalid)
     ,.axi_wready_o(axi_wready)

     ,.axi_bid_o(axi_bid)
     ,.axi_bresp_o(axi_bresp)
     ,.axi_bvalid_o(axi_bvalid)
     ,.axi_bready_i(axi_bready)

     ,.axi_arid_i(axi_arid)
     ,.axi_araddr_i(raddr_dram_translated_lo)
     ,.axi_arvalid_i(axi_arvalid)
     ,.axi_arready_o(axi_arready)

     ,.axi_rid_o(axi_rid)
     ,.axi_rdata_o(axi_rdata)
     ,.axi_rresp_o(axi_rresp)
     ,.axi_rlast_o(axi_rlast)
     ,.axi_rvalid_o(axi_rvalid)
     ,.axi_rready_i(axi_rready)
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
