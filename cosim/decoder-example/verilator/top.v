
`timescale 1 ns / 1 ps

module top #
  (
   // Users to add parameters here
   
   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_S00_AXI_DATA_WIDTH = 32,
   parameter integer C_S00_AXI_ADDR_WIDTH = 6
   )
   (
    // Users to add ports here
    
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input wire 					s00_axi_aclk,
    input wire 					s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] 	s00_axi_awaddr,
    input wire [2 : 0] 				s00_axi_awprot,
    input wire 					s00_axi_awvalid,
    output wire 				s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] 	s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire 					s00_axi_wvalid,
    output wire 				s00_axi_wready,
    output wire [1 : 0] 			s00_axi_bresp,
    output wire 				s00_axi_bvalid,
    input wire 					s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] 	s00_axi_araddr,
    input wire [2 : 0] 				s00_axi_arprot,
    input wire 					s00_axi_arvalid,
    output wire 				s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] 	s00_axi_rdata,
    output wire [1 : 0] 			s00_axi_rresp,
    output wire 				s00_axi_rvalid,
    input wire 					s00_axi_rready
    );

   genvar 					k;
   
   
   localparam num_regs_lp = 4;
   localparam num_fifo_ps_to_pl_lp = 4;
   localparam num_fifo_pl_to_ps_lp = 2;

   wire [num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [num_fifo_pl_to_ps_lp-1:0] 			     pl_to_ps_fifo_v_li;
   wire [num_fifo_pl_to_ps_lp-1:0] 			     pl_to_ps_fifo_ready_lo;
   
   wire [num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [num_fifo_ps_to_pl_lp-1:0] 			     ps_to_pl_fifo_v_lo;
   wire [num_fifo_ps_to_pl_lp-1:0] 			     ps_to_pl_fifo_yumi_li;

   wire [num_regs_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] 	     csr_data_lo;
   
   
   bsg_zynq_pl_shell 
     #(
       .num_regs_p(num_regs_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
       ) bzps 
       (
	.pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li)
	,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
	,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

	,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
	,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
	,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

	,.csr_data_o(csr_data_lo)

	,.S_AXI_ACLK   (s00_axi_aclk   )
	,.S_AXI_ARESETN(s00_axi_aresetn)
	,.S_AXI_AWADDR (s00_axi_awaddr )
	,.S_AXI_AWPROT (s00_axi_awprot )
	,.S_AXI_AWVALID(s00_axi_awvalid)
	,.S_AXI_AWREADY(s00_axi_awready)
	,.S_AXI_WDATA  (s00_axi_wdata  )
	,.S_AXI_WSTRB  (s00_axi_wstrb  )
	,.S_AXI_WVALID (s00_axi_wvalid )
	,.S_AXI_WREADY (s00_axi_wready )
	,.S_AXI_BRESP  (s00_axi_bresp  )
	,.S_AXI_BVALID (s00_axi_bvalid )
	,.S_AXI_BREADY (s00_axi_bready )
	,.S_AXI_ARADDR (s00_axi_araddr )
	,.S_AXI_ARPROT (s00_axi_arprot )
	,.S_AXI_ARVALID(s00_axi_arvalid)
	,.S_AXI_ARREADY(s00_axi_arready)
	,.S_AXI_RDATA  (s00_axi_rdata  )
	,.S_AXI_RRESP  (s00_axi_rresp  )
	,.S_AXI_RVALID (s00_axi_rvalid )
	,.S_AXI_RREADY (s00_axi_rready )
	);

   //-------------------------------------------------------------------------------- 
   // USER MODIFY -- Configure your accelerator interface by wiring these signals to
   //                your accelerator.
   //--------------------------------------------------------------------------------
   //
   // BEGIN logic is replaced with connections to the accelerator core
   // as a stand-in, we loopback the ps to pl fifos to the pl to ps fifos,
   // adding the outputs of a pair of ps to pl fifos to generate the value
   // inserted into a pl to ps fifo.

   for (k=0; k < num_fifo_pl_to_ps_lp; k++)
     begin: rof4
	assign pl_to_ps_fifo_data_li [k] = ps_to_pl_fifo_data_lo[k*2] + ps_to_pl_fifo_data_lo [k*2+1];
	assign pl_to_ps_fifo_v_li    [k] = ps_to_pl_fifo_v_lo   [k*2] & ps_to_pl_fifo_v_lo    [k*2+1];
	
	assign ps_to_pl_fifo_yumi_li[k*2]   = pl_to_ps_fifo_v_li[k] & pl_to_ps_fifo_ready_lo[k];
	assign ps_to_pl_fifo_yumi_li[k*2+1] = pl_to_ps_fifo_v_li[k] & pl_to_ps_fifo_ready_lo[k];
     end

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
