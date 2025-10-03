
`include "bsg_defines.sv"

module bsg_nonsynth_zynq_testbench;

`ifdef GP0_ENABLE
  localparam C_GP0_AXI_DATA_WIDTH = `GP0_DATA_WIDTH;
  localparam C_GP0_AXI_ADDR_WIDTH = `GP0_ADDR_WIDTH;
  localparam C_GP0_AXI_STRB_WIDTH = C_GP0_AXI_DATA_WIDTH >> 3;
`endif
`ifdef GP1_ENABLE
  localparam C_GP1_AXI_DATA_WIDTH = `GP1_DATA_WIDTH;
  localparam C_GP1_AXI_ADDR_WIDTH = `GP1_ADDR_WIDTH;
  localparam C_GP1_AXI_STRB_WIDTH = C_GP1_AXI_DATA_WIDTH >> 3;
`endif
`ifdef GP2_ENABLE
  localparam C_GP2_AXI_DATA_WIDTH = `GP2_DATA_WIDTH;
  localparam C_GP2_AXI_ADDR_WIDTH = `GP2_ADDR_WIDTH;
  localparam C_GP2_AXI_STRB_WIDTH = C_GP2_AXI_DATA_WIDTH >> 3;
`endif
`ifdef IP0_ENABLE
  localparam C_IP0_AXI_DATA_WIDTH = `IP0_DATA_WIDTH;
  localparam C_IP0_AXI_ADDR_WIDTH = `IP0_ADDR_WIDTH;
  localparam C_IP0_AXI_STRB_WIDTH = C_IP0_AXI_DATA_WIDTH >> 3;
`endif
`ifdef IP1_ENABLE
  localparam C_IP1_AXI_DATA_WIDTH = `IP1_DATA_WIDTH;
  localparam C_IP1_AXI_ADDR_WIDTH = `IP1_ADDR_WIDTH;
  localparam C_IP1_AXI_STRB_WIDTH = C_IP1_AXI_DATA_WIDTH >> 3;
`endif
`ifdef IP2_ENABLE
  localparam C_IP2_AXI_DATA_WIDTH = `IP2_DATA_WIDTH;
  localparam C_IP2_AXI_ADDR_WIDTH = `IP2_ADDR_WIDTH;
  localparam C_IP2_AXI_STRB_WIDTH = C_IP2_AXI_DATA_WIDTH >> 3;
`endif
`ifdef BP0_ENABLE
  localparam C_BP0_AXI_DATA_WIDTH = `BP0_DATA_WIDTH;
  localparam C_BP0_AXI_ADDR_WIDTH = `BP0_ADDR_WIDTH;
  localparam C_BP0_AXI_STRB_WIDTH = C_BP0_AXI_DATA_WIDTH >> 3;
`endif
`ifdef BP1_ENABLE
  localparam C_BP1_AXI_DATA_WIDTH = `BP1_DATA_WIDTH;
  localparam C_BP1_AXI_ADDR_WIDTH = `BP1_ADDR_WIDTH;
  localparam C_BP1_AXI_STRB_WIDTH = C_BP1_AXI_DATA_WIDTH >> 3;
`endif
`ifdef BP2_ENABLE
  localparam C_BP2_AXI_DATA_WIDTH = `BP2_DATA_WIDTH;
  localparam C_BP2_AXI_ADDR_WIDTH = `BP2_ADDR_WIDTH;
  localparam C_BP2_AXI_STRB_WIDTH = C_BP2_AXI_DATA_WIDTH >> 3;
`endif
`ifdef HP0_ENABLE
  localparam C_HP0_AXI_DATA_WIDTH = `HP0_DATA_WIDTH;
  localparam C_HP0_AXI_ADDR_WIDTH = `HP0_ADDR_WIDTH;
  localparam C_HP0_AXI_STRB_WIDTH = C_HP0_AXI_DATA_WIDTH >> 3;
`endif
`ifdef HP1_ENABLE
  localparam C_HP1_AXI_DATA_WIDTH = `HP1_DATA_WIDTH;
  localparam C_HP1_AXI_ADDR_WIDTH = `HP1_ADDR_WIDTH;
  localparam C_HP1_AXI_STRB_WIDTH = C_HP1_AXI_DATA_WIDTH >> 3;
`endif
`ifdef HP2_ENABLE
  localparam C_HP2_AXI_DATA_WIDTH = `HP2_DATA_WIDTH;
  localparam C_HP2_AXI_ADDR_WIDTH = `HP2_ADDR_WIDTH;
  localparam C_HP2_AXI_STRB_WIDTH = C_HP2_AXI_DATA_WIDTH >> 3;
`endif
`ifdef SP0_ENABLE
  localparam C_SP0_AXI_DATA_WIDTH = `SP0_DATA_WIDTH;
  localparam C_SP0_AXI_STRB_WIDTH = C_SP0_AXI_DATA_WIDTH >> 3;
`endif
`ifdef SP1_ENABLE
  localparam C_SP1_AXI_DATA_WIDTH = `SP1_DATA_WIDTH;
  localparam C_SP1_AXI_STRB_WIDTH = C_SP1_AXI_DATA_WIDTH >> 3;
`endif
`ifdef SP2_ENABLE
  localparam C_SP2_AXI_DATA_WIDTH = `SP2_DATA_WIDTH;
  localparam C_SP2_AXI_STRB_WIDTH = C_SP2_AXI_DATA_WIDTH >> 3;
`endif
`ifdef MP0_ENABLE
  localparam C_MP0_AXI_DATA_WIDTH = `MP0_DATA_WIDTH;
  localparam C_MP0_AXI_STRB_WIDTH = C_MP0_AXI_DATA_WIDTH >> 3;
`endif
`ifdef MP1_ENABLE
  localparam C_MP1_AXI_DATA_WIDTH = `MP1_DATA_WIDTH;
  localparam C_MP1_AXI_STRB_WIDTH = C_MP1_AXI_DATA_WIDTH >> 3;
`endif
`ifdef MP2_ENABLE
  localparam C_MP2_AXI_DATA_WIDTH = `MP2_DATA_WIDTH;
  localparam C_MP2_AXI_STRB_WIDTH = C_MP2_AXI_DATA_WIDTH >> 3;
`endif

  localparam aclk_period_lp = 50000;
  logic aclk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(aclk_period_lp))
   aclk_gen
    (.o(aclk));

  logic core_clk;
`ifdef ASYNC_ACLK_CORE_CLK
  localparam aclk_period_lp = 40000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(core_clk_period_lp))
   core_clk_gen
    (.o(core_clk));
`elsif
  assign core_clk = aclk;
`endif

  logic areset;
  bsg_nonsynth_reset_gen
   #(.reset_cycles_lo_p(0), .reset_cycles_hi_p(10))
   reset_gen
    (.clk_i(aclk), .async_reset_o(areset));
  wire aresetn = ~areset;

  localparam rt_clk_period_lp = 2500000;
  logic rt_clk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(rt_clk_period_lp))
   rt_clk_gen
    (.o(rt_clk));

  logic tag_ck, tag_data, sys_resetn;

`ifdef GP0_ENABLE
  logic [C_GP0_AXI_ADDR_WIDTH-1:0] gp0_axi_awaddr;
  logic gp0_axi_awvalid, gp0_axi_awready;
  logic [C_GP0_AXI_DATA_WIDTH-1:0] gp0_axi_wdata;
  logic [C_GP0_AXI_STRB_WIDTH-1:0] gp0_axi_wstrb;
  logic gp0_axi_wvalid, gp0_axi_wready;
  logic [1:0] gp0_axi_bresp;
  logic gp0_axi_bvalid, gp0_axi_bready;
  logic [C_GP0_AXI_ADDR_WIDTH-1:0] gp0_axi_araddr;
  logic gp0_axi_arvalid, gp0_axi_arready;
  logic [C_GP0_AXI_DATA_WIDTH-1:0] gp0_axi_rdata;
  logic [1:0] gp0_axi_rresp;
  logic gp0_axi_rvalid, gp0_axi_rready;
  bsg_nonsynth_dpi_to_axil
   #(.addr_width_p(C_GP0_AXI_ADDR_WIDTH), .data_width_p(C_GP0_AXI_DATA_WIDTH))
   axil0
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_o(gp0_axi_awaddr)
     ,.awvalid_o(gp0_axi_awvalid)
     ,.awready_i(gp0_axi_awready)
     ,.wdata_o(gp0_axi_wdata)
     ,.wstrb_o(gp0_axi_wstrb)
     ,.wvalid_o(gp0_axi_wvalid)
     ,.wready_i(gp0_axi_wready)
     ,.bresp_i(gp0_axi_bresp)
     ,.bvalid_i(gp0_axi_bvalid)
     ,.bready_o(gp0_axi_bready)

     ,.araddr_o(gp0_axi_araddr)
     ,.arvalid_o(gp0_axi_arvalid)
     ,.arready_i(gp0_axi_arready)
     ,.rdata_i(gp0_axi_rdata)
     ,.rresp_i(gp0_axi_rresp)
     ,.rvalid_i(gp0_axi_rvalid)
     ,.rready_o(gp0_axi_rready)
     );
`endif

`ifdef GP1_ENABLE
  logic [C_GP1_AXI_ADDR_WIDTH-1:0] gp1_axi_awaddr;
  logic gp1_axi_awvalid, gp1_axi_awready;
  logic [C_GP1_AXI_DATA_WIDTH-1:0] gp1_axi_wdata;
  logic [C_GP1_AXI_STRB_WIDTH-1:0] gp1_axi_wstrb;
  logic gp1_axi_wvalid, gp1_axi_wready;
  logic [1:0] gp1_axi_bresp;
  logic gp1_axi_bvalid, gp1_axi_bready;
  logic [C_GP1_AXI_ADDR_WIDTH-1:0] gp1_axi_araddr;
  logic gp1_axi_arvalid, gp1_axi_arready;
  logic [C_GP1_AXI_DATA_WIDTH-1:0] gp1_axi_rdata;
  logic [1:0] gp1_axi_rresp;
  logic gp1_axi_rvalid, gp1_axi_rready;
  bsg_nonsynth_dpi_to_axil
   #(.addr_width_p(C_GP1_AXI_ADDR_WIDTH), .data_width_p(C_GP1_AXI_DATA_WIDTH))
   axil1
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_o(gp1_axi_awaddr)
     ,.awvalid_o(gp1_axi_awvalid)
     ,.awready_i(gp1_axi_awready)
     ,.wdata_o(gp1_axi_wdata)
     ,.wstrb_o(gp1_axi_wstrb)
     ,.wvalid_o(gp1_axi_wvalid)
     ,.wready_i(gp1_axi_wready)
     ,.bresp_i(gp1_axi_bresp)
     ,.bvalid_i(gp1_axi_bvalid)
     ,.bready_o(gp1_axi_bready)

     ,.araddr_o(gp1_axi_araddr)
     ,.arvalid_o(gp1_axi_arvalid)
     ,.arready_i(gp1_axi_arready)
     ,.rdata_i(gp1_axi_rdata)
     ,.rresp_i(gp1_axi_rresp)
     ,.rvalid_i(gp1_axi_rvalid)
     ,.rready_o(gp1_axi_rready)
     );
`endif

`ifdef GP2_ENABLE
  logic [C_GP2_AXI_ADDR_WIDTH-1:0] gp2_axi_awaddr;
  logic gp2_axi_awvalid, gp2_axi_awready;
  logic [C_GP2_AXI_DATA_WIDTH-1:0] gp2_axi_wdata;
  logic [C_GP2_AXI_STRB_WIDTH-1:0] gp2_axi_wstrb;
  logic gp2_axi_wvalid, gp2_axi_wready;
  logic [1:0] gp2_axi_bresp;
  logic gp2_axi_bvalid, gp2_axi_bready;
  logic [C_GP2_AXI_ADDR_WIDTH-1:0] gp2_axi_araddr;
  logic gp2_axi_arvalid, gp2_axi_arready;
  logic [C_GP2_AXI_DATA_WIDTH-1:0] gp2_axi_rdata;
  logic [1:0] gp2_axi_rresp;
  logic gp2_axi_rvalid, gp2_axi_rready;
  bsg_nonsynth_dpi_to_axil
   #(.addr_width_p(C_GP2_AXI_ADDR_WIDTH), .data_width_p(C_GP2_AXI_DATA_WIDTH))
   axil2
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_o(gp2_axi_awaddr)
     ,.awvalid_o(gp2_axi_awvalid)
     ,.awready_i(gp2_axi_awready)
     ,.wdata_o(gp2_axi_wdata)
     ,.wstrb_o(gp2_axi_wstrb)
     ,.wvalid_o(gp2_axi_wvalid)
     ,.wready_i(gp2_axi_wready)
     ,.bresp_i(gp2_axi_bresp)
     ,.bvalid_i(gp2_axi_bvalid)
     ,.bready_o(gp2_axi_bready)

     ,.araddr_o(gp2_axi_araddr)
     ,.arvalid_o(gp2_axi_arvalid)
     ,.arready_i(gp2_axi_arready)
     ,.rdata_i(gp2_axi_rdata)
     ,.rresp_i(gp2_axi_rresp)
     ,.rvalid_i(gp2_axi_rvalid)
     ,.rready_o(gp2_axi_rready)
     );
`endif

`ifdef IP0_ENABLE
  logic [C_IP0_AXI_ADDR_WIDTH-1:0] ip0_axi_awaddr;
  logic ip0_axi_awvalid, ip0_axi_awready;
  logic [C_IP0_AXI_DATA_WIDTH-1:0] ip0_axi_wdata;
  logic [C_IP0_AXI_STRB_WIDTH-1:0] ip0_axi_wstrb;
  logic ip0_axi_wvalid, ip0_axi_wready;
  logic [1:0] ip0_axi_bresp;
  logic ip0_axi_bvalid, ip0_axi_bready;
  logic [C_IP0_AXI_ADDR_WIDTH-1:0] ip0_axi_araddr;
  logic ip0_axi_arvalid, ip0_axi_arready;
  logic [C_IP0_AXI_DATA_WIDTH-1:0] ip0_axi_rdata;
  logic [1:0] ip0_axi_rresp;
  logic ip0_axi_rvalid, ip0_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_IP0_AXI_ADDR_WIDTH), .data_width_p(C_IP0_AXI_DATA_WIDTH))
   axil3
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(ip0_axi_awaddr)
     ,.awvalid_i(ip0_axi_awvalid)
     ,.awready_o(ip0_axi_awready)
     ,.wdata_i(ip0_axi_wdata)
     ,.wstrb_i(ip0_axi_wstrb)
     ,.wvalid_i(ip0_axi_wvalid)
     ,.wready_o(ip0_axi_wready)
     ,.bresp_o(ip0_axi_bresp)
     ,.bvalid_o(ip0_axi_bvalid)
     ,.bready_i(ip0_axi_bready)

     ,.araddr_i(ip0_axi_araddr)
     ,.arvalid_i(ip0_axi_arvalid)
     ,.arready_o(ip0_axi_arready)
     ,.rdata_o(ip0_axi_rdata)
     ,.rresp_o(ip0_axi_rresp)
     ,.rvalid_o(ip0_axi_rvalid)
     ,.rready_i(ip0_axi_rready)
     );
`endif

`ifdef IP1_ENABLE
  logic [C_IP1_AXI_ADDR_WIDTH-1:0] ip1_axi_awaddr;
  logic ip1_axi_awvalid, ip1_axi_awready;
  logic [C_IP1_AXI_DATA_WIDTH-1:0] ip1_axi_wdata;
  logic [C_IP1_AXI_STRB_WIDTH-1:0] ip1_axi_wstrb;
  logic ip1_axi_wvalid, ip1_axi_wready;
  logic [1:0] ip1_axi_bresp;
  logic ip1_axi_bvalid, ip1_axi_bready;
  logic [C_IP1_AXI_ADDR_WIDTH-1:0] ip1_axi_araddr;
  logic ip1_axi_arvalid, ip1_axi_arready;
  logic [C_IP1_AXI_DATA_WIDTH-1:0] ip1_axi_rdata;
  logic [1:0] ip1_axi_rresp;
  logic ip1_axi_rvalid, ip1_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_IP1_AXI_ADDR_WIDTH), .data_width_p(C_IP1_AXI_DATA_WIDTH))
   axil4
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(ip1_axi_awaddr)
     ,.awvalid_i(ip1_axi_awvalid)
     ,.awready_o(ip1_axi_awready)
     ,.wdata_i(ip1_axi_wdata)
     ,.wstrb_i(ip1_axi_wstrb)
     ,.wvalid_i(ip1_axi_wvalid)
     ,.wready_o(ip1_axi_wready)
     ,.bresp_o(ip1_axi_bresp)
     ,.bvalid_o(ip1_axi_bvalid)
     ,.bready_i(ip1_axi_bready)

     ,.araddr_i(ip1_axi_araddr)
     ,.arvalid_i(ip1_axi_arvalid)
     ,.arready_o(ip1_axi_arready)
     ,.rdata_o(ip1_axi_rdata)
     ,.rresp_o(ip1_axi_rresp)
     ,.rvalid_o(ip1_axi_rvalid)
     ,.rready_i(ip1_axi_rready)
     );
`endif

`ifdef IP2_ENABLE
  logic [C_IP2_AXI_ADDR_WIDTH-1:0] ip2_axi_awaddr;
  logic ip2_axi_awvalid, ip2_axi_awready;
  logic [C_IP2_AXI_DATA_WIDTH-1:0] ip2_axi_wdata;
  logic [C_IP2_AXI_STRB_WIDTH-1:0] ip2_axi_wstrb;
  logic ip2_axi_wvalid, ip2_axi_wready;
  logic [1:0] ip2_axi_bresp;
  logic ip2_axi_bvalid, ip2_axi_bready;
  logic [C_IP2_AXI_ADDR_WIDTH-1:0] ip2_axi_araddr;
  logic ip2_axi_arvalid, ip2_axi_arready;
  logic [C_IP2_AXI_DATA_WIDTH-1:0] ip2_axi_rdata;
  logic [1:0] ip2_axi_rresp;
  logic ip2_axi_rvalid, ip2_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_IP2_AXI_ADDR_WIDTH), .data_width_p(C_IP2_AXI_DATA_WIDTH))
   axil5
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(ip2_axi_awaddr)
     ,.awvalid_i(ip2_axi_awvalid)
     ,.awready_o(ip2_axi_awready)
     ,.wdata_i(ip2_axi_wdata)
     ,.wstrb_i(ip2_axi_wstrb)
     ,.wvalid_i(ip2_axi_wvalid)
     ,.wready_o(ip2_axi_wready)
     ,.bresp_o(ip2_axi_bresp)
     ,.bvalid_o(ip2_axi_bvalid)
     ,.bready_i(ip2_axi_bready)

     ,.araddr_i(ip2_axi_araddr)
     ,.arvalid_i(ip2_axi_arvalid)
     ,.arready_o(ip2_axi_arready)
     ,.rdata_o(ip2_axi_rdata)
     ,.rresp_o(ip2_axi_rresp)
     ,.rvalid_o(ip2_axi_rvalid)
     ,.rready_i(ip2_axi_rready)
     );
`endif

`ifdef BP0_ENABLE
  logic [C_BP0_AXI_ADDR_WIDTH-1:0]      bp0_axi_awaddr;
  logic [1:0]                           bp0_axi_awburst;
  logic [7:0]                           bp0_axi_awlen;
  logic                                 bp0_axi_awvalid;
  logic                                 bp0_axi_awready;

  logic [C_BP0_AXI_DATA_WIDTH-1:0]      bp0_axi_wdata;
  logic [C_BP0_AXI_STRB_WIDTH-1:0]      bp0_axi_wstrb;
  logic                                 bp0_axi_wlast;
  logic                                 bp0_axi_wvalid;
  logic                                 bp0_axi_wready;

  logic                                 bp0_axi_bvalid;
  logic                                 bp0_axi_bready;
  logic [0:0]                           bp0_axi_bid;
  logic [1:0]                           bp0_axi_bresp;

  logic [C_BP0_AXI_ADDR_WIDTH-1:0]      bp0_axi_araddr;
  logic [1:0]                           bp0_axi_arburst;
  logic [7:0]                           bp0_axi_arlen;
  logic                                 bp0_axi_arvalid;
  logic                                 bp0_axi_arready;
  logic [0:0]                           bp0_axi_arid;

  logic [C_BP0_AXI_DATA_WIDTH-1:0]      bp0_axi_rdata;
  logic                                 bp0_axi_rlast;
  logic                                 bp0_axi_rvalid;
  logic                                 bp0_axi_rready;
  logic [0:0]                           bp0_axi_rid;
  logic [1:0]                           bp0_axi_rresp;

  bsg_nonsynth_dpi_to_axi4
   #(.addr_width_p(C_BP0_AXI_ADDR_WIDTH), .data_width_p(C_BP0_AXI_DATA_WIDTH))
   axi6
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(bp0_axi_awaddr)
     ,.awburst_i(bp0_axi_awburst)
     ,.awlen_i(bp0_axi_awlen)
     ,.awvalid_i(bp0_axi_awvalid)
     ,.awready_o(bp0_axi_awready)
     ,.awid_i(bp0_axi_awid)

     ,.wdata_i(bp0_axi_wdata)
     ,.wstrb_i(bp0_axi_wstrb)
     ,.wlast_i(bp0_axi_wlast)
     ,.wvalid_i(bp0_axi_wvalid)
     ,.wready_o(bp0_axi_wready)

     ,.bvalid_o(bp0_axi_bvalid)
     ,.bready_i(bp0_axi_bready)
     ,.bid_o(bp0_axi_bid)
     ,.bresp_o(bp0_axi_bresp)

     ,.araddr_i(bp0_axi_araddr)
     ,.arburst_i(bp0_axi_arburst)
     ,.arlen_i(bp0_axi_arlen)
     ,.arvalid_i(bp0_axi_arvalid)
     ,.arready_o(bp0_axi_arready)
     ,.arid_i(bp0_axi_arid)

     ,.rdata_o(bp0_axi_rdata)
     ,.rlast_o(bp0_axi_rlast)
     ,.rvalid_o(bp0_axi_rvalid)
     ,.rready_i(bp0_axi_rready)
     ,.rid_o(bp0_axi_rid)
     ,.rresp_o(bp0_axi_rresp)
     );
`endif

`ifdef BP1_ENABLE
  logic [C_BP1_AXI_ADDR_WIDTH-1:0]      bp1_axi_awaddr;
  logic [1:0]                           bp1_axi_awburst;
  logic [7:0]                           bp1_axi_awlen;
  logic                                 bp1_axi_awvalid;
  logic                                 bp1_axi_awready;
  logic [0:0]                           bp1_axi_awid;

  logic [C_BP1_AXI_DATA_WIDTH-1:0]      bp1_axi_wdata;
  logic [C_BP1_AXI_STRB_WIDTH-1:0]      bp1_axi_wstrb;
  logic                                 bp1_axi_wlast;
  logic                                 bp1_axi_wvalid;
  logic                                 bp1_axi_wready;

  logic                                 bp1_axi_bvalid;
  logic                                 bp1_axi_bready;
  logic [0:0]                           bp1_axi_bid;
  logic [1:0]                           bp1_axi_bresp;

  logic [C_BP1_AXI_ADDR_WIDTH-1:0]      bp1_axi_araddr;
  logic [1:0]                           bp1_axi_arburst;
  logic [7:0]                           bp1_axi_arlen;
  logic                                 bp1_axi_arvalid;
  logic                                 bp1_axi_arready;
  logic [0:0]                           bp1_axi_arid;

  logic [C_BP1_AXI_DATA_WIDTH-1:0]      bp1_axi_rdata;
  logic                                 bp1_axi_rlast;
  logic                                 bp1_axi_rvalid;
  logic                                 bp1_axi_rready;
  logic [0:0]                           bp1_axi_rid;
  logic [1:0]                           bp1_axi_rresp;

  bsg_nonsynth_dpi_to_axi4
   #(.addr_width_p(C_BP1_AXI_ADDR_WIDTH), .data_width_p(C_BP1_AXI_DATA_WIDTH))
   axi7
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(bp1_axi_awaddr)
     ,.awburst_i(bp1_axi_awburst)
     ,.awlen_i(bp1_axi_awlen)
     ,.awvalid_i(bp1_axi_awvalid)
     ,.awready_o(bp1_axi_awready)
     ,.awid_i(bp1_axi_awid)

     ,.wdata_i(bp1_axi_wdata)
     ,.wstrb_i(bp1_axi_wstrb)
     ,.wlast_i(bp1_axi_wlast)
     ,.wvalid_i(bp1_axi_wvalid)
     ,.wready_o(bp1_axi_wready)

     ,.bvalid_o(bp1_axi_bvalid)
     ,.bready_i(bp1_axi_bready)
     ,.bid_o(bp1_axi_bid)
     ,.bresp_o(bp1_axi_bresp)

     ,.araddr_i(bp1_axi_araddr)
     ,.arburst_i(bp1_axi_arburst)
     ,.arlen_i(bp1_axi_arlen)
     ,.arvalid_i(bp1_axi_arvalid)
     ,.arready_o(bp1_axi_arready)
     ,.arid_i(bp1_axi_arid)

     ,.rdata_o(bp1_axi_rdata)
     ,.rlast_o(bp1_axi_rlast)
     ,.rvalid_o(bp1_axi_rvalid)
     ,.rready_i(bp1_axi_rready)
     ,.rid_o(bp1_axi_rid)
     ,.rresp_o(bp1_axi_rresp)
     );
`endif

`ifdef BP2_ENABLE
  logic [C_BP2_AXI_ADDR_WIDTH-1:0]      bp2_axi_awaddr;
  logic [1:0]                           bp2_axi_awburst;
  logic [7:0]                           bp2_axi_awlen;
  logic                                 bp2_axi_awvalid;
  logic                                 bp2_axi_awready;
  logic [0:0]                           bp2_axi_awid;

  logic [C_BP2_AXI_DATA_WIDTH-1:0]      bp2_axi_wdata;
  logic [C_BP2_AXI_STRB_WIDTH-1:0]      bp2_axi_wstrb;
  logic                                 bp2_axi_wlast;
  logic                                 bp2_axi_wvalid;
  logic                                 bp2_axi_wready;

  logic                                 bp2_axi_bvalid;
  logic                                 bp2_axi_bready;
  logic [0:0]                           bp2_axi_bid;
  logic [1:0]                           bp2_axi_bresp;

  logic [C_BP2_AXI_ADDR_WIDTH-1:0]      bp2_axi_araddr;
  logic [1:0]                           bp2_axi_arburst;
  logic [7:0]                           bp2_axi_arlen;
  logic                                 bp2_axi_arvalid;
  logic                                 bp2_axi_arready;
  logic [0:0]                           bp2_axi_arid;

  logic [C_BP2_AXI_DATA_WIDTH-1:0]      bp2_axi_rdata;
  logic                                 bp2_axi_rlast;
  logic                                 bp2_axi_rvalid;
  logic                                 bp2_axi_rready;
  logic [0:0]                           bp2_axi_rid;
  logic [1:0]                           bp2_axi_rresp;

  bsg_nonsynth_dpi_to_axi4
   #(.addr_width_p(C_BP2_AXI_ADDR_WIDTH), .data_width_p(C_BP2_AXI_DATA_WIDTH))
   axi8
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(bp2_axi_awaddr)
     ,.awburst_i(bp2_axi_awburst)
     ,.awlen_i(bp2_axi_awlen)
     ,.awvalid_i(bp2_axi_awvalid)
     ,.awready_o(bp2_axi_awready)
     ,.awid_i(bp2_axi_awid)

     ,.wdata_i(bp2_axi_wdata)
     ,.wstrb_i(bp2_axi_wstrb)
     ,.wlast_i(bp2_axi_wlast)
     ,.wvalid_i(bp2_axi_wvalid)
     ,.wready_o(bp2_axi_wready)

     ,.bvalid_o(bp2_axi_bvalid)
     ,.bready_i(bp2_axi_bready)
     ,.bid_o(bp2_axi_bid)
     ,.bresp_o(bp2_axi_bresp)

     ,.araddr_i(bp2_axi_araddr)
     ,.arburst_i(bp2_axi_arburst)
     ,.arlen_i(bp2_axi_arlen)
     ,.arvalid_i(bp2_axi_arvalid)
     ,.arready_o(bp2_axi_arready)
     ,.arid_i(bp2_axi_arid)

     ,.rdata_o(bp2_axi_rdata)
     ,.rlast_o(bp2_axi_rlast)
     ,.rvalid_o(bp2_axi_rvalid)
     ,.rready_i(bp2_axi_rready)
     ,.rid_o(bp2_axi_rid)
     ,.rresp_o(bp2_axi_rresp)
     );
`endif

`ifdef HP0_ENABLE
  logic [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_awaddr;
  logic [1:0]                           hp0_axi_awburst;
  logic [7:0]                           hp0_axi_awlen;
  logic                                 hp0_axi_awvalid;
  logic                                 hp0_axi_awready;
  logic [0:0]                           hp0_axi_awid;

  logic [C_HP0_AXI_DATA_WIDTH-1:0]      hp0_axi_wdata;
  logic [C_HP0_AXI_STRB_WIDTH-1:0]      hp0_axi_wstrb;
  logic                                 hp0_axi_wlast;
  logic                                 hp0_axi_wvalid;
  logic                                 hp0_axi_wready;

  logic                                 hp0_axi_bvalid;
  logic                                 hp0_axi_bready;
  logic [0:0]                           hp0_axi_bid;
  logic [1:0]                           hp0_axi_bresp;

  logic [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_araddr;
  logic [1:0]                           hp0_axi_arburst;
  logic [7:0]                           hp0_axi_arlen;
  logic                                 hp0_axi_arvalid;
  logic                                 hp0_axi_arready;
  logic [0:0]                           hp0_axi_arid;

  logic [C_HP0_AXI_DATA_WIDTH-1:0]      hp0_axi_rdata;
  logic                                 hp0_axi_rlast;
  logic                                 hp0_axi_rvalid;
  logic                                 hp0_axi_rready;
  logic [0:0]                           hp0_axi_rid;
  logic [1:0]                           hp0_axi_rresp;

  bsg_nonsynth_axi4_to_dpi
   #(.addr_width_p(C_HP0_AXI_ADDR_WIDTH), .data_width_p(C_HP0_AXI_DATA_WIDTH))
   axi9
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(hp0_axi_awaddr)
     ,.awburst_i(hp0_axi_awburst)
     ,.awlen_i(hp0_axi_awlen)
     ,.awvalid_i(hp0_axi_awvalid)
     ,.awready_o(hp0_axi_awready)
     ,.awid_i(hp0_axi_awid)

     ,.wdata_i(hp0_axi_wdata)
     ,.wstrb_i(hp0_axi_wstrb)
     ,.wlast_i(hp0_axi_wlast)
     ,.wvalid_i(hp0_axi_wvalid)
     ,.wready_o(hp0_axi_wready)

     ,.bvalid_o(hp0_axi_bvalid)
     ,.bready_i(hp0_axi_bready)
     ,.bid_o(hp0_axi_bid)
     ,.bresp_o(hp0_axi_bresp)

     ,.araddr_i(hp0_axi_araddr)
     ,.arburst_i(hp0_axi_arburst)
     ,.arlen_i(hp0_axi_arlen)
     ,.arvalid_i(hp0_axi_arvalid)
     ,.arready_o(hp0_axi_arready)
     ,.arid_i(hp0_axi_arid)

     ,.rdata_o(hp0_axi_rdata)
     ,.rlast_o(hp0_axi_rlast)
     ,.rvalid_o(hp0_axi_rvalid)
     ,.rready_i(hp0_axi_rready)
     ,.rid_o(hp0_axi_rid)
     ,.rresp_o(hp0_axi_rresp)
     );
`endif

`ifdef HP1_ENABLE
  logic [C_HP1_AXI_ADDR_WIDTH-1:0]      hp1_axi_awaddr;
  logic [1:0]                           hp1_axi_awburst;
  logic [7:0]                           hp1_axi_awlen;
  logic                                 hp1_axi_awvalid;
  logic                                 hp1_axi_awready;
  logic [0:0]                           hp1_axi_awid;

  logic [C_HP1_AXI_DATA_WIDTH-1:0]      hp1_axi_wdata;
  logic [C_HP1_AXI_STRB_WIDTH-1:0]      hp1_axi_wstrb;
  logic                                 hp1_axi_wlast;
  logic                                 hp1_axi_wvalid;
  logic                                 hp1_axi_wready;

  logic                                 hp1_axi_bvalid;
  logic                                 hp1_axi_bready;
  logic [0:0]                           hp1_axi_bid;
  logic [1:0]                           hp1_axi_bresp;

  logic [C_HP1_AXI_ADDR_WIDTH-1:0]      hp1_axi_araddr;
  logic [1:0]                           hp1_axi_arburst;
  logic [7:0]                           hp1_axi_arlen;
  logic                                 hp1_axi_arvalid;
  logic                                 hp1_axi_arready;
  logic [0:0]                           hp1_axi_arid;

  logic [C_HP1_AXI_DATA_WIDTH-1:0]      hp1_axi_rdata;
  logic                                 hp1_axi_rlast;
  logic                                 hp1_axi_rvalid;
  logic                                 hp1_axi_rready;
  logic [0:0]                           hp1_axi_rid;
  logic [1:0]                           hp1_axi_rresp;

  bsg_nonsynth_axi4_to_dpi
   #(.addr_width_p(C_HP1_AXI_ADDR_WIDTH), .data_width_p(C_HP1_AXI_DATA_WIDTH))
   axi10
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(hp1_axi_awaddr)
     ,.awburst_i(hp1_axi_awburst)
     ,.awlen_i(hp1_axi_awlen)
     ,.awvalid_i(hp1_axi_awvalid)
     ,.awready_o(hp1_axi_awready)
     ,.awid_i(hp1_axi_awid)

     ,.wdata_i(hp1_axi_wdata)
     ,.wstrb_i(hp1_axi_wstrb)
     ,.wlast_i(hp1_axi_wlast)
     ,.wvalid_i(hp1_axi_wvalid)
     ,.wready_o(hp1_axi_wready)

     ,.bvalid_o(hp1_axi_bvalid)
     ,.bready_i(hp1_axi_bready)
     ,.bid_o(hp1_axi_bid)
     ,.bresp_o(hp1_axi_bresp)

     ,.araddr_i(hp1_axi_araddr)
     ,.arburst_i(hp1_axi_arburst)
     ,.arlen_i(hp1_axi_arlen)
     ,.arvalid_i(hp1_axi_arvalid)
     ,.arready_o(hp1_axi_arready)
     ,.arid_i(hp1_axi_arid)

     ,.rdata_o(hp1_axi_rdata)
     ,.rlast_o(hp1_axi_rlast)
     ,.rvalid_o(hp1_axi_rvalid)
     ,.rready_i(hp1_axi_rready)
     ,.rid_o(hp1_axi_rid)
     ,.rresp_o(hp1_axi_rresp)
     );
`endif

`ifdef HP2_ENABLE
  logic [C_HP2_AXI_ADDR_WIDTH-1:0]      hp2_axi_awaddr;
  logic [1:0]                           hp2_axi_awburst;
  logic [7:0]                           hp2_axi_awlen;
  logic                                 hp2_axi_awvalid;
  logic                                 hp2_axi_awready;
  logic [0:0]                           hp2_axi_awid;

  logic [C_HP2_AXI_DATA_WIDTH-1:0]      hp2_axi_wdata;
  logic [C_HP2_AXI_STRB_WIDTH-1:0]      hp2_axi_wstrb;
  logic                                 hp2_axi_wlast;
  logic                                 hp2_axi_wvalid;
  logic                                 hp2_axi_wready;

  logic                                 hp2_axi_bvalid;
  logic                                 hp2_axi_bready;
  logic [0:0]                           hp2_axi_bid;
  logic [1:0]                           hp2_axi_bresp;

  logic [C_HP2_AXI_ADDR_WIDTH-1:0]      hp2_axi_araddr;
  logic [1:0]                           hp2_axi_arburst;
  logic [7:0]                           hp2_axi_arlen;
  logic                                 hp2_axi_arvalid;
  logic                                 hp2_axi_arready;
  logic [0:0]                           hp2_axi_arid;

  logic [C_HP2_AXI_DATA_WIDTH-1:0]      hp2_axi_rdata;
  logic                                 hp2_axi_rlast;
  logic                                 hp2_axi_rvalid;
  logic                                 hp2_axi_rready;
  logic [0:0]                           hp2_axi_rid;
  logic [1:0]                           hp2_axi_rresp;

  bsg_nonsynth_axi4_to_dpi
   #(.addr_width_p(C_HP2_AXI_ADDR_WIDTH), .data_width_p(C_HP2_AXI_DATA_WIDTH))
   axi11
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(hp2_axi_awaddr)
     ,.awburst_i(hp2_axi_awburst)
     ,.awlen_i(hp2_axi_awlen)
     ,.awvalid_i(hp2_axi_awvalid)
     ,.awready_o(hp2_axi_awready)
     ,.awid_i(hp2_axi_awid)

     ,.wdata_i(hp2_axi_wdata)
     ,.wstrb_i(hp2_axi_wstrb)
     ,.wlast_i(hp2_axi_wlast)
     ,.wvalid_i(hp2_axi_wvalid)
     ,.wready_o(hp2_axi_wready)

     ,.bvalid_o(hp2_axi_bvalid)
     ,.bready_i(hp2_axi_bready)
     ,.bid_o(hp2_axi_bid)
     ,.bresp_o(hp2_axi_bresp)

     ,.araddr_i(hp2_axi_araddr)
     ,.arburst_i(hp2_axi_arburst)
     ,.arlen_i(hp2_axi_arlen)
     ,.arvalid_i(hp2_axi_arvalid)
     ,.arready_o(hp2_axi_arready)
     ,.arid_i(hp2_axi_arid)

     ,.rdata_o(hp2_axi_rdata)
     ,.rlast_o(hp2_axi_rlast)
     ,.rvalid_o(hp2_axi_rvalid)
     ,.rready_i(hp2_axi_rready)
     ,.rid_o(hp2_axi_rid)
     ,.rresp_o(hp2_axi_rresp)
     );
`endif

`ifdef SP0_ENABLE
  logic sp0_axi_tvalid, sp0_axi_tready;
  logic [C_SP0_AXI_DATA_WIDTH-1:0] sp0_axi_tdata;
  logic sp0_axi_tlast;
  bsg_nonsynth_dpi_to_axis
   #(.data_width_p(C_SP0_AXI_DATA_WIDTH))
   axis12
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_o(sp0_axi_tdata)
     ,.tvalid_o(sp0_axi_tvalid)
     ,.tlast_o(sp0_axi_tlast)
     ,.tready_i(sp0_axi_tready)
     );
`endif

`ifdef SP1_ENABLE
  logic sp1_axi_tvalid, sp1_axi_tready;
  logic [C_SP1_AXI_DATA_WIDTH-1:0] sp1_axi_tdata;
  logic sp1_axi_tlast;
  bsg_nonsynth_dpi_to_axis
   #(.data_width_p(C_SP1_AXI_DATA_WIDTH))
   axis13
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_o(sp1_axi_tdata)
     ,.tvalid_o(sp1_axi_tvalid)
     ,.tlast_o(sp1_axi_tlast)
     ,.tready_i(sp1_axi_tready)
     );
`endif

`ifdef SP2_ENABLE
  logic sp2_axi_tvalid, sp2_axi_tready;
  logic [C_SP2_AXI_DATA_WIDTH-1:0] sp2_axi_tdata;
  logic sp2_axi_tlast;
  bsg_nonsynth_dpi_to_axis
   #(.data_width_p(C_SP2_AXI_DATA_WIDTH))
   axis14
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_o(sp2_axi_tdata)
     ,.tvalid_o(sp2_axi_tvalid)
     ,.tlast_o(sp2_axi_tlast)
     ,.tready_i(sp2_axi_tready)
     );
`endif

`ifdef MP0_ENABLE
  logic mp0_axi_tvalid, mp0_axi_tready;
  logic [C_MP0_AXI_DATA_WIDTH-1:0] mp0_axi_tdata;
  logic mp0_axi_tlast;
  bsg_nonsynth_axis_to_dpi
   #(.data_width_p(C_MP0_AXI_DATA_WIDTH))
   axis15
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_i(mp0_axi_tdata)
     ,.tvalid_i(mp0_axi_tvalid)
     ,.tready_o(mp0_axi_tready)
     ,.tlast_i(mp0_axi_tlast)
     );
`endif

`ifdef MP1_ENABLE
  logic mp1_axi_tvalid, mp1_axi_tready;
  logic [C_MP1_AXI_DATA_WIDTH-1:0] mp1_axi_tdata;
  logic mp1_axi_tlast;
  bsg_nonsynth_axis_to_dpi
   #(.data_width_p(C_MP1_AXI_DATA_WIDTH))
   axis16
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_i(mp1_axi_tdata)
     ,.tvalid_i(mp1_axi_tvalid)
     ,.tready_o(mp1_axi_tready)
     ,.tlast_i(mp1_axi_tlast)
     );
`endif

`ifdef MP2_ENABLE
  logic mp2_axi_tvalid, mp2_axi_tready;
  logic [C_MP2_AXI_DATA_WIDTH-1:0] mp2_axi_tdata;
  logic mp2_axi_tlast;
  bsg_nonsynth_axis_to_dpi
   #(.data_width_p(C_MP2_AXI_DATA_WIDTH))
   axis17
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_i(mp2_axi_tdata)
     ,.tvalid_i(mp2_axi_tvalid)
     ,.tready_o(mp2_axi_tready)
     ,.tlast_i(mp2_axi_tlast)
     );
`endif

  top #(
`ifdef GP0_ENABLE
     .C_GP0_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH),
     .C_GP0_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH),
`endif
`ifdef GP1_ENABLE
     .C_GP1_AXI_DATA_WIDTH(C_GP1_AXI_DATA_WIDTH),
     .C_GP1_AXI_ADDR_WIDTH(C_GP1_AXI_ADDR_WIDTH),
`endif
`ifdef GP2_ENABLE
     .C_GP2_AXI_DATA_WIDTH(C_GP2_AXI_DATA_WIDTH),
     .C_GP2_AXI_ADDR_WIDTH(C_GP2_AXI_ADDR_WIDTH),
`endif
`ifdef IP0_ENABLE
     .C_IP0_AXI_DATA_WIDTH(C_IP0_AXI_DATA_WIDTH),
     .C_IP0_AXI_ADDR_WIDTH(C_IP0_AXI_ADDR_WIDTH),
`endif
`ifdef IP1_ENABLE
     .C_IP1_AXI_DATA_WIDTH(C_IP1_AXI_DATA_WIDTH),
     .C_IP1_AXI_ADDR_WIDTH(C_IP1_AXI_ADDR_WIDTH),
`endif
`ifdef IP2_ENABLE
     .C_IP2_AXI_DATA_WIDTH(C_IP2_AXI_DATA_WIDTH),
     .C_IP2_AXI_ADDR_WIDTH(C_IP2_AXI_ADDR_WIDTH),
`endif
`ifdef BP0_ENABLE
     .C_BP0_AXI_DATA_WIDTH(C_BP0_AXI_DATA_WIDTH),
     .C_BP0_AXI_ADDR_WIDTH(C_BP0_AXI_ADDR_WIDTH),
`endif
`ifdef BP1_ENABLE
     .C_BP1_AXI_DATA_WIDTH(C_BP1_AXI_DATA_WIDTH),
     .C_BP1_AXI_ADDR_WIDTH(C_BP1_AXI_ADDR_WIDTH),
`endif
`ifdef BP2_ENABLE
     .C_BP2_AXI_DATA_WIDTH(C_BP2_AXI_DATA_WIDTH),
     .C_BP2_AXI_ADDR_WIDTH(C_BP2_AXI_ADDR_WIDTH),
`endif
`ifdef HP0_ENABLE
     .C_HP0_AXI_DATA_WIDTH(C_HP0_AXI_DATA_WIDTH),
     .C_HP0_AXI_ADDR_WIDTH(C_HP0_AXI_ADDR_WIDTH),
`endif
`ifdef HP1_ENABLE
     .C_HP1_AXI_DATA_WIDTH(C_HP1_AXI_DATA_WIDTH),
     .C_HP1_AXI_ADDR_WIDTH(C_HP1_AXI_ADDR_WIDTH),
`endif
`ifdef HP2_ENABLE
     .C_HP2_AXI_DATA_WIDTH(C_HP2_AXI_DATA_WIDTH),
     .C_HP2_AXI_ADDR_WIDTH(C_HP2_AXI_ADDR_WIDTH),
`endif
`ifdef SP0_ENABLE
     .C_SP0_AXI_DATA_WIDTH(C_SP0_AXI_DATA_WIDTH),
`endif
`ifdef SP1_ENABLE
     .C_SP1_AXI_DATA_WIDTH(C_SP1_AXI_DATA_WIDTH),
`endif
`ifdef SP2_ENABLE
     .C_SP2_AXI_DATA_WIDTH(C_SP2_AXI_DATA_WIDTH),
`endif
`ifdef MP0_ENABLE
     .C_MP0_AXI_DATA_WIDTH(C_MP0_AXI_DATA_WIDTH),
`endif
`ifdef MP1_ENABLE
     .C_MP1_AXI_DATA_WIDTH(C_MP1_AXI_DATA_WIDTH),
`endif
`ifdef MP2_ENABLE
     .C_MP2_AXI_DATA_WIDTH(C_MP2_AXI_DATA_WIDTH),
`endif
     .__DUMMY(0)
     )
   dut
    (.*);

`ifdef VERILATOR
   initial
     begin
   `ifdef FSTON
     if ($test$plusargs("bsg_trace") != 0)
       begin
         $display("[%0t] Tracing to dump.fst...\n", $time);
         $dumpfile("dump.fst");
         $dumpvars();
       end
   `endif
     end

   export "DPI-C" task bsg_dpi_next;
   task bsg_dpi_next();
     $error("BSG-ERROR: bsg_dpi_next should not be called from Verilator");
     bsg_dpi_finish("verilator next call");
   endtask
`else
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       $assertoff();
       @(posedge aclk);
       @(posedge aresetn);
       $asserton();
   `ifdef VCS
     `ifdef VCDPLUSON
       if ($test$plusargs("bsg_trace"))
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $vcdpluson();
           $vcdplusautoflushon();
         end
     `endif
   `endif
       if ($test$plusargs("c_args"))
         begin
           $value$plusargs("c_args=%s", c_args);
         end
       cosim_main(c_args);
       bsg_dpi_finish("cosim_main return");
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
     @(posedge aclk);
     #1;
   endtask
`endif

   export "DPI-C" function bsg_dpi_time;
   function int bsg_dpi_time();
     return int'($time);
   endfunction

   export "DPI-C" function bsg_dpi_finish;
   function void bsg_dpi_finish(string reason);
     $display("[BSG-INFO]: Finish called for reason: %s", reason);
     $finish;
   endfunction


endmodule

