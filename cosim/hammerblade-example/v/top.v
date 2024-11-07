
module top
  #(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_GP0_AXI_DATA_WIDTH = 32
    , parameter integer C_GP0_AXI_ADDR_WIDTH = 10
    , parameter integer C_GP1_AXI_DATA_WIDTH = 32
    , parameter integer C_GP1_AXI_ADDR_WIDTH = 30
    , parameter integer C_HP0_AXI_DATA_WIDTH = 32
    , parameter integer C_HP0_AXI_ADDR_WIDTH = 32
    , parameter integer C_HP1_AXI_DATA_WIDTH = 32
    , parameter integer C_HP1_AXI_ADDR_WIDTH = 32
    , parameter integer __DUMMY = 0
    )
   (
    input wire                                   aclk
    ,input wire                                  aresetn
    ,input wire                                  rt_clk

    ,input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_awaddr
    ,input wire [2 : 0]                          gp0_axi_awprot
    ,input wire                                  gp0_axi_awvalid
    ,output wire                                 gp0_axi_awready
    ,input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     gp0_axi_wdata
    ,input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp0_axi_wstrb
    ,input wire                                  gp0_axi_wvalid
    ,output wire                                 gp0_axi_wready
    ,output wire [1 : 0]                         gp0_axi_bresp
    ,output wire                                 gp0_axi_bvalid
    ,input wire                                  gp0_axi_bready
    ,input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_araddr
    ,input wire [2 : 0]                          gp0_axi_arprot
    ,input wire                                  gp0_axi_arvalid
    ,output wire                                 gp0_axi_arready
    ,output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    gp0_axi_rdata
    ,output wire [1 : 0]                         gp0_axi_rresp
    ,output wire                                 gp0_axi_rvalid
    ,input wire                                  gp0_axi_rready

    ,input wire [C_GP1_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_awaddr
    ,input wire [2 : 0]                          gp1_axi_awprot
    ,input wire                                  gp1_axi_awvalid
    ,output wire                                 gp1_axi_awready
    ,input wire [C_GP1_AXI_DATA_WIDTH-1 : 0]     gp1_axi_wdata
    ,input wire [(C_GP1_AXI_DATA_WIDTH/8)-1 : 0] gp1_axi_wstrb
    ,input wire                                  gp1_axi_wvalid
    ,output wire                                 gp1_axi_wready
    ,output wire [1 : 0]                         gp1_axi_bresp
    ,output wire                                 gp1_axi_bvalid
    ,input wire                                  gp1_axi_bready
    ,input wire [C_GP1_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_araddr
    ,input wire [2 : 0]                          gp1_axi_arprot
    ,input wire                                  gp1_axi_arvalid
    ,output wire                                 gp1_axi_arready
    ,output wire [C_GP1_AXI_DATA_WIDTH-1 : 0]    gp1_axi_rdata
    ,output wire [1 : 0]                         gp1_axi_rresp
    ,output wire                                 gp1_axi_rvalid
    ,input wire                                  gp1_axi_rready

    ,output wire [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_awaddr
    ,output wire                                 hp0_axi_awvalid
    ,input wire                                  hp0_axi_awready
    ,output wire [5:0]                           hp0_axi_awid
    ,output wire                                 hp0_axi_awlock
    ,output wire [3:0]                           hp0_axi_awcache
    ,output wire [2:0]                           hp0_axi_awprot
    ,output wire [7:0]                           hp0_axi_awlen
    ,output wire [2:0]                           hp0_axi_awsize
    ,output wire [1:0]                           hp0_axi_awburst
    ,output wire [3:0]                           hp0_axi_awqos

    ,output wire [C_HP0_AXI_DATA_WIDTH-1:0]      hp0_axi_wdata
    ,output wire                                 hp0_axi_wvalid
    ,input wire                                  hp0_axi_wready
    ,output wire [5:0]                           hp0_axi_wid
    ,output wire                                 hp0_axi_wlast
    ,output wire [(C_HP0_AXI_DATA_WIDTH/8)-1:0]  hp0_axi_wstrb

    ,input wire                                  hp0_axi_bvalid
    ,output wire                                 hp0_axi_bready
    ,input wire [5:0]                            hp0_axi_bid
    ,input wire [1:0]                            hp0_axi_bresp

    ,output wire [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_araddr
    ,output wire                                 hp0_axi_arvalid
    ,input wire                                  hp0_axi_arready
    ,output wire [5:0]                           hp0_axi_arid
    ,output wire                                 hp0_axi_arlock
    ,output wire [3:0]                           hp0_axi_arcache
    ,output wire [2:0]                           hp0_axi_arprot
    ,output wire [7:0]                           hp0_axi_arlen
    ,output wire [2:0]                           hp0_axi_arsize
    ,output wire [1:0]                           hp0_axi_arburst
    ,output wire [3:0]                           hp0_axi_arqos

    ,input wire [C_HP0_AXI_DATA_WIDTH-1:0]       hp0_axi_rdata
    ,input wire                                  hp0_axi_rvalid
    ,output wire                                 hp0_axi_rready
    ,input wire [5:0]                            hp0_axi_rid
    ,input wire                                  hp0_axi_rlast
    ,input wire [1:0]                            hp0_axi_rresp

    ,output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]    hp1_axi_awaddr
    ,output wire [2 : 0]                         hp1_axi_awprot
    ,output wire                                 hp1_axi_awvalid
    ,input wire                                  hp1_axi_awready
    ,output wire [C_HP1_AXI_DATA_WIDTH-1 : 0]    hp1_axi_wdata
    ,output wire [(C_HP1_AXI_DATA_WIDTH/8)-1:0]  hp1_axi_wstrb
    ,output wire                                 hp1_axi_wvalid
    ,input wire                                  hp1_axi_wready
    ,input wire [1 : 0]                          hp1_axi_bresp
    ,input wire                                  hp1_axi_bvalid
    ,output wire                                 hp1_axi_bready
    ,output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]    hp1_axi_araddr
    ,output wire [2 : 0]                         hp1_axi_arprot
    ,output wire                                 hp1_axi_arvalid
    ,input wire                                  hp1_axi_arready
    ,input wire [C_HP1_AXI_DATA_WIDTH-1 : 0]     hp1_axi_rdata
    ,input wire [1 : 0]                          hp1_axi_rresp
    ,input wire                                  hp1_axi_rvalid
    ,output wire                                 hp1_axi_rready
    );

   top_zynq #
     (.C_GP0_AXI_DATA_WIDTH (C_GP0_AXI_DATA_WIDTH)
      ,.C_GP0_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
      ,.C_GP1_AXI_DATA_WIDTH(C_GP1_AXI_DATA_WIDTH)
      ,.C_GP1_AXI_ADDR_WIDTH(C_GP1_AXI_ADDR_WIDTH)
      ,.C_HP0_AXI_DATA_WIDTH(C_HP0_AXI_DATA_WIDTH)
      ,.C_HP0_AXI_ADDR_WIDTH(C_HP0_AXI_ADDR_WIDTH)
      ,.C_HP1_AXI_DATA_WIDTH(C_HP1_AXI_DATA_WIDTH)
      ,.C_HP1_AXI_ADDR_WIDTH(C_HP1_AXI_ADDR_WIDTH)
      )
     top_fpga_inst
     ( .aclk           (aclk)
      ,.aresetn        (aresetn)
      ,.rt_clk         (rt_clk)
      ,.gp0_axi_awaddr (gp0_axi_awaddr)
      ,.gp0_axi_awprot (gp0_axi_awprot)
      ,.gp0_axi_awvalid(gp0_axi_awvalid)
      ,.gp0_axi_awready(gp0_axi_awready)
      ,.gp0_axi_wdata  (gp0_axi_wdata)
      ,.gp0_axi_wstrb  (gp0_axi_wstrb)
      ,.gp0_axi_wvalid (gp0_axi_wvalid)
      ,.gp0_axi_wready (gp0_axi_wready)
      ,.gp0_axi_bresp  (gp0_axi_bresp)
      ,.gp0_axi_bvalid (gp0_axi_bvalid)
      ,.gp0_axi_bready (gp0_axi_bready)
      ,.gp0_axi_araddr (gp0_axi_araddr)
      ,.gp0_axi_arprot (gp0_axi_arprot)
      ,.gp0_axi_arvalid(gp0_axi_arvalid)
      ,.gp0_axi_arready(gp0_axi_arready)
      ,.gp0_axi_rdata  (gp0_axi_rdata)
      ,.gp0_axi_rresp  (gp0_axi_rresp)
      ,.gp0_axi_rvalid (gp0_axi_rvalid)
      ,.gp0_axi_rready (gp0_axi_rready)

      ,.gp1_axi_awaddr (gp1_axi_awaddr)
      ,.gp1_axi_awprot (gp1_axi_awprot)
      ,.gp1_axi_awvalid(gp1_axi_awvalid)
      ,.gp1_axi_awready(gp1_axi_awready)
      ,.gp1_axi_wdata  (gp1_axi_wdata)
      ,.gp1_axi_wstrb  (gp1_axi_wstrb)
      ,.gp1_axi_wvalid (gp1_axi_wvalid)
      ,.gp1_axi_wready (gp1_axi_wready)
      ,.gp1_axi_bresp  (gp1_axi_bresp)
      ,.gp1_axi_bvalid (gp1_axi_bvalid)
      ,.gp1_axi_bready (gp1_axi_bready)
      ,.gp1_axi_araddr (gp1_axi_araddr)
      ,.gp1_axi_arprot (gp1_axi_arprot)
      ,.gp1_axi_arvalid(gp1_axi_arvalid)
      ,.gp1_axi_arready(gp1_axi_arready)
      ,.gp1_axi_rdata  (gp1_axi_rdata)
      ,.gp1_axi_rresp  (gp1_axi_rresp)
      ,.gp1_axi_rvalid (gp1_axi_rvalid)
      ,.gp1_axi_rready (gp1_axi_rready)

      ,.hp0_axi_awaddr (hp0_axi_awaddr)
      ,.hp0_axi_awvalid(hp0_axi_awvalid)
      ,.hp0_axi_awready(hp0_axi_awready)
      ,.hp0_axi_awid   (hp0_axi_awid)
      ,.hp0_axi_awlock (hp0_axi_awlock)
      ,.hp0_axi_awcache(hp0_axi_awcache)
      ,.hp0_axi_awprot (hp0_axi_awprot)
      ,.hp0_axi_awlen  (hp0_axi_awlen)
      ,.hp0_axi_awsize (hp0_axi_awsize)
      ,.hp0_axi_awburst(hp0_axi_awburst)
      ,.hp0_axi_awqos  (hp0_axi_awqos)

      ,.hp0_axi_wdata  (hp0_axi_wdata)
      ,.hp0_axi_wvalid (hp0_axi_wvalid)
      ,.hp0_axi_wready (hp0_axi_wready)
      ,.hp0_axi_wid    (hp0_axi_wid)
      ,.hp0_axi_wlast  (hp0_axi_wlast)
      ,.hp0_axi_wstrb  (hp0_axi_wstrb)

      ,.hp0_axi_bvalid (hp0_axi_bvalid)
      ,.hp0_axi_bready (hp0_axi_bready)
      ,.hp0_axi_bid    (hp0_axi_bid)
      ,.hp0_axi_bresp  (hp0_axi_bresp)

      ,.hp0_axi_araddr (hp0_axi_araddr)
      ,.hp0_axi_arvalid(hp0_axi_arvalid)
      ,.hp0_axi_arready(hp0_axi_arready)
      ,.hp0_axi_arid   (hp0_axi_arid)
      ,.hp0_axi_arlock (hp0_axi_arlock)
      ,.hp0_axi_arcache(hp0_axi_arcache)
      ,.hp0_axi_arprot (hp0_axi_arprot)
      ,.hp0_axi_arlen  (hp0_axi_arlen)
      ,.hp0_axi_arsize (hp0_axi_arsize)
      ,.hp0_axi_arburst(hp0_axi_arburst)
      ,.hp0_axi_arqos  (hp0_axi_arqos)

      ,.hp0_axi_rdata  (hp0_axi_rdata)
      ,.hp0_axi_rvalid (hp0_axi_rvalid)
      ,.hp0_axi_rready (hp0_axi_rready)
      ,.hp0_axi_rid    (hp0_axi_rid)
      ,.hp0_axi_rlast  (hp0_axi_rlast)
      ,.hp0_axi_rresp  (hp0_axi_rresp)

      ,.hp1_axi_awaddr (hp1_axi_awaddr)
      ,.hp1_axi_awprot (hp1_axi_awprot)
      ,.hp1_axi_awvalid(hp1_axi_awvalid)
      ,.hp1_axi_awready(hp1_axi_awready)
      ,.hp1_axi_wdata  (hp1_axi_wdata)
      ,.hp1_axi_wstrb  (hp1_axi_wstrb)
      ,.hp1_axi_wvalid (hp1_axi_wvalid)
      ,.hp1_axi_wready (hp1_axi_wready)
      ,.hp1_axi_bresp  (hp1_axi_bresp)
      ,.hp1_axi_bvalid (hp1_axi_bvalid)
      ,.hp1_axi_bready (hp1_axi_bready)
      ,.hp1_axi_araddr (hp1_axi_araddr)
      ,.hp1_axi_arprot (hp1_axi_arprot)
      ,.hp1_axi_arvalid(hp1_axi_arvalid)
      ,.hp1_axi_arready(hp1_axi_arready)
      ,.hp1_axi_rdata  (hp1_axi_rdata)
      ,.hp1_axi_rresp  (hp1_axi_rresp)
      ,.hp1_axi_rvalid (hp1_axi_rvalid)
      ,.hp1_axi_rready (hp1_axi_rready)
      );

 endmodule

