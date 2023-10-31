
`timescale 1 ps / 1 ps
`include "bp_zynq_pl.vh"

    module top #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line

        // Parameters of Axi Slave Bus Interface S00_AXI
        parameter integer C_S00_AXI_DATA_WIDTH    = 32,
        parameter integer C_S00_AXI_ADDR_WIDTH    = 4,

        // Used for placeholder
        parameter integer __DUMMY = 0
    )
    (
        // Users to add ports here

        // User ports ends
        // Do not modify the ports beyond this line

        // Ports of Axi Slave Bus Interface S00_AXI
        input wire  aclk,
        input wire  aresetn,

        input wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr,
        input wire [2:0] s00_axi_awprot,
        input wire  s00_axi_awvalid,
        output wire  s00_axi_awready,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata,
        input wire [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb,
        input wire  s00_axi_wvalid,
        output wire  s00_axi_wready,
        output wire [1:0] s00_axi_bresp,
        output wire  s00_axi_bvalid,
        input wire  s00_axi_bready,
        input wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr,
        input wire [2:0] s00_axi_arprot,
        input wire  s00_axi_arvalid,
        output wire  s00_axi_arready,
        output wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata,
        output wire [1:0] s00_axi_rresp,
        output wire  s00_axi_rvalid,
        input wire  s00_axi_rready
    );

    top_zynq
     #(.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
       )
     top_zynq
      (.aclk(aclk)
       ,.aresetn(aresetn)

       ,.s00_axi_awaddr(s00_axi_awaddr)
       ,.s00_axi_awprot(s00_axi_awprot)
       ,.s00_axi_awvalid(s00_axi_awvalid)
       ,.s00_axi_awready(s00_axi_awready)

       ,.s00_axi_wdata(s00_axi_wdata)
       ,.s00_axi_wstrb(s00_axi_wstrb)
       ,.s00_axi_wvalid(s00_axi_wvalid)
       ,.s00_axi_wready(s00_axi_wready)

       ,.s00_axi_bresp(s00_axi_bresp)
       ,.s00_axi_bvalid(s00_axi_bvalid)
       ,.s00_axi_bready(s00_axi_bready)

       ,.s00_axi_araddr(s00_axi_araddr)
       ,.s00_axi_arprot(s00_axi_arprot)
       ,.s00_axi_arvalid(s00_axi_arvalid)
       ,.s00_axi_arready(s00_axi_arready)

       ,.s00_axi_rdata(s00_axi_rdata)
       ,.s00_axi_rresp(s00_axi_rresp)
       ,.s00_axi_rvalid(s00_axi_rvalid)
       ,.s00_axi_rready(s00_axi_rready)
       );

endmodule

