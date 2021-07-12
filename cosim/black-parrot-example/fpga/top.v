
`timescale 1 ns / 1 ps

module top
  #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH = 6
    , parameter integer C_S01_AXI_DATA_WIDTH = 32
    , parameter integer C_S01_AXI_ADDR_WIDTH = 30
    , parameter integer C_M00_AXI_DATA_WIDTH = 64
    , parameter integer C_M00_AXI_ADDR_WIDTH = 32
    )
   (
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire                                   s00_axi_aclk
    ,input wire                                  s00_axi_aresetn
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
    ,input wire [2 : 0]                          s00_axi_awprot
    ,input wire                                  s00_axi_awvalid
    ,output wire                                 s00_axi_awready
    ,input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
    ,input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
    ,input wire                                  s00_axi_wvalid
    ,output wire                                 s00_axi_wready
    ,output wire [1 : 0]                         s00_axi_bresp
    ,output wire                                 s00_axi_bvalid
    ,input wire                                  s00_axi_bready
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
    ,input wire [2 : 0]                          s00_axi_arprot
    ,input wire                                  s00_axi_arvalid
    ,output wire                                 s00_axi_arready
    ,output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
    ,output wire [1 : 0]                         s00_axi_rresp
    ,output wire                                 s00_axi_rvalid
    ,input wire                                  s00_axi_rready

    ,input wire                                  s01_axi_aclk
    ,input wire                                  s01_axi_aresetn
    ,input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_awaddr
    ,input wire [2 : 0]                          s01_axi_awprot
    ,input wire                                  s01_axi_awvalid
    ,output wire                                 s01_axi_awready
    ,input wire [C_S01_AXI_DATA_WIDTH-1 : 0]     s01_axi_wdata
    ,input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb
    ,input wire                                  s01_axi_wvalid
    ,output wire                                 s01_axi_wready
    ,output wire [1 : 0]                         s01_axi_bresp
    ,output wire                                 s01_axi_bvalid
    ,input wire                                  s01_axi_bready
    ,input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_araddr
    ,input wire [2 : 0]                          s01_axi_arprot
    ,input wire                                  s01_axi_arvalid
    ,output wire                                 s01_axi_arready
    ,output wire [C_S01_AXI_DATA_WIDTH-1 : 0]    s01_axi_rdata
    ,output wire [1 : 0]                         s01_axi_rresp
    ,output wire                                 s01_axi_rvalid
    ,input wire                                  s01_axi_rready

    ,input wire                             m00_axi_aclk
    ,input wire                             m00_axi_aresetn
    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0] m00_axi_awaddr
    ,output wire                            m00_axi_awvalid
    ,input wire                             m00_axi_awready
    ,output wire [5:0]                      m00_axi_awid
    ,output wire [1:0]                      m00_axi_awlock  // 1 bit bsg_cache_to_axi (AXI4); 2 bit (AXI3)
    ,output wire [3:0]                      m00_axi_awcache
    ,output wire [2:0]                      m00_axi_awprot
    ,output wire [3:0]                      m00_axi_awlen   // 8 bits bsg_cache_to_axi
    ,output wire [2:0]                      m00_axi_awsize
    ,output wire [1:0]                      m00_axi_awburst
    ,output wire [3:0]                      m00_axi_awqos

    ,output wire [C_M00_AXI_DATA_WIDTH-1:0]     m00_axi_wdata
    ,output wire                                m00_axi_wvalid
    ,input wire                                 m00_axi_wready
    ,output wire [5:0]                          m00_axi_wid
    ,output wire                                m00_axi_wlast
    ,output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0] m00_axi_wstrb

    ,input wire                                 m00_axi_bvalid
    ,output wire                                m00_axi_bready
    ,input wire [5:0]                           m00_axi_bid
    ,input wire [1:0]                           m00_axi_bresp

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]     m00_axi_araddr
    ,output wire                                m00_axi_arvalid
    ,input wire                                 m00_axi_arready
    ,output wire [5:0]                          m00_axi_arid
    ,output wire [1:0]                          m00_axi_arlock
    ,output wire [3:0]                          m00_axi_arcache
    ,output wire [2:0]                          m00_axi_arprot
    ,output wire [3:0]                          m00_axi_arlen
    ,output wire [2:0]                          m00_axi_arsize
    ,output wire [1:0]                          m00_axi_arburst
    ,output wire [3:0]                          m00_axi_arqos

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata
    ,input wire                                 m00_axi_rvalid
    ,output wire                                m00_axi_rready
    ,input wire [5:0]                           m00_axi_rid
    ,input wire                                 m00_axi_rlast
    ,input wire [1:0]                           m00_axi_rresp
    );

   top_zynq
     #(.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)

       ,.C_S01_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH)
       ,.C_S01_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH)

       ,.C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
       ,.C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH)
       )
     top_zynq_inst
     (.s00_axi_aclk    (s00_axi_aclk)
      ,.s00_axi_aresetn(s00_axi_aresetn)
      ,.s00_axi_awaddr (s00_axi_awaddr)
      ,.s00_axi_awprot (s00_axi_awprot)
      ,.s00_axi_awvalid(s00_axi_awvalid)
      ,.s00_axi_awready(s00_axi_awready)
      ,.s00_axi_wdata  (s00_axi_wdata)
      ,.s00_axi_wstrb  (s00_axi_wstrb)
      ,.s00_axi_wvalid (s00_axi_wvalid)
      ,.s00_axi_wready (s00_axi_wready)
      ,.s00_axi_bresp  (s00_axi_bresp)
      ,.s00_axi_bvalid (s00_axi_bvalid)
      ,.s00_axi_bready (s00_axi_bready)
      ,.s00_axi_araddr (s00_axi_araddr)
      ,.s00_axi_arprot (s00_axi_arprot)
      ,.s00_axi_arvalid(s00_axi_arvalid)
      ,.s00_axi_arready(s00_axi_arready)
      ,.s00_axi_rdata  (s00_axi_rdata)
      ,.s00_axi_rresp  (s00_axi_rresp)
      ,.s00_axi_rvalid (s00_axi_rvalid)
      ,.s00_axi_rready (s00_axi_rready)

      ,.s01_axi_aclk   (s01_axi_aclk)
      ,.s01_axi_aresetn(s01_axi_aresetn)
      ,.s01_axi_awaddr (s01_axi_awaddr)
      ,.s01_axi_awprot (s01_axi_awprot)
      ,.s01_axi_awvalid(s01_axi_awvalid)
      ,.s01_axi_awready(s01_axi_awready)
      ,.s01_axi_wdata  (s01_axi_wdata)
      ,.s01_axi_wstrb  (s01_axi_wstrb)
      ,.s01_axi_wvalid (s01_axi_wvalid)
      ,.s01_axi_wready (s01_axi_wready)
      ,.s01_axi_bresp  (s01_axi_bresp)
      ,.s01_axi_bvalid (s01_axi_bvalid)
      ,.s01_axi_bready (s01_axi_bready)
      ,.s01_axi_araddr (s01_axi_araddr)
      ,.s01_axi_arprot (s01_axi_arprot)
      ,.s01_axi_arvalid(s01_axi_arvalid)
      ,.s01_axi_arready(s01_axi_arready)
      ,.s01_axi_rdata  (s01_axi_rdata)
      ,.s01_axi_rresp  (s01_axi_rresp)
      ,.s01_axi_rvalid (s01_axi_rvalid)
      ,.s01_axi_rready (s01_axi_rready)

      ,.m00_axi_aclk   (m00_axi_aclk)
      ,.m00_axi_aresetn(m00_axi_aresetn)
      ,.m00_axi_awaddr (m00_axi_awaddr)
      ,.m00_axi_awvalid(m00_axi_awvalid)
      ,.m00_axi_awready(m00_axi_awready)
      ,.m00_axi_awid   (m00_axi_awid)
      ,.m00_axi_awlock (m00_axi_awlock)
      ,.m00_axi_awcache(m00_axi_awcache)
      ,.m00_axi_awprot (m00_axi_awprot)
      ,.m00_axi_awlen  (m00_axi_awlen)
      ,.m00_axi_awsize (m00_axi_awsize)
      ,.m00_axi_awburst(m00_axi_awburst)
      ,.m00_axi_awqos  (m00_axi_awqos)

      ,.m00_axi_wdata  (m00_axi_wdata)
      ,.m00_axi_wvalid (m00_axi_wvalid)
      ,.m00_axi_wready (m00_axi_wready)
      ,.m00_axi_wid    (m00_axi_wid)
      ,.m00_axi_wlast  (m00_axi_wlast)
      ,.m00_axi_wstrb  (m00_axi_wstrb)

      ,.m00_axi_bvalid (m00_axi_bvalid)
      ,.m00_axi_bready (m00_axi_bready)
      ,.m00_axi_bid    (m00_axi_bid)
      ,.m00_axi_bresp  (m00_axi_bresp)

      ,.m00_axi_araddr (m00_axi_araddr)
      ,.m00_axi_arvalid(m00_axi_arvalid)
      ,.m00_axi_arready(m00_axi_arready)
      ,.m00_axi_arid   (m00_axi_arid)
      ,.m00_axi_arlock (m00_axi_arlock)
      ,.m00_axi_arcache(m00_axi_arcache)
      ,.m00_axi_arprot (m00_axi_arprot)
      ,.m00_axi_arlen  (m00_axi_arlen)
      ,.m00_axi_arsize (m00_axi_arsize)
      ,.m00_axi_arburst(m00_axi_arburst)
      ,.m00_axi_arqos  (m00_axi_arqos)

      ,.m00_axi_rdata  (m00_axi_rdata)
      ,.m00_axi_rvalid (m00_axi_rvalid)
      ,.m00_axi_rready (m00_axi_rready)
      ,.m00_axi_rid    (m00_axi_rid)
      ,.m00_axi_rlast  (m00_axi_rlast)
      ,.m00_axi_rresp  (m00_axi_rresp)
      );

endmodule
