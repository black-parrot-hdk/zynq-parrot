
    module top #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line


        // Parameters of Axi Slave Bus Interface S00_AXI
        parameter integer C_GP0_AXI_ID_WIDTH    = 12,
        parameter integer C_GP0_AXI_DATA_WIDTH    = 32,
        parameter integer C_GP0_AXI_ADDR_WIDTH    = 9,
        parameter integer C_GP0_AXI_AWUSER_WIDTH    = 0,
        parameter integer C_GP0_AXI_ARUSER_WIDTH    = 0,
        parameter integer C_GP0_AXI_WUSER_WIDTH    = 0,
        parameter integer C_GP0_AXI_RUSER_WIDTH    = 0,
        parameter integer C_GP0_AXI_BUSER_WIDTH    = 0,
        parameter integer C_GP0_AXI_PROTOCOL="AXI3"
    )
    (
        // Users to add ports here

        // User ports ends
        // Do not modify the ports beyond this line


        // Ports of Axi Slave Bus Interface S00_AXI
        input wire  gp0_axi_aclk,
        input wire  gp0_axi_aresetn,
        input wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_awid,
        input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0] gp0_axi_awaddr,
        input wire [3 : 0] gp0_axi_awlen,
        input wire [2 : 0] gp0_axi_awsize,
        input wire [1 : 0] gp0_axi_awburst,
        input wire  gp0_axi_awlock,
        input wire [3 : 0] gp0_axi_awcache,
        input wire [2 : 0] gp0_axi_awprot,
        input wire [3 : 0] gp0_axi_awqos,
        input wire [3 : 0] gp0_axi_awregion,
        input wire [C_GP0_AXI_AWUSER_WIDTH-1 : 0] gp0_axi_awuser,
        input wire  gp0_axi_awvalid,
        output wire  gp0_axi_awready,
        input wire [C_GP0_AXI_DATA_WIDTH-1 : 0] gp0_axi_wdata,
        input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp0_axi_wstrb,
        input wire  gp0_axi_wlast,
        input wire [C_GP0_AXI_WUSER_WIDTH-1 : 0] gp0_axi_wuser,
        input wire  gp0_axi_wvalid,
        output wire  gp0_axi_wready,
        output wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_bid,
        output wire [1 : 0] gp0_axi_bresp,
        output wire [C_GP0_AXI_BUSER_WIDTH-1 : 0] gp0_axi_buser,
        output wire  gp0_axi_bvalid,
        input wire  gp0_axi_bready,
        input wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_arid,
        input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0] gp0_axi_araddr,
        input wire [3 : 0] gp0_axi_arlen,
        input wire [2 : 0] gp0_axi_arsize,
        input wire [1 : 0] gp0_axi_arburst,
        input wire  gp0_axi_arlock,
        input wire [3 : 0] gp0_axi_arcache,
        input wire [2 : 0] gp0_axi_arprot,
        input wire [3 : 0] gp0_axi_arqos,
        input wire [3 : 0] gp0_axi_arregion,
        input wire [C_GP0_AXI_ARUSER_WIDTH-1 : 0] gp0_axi_aruser,
        input wire  gp0_axi_arvalid,
        output wire  gp0_axi_arready,
        output wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_rid,
        output wire [C_GP0_AXI_DATA_WIDTH-1 : 0] gp0_axi_rdata,
        output wire [1 : 0] gp0_axi_rresp,
        output wire  gp0_axi_rlast,
        output wire [C_GP0_AXI_RUSER_WIDTH-1 : 0] gp0_axi_ruser,
        output wire  gp0_axi_rvalid,
        input wire  gp0_axi_rready
    );
// Instantiation of Axi Bus Interface S00_AXI
    top_zynq # (
        .C_GP0_AXI_ID_WIDTH(C_GP0_AXI_ID_WIDTH),
        .C_GP0_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH),
        .C_GP0_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH),
        .C_GP0_AXI_AWUSER_WIDTH(C_GP0_AXI_AWUSER_WIDTH),
        .C_GP0_AXI_ARUSER_WIDTH(C_GP0_AXI_ARUSER_WIDTH),
        .C_GP0_AXI_WUSER_WIDTH(C_GP0_AXI_WUSER_WIDTH),
        .C_GP0_AXI_RUSER_WIDTH(C_GP0_AXI_RUSER_WIDTH),
        .C_GP0_AXI_BUSER_WIDTH(C_GP0_AXI_BUSER_WIDTH),
        .C_GP0_AXI_PROTOCOL(C_GP0_AXI_PROTOCOL)
    ) axi3speed_v1_0_S00_AXI_inst (
        .S_AXI_ACLK(gp0_axi_aclk),
        .S_AXI_ARESETN(gp0_axi_aresetn),
        .S_AXI_AWID(gp0_axi_awid),
        .S_AXI_AWADDR(gp0_axi_awaddr),
        .S_AXI_AWLEN(gp0_axi_awlen),
        .S_AXI_AWSIZE(gp0_axi_awsize),
        .S_AXI_AWBURST(gp0_axi_awburst),
        .S_AXI_AWLOCK(gp0_axi_awlock),
        .S_AXI_AWCACHE(gp0_axi_awcache),
        .S_AXI_AWPROT(gp0_axi_awprot),
        .S_AXI_AWQOS(gp0_axi_awqos),
        .S_AXI_AWREGION(gp0_axi_awregion),
        .S_AXI_AWUSER(gp0_axi_awuser),
        .S_AXI_AWVALID(gp0_axi_awvalid),
        .S_AXI_AWREADY(gp0_axi_awready),
        .S_AXI_WDATA(gp0_axi_wdata),
        .S_AXI_WSTRB(gp0_axi_wstrb),
        .S_AXI_WLAST(gp0_axi_wlast),
        .S_AXI_WUSER(gp0_axi_wuser),
        .S_AXI_WVALID(gp0_axi_wvalid),
        .S_AXI_WREADY(gp0_axi_wready),
        .S_AXI_BID(gp0_axi_bid),
        .S_AXI_BRESP(gp0_axi_bresp),
        .S_AXI_BUSER(gp0_axi_buser),
        .S_AXI_BVALID(gp0_axi_bvalid),
        .S_AXI_BREADY(gp0_axi_bready),
        .S_AXI_ARID(gp0_axi_arid),
        .S_AXI_ARADDR(gp0_axi_araddr),
        .S_AXI_ARLEN(gp0_axi_arlen),
        .S_AXI_ARSIZE(gp0_axi_arsize),
        .S_AXI_ARBURST(gp0_axi_arburst),
        .S_AXI_ARLOCK(gp0_axi_arlock),
        .S_AXI_ARCACHE(gp0_axi_arcache),
        .S_AXI_ARPROT(gp0_axi_arprot),
        .S_AXI_ARQOS(gp0_axi_arqos),
        .S_AXI_ARREGION(gp0_axi_arregion),
        .S_AXI_ARUSER(gp0_axi_aruser),
        .S_AXI_ARVALID(gp0_axi_arvalid),
        .S_AXI_ARREADY(gp0_axi_arready),
        .S_AXI_RID(gp0_axi_rid),
        .S_AXI_RDATA(gp0_axi_rdata),
        .S_AXI_RRESP(gp0_axi_rresp),
        .S_AXI_RLAST(gp0_axi_rlast),
        .S_AXI_RUSER(gp0_axi_ruser),
        .S_AXI_RVALID(gp0_axi_rvalid),
        .S_AXI_RREADY(gp0_axi_rready)
    );

    // Add user logic here

    // User logic ends

    endmodule
