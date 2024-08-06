
module top_zynq
 #(// Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_GP0_AXI_DATA_WIDTH     = 32

   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_GP0_AXI_ADDR_WIDTH   = 10
   )
  (input                                         aclk
   , input                                       aresetn

   , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
   , input wire [2 : 0]                          s00_axi_awprot
   , input wire                                  s00_axi_awvalid
   , output wire                                 s00_axi_awready
   , input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
   , input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
   , input wire                                  s00_axi_wvalid
   , output wire                                 s00_axi_wready
   , output wire [1 : 0]                         s00_axi_bresp
   , output wire                                 s00_axi_bvalid
   , input wire                                  s00_axi_bready
   , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
   , input wire [2 : 0]                          s00_axi_arprot
   , input wire                                  s00_axi_arvalid
   , output wire                                 s00_axi_arready
   , output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
   , output wire [1 : 0]                         s00_axi_rresp
   , output wire                                 s00_axi_rvalid
   , input wire                                  s00_axi_rready
   );

  // Instantiation of Axi Bus Interface S00_AXI
  example_axi_v1_0_S00_AXI
   #(.C_S_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH)
     ,.C_S_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
     )
   example_axi_v1_0_S00_AXI_inst
    (.S_AXI_ACLK(aclk)
     ,.S_AXI_ARESETN(aresetn)
     ,.S_AXI_AWADDR(s00_axi_awaddr)
     ,.S_AXI_AWPROT(s00_axi_awprot)
     ,.S_AXI_AWVALID(s00_axi_awvalid)
     ,.S_AXI_AWREADY(s00_axi_awready)
     ,.S_AXI_WDATA(s00_axi_wdata)
     ,.S_AXI_WSTRB(s00_axi_wstrb)
     ,.S_AXI_WVALID(s00_axi_wvalid)
     ,.S_AXI_WREADY(s00_axi_wready)
     ,.S_AXI_BRESP(s00_axi_bresp)
     ,.S_AXI_BVALID(s00_axi_bvalid)
     ,.S_AXI_BREADY(s00_axi_bready)
     ,.S_AXI_ARADDR(s00_axi_araddr)
     ,.S_AXI_ARPROT(s00_axi_arprot)
     ,.S_AXI_ARVALID(s00_axi_arvalid)
     ,.S_AXI_ARREADY(s00_axi_arready)
     ,.S_AXI_RDATA(s00_axi_rdata)
     ,.S_AXI_RRESP(s00_axi_rresp)
     ,.S_AXI_RVALID(s00_axi_rvalid)
     ,.S_AXI_RREADY(s00_axi_rready)
     );

endmodule

