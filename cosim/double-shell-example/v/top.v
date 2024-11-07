
module top #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_GP0_AXI_DATA_WIDTH = 32,
   parameter integer C_GP0_AXI_ADDR_WIDTH = 5,

   parameter integer C_GP1_AXI_DATA_WIDTH = 32,
   parameter integer C_GP1_AXI_ADDR_WIDTH = 5,
   parameter integer __DUMMY = 0
   )
   (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line
    input wire                                  aclk,
    input wire                                  aresetn,
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_awaddr,
    input wire [2 : 0]                          gp0_axi_awprot,
    input wire                                  gp0_axi_awvalid,
    output wire                                 gp0_axi_awready,
    input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     gp0_axi_wdata,
    input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp0_axi_wstrb,
    input wire                                  gp0_axi_wvalid,
    output wire                                 gp0_axi_wready,
    output wire [1 : 0]                         gp0_axi_bresp,
    output wire                                 gp0_axi_bvalid,
    input wire                                  gp0_axi_bready,
    input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_araddr,
    input wire [2 : 0]                          gp0_axi_arprot,
    input wire                                  gp0_axi_arvalid,
    output wire                                 gp0_axi_arready,
    output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    gp0_axi_rdata,
    output wire [1 : 0]                         gp0_axi_rresp,
    output wire                                 gp0_axi_rvalid,
    input wire                                  gp0_axi_rready,

    // Ports of Axi Slave Bus Interface S01_AXI
    input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_awaddr,
    input wire [2 : 0]                          gp1_axi_awprot,
    input wire                                  gp1_axi_awvalid,
    output wire                                 gp1_axi_awready,
    input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     gp1_axi_wdata,
    input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp1_axi_wstrb,
    input wire                                  gp1_axi_wvalid,
    output wire                                 gp1_axi_wready,
    output wire [1 : 0]                         gp1_axi_bresp,
    output wire                                 gp1_axi_bvalid,
    input wire                                  gp1_axi_bready,
    input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_araddr,
    input wire [2 : 0]                          gp1_axi_arprot,
    input wire                                  gp1_axi_arvalid,
    output wire                                 gp1_axi_arready,
    output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    gp1_axi_rdata,
    output wire [1 : 0]                         gp1_axi_rresp,
    output wire                                 gp1_axi_rvalid,
    input wire                                  gp1_axi_rready
    );

    top_zynq
     #(.C_GP0_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH)
       ,.C_GP0_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
       )
     top_zynq
      (.aclk(aclk)
       ,.aresetn(aresetn)

       ,.gp0_axi_awaddr(gp0_axi_awaddr)
       ,.gp0_axi_awprot(gp0_axi_awprot)
       ,.gp0_axi_awvalid(gp0_axi_awvalid)
       ,.gp0_axi_awready(gp0_axi_awready)

       ,.gp0_axi_wdata(gp0_axi_wdata)
       ,.gp0_axi_wstrb(gp0_axi_wstrb)
       ,.gp0_axi_wvalid(gp0_axi_wvalid)
       ,.gp0_axi_wready(gp0_axi_wready)

       ,.gp0_axi_bresp(gp0_axi_bresp)
       ,.gp0_axi_bvalid(gp0_axi_bvalid)
       ,.gp0_axi_bready(gp0_axi_bready)

       ,.gp0_axi_araddr(gp0_axi_araddr)
       ,.gp0_axi_arprot(gp0_axi_arprot)
       ,.gp0_axi_arvalid(gp0_axi_arvalid)
       ,.gp0_axi_arready(gp0_axi_arready)

       ,.gp0_axi_rdata(gp0_axi_rdata)
       ,.gp0_axi_rresp(gp0_axi_rresp)
       ,.gp0_axi_rvalid(gp0_axi_rvalid)
       ,.gp0_axi_rready(gp0_axi_rready)

       ,.gp1_axi_awaddr(gp1_axi_awaddr)
       ,.gp1_axi_awprot(gp1_axi_awprot)
       ,.gp1_axi_awvalid(gp1_axi_awvalid)
       ,.gp1_axi_awready(gp1_axi_awready)

       ,.gp1_axi_wdata(gp1_axi_wdata)
       ,.gp1_axi_wstrb(gp1_axi_wstrb)
       ,.gp1_axi_wvalid(gp1_axi_wvalid)
       ,.gp1_axi_wready(gp1_axi_wready)

       ,.gp1_axi_bresp(gp1_axi_bresp)
       ,.gp1_axi_bvalid(gp1_axi_bvalid)
       ,.gp1_axi_bready(gp1_axi_bready)

       ,.gp1_axi_araddr(gp1_axi_araddr)
       ,.gp1_axi_arprot(gp1_axi_arprot)
       ,.gp1_axi_arvalid(gp1_axi_arvalid)
       ,.gp1_axi_arready(gp1_axi_arready)

       ,.gp1_axi_rdata(gp1_axi_rdata)
       ,.gp1_axi_rresp(gp1_axi_rresp)
       ,.gp1_axi_rvalid(gp1_axi_rvalid)
       ,.gp1_axi_rready(gp1_axi_rready)
       );

endmodule

