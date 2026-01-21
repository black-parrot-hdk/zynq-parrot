
    module top #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line

        // Parameters of Axi Slave Bus Interface S00_AXI
        parameter integer C_HP1_AXI_DATA_WIDTH    = 32,
        parameter integer C_HP1_AXI_ADDR_WIDTH    = 6,

        // Used for placeholder
        parameter integer __DUMMY = 0
    )
    (
        // Users to add ports here

        // User ports ends
        // Do not modify the ports beyond this line

        // Ports of Axi Slave Bus Interface S00_AXI
        input wire  aclk,
        input wire  aresetn

   , output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]     hp1_axi_awaddr
   , output wire [2 : 0]                          hp1_axi_awprot
   , output wire                                  hp1_axi_awvalid
   , input wire                                 hp1_axi_awready
   , output wire [C_HP1_AXI_DATA_WIDTH-1 : 0]     hp1_axi_wdata
   , output wire [(C_HP1_AXI_DATA_WIDTH/8)-1 : 0] hp1_axi_wstrb
   , output wire                                  hp1_axi_wvalid
   , input wire                                 hp1_axi_wready
   , input wire [1 : 0]                         hp1_axi_bresp
   , input wire                                 hp1_axi_bvalid
   , output wire                                  hp1_axi_bready
   , output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]     hp1_axi_araddr
   , output wire [2 : 0]                          hp1_axi_arprot
   , output wire                                  hp1_axi_arvalid
   , input wire                                 hp1_axi_arready
   , input wire [C_HP1_AXI_DATA_WIDTH-1 : 0]    hp1_axi_rdata
   , input wire [1 : 0]                         hp1_axi_rresp
   , input wire                                 hp1_axi_rvalid
   , output wire                                  hp1_axi_rready

   , input                                       intc0
   );

    top_zynq
     #(.C_HP1_AXI_DATA_WIDTH(C_HP1_AXI_DATA_WIDTH)
       ,.C_HP1_AXI_ADDR_WIDTH(C_HP1_AXI_ADDR_WIDTH)
       )
     top_zynq
      (.aclk(aclk)
       ,.aresetn(aresetn)

       ,.hp1_axi_awaddr(hp1_axi_awaddr)
       ,.hp1_axi_awprot(hp1_axi_awprot)
       ,.hp1_axi_awvalid(hp1_axi_awvalid)
       ,.hp1_axi_awready(hp1_axi_awready)

       ,.hp1_axi_wdata(hp1_axi_wdata)
       ,.hp1_axi_wstrb(hp1_axi_wstrb)
       ,.hp1_axi_wvalid(hp1_axi_wvalid)
       ,.hp1_axi_wready(hp1_axi_wready)

       ,.hp1_axi_bresp(hp1_axi_bresp)
       ,.hp1_axi_bvalid(hp1_axi_bvalid)
       ,.hp1_axi_bready(hp1_axi_bready)

       ,.hp1_axi_araddr(hp1_axi_araddr)
       ,.hp1_axi_arprot(hp1_axi_arprot)
       ,.hp1_axi_arvalid(hp1_axi_arvalid)
       ,.hp1_axi_arready(hp1_axi_arready)

       ,.hp1_axi_rdata(hp1_axi_rdata)
       ,.hp1_axi_rresp(hp1_axi_rresp)
       ,.hp1_axi_rvalid(hp1_axi_rvalid)
       ,.hp1_axi_rready(hp1_axi_rready)

       ,.intc0(intc0)
       );

endmodule

