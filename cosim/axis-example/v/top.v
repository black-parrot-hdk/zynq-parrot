
`timescale 1 ps / 1 ps
`include "bsg_zynq_pl.vh"

    module top #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line

        parameter integer C_GP0_AXI_DATA_WIDTH    = 32,
        parameter integer C_GP0_AXI_ADDR_WIDTH    = 6,
        parameter integer C_SP0_AXI_DATA_WIDTH    = 32,
        parameter integer C_MP0_AXI_DATA_WIDTH    = 32,

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

        input wire [C_GP0_AXI_ADDR_WIDTH-1:0] gp0_axi_awaddr,
        input wire [2:0] gp0_axi_awprot,
        input wire  gp0_axi_awvalid,
        output wire  gp0_axi_awready,
        input wire [C_GP0_AXI_DATA_WIDTH-1:0] gp0_axi_wdata,
        input wire [(C_GP0_AXI_DATA_WIDTH/8)-1:0] gp0_axi_wstrb,
        input wire  gp0_axi_wvalid,
        output wire  gp0_axi_wready,
        output wire [1:0] gp0_axi_bresp,
        output wire  gp0_axi_bvalid,
        input wire  gp0_axi_bready,
        input wire [C_GP0_AXI_ADDR_WIDTH-1:0] gp0_axi_araddr,
        input wire [2:0] gp0_axi_arprot,
        input wire  gp0_axi_arvalid,
        output wire  gp0_axi_arready,
        output wire [C_GP0_AXI_DATA_WIDTH-1:0] gp0_axi_rdata,
        output wire [1:0] gp0_axi_rresp,
        output wire  gp0_axi_rvalid,
        input wire  gp0_axi_rready,

        input wire [C_SP0_AXI_DATA_WIDTH-1:0] sp0_axi_tdata,
        input wire sp0_axi_tvalid,
        input wire [(C_SP0_AXI_DATA_WIDTH/8)-1:0] sp0_axi_tkeep,
        input wire sp0_axi_tlast,
        output wire sp0_axi_tready,

        output wire [C_MP0_AXI_DATA_WIDTH-1:0] mp0_axi_tdata,
        output wire mp0_axi_tvalid,
        output wire [(C_MP0_AXI_DATA_WIDTH/8)-1:0] mp0_axi_tkeep,
        output wire mp0_axi_tlast,
        input wire mp0_axi_tready
    );

    top_zynq
     #(.C_SP0_AXI_DATA_WIDTH(C_SP0_AXI_DATA_WIDTH)
       ,.C_MP0_AXI_DATA_WIDTH(C_MP0_AXI_DATA_WIDTH)
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

       ,.sp0_axi_tdata(sp0_axi_tdata)
       ,.sp0_axi_tvalid(sp0_axi_tvalid)
       ,.sp0_axi_tkeep(sp0_axi_tkeep)
       ,.sp0_axi_tlast(sp0_axi_tlast)
       ,.sp0_axi_tready(sp0_axi_tready)

       ,.mp0_axi_tdata(mp0_axi_tdata)
       ,.mp0_axi_tvalid(mp0_axi_tvalid)
       ,.mp0_axi_tkeep(mp0_axi_tkeep)
       ,.mp0_axi_tlast(mp0_axi_tlast)
       ,.mp0_axi_tready(mp0_axi_tready)
       );

endmodule

