
`timescale 1 ps / 1 ps

`include "bp_zynq_pl.vh"

module top
  #(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH = 10
    , parameter integer C_S01_AXI_DATA_WIDTH = 32
    , parameter integer C_S01_AXI_ADDR_WIDTH = 30
    , parameter integer C_S02_AXI_DATA_WIDTH = 32
    , parameter integer C_S02_AXI_ADDR_WIDTH = 32
    , parameter integer C_M00_AXI_DATA_WIDTH = 64
    , parameter integer C_M00_AXI_ADDR_WIDTH = 32
    , parameter integer C_M01_AXI_DATA_WIDTH = 32
    , parameter integer C_M01_AXI_ADDR_WIDTH = 32
    )
   (
    // Ports of Axi Slave Bus Interface S00_AXI
`ifdef FPGA
    input wire                                   aclk
    ,input wire                                  aresetn
    ,input wire                                  rt_clk
    ,input wire                                  clk250_i
    // Ethernet clocks
    ,input wire                                  tx_clk_i
    ,input wire                                  rx_clk_i
    // resets
    ,output wire                                 reset_o
    ,output wire                                 clk250_reset_o
    ,output wire                                 tx_clk_gen_reset_o
    ,output wire                                 tx_reset_o
    ,output wire                                 rx_reset_o

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

    ,input wire [C_S02_AXI_ADDR_WIDTH-1 : 0]     s02_axi_awaddr
    ,input wire [2 : 0]                          s02_axi_awprot
    ,input wire                                  s02_axi_awvalid
    ,output wire                                 s02_axi_awready
    ,input wire [C_S02_AXI_DATA_WIDTH-1 : 0]     s02_axi_wdata
    ,input wire [(C_S02_AXI_DATA_WIDTH/8)-1 : 0] s02_axi_wstrb
    ,input wire                                  s02_axi_wvalid
    ,output wire                                 s02_axi_wready
    ,output wire [1 : 0]                         s02_axi_bresp
    ,output wire                                 s02_axi_bvalid
    ,input wire                                  s02_axi_bready
    ,input wire [C_S02_AXI_ADDR_WIDTH-1 : 0]     s02_axi_araddr
    ,input wire [2 : 0]                          s02_axi_arprot
    ,input wire                                  s02_axi_arvalid
    ,output wire                                 s02_axi_arready
    ,output wire [C_S02_AXI_DATA_WIDTH-1 : 0]    s02_axi_rdata
    ,output wire [1 : 0]                         s02_axi_rresp
    ,output wire                                 s02_axi_rvalid
    ,input wire                                  s02_axi_rready

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
    ,output wire                                 m00_axi_awvalid
    ,input wire                                  m00_axi_awready
    ,output wire [5:0]                           m00_axi_awid
    ,output wire [1:0]                           m00_axi_awlock  // 1 bit bsg_cache_to_axi (AXI4); 2 bit (AXI3)
    ,output wire [3:0]                           m00_axi_awcache
    ,output wire [2:0]                           m00_axi_awprot
    ,output wire [3:0]                           m00_axi_awlen   // 8 bits bsg_cache_to_axi
    ,output wire [2:0]                           m00_axi_awsize
    ,output wire [1:0]                           m00_axi_awburst
    ,output wire [3:0]                           m00_axi_awqos

    ,output wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata
    ,output wire                                 m00_axi_wvalid
    ,input wire                                  m00_axi_wready
    ,output wire [5:0]                           m00_axi_wid
    ,output wire                                 m00_axi_wlast
    ,output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb

    ,input wire                                  m00_axi_bvalid
    ,output wire                                 m00_axi_bready
    ,input wire [5:0]                            m00_axi_bid
    ,input wire [1:0]                            m00_axi_bresp

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr
    ,output wire                                 m00_axi_arvalid
    ,input wire                                  m00_axi_arready
    ,output wire [5:0]                           m00_axi_arid
    ,output wire [1:0]                           m00_axi_arlock
    ,output wire [3:0]                           m00_axi_arcache
    ,output wire [2:0]                           m00_axi_arprot
    ,output wire [3:0]                           m00_axi_arlen
    ,output wire [2:0]                           m00_axi_arsize
    ,output wire [1:0]                           m00_axi_arburst
    ,output wire [3:0]                           m00_axi_arqos

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
    ,input wire                                  m00_axi_rvalid
    ,output wire                                 m00_axi_rready
    ,input wire [5:0]                            m00_axi_rid
    ,input wire                                  m00_axi_rlast
    ,input wire [1:0]                            m00_axi_rresp

    ,output wire [C_M01_AXI_ADDR_WIDTH-1 : 0]    m01_axi_awaddr
    ,output wire [2 : 0]                         m01_axi_awprot
    ,output wire                                 m01_axi_awvalid
    ,input wire                                  m01_axi_awready
    ,output wire [C_M01_AXI_DATA_WIDTH-1 : 0]    m01_axi_wdata
    ,output wire [(C_M01_AXI_DATA_WIDTH/8)-1:0]  m01_axi_wstrb
    ,output wire                                 m01_axi_wvalid
    ,input wire                                  m01_axi_wready
    ,input wire [1 : 0]                          m01_axi_bresp
    ,input wire                                  m01_axi_bvalid
    ,output wire                                 m01_axi_bready
    ,output wire [C_M01_AXI_ADDR_WIDTH-1 : 0]    m01_axi_araddr
    ,output wire [2 : 0]                         m01_axi_arprot
    ,output wire                                 m01_axi_arvalid
    ,input wire                                  m01_axi_arready
    ,input wire [C_M01_AXI_DATA_WIDTH-1 : 0]     m01_axi_rdata
    ,input wire [1 : 0]                          m01_axi_rresp
    ,input wire                                  m01_axi_rvalid
    ,output wire                                 m01_axi_rready
    );

    logic s00_axi_aclk, s01_axi_aclk, s02_axi_aclk, m00_axi_aclk, m01_axi_aclk;
    logic s00_axi_aresetn, s01_axi_aresetn, s02_axi_aresetn, m00_axi_aresetn, m01_axi_aresetn;

`else
    );

    logic tx_clk_i;
    logic rx_clk_i;
    logic reset_o;
    logic clk250_reset_o;
    logic tx_clk_gen_reset_o;
    logic tx_reset_o;
    logic rx_reset_o;

    logic clk250_i;
    bsg_nonsynth_clock_gen
     #(.cycle_time_p(4000)) // 250 MHZ
     clk250_gen
      (.o(clk250_i));

    logic iodelay_ref_clk_i;
    bsg_nonsynth_clock_gen
     #(.cycle_time_p(5000)) // 200 MHZ
     iodelay_ref_clk_gen
      (.o(iodelay_ref_clk_i));

    localparam rt_clk_period_lp = 2500000;
    logic rt_clk;
    bsg_nonsynth_clock_gen
     #(.cycle_time_p(rt_clk_period_lp))
     rt_clk_gen
      (.o(rt_clk));

    localparam aclk_period_lp = 50000;
    logic aclk;
    bsg_nonsynth_clock_gen
     #(.cycle_time_p(aclk_period_lp))
     aclk_gen
      (.o(aclk));

    logic areset;
    bsg_nonsynth_reset_gen
     #(.reset_cycles_lo_p(0), .reset_cycles_hi_p(10))
     reset_gen
      (.clk_i(aclk), .async_reset_o(areset));
    wire aresetn = ~areset;

    logic s00_axi_aclk, s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [2:0] s00_axi_awprot;
    logic s00_axi_awvalid, s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic s00_axi_wvalid, s00_axi_wready;
    logic [1:0] s00_axi_bresp;
    logic s00_axi_bvalid, s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [2:0] s00_axi_arprot;
    logic s00_axi_arvalid, s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    logic [1:0] s00_axi_rresp;
    logic s00_axi_rvalid, s00_axi_rready;
    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S00_AXI_ADDR_WIDTH), .data_width_p(C_S00_AXI_DATA_WIDTH))
     axil0
      (.aclk_i(s00_axi_aclk)
       ,.aresetn_i(s00_axi_aresetn)

       ,.awaddr_o(s00_axi_awaddr)
       ,.awprot_o(s00_axi_awprot)
       ,.awvalid_o(s00_axi_awvalid)
       ,.awready_i(s00_axi_awready)
       ,.wdata_o(s00_axi_wdata)
       ,.wstrb_o(s00_axi_wstrb)
       ,.wvalid_o(s00_axi_wvalid)
       ,.wready_i(s00_axi_wready)
       ,.bresp_i(s00_axi_bresp)
       ,.bvalid_i(s00_axi_bvalid)
       ,.bready_o(s00_axi_bready)

       ,.araddr_o(s00_axi_araddr)
       ,.arprot_o(s00_axi_arprot)
       ,.arvalid_o(s00_axi_arvalid)
       ,.arready_i(s00_axi_arready)
       ,.rdata_i(s00_axi_rdata)
       ,.rresp_i(s00_axi_rresp)
       ,.rvalid_i(s00_axi_rvalid)
       ,.rready_o(s00_axi_rready)
       );

    logic s01_axi_aclk, s01_axi_aresetn;
    logic [C_S01_AXI_ADDR_WIDTH-1:0] s01_axi_awaddr;
    logic [2:0] s01_axi_awprot;
    logic s01_axi_awvalid, s01_axi_awready;
    logic [C_S01_AXI_DATA_WIDTH-1:0] s01_axi_wdata;
    logic [(C_S01_AXI_DATA_WIDTH/8)-1:0] s01_axi_wstrb;
    logic s01_axi_wvalid, s01_axi_wready;
    logic [1:0] s01_axi_bresp;
    logic s01_axi_bvalid, s01_axi_bready;
    logic [C_S01_AXI_ADDR_WIDTH-1:0] s01_axi_araddr;
    logic [2:0] s01_axi_arprot;
    logic s01_axi_arvalid, s01_axi_arready;
    logic [C_S01_AXI_DATA_WIDTH-1:0] s01_axi_rdata;
    logic [1:0] s01_axi_rresp;
    logic s01_axi_rvalid, s01_axi_rready;
    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S01_AXI_ADDR_WIDTH), .data_width_p(C_S01_AXI_DATA_WIDTH))
     axil1
      (.aclk_i(s01_axi_aclk)
       ,.aresetn_i(s01_axi_aresetn)

       ,.awaddr_o(s01_axi_awaddr)
       ,.awprot_o(s01_axi_awprot)
       ,.awvalid_o(s01_axi_awvalid)
       ,.awready_i(s01_axi_awready)
       ,.wdata_o(s01_axi_wdata)
       ,.wstrb_o(s01_axi_wstrb)
       ,.wvalid_o(s01_axi_wvalid)
       ,.wready_i(s01_axi_wready)
       ,.bresp_i(s01_axi_bresp)
       ,.bvalid_i(s01_axi_bvalid)
       ,.bready_o(s01_axi_bready)

       ,.araddr_o(s01_axi_araddr)
       ,.arprot_o(s01_axi_arprot)
       ,.arvalid_o(s01_axi_arvalid)
       ,.arready_i(s01_axi_arready)
       ,.rdata_i(s01_axi_rdata)
       ,.rresp_i(s01_axi_rresp)
       ,.rvalid_i(s01_axi_rvalid)
       ,.rready_o(s01_axi_rready)
       );

    // TODO: Fix widths
    logic m01_axi_aclk, m01_axi_aresetn;
    logic [C_M01_AXI_ADDR_WIDTH-1:0] m01_axi_awaddr;
    logic [2:0] m01_axi_awprot;
    logic m01_axi_awvalid, m01_axi_awready;
    logic [C_M01_AXI_DATA_WIDTH-1:0] m01_axi_wdata;
    logic [(C_M01_AXI_DATA_WIDTH/8)-1:0] m01_axi_wstrb;
    logic m01_axi_wvalid, m01_axi_wready;
    logic [1:0] m01_axi_bresp;
    logic m01_axi_bvalid, m01_axi_bready;
    logic [C_M01_AXI_ADDR_WIDTH-1:0] m01_axi_araddr;
    logic [2:0] m01_axi_arprot;
    logic m01_axi_arvalid, m01_axi_arready;
    logic [C_M01_AXI_DATA_WIDTH-1:0] m01_axi_rdata;
    logic [1:0] m01_axi_rresp;
    logic m01_axi_rvalid, m01_axi_rready;

   localparam axi_id_width_p = 6;
   localparam axi_addr_width_p = 32;
   localparam axi_data_width_p = 64;
   localparam axi_strb_width_p = axi_data_width_p >> 3;
   localparam axi_burst_len_p = 8;

   logic                                m00_axi_aclk;
   logic                                m00_axi_aresetn;
   wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr;
   wire                                 m00_axi_awvalid;
   wire                                 m00_axi_awready;
   wire [5:0]                           m00_axi_awid;
   wire [1:0]                           m00_axi_awlock;
   wire [3:0]                           m00_axi_awcache;
   wire [2:0]                           m00_axi_awprot;
   wire [3:0]                           m00_axi_awlen;
   wire [2:0]                           m00_axi_awsize;
   wire [1:0]                           m00_axi_awburst;
   wire [3:0]                           m00_axi_awqos;
   wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata;
   wire                                 m00_axi_wvalid;
   wire                                 m00_axi_wready;
   wire [5:0]                           m00_axi_wid;
   wire                                 m00_axi_wlast;
   wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb;
   wire                                 m00_axi_bvalid;
   wire                                 m00_axi_bready;
   wire [5:0]                           m00_axi_bid;
   wire [1:0]                           m00_axi_bresp;
   wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr;
   wire                                 m00_axi_arvalid;
   wire                                 m00_axi_arready;
   wire [5:0]                           m00_axi_arid;
   wire [1:0]                           m00_axi_arlock;
   wire [3:0]                           m00_axi_arcache;
   wire [2:0]                           m00_axi_arprot;
   wire [3:0]                           m00_axi_arlen;
   wire [2:0]                           m00_axi_arsize;
   wire [1:0]                           m00_axi_arburst;
   wire [3:0]                           m00_axi_arqos;
   wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata;
   wire                                 m00_axi_rvalid;
   wire                                 m00_axi_rready;
   wire [5:0]                           m00_axi_rid;
   wire                                 m00_axi_rlast;
   wire [1:0]                           m00_axi_rresp;

   wire                                 s02_axi_aclk;
   wire                                 s02_axi_aresetn;
   wire [C_S02_AXI_ADDR_WIDTH-1 : 0]    s02_axi_awaddr;
   wire [2 : 0]                         s02_axi_awprot;
   wire                                 s02_axi_awvalid;
   wire                                 s02_axi_awready;
   wire [C_S02_AXI_DATA_WIDTH-1 : 0]    s02_axi_wdata;
   wire [(C_S02_AXI_DATA_WIDTH/8)-1 : 0]s02_axi_wstrb;
   wire                                 s02_axi_wvalid;
   wire                                 s02_axi_wready;
   wire [1 : 0]                         s02_axi_bresp;
   wire                                 s02_axi_bvalid;
   wire                                 s02_axi_bready;
   wire [C_S02_AXI_ADDR_WIDTH-1 : 0]    s02_axi_araddr;
   wire [2 : 0]                         s02_axi_arprot;
   wire                                 s02_axi_arvalid;
   wire                                 s02_axi_arready;
   wire [C_S02_AXI_DATA_WIDTH-1 : 0]    s02_axi_rdata;
   wire [1 : 0]                         s02_axi_rresp;
   wire                                 s02_axi_rvalid;
   wire                                 s02_axi_rready;


   bsg_nonsynth_axi_mem
     #(.axi_id_width_p(axi_id_width_p)
       ,.axi_addr_width_p(axi_addr_width_p)
       ,.axi_data_width_p(axi_data_width_p)
       ,.axi_len_width_p(4)
       ,.mem_els_p(2**28) // 256 MB
       ,.init_data_p('0)
     )
   axi_mem
     (.clk_i          (m00_axi_aclk)
      ,.reset_i       (~m00_axi_aresetn)

      ,.axi_awid_i    (m00_axi_awid)
      ,.axi_awaddr_i  (m00_axi_awaddr)
      ,.axi_awlen_i   (m00_axi_awlen)
      ,.axi_awburst_i (m00_axi_awburst)
      ,.axi_awvalid_i (m00_axi_awvalid)
      ,.axi_awready_o (m00_axi_awready)

      ,.axi_wdata_i   (m00_axi_wdata)
      ,.axi_wstrb_i   (m00_axi_wstrb)
      ,.axi_wlast_i   (m00_axi_wlast)
      ,.axi_wvalid_i  (m00_axi_wvalid)
      ,.axi_wready_o  (m00_axi_wready)

      ,.axi_bid_o     (m00_axi_bid)
      ,.axi_bresp_o   (m00_axi_bresp)
      ,.axi_bvalid_o  (m00_axi_bvalid)
      ,.axi_bready_i  (m00_axi_bready)

      ,.axi_arid_i    (m00_axi_arid)
      ,.axi_araddr_i  (m00_axi_araddr)
      ,.axi_arlen_i   (m00_axi_arlen)
      ,.axi_arburst_i (m00_axi_arburst)
      ,.axi_arvalid_i (m00_axi_arvalid)
      ,.axi_arready_o (m00_axi_arready)

      ,.axi_rid_o     (m00_axi_rid)
      ,.axi_rdata_o   (m00_axi_rdata)
      ,.axi_rresp_o   (m00_axi_rresp)
      ,.axi_rlast_o   (m00_axi_rlast)
      ,.axi_rvalid_o  (m00_axi_rvalid)
      ,.axi_rready_i  (m00_axi_rready)
      );

  logic       rgmii_rx_clk_i;
  logic [3:0] rgmii_rxd_i;
  logic       rgmii_rx_ctl_i;
  logic       rgmii_tx_clk_o;
  logic [3:0] rgmii_txd_o;
  logic       rgmii_tx_ctl_o;

  // Ethernet speed: cycle time
  // 10M: 400000;
  // 100M: 40000;
  // 1000M: 8000;
  localparam rgmii_rx_cycle_time_lp = 40000; // 100M

  bsg_nonsynth_clock_gen #(.cycle_time_p(rgmii_rx_cycle_time_lp)
  ) rgmii_rx_clk_gen (
    .o(rgmii_rx_clk_i)
  );
  rgmii_loopback_nonsynth rgmii_loopback_nonsynth (
    .rx_rst_i(tx_reset_o)
   ,.rgmii_rx_clk_i(rgmii_tx_clk_o)
   ,.rgmii_rxd_i(rgmii_txd_o)
   ,.rgmii_rx_ctl_i(rgmii_tx_ctl_o)

   ,.tx_rst_i(rx_reset_o)
   ,.rgmii_tx_clk_i(rgmii_rx_clk_i)
   ,.rgmii_txd_o(rgmii_rxd_i)
   ,.rgmii_tx_ctl_o(rgmii_rx_ctl_i)
  );


  peripheral_nonsynth #(
    .C_M01_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH)
   ,.C_M01_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH)
   ,.C_S02_AXI_DATA_WIDTH(C_S02_AXI_DATA_WIDTH)
   ,.C_S02_AXI_ADDR_WIDTH(C_S02_AXI_ADDR_WIDTH)
  ) peripheral_nonsynth_inst (
    .aclk(aclk)
   ,.reset_i(reset_o)
   ,.clk250_i(clk250_i)
   ,.clk250_reset_i(clk250_reset_o)
   ,.tx_clk_gen_reset_i(tx_clk_gen_reset_o)
   ,.tx_clk_o(tx_clk_i)
   ,.tx_reset_i(tx_reset_o)
   ,.rx_clk_o(rx_clk_i)
   ,.rx_reset_i(rx_reset_o)
   ,.iodelay_ref_clk_i(iodelay_ref_clk_i)

   ,.s01_axi_awaddr (m01_axi_awaddr )
   ,.s01_axi_awprot (m01_axi_awprot )
   ,.s01_axi_awvalid(m01_axi_awvalid)
   ,.s01_axi_awready(m01_axi_awready)

   ,.s01_axi_wdata  (m01_axi_wdata  )
   ,.s01_axi_wstrb  (m01_axi_wstrb  )
   ,.s01_axi_wvalid (m01_axi_wvalid )
   ,.s01_axi_wready (m01_axi_wready )

   ,.s01_axi_bresp  (m01_axi_bresp  )
   ,.s01_axi_bvalid (m01_axi_bvalid )
   ,.s01_axi_bready (m01_axi_bready )

   ,.s01_axi_araddr (m01_axi_araddr )
   ,.s01_axi_arprot (m01_axi_arprot )
   ,.s01_axi_arvalid(m01_axi_arvalid)
   ,.s01_axi_arready(m01_axi_arready)

   ,.s01_axi_rdata  (m01_axi_rdata  )
   ,.s01_axi_rresp  (m01_axi_rresp  )
   ,.s01_axi_rvalid (m01_axi_rvalid )
   ,.s01_axi_rready (m01_axi_rready )

   ,.m02_axi_awaddr (s02_axi_awaddr )
   ,.m02_axi_awprot (s02_axi_awprot )
   ,.m02_axi_awvalid(s02_axi_awvalid)
   ,.m02_axi_awready(s02_axi_awready)

   ,.m02_axi_wdata  (s02_axi_wdata  )
   ,.m02_axi_wstrb  (s02_axi_wstrb  )
   ,.m02_axi_wvalid (s02_axi_wvalid )
   ,.m02_axi_wready (s02_axi_wready )

   ,.m02_axi_bresp  (s02_axi_bresp  )
   ,.m02_axi_bvalid (s02_axi_bvalid )
   ,.m02_axi_bready (s02_axi_bready )

   ,.m02_axi_araddr (s02_axi_araddr )
   ,.m02_axi_arprot (s02_axi_arprot )
   ,.m02_axi_arvalid(s02_axi_arvalid)
   ,.m02_axi_arready(s02_axi_arready)

   ,.m02_axi_rdata  (s02_axi_rdata  )
   ,.m02_axi_rresp  (s02_axi_rresp  )
   ,.m02_axi_rvalid (s02_axi_rvalid )
   ,.m02_axi_rready (s02_axi_rready )

   ,.rgmii_rx_clk_i(rgmii_rx_clk_i)
   ,.rgmii_rxd_i(rgmii_rxd_i)
   ,.rgmii_rx_ctl_i(rgmii_rx_ctl_i)
   ,.rgmii_tx_clk_o(rgmii_tx_clk_o)
   ,.rgmii_txd_o(rgmii_txd_o)
   ,.rgmii_tx_ctl_o(rgmii_tx_ctl_o)
  );
`endif

   assign {s00_axi_aclk, s01_axi_aclk, s02_axi_aclk, m00_axi_aclk, m01_axi_aclk} = {5{aclk}};

   top_zynq #
     (.C_S00_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH)
      ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ,.C_S01_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH)
      ,.C_S01_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH)
      ,.C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
      ,.C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH)
      ,.C_M01_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH)
      ,.C_M01_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH)
      )
     top_fpga_inst
     (.aclk            (aclk)
      ,.aresetn        (aresetn)
      ,.rt_clk         (rt_clk)
      ,.clk250_i       (clk250_i)
      ,.tx_clk_i       (tx_clk_i)
      ,.rx_clk_i       (rx_clk_i)

      ,.reset_o(reset_o)
      ,.clk250_reset_o (clk250_reset_o)
      ,.tx_clk_gen_reset_o(tx_clk_gen_reset_o)
      ,.tx_reset_o     (tx_reset_o)
      ,.rx_reset_o     (rx_reset_o)

      ,.s00_axi_aclk   (s00_axi_aclk)
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

      ,.s02_axi_aclk   (s02_axi_aclk)
      ,.s02_axi_aresetn(s02_axi_aresetn)
      ,.s02_axi_awaddr (s02_axi_awaddr)
      ,.s02_axi_awprot (s02_axi_awprot)
      ,.s02_axi_awvalid(s02_axi_awvalid)
      ,.s02_axi_awready(s02_axi_awready)
      ,.s02_axi_wdata  (s02_axi_wdata)
      ,.s02_axi_wstrb  (s02_axi_wstrb)
      ,.s02_axi_wvalid (s02_axi_wvalid)
      ,.s02_axi_wready (s02_axi_wready)
      ,.s02_axi_bresp  (s02_axi_bresp)
      ,.s02_axi_bvalid (s02_axi_bvalid)
      ,.s02_axi_bready (s02_axi_bready)
      ,.s02_axi_araddr (s02_axi_araddr)
      ,.s02_axi_arprot (s02_axi_arprot)
      ,.s02_axi_arvalid(s02_axi_arvalid)
      ,.s02_axi_arready(s02_axi_arready)
      ,.s02_axi_rdata  (s02_axi_rdata)
      ,.s02_axi_rresp  (s02_axi_rresp)
      ,.s02_axi_rvalid (s02_axi_rvalid)
      ,.s02_axi_rready (s02_axi_rready)

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

      ,.m01_axi_aclk   (m01_axi_aclk)
      ,.m01_axi_aresetn(m01_axi_aresetn)
      ,.m01_axi_awaddr (m01_axi_awaddr)
      ,.m01_axi_awprot (m01_axi_awprot)
      ,.m01_axi_awvalid(m01_axi_awvalid)
      ,.m01_axi_awready(m01_axi_awready)
      ,.m01_axi_wdata  (m01_axi_wdata)
      ,.m01_axi_wstrb  (m01_axi_wstrb)
      ,.m01_axi_wvalid (m01_axi_wvalid)
      ,.m01_axi_wready (m01_axi_wready)
      ,.m01_axi_bresp  (m01_axi_bresp)
      ,.m01_axi_bvalid (m01_axi_bvalid)
      ,.m01_axi_bready (m01_axi_bready)
      ,.m01_axi_araddr (m01_axi_araddr)
      ,.m01_axi_arprot (m01_axi_arprot)
      ,.m01_axi_arvalid(m01_axi_arvalid)
      ,.m01_axi_arready(m01_axi_arready)
      ,.m01_axi_rdata  (m01_axi_rdata)
      ,.m01_axi_rresp  (m01_axi_rresp)
      ,.m01_axi_rvalid (m01_axi_rvalid)
      ,.m01_axi_rready (m01_axi_rready)
      );

`ifdef VCS
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $vcdplusfile("vcdplus.vpd");
           $vcdpluson();
           $vcdplusautoflushon();
         end
       if ($test$plusargs("c_args") != 0)
         begin
           $value$plusargs("c_args=%s", c_args);
         end
       cosim_main(c_args);
       $finish;
     end

   // Evaluate the simulation, until the next clk_i positive edge.
   //
   // Call bsg_dpi_next in simulators where the C testbench does not
   // control the progression of time (i.e. NOT Verilator).
   //
   // The #1 statement guarantees that the positive edge has been
   // evaluated, which is necessary for ordering in all of the DPI
   // functions.
   export "DPI-C" task bsg_dpi_next;
   task bsg_dpi_next();
     @(posedge s00_axi_aclk);
     #1;
   endtask

  initial
    begin
      $assertoff();
      @(posedge s00_axi_aclk);
      @(negedge s00_axi_aresetn);
      $asserton();
    end
`endif

endmodule
