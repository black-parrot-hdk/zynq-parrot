
`default_nettype none

module peripheral_nonsynth #(
    parameter integer C_M01_AXI_DATA_WIDTH = 32
  , parameter integer C_M01_AXI_ADDR_WIDTH = 32
  , parameter integer C_S02_AXI_DATA_WIDTH = 32
  , parameter integer C_S02_AXI_ADDR_WIDTH = 32
)
(
    input wire                                  aclk
  , input wire                                  reset_i

  , input wire                                  clk250_i
  , input wire                                  clk250_reset_i
  , input wire                                  tx_clk_gen_reset_i

  , input wire                                  tx_clk_o
  , input wire                                  tx_reset_i

  , input wire                                  rx_clk_o
  , input wire                                  rx_reset_i

  , input wire                                  iodelay_ref_clk_i

  , input wire [C_M01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_awaddr
  , input wire [2 : 0]                          s01_axi_awprot
  , input wire                                  s01_axi_awvalid
  , output wire                                 s01_axi_awready

  , input wire [C_M01_AXI_DATA_WIDTH-1 : 0]     s01_axi_wdata
  , input wire [(C_M01_AXI_DATA_WIDTH/8)-1:0]   s01_axi_wstrb
  , input wire                                  s01_axi_wvalid
  , output wire                                 s01_axi_wready

  , output wire [1 : 0]                         s01_axi_bresp
  , output wire                                 s01_axi_bvalid
  , input wire                                  s01_axi_bready

  , input wire [C_M01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_araddr
  , input wire [2 : 0]                          s01_axi_arprot
  , input wire                                  s01_axi_arvalid
  , output wire                                 s01_axi_arready

  , output wire [C_M01_AXI_DATA_WIDTH-1 : 0]    s01_axi_rdata
  , output wire [1 : 0]                         s01_axi_rresp
  , output wire                                 s01_axi_rvalid
  , input wire                                  s01_axi_rready

  , output wire [C_S02_AXI_ADDR_WIDTH-1 : 0]    m02_axi_awaddr
  , output wire [2 : 0]                         m02_axi_awprot
  , output wire                                 m02_axi_awvalid
  , input wire                                  m02_axi_awready

  , output wire [C_S02_AXI_DATA_WIDTH-1 : 0]    m02_axi_wdata
  , output wire [(C_S02_AXI_DATA_WIDTH/8)-1 : 0]m02_axi_wstrb
  , output wire                                 m02_axi_wvalid
  , input wire                                  m02_axi_wready

  , input wire [1 : 0]                          m02_axi_bresp
  , input wire                                  m02_axi_bvalid
  , output wire                                 m02_axi_bready

  , output wire [C_S02_AXI_ADDR_WIDTH-1 : 0]    m02_axi_araddr
  , output wire [2 : 0]                         m02_axi_arprot
  , output wire                                 m02_axi_arvalid
  , input wire                                  m02_axi_arready

  , input wire [C_S02_AXI_DATA_WIDTH-1 : 0]     m02_axi_rdata
  , input wire [1 : 0]                          m02_axi_rresp
  , input wire                                  m02_axi_rvalid
  , output wire                                 m02_axi_rready

  , input wire                                  rgmii_rx_clk_i
  , input wire [3:0]                            rgmii_rxd_i
  , input wire                                  rgmii_rx_ctl_i
  , output wire                                 rgmii_tx_clk_o
  , output wire [3:0]                           rgmii_txd_o
  , output wire                                 rgmii_tx_ctl_o
);

  logic irq_lo;
  // Ethernet
  wire [C_M01_AXI_ADDR_WIDTH-1 : 0]   eth_axi_awaddr;
  wire [2 : 0]                        eth_axi_awprot;
  wire                                eth_axi_awvalid;
  wire                                eth_axi_awready;

  wire [C_M01_AXI_DATA_WIDTH-1 : 0]   eth_axi_wdata;
  wire [(C_M01_AXI_DATA_WIDTH/8)-1:0] eth_axi_wstrb;
  wire                                eth_axi_wvalid;
  wire                                eth_axi_wready;

  wire [1 : 0]                        eth_axi_bresp;
  wire                                eth_axi_bvalid;
  wire                                eth_axi_bready;

  wire [C_M01_AXI_ADDR_WIDTH-1 : 0]   eth_axi_araddr;
  wire [2 : 0]                        eth_axi_arprot;
  wire                                eth_axi_arvalid;
  wire                                eth_axi_arready;

  wire [C_M01_AXI_DATA_WIDTH-1 : 0]   eth_axi_rdata;
  wire [1 : 0]                        eth_axi_rresp;
  wire                                eth_axi_rvalid;
  wire                                eth_axi_rready;

  // PLIC
  wire [C_M01_AXI_ADDR_WIDTH-1 : 0]   plic_axi_awaddr;
  wire [2 : 0]                        plic_axi_awprot;
  wire                                plic_axi_awvalid;
  wire                                plic_axi_awready;

  wire [C_M01_AXI_DATA_WIDTH-1 : 0]   plic_axi_wdata;
  wire [(C_M01_AXI_DATA_WIDTH/8)-1:0] plic_axi_wstrb;
  wire                                plic_axi_wvalid;
  wire                                plic_axi_wready;

  wire [1 : 0]                        plic_axi_bresp;
  wire                                plic_axi_bvalid;
  wire                                plic_axi_bready;

  wire [C_M01_AXI_ADDR_WIDTH-1 : 0]   plic_axi_araddr;
  wire [2 : 0]                        plic_axi_arprot;
  wire                                plic_axi_arvalid;
  wire                                plic_axi_arready;

  wire [C_M01_AXI_DATA_WIDTH-1 : 0]   plic_axi_rdata;
  wire [1 : 0]                        plic_axi_rresp;
  wire                                plic_axi_rvalid;
  wire                                plic_axi_rready;

  bsg_axil_demux #(
    .addr_width_p(C_M01_AXI_ADDR_WIDTH)
   ,.data_width_p(C_M01_AXI_DATA_WIDTH)
   ,.split_addr_p(32'h20000000) // 0x10000000: Ethernet, 0x20000000: PLIC
  ) demux (
    .clk_i(aclk)
   ,.reset_i(reset_i)

   ,.s00_axil_awaddr (s01_axi_awaddr )
   ,.s00_axil_awprot (s01_axi_awprot )
   ,.s00_axil_awvalid(s01_axi_awvalid)
   ,.s00_axil_awready(s01_axi_awready)

   ,.s00_axil_wdata  (s01_axi_wdata  )
   ,.s00_axil_wstrb  (s01_axi_wstrb  )
   ,.s00_axil_wvalid (s01_axi_wvalid )
   ,.s00_axil_wready (s01_axi_wready )

   ,.s00_axil_bresp  (s01_axi_bresp  )
   ,.s00_axil_bvalid (s01_axi_bvalid )
   ,.s00_axil_bready (s01_axi_bready )

   ,.s00_axil_araddr (s01_axi_araddr )
   ,.s00_axil_arprot (s01_axi_arprot )
   ,.s00_axil_arvalid(s01_axi_arvalid)
   ,.s00_axil_arready(s01_axi_arready)

   ,.s00_axil_rdata  (s01_axi_rdata  )
   ,.s00_axil_rresp  (s01_axi_rresp  )
   ,.s00_axil_rvalid (s01_axi_rvalid )
   ,.s00_axil_rready (s01_axi_rready )

   ,.m00_axil_awaddr (eth_axi_awaddr )
   ,.m00_axil_awprot (eth_axi_awprot )
   ,.m00_axil_awvalid(eth_axi_awvalid)
   ,.m00_axil_awready(eth_axi_awready)

   ,.m00_axil_wdata  (eth_axi_wdata  )
   ,.m00_axil_wstrb  (eth_axi_wstrb  )
   ,.m00_axil_wvalid (eth_axi_wvalid )
   ,.m00_axil_wready (eth_axi_wready )

   ,.m00_axil_bresp  (eth_axi_bresp  )
   ,.m00_axil_bvalid (eth_axi_bvalid )
   ,.m00_axil_bready (eth_axi_bready )

   ,.m00_axil_araddr (eth_axi_araddr )
   ,.m00_axil_arprot (eth_axi_arprot )
   ,.m00_axil_arvalid(eth_axi_arvalid)
   ,.m00_axil_arready(eth_axi_arready)

   ,.m00_axil_rdata  (eth_axi_rdata  )
   ,.m00_axil_rresp  (eth_axi_rresp  )
   ,.m00_axil_rvalid (eth_axi_rvalid )
   ,.m00_axil_rready (eth_axi_rready )

   ,.m01_axil_awaddr (plic_axi_awaddr )
   ,.m01_axil_awprot (plic_axi_awprot )
   ,.m01_axil_awvalid(plic_axi_awvalid)
   ,.m01_axil_awready(plic_axi_awready)

   ,.m01_axil_wdata  (plic_axi_wdata  )
   ,.m01_axil_wstrb  (plic_axi_wstrb  )
   ,.m01_axil_wvalid (plic_axi_wvalid )
   ,.m01_axil_wready (plic_axi_wready )

   ,.m01_axil_bresp  (plic_axi_bresp  )
   ,.m01_axil_bvalid (plic_axi_bvalid )
   ,.m01_axil_bready (plic_axi_bready )

   ,.m01_axil_araddr (plic_axi_araddr )
   ,.m01_axil_arprot (plic_axi_arprot )
   ,.m01_axil_arvalid(plic_axi_arvalid)
   ,.m01_axil_arready(plic_axi_arready)

   ,.m01_axil_rdata  (plic_axi_rdata  )
   ,.m01_axil_rresp  (plic_axi_rresp  )
   ,.m01_axil_rvalid (plic_axi_rvalid )
   ,.m01_axil_rready (plic_axi_rready )
  );

  ethernet_axil_wrapper #(
    .axil_data_width_p(32)
   ,.axil_addr_width_p(32)
  ) ethernet_wrapper (
    .aclk
   ,.reset_i
   ,.clk250_i
   ,.clk250_reset_i
   ,.tx_clk_gen_reset_i

   ,.tx_clk_o
   ,.tx_reset_i

   ,.rx_clk_o
   ,.rx_reset_i

   ,.iodelay_ref_clk_i

   ,.s00_axi_awaddr (eth_axi_awaddr )
   ,.s00_axi_awprot (eth_axi_awprot )
   ,.s00_axi_awvalid(eth_axi_awvalid)
   ,.s00_axi_awready(eth_axi_awready)

   ,.s00_axi_wdata  (eth_axi_wdata  )
   ,.s00_axi_wstrb  (eth_axi_wstrb  )
   ,.s00_axi_wvalid (eth_axi_wvalid )
   ,.s00_axi_wready (eth_axi_wready )

   ,.s00_axi_bresp  (eth_axi_bresp  )
   ,.s00_axi_bvalid (eth_axi_bvalid )
   ,.s00_axi_bready (eth_axi_bready )

   ,.s00_axi_araddr (eth_axi_araddr )
   ,.s00_axi_arprot (eth_axi_arprot )
   ,.s00_axi_arvalid(eth_axi_arvalid)
   ,.s00_axi_arready(eth_axi_arready)

   ,.s00_axi_rdata  (eth_axi_rdata  )
   ,.s00_axi_rresp  (eth_axi_rresp  )
   ,.s00_axi_rvalid (eth_axi_rvalid )
   ,.s00_axi_rready (eth_axi_rready )

   ,.rgmii_rx_clk_i
   ,.rgmii_rxd_i
   ,.rgmii_rx_ctl_i
   ,.rgmii_tx_clk_o
   ,.rgmii_txd_o
   ,.rgmii_tx_ctl_o

   ,.irq_o(irq_lo)
  );


  rv_plic_axil_wrapper #(
    .axil_data_width_p(32)
   ,.axil_addr_width_p(32)
  ) plic_wrapper (
    .aclk
   ,.reset_i
   ,.intr_src_i(irq_lo)

   ,.m00_axi_awaddr (m02_axi_awaddr)
   ,.m00_axi_awprot (m02_axi_awprot)
   ,.m00_axi_awvalid(m02_axi_awvalid)
   ,.m00_axi_awready(m02_axi_awready)

   ,.m00_axi_wdata  (m02_axi_wdata )
   ,.m00_axi_wstrb  (m02_axi_wstrb )
   ,.m00_axi_wvalid (m02_axi_wvalid)
   ,.m00_axi_wready (m02_axi_wready)

   ,.m00_axi_bresp  (m02_axi_bresp )
   ,.m00_axi_bvalid (m02_axi_bvalid)
   ,.m00_axi_bready (m02_axi_bready)

   ,.m00_axi_araddr (m02_axi_araddr)
   ,.m00_axi_arprot (m02_axi_arprot)
   ,.m00_axi_arvalid(m02_axi_arvalid)
   ,.m00_axi_arready(m02_axi_arready)

   ,.m00_axi_rdata  (m02_axi_rdata )
   ,.m00_axi_rresp  (m02_axi_rresp )
   ,.m00_axi_rvalid (m02_axi_rvalid)
   ,.m00_axi_rready (m02_axi_rready)

   ,.s00_axi_awaddr (plic_axi_awaddr )
   ,.s00_axi_awprot (plic_axi_awprot )
   ,.s00_axi_awvalid(plic_axi_awvalid)
   ,.s00_axi_awready(plic_axi_awready)

   ,.s00_axi_wdata  (plic_axi_wdata  )
   ,.s00_axi_wstrb  (plic_axi_wstrb  )
   ,.s00_axi_wvalid (plic_axi_wvalid )
   ,.s00_axi_wready (plic_axi_wready )

   ,.s00_axi_bresp  (plic_axi_bresp  )
   ,.s00_axi_bvalid (plic_axi_bvalid )
   ,.s00_axi_bready (plic_axi_bready )

   ,.s00_axi_araddr (plic_axi_araddr )
   ,.s00_axi_arprot (plic_axi_arprot )
   ,.s00_axi_arvalid(plic_axi_arvalid)
   ,.s00_axi_arready(plic_axi_arready)

   ,.s00_axi_rdata  (plic_axi_rdata  )
   ,.s00_axi_rresp  (plic_axi_rresp  )
   ,.s00_axi_rvalid (plic_axi_rvalid )
   ,.s00_axi_rready (plic_axi_rready )
  );

endmodule
