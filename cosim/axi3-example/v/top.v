
    module top #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line


        // Parameters of Axi Slave Bus Interface S00_AXI
        parameter integer C_GP0_AXI_ID_WIDTH    = 1,
        parameter integer C_GP0_AXI_DATA_WIDTH    = 32,
        parameter integer C_GP0_AXI_ADDR_WIDTH    = 9,
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
        input wire [1 : 0] gp0_axi_awburst,
        input wire [2 : 0] gp0_axi_awprot,
        input wire  gp0_axi_awvalid,
        output wire  gp0_axi_awready,
        input wire [C_GP0_AXI_DATA_WIDTH-1 : 0] gp0_axi_wdata,
        input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp0_axi_wstrb,
        input wire  gp0_axi_wlast,
        input wire  gp0_axi_wvalid,
        output wire  gp0_axi_wready,
        output wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_bid,
        output wire [1 : 0] gp0_axi_bresp,
        output wire  gp0_axi_bvalid,
        input wire  gp0_axi_bready,
        input wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_arid,
        input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0] gp0_axi_araddr,
        input wire [3 : 0] gp0_axi_arlen,
        input wire [1 : 0] gp0_axi_arburst,
        input wire [2 : 0] gp0_axi_arprot,
        input wire  gp0_axi_arvalid,
        output wire  gp0_axi_arready,
        output wire [C_GP0_AXI_ID_WIDTH-1 : 0] gp0_axi_rid,
        output wire [C_GP0_AXI_DATA_WIDTH-1 : 0] gp0_axi_rdata,
        output wire [1 : 0] gp0_axi_rresp,
        output wire  gp0_axi_rlast,
        output wire  gp0_axi_rvalid,
        input wire  gp0_axi_rready
    );
// Instantiation of Axi Bus Interface S00_AXI
    top_zynq # (
        .C_GP0_AXI_ID_WIDTH(C_GP0_AXI_ID_WIDTH),
        .C_GP0_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH),
        .C_GP0_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH),
        .C_GP0_AXI_PROTOCOL(C_GP0_AXI_PROTOCOL)
    ) axi3speed_v1_0_S00_AXI_inst (
        .S_AXI_ACLK(gp0_axi_aclk),
        .S_AXI_ARESETN(gp0_axi_aresetn),
        .S_AXI_AWID(gp0_axi_awid),
        .S_AXI_AWADDR(gp0_axi_awaddr),
        .S_AXI_AWLEN(gp0_axi_awlen),
        .S_AXI_AWBURST(gp0_axi_awburst),
        .S_AXI_AWVALID(gp0_axi_awvalid),
        .S_AXI_AWREADY(gp0_axi_awready),
        .S_AXI_WDATA(gp0_axi_wdata),
        .S_AXI_WSTRB(gp0_axi_wstrb),
        .S_AXI_WLAST(gp0_axi_wlast),
        .S_AXI_WVALID(gp0_axi_wvalid),
        .S_AXI_WREADY(gp0_axi_wready),
        .S_AXI_BID(gp0_axi_bid),
        .S_AXI_BRESP(gp0_axi_bresp),
        .S_AXI_BVALID(gp0_axi_bvalid),
        .S_AXI_BREADY(gp0_axi_bready),
        .S_AXI_ARID(gp0_axi_arid),
        .S_AXI_ARADDR(gp0_axi_araddr),
        .S_AXI_ARLEN(gp0_axi_arlen),
        .S_AXI_ARBURST(gp0_axi_arburst),
        .S_AXI_ARVALID(gp0_axi_arvalid),
        .S_AXI_ARREADY(gp0_axi_arready),
        .S_AXI_RID(gp0_axi_rid),
        .S_AXI_RDATA(gp0_axi_rdata),
        .S_AXI_RRESP(gp0_axi_rresp),
        .S_AXI_RLAST(gp0_axi_rlast),
        .S_AXI_RVALID(gp0_axi_rvalid),
        .S_AXI_RREADY(gp0_axi_rready)
    );

    // Add user logic here

    // User logic ends

    endmodule
