
`timescale 1 ps / 1 ps
`include "bsg_defines.sv"

module bsg_nonsynth_zynq_testbench;

`ifdef GP0_ENABLE
  localparam C_GP0_AXI_DATA_WIDTH = `GP0_DATA_WIDTH;
  localparam C_GP0_AXI_ADDR_WIDTH = `GP0_ADDR_WIDTH;
`endif
`ifdef GP1_ENABLE
  localparam C_GP1_AXI_DATA_WIDTH = `GP1_DATA_WIDTH;
  localparam C_GP1_AXI_ADDR_WIDTH = `GP1_ADDR_WIDTH;
`endif
`ifdef GP2_ENABLE
  localparam C_GP2_AXI_DATA_WIDTH = `GP2_DATA_WIDTH;
  localparam C_GP2_AXI_ADDR_WIDTH = `GP2_ADDR_WIDTH;
`endif
`ifdef HP0_ENABLE
  localparam C_HP0_AXI_DATA_WIDTH = `HP0_DATA_WIDTH;
  localparam C_HP0_AXI_ADDR_WIDTH = `HP0_ADDR_WIDTH;
`endif
`ifdef HP1_ENABLE
  localparam C_HP1_AXI_DATA_WIDTH = `HP1_DATA_WIDTH;
  localparam C_HP1_AXI_ADDR_WIDTH = `HP1_ADDR_WIDTH;
`endif
`ifdef HP2_ENABLE
  localparam C_HP2_AXI_DATA_WIDTH = `HP2_DATA_WIDTH;
  localparam C_HP2_AXI_ADDR_WIDTH = `HP2_ADDR_WIDTH;
`endif
`ifdef SP0_ENABLE
  localparam C_SP0_AXI_DATA_WIDTH = `SP0_DATA_WIDTH;
`endif
`ifdef SP1_ENABLE
  localparam C_SP1_AXI_DATA_WIDTH = `SP1_DATA_WIDTH;
`endif
`ifdef SP2_ENABLE
  localparam C_SP2_AXI_DATA_WIDTH = `SP2_DATA_WIDTH;
`endif
`ifdef MP0_ENABLE
  localparam C_MP0_AXI_DATA_WIDTH = `MP0_DATA_WIDTH;
`endif
`ifdef MP1_ENABLE
  localparam C_MP1_AXI_DATA_WIDTH = `MP1_DATA_WIDTH;
`endif
`ifdef MP2_ENABLE
  localparam C_MP2_AXI_DATA_WIDTH = `MP2_DATA_WIDTH;
`endif

  localparam aclk_period_lp = 50000;
  logic aclk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(aclk_period_lp))
   aclk_gen
    (.o(aclk));

  logic core_clk;
`ifdef ASYNC_ACLK_CORE_CLK
  localparam core_clk_period_lp = 200000;
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
  logic [2:0] gp0_axi_awprot;
  logic gp0_axi_awvalid, gp0_axi_awready;
  logic [C_GP0_AXI_DATA_WIDTH-1:0] gp0_axi_wdata;
  logic [(C_GP0_AXI_DATA_WIDTH/8)-1:0] gp0_axi_wstrb;
  logic gp0_axi_wvalid, gp0_axi_wready;
  logic [1:0] gp0_axi_bresp;
  logic gp0_axi_bvalid, gp0_axi_bready;
  logic [C_GP0_AXI_ADDR_WIDTH-1:0] gp0_axi_araddr;
  logic [2:0] gp0_axi_arprot;
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
     ,.awprot_o(gp0_axi_awprot)
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
     ,.arprot_o(gp0_axi_arprot)
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
  logic [2:0] gp1_axi_awprot;
  logic gp1_axi_awvalid, gp1_axi_awready;
  logic [C_GP1_AXI_DATA_WIDTH-1:0] gp1_axi_wdata;
  logic [(C_GP1_AXI_DATA_WIDTH/8)-1:0] gp1_axi_wstrb;
  logic gp1_axi_wvalid, gp1_axi_wready;
  logic [1:0] gp1_axi_bresp;
  logic gp1_axi_bvalid, gp1_axi_bready;
  logic [C_GP1_AXI_ADDR_WIDTH-1:0] gp1_axi_araddr;
  logic [2:0] gp1_axi_arprot;
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
     ,.awprot_o(gp1_axi_awprot)
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
     ,.arprot_o(gp1_axi_arprot)
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
  logic [2:0] gp2_axi_awprot;
  logic gp2_axi_awvalid, gp2_axi_awready;
  logic [C_GP2_AXI_DATA_WIDTH-1:0] gp2_axi_wdata;
  logic [(C_GP2_AXI_DATA_WIDTH/8)-1:0] gp2_axi_wstrb;
  logic gp2_axi_wvalid, gp2_axi_wready;
  logic [1:0] gp2_axi_bresp;
  logic gp2_axi_bvalid, gp2_axi_bready;
  logic [C_GP2_AXI_ADDR_WIDTH-1:0] gp2_axi_araddr;
  logic [2:0] gp2_axi_arprot;
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
     ,.awprot_o(gp2_axi_awprot)
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
     ,.arprot_o(gp2_axi_arprot)
     ,.arvalid_o(gp2_axi_arvalid)
     ,.arready_i(gp2_axi_arready)
     ,.rdata_i(gp2_axi_rdata)
     ,.rresp_i(gp2_axi_rresp)
     ,.rvalid_i(gp2_axi_rvalid)
     ,.rready_o(gp2_axi_rready)
     );
`endif

`ifdef HP0_ENABLE
  logic [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_awaddr;
  logic                                 hp0_axi_awvalid;
  logic                                 hp0_axi_awready;
  logic [5:0]                           hp0_axi_awid;
  logic                                 hp0_axi_awlock;
  logic [3:0]                           hp0_axi_awcache;
  logic [2:0]                           hp0_axi_awprot;
  logic [7:0]                           hp0_axi_awlen;
  logic [2:0]                           hp0_axi_awsize;
  logic [1:0]                           hp0_axi_awburst;
  logic [3:0]                           hp0_axi_awqos;

  logic [C_HP0_AXI_DATA_WIDTH-1:0]      hp0_axi_wdata;
  logic                                 hp0_axi_wvalid;
  logic                                 hp0_axi_wready;
  logic [5:0]                           hp0_axi_wid;
  logic                                 hp0_axi_wlast;
  logic [(C_HP0_AXI_DATA_WIDTH/8)-1:0]  hp0_axi_wstrb;

  logic                                 hp0_axi_bvalid;
  logic                                 hp0_axi_bready;
  logic [5:0]                           hp0_axi_bid;
  logic [1:0]                           hp0_axi_bresp;

  logic [C_HP0_AXI_ADDR_WIDTH-1:0]      hp0_axi_araddr;
  logic                                 hp0_axi_arvalid;
  logic                                 hp0_axi_arready;
  logic [5:0]                           hp0_axi_arid;
  logic                                 hp0_axi_arlock;
  logic [3:0]                           hp0_axi_arcache;
  logic [2:0]                           hp0_axi_arprot;
  logic [7:0]                           hp0_axi_arlen;
  logic [2:0]                           hp0_axi_arsize;
  logic [1:0]                           hp0_axi_arburst;
  logic [3:0]                           hp0_axi_arqos;

  logic [C_HP0_AXI_DATA_WIDTH-1:0]      hp0_axi_rdata;
  logic                                 hp0_axi_rvalid;
  logic                                 hp0_axi_rready;
  logic [5:0]                           hp0_axi_rid;
  logic                                 hp0_axi_rlast;
  logic [1:0]                           hp0_axi_rresp;

`ifdef AXI_MEM_ENABLE
  bsg_nonsynth_axi_mem_dma
    #(.axi_id_width_p(6)
      ,.axi_addr_width_p(C_HP0_AXI_ADDR_WIDTH)
      ,.axi_data_width_p(C_HP0_AXI_DATA_WIDTH)
      ,.axi_len_width_p(8)
      ,.mem_els_p(2**28) // 256 MB
      ,.init_data_p('0)
    )
  axi_mem
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.axi_awid_i(hp0_axi_awid)
     ,.axi_awaddr_i(hp0_axi_awaddr)
     ,.axi_awlen_i(hp0_axi_awlen)
     ,.axi_awburst_i(hp0_axi_awburst)
     ,.axi_awvalid_i(hp0_axi_awvalid)
     ,.axi_awready_o(hp0_axi_awready)

     ,.axi_wdata_i(hp0_axi_wdata)
     ,.axi_wstrb_i(hp0_axi_wstrb)
     ,.axi_wlast_i(hp0_axi_wlast)
     ,.axi_wvalid_i(hp0_axi_wvalid)
     ,.axi_wready_o(hp0_axi_wready)

     ,.axi_bid_o(hp0_axi_bid)
     ,.axi_bresp_o(hp0_axi_bresp)
     ,.axi_bvalid_o(hp0_axi_bvalid)
     ,.axi_bready_i(hp0_axi_bready)

     ,.axi_arid_i(hp0_axi_arid)
     ,.axi_araddr_i(hp0_axi_araddr)
     ,.axi_arlen_i(hp0_axi_arlen)
     ,.axi_arburst_i(hp0_axi_arburst)
     ,.axi_arvalid_i(hp0_axi_arvalid)
     ,.axi_arready_o(hp0_axi_arready)

     ,.axi_rid_o(hp0_axi_rid)
     ,.axi_rdata_o(hp0_axi_rdata)
     ,.axi_rresp_o(hp0_axi_rresp)
     ,.axi_rlast_o(hp0_axi_rlast)
     ,.axi_rvalid_o(hp0_axi_rvalid)
     ,.axi_rready_i(hp0_axi_rready)
     );
`else
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_HP0_AXI_ADDR_WIDTH), .data_width_p(C_HP0_AXI_DATA_WIDTH))
   axil3
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(hp0_axi_awaddr)
     ,.awprot_i(hp0_axi_awprot)
     ,.awvalid_i(hp0_axi_awvalid)
     ,.awready_o(hp0_axi_awready)
     ,.wdata_i(hp0_axi_wdata)
     ,.wstrb_i(hp0_axi_wstrb)
     ,.wvalid_i(hp0_axi_wvalid)
     ,.wready_o(hp0_axi_wready)
     ,.bresp_o(hp0_axi_bresp)
     ,.bvalid_o(hp0_axi_bvalid)
     ,.bready_i(hp0_axi_bready)

     ,.araddr_i(hp0_axi_araddr)
     ,.arprot_i(hp0_axi_arprot)
     ,.arvalid_i(hp0_axi_arvalid)
     ,.arready_o(hp0_axi_arready)
     ,.rdata_o(hp0_axi_rdata)
     ,.rresp_o(hp0_axi_rresp)
     ,.rvalid_o(hp0_axi_rvalid)
     ,.rready_i(hp0_axi_rready)
     );
`endif
`endif

`ifdef HP1_ENABLE
  logic [C_HP1_AXI_ADDR_WIDTH-1:0] hp1_axi_awaddr;
  logic [2:0] hp1_axi_awprot;
  logic hp1_axi_awvalid, hp1_axi_awready;
  logic [C_HP1_AXI_DATA_WIDTH-1:0] hp1_axi_wdata;
  logic [(C_HP1_AXI_DATA_WIDTH/8)-1:0] hp1_axi_wstrb;
  logic hp1_axi_wvalid, hp1_axi_wready;
  logic [1:0] hp1_axi_bresp;
  logic hp1_axi_bvalid, hp1_axi_bready;
  logic [C_HP1_AXI_ADDR_WIDTH-1:0] hp1_axi_araddr;
  logic [2:0] hp1_axi_arprot;
  logic hp1_axi_arvalid, hp1_axi_arready;
  logic [C_HP1_AXI_DATA_WIDTH-1:0] hp1_axi_rdata;
  logic [1:0] hp1_axi_rresp;
  logic hp1_axi_rvalid, hp1_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_HP1_AXI_ADDR_WIDTH), .data_width_p(C_HP1_AXI_DATA_WIDTH))
   axil4
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(hp1_axi_awaddr)
     ,.awprot_i(hp1_axi_awprot)
     ,.awvalid_i(hp1_axi_awvalid)
     ,.awready_o(hp1_axi_awready)
     ,.wdata_i(hp1_axi_wdata)
     ,.wstrb_i(hp1_axi_wstrb)
     ,.wvalid_i(hp1_axi_wvalid)
     ,.wready_o(hp1_axi_wready)
     ,.bresp_o(hp1_axi_bresp)
     ,.bvalid_o(hp1_axi_bvalid)
     ,.bready_i(hp1_axi_bready)

     ,.araddr_i(hp1_axi_araddr)
     ,.arprot_i(hp1_axi_arprot)
     ,.arvalid_i(hp1_axi_arvalid)
     ,.arready_o(hp1_axi_arready)
     ,.rdata_o(hp1_axi_rdata)
     ,.rresp_o(hp1_axi_rresp)
     ,.rvalid_o(hp1_axi_rvalid)
     ,.rready_i(hp1_axi_rready)
     );
`endif

`ifdef HP2_ENABLE
  logic [C_HP2_AXI_ADDR_WIDTH-1:0] hp2_axi_awaddr;
  logic [2:0] hp2_axi_awprot;
  logic hp2_axi_awvalid, hp2_axi_awready;
  logic [C_HP2_AXI_DATA_WIDTH-1:0] hp2_axi_wdata;
  logic [(C_HP2_AXI_DATA_WIDTH/8)-1:0] hp2_axi_wstrb;
  logic hp2_axi_wvalid, hp2_axi_wready;
  logic [1:0] hp2_axi_bresp;
  logic hp2_axi_bvalid, hp2_axi_bready;
  logic [C_HP2_AXI_ADDR_WIDTH-1:0] hp2_axi_araddr;
  logic [2:0] hp2_axi_arprot;
  logic hp2_axi_arvalid, hp2_axi_arready;
  logic [C_HP2_AXI_DATA_WIDTH-1:0] hp2_axi_rdata;
  logic [1:0] hp2_axi_rresp;
  logic hp2_axi_rvalid, hp2_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_HP2_AXI_ADDR_WIDTH), .data_width_p(C_HP2_AXI_DATA_WIDTH))
   axil5
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(hp2_axi_awaddr)
     ,.awprot_i(hp2_axi_awprot)
     ,.awvalid_i(hp2_axi_awvalid)
     ,.awready_o(hp2_axi_awready)
     ,.wdata_i(hp2_axi_wdata)
     ,.wstrb_i(hp2_axi_wstrb)
     ,.wvalid_i(hp2_axi_wvalid)
     ,.wready_o(hp2_axi_wready)
     ,.bresp_o(hp2_axi_bresp)
     ,.bvalid_o(hp2_axi_bvalid)
     ,.bready_i(hp2_axi_bready)

     ,.araddr_i(hp2_axi_araddr)
     ,.arprot_i(hp2_axi_arprot)
     ,.arvalid_i(hp2_axi_arvalid)
     ,.arready_o(hp2_axi_arready)
     ,.rdata_o(hp2_axi_rdata)
     ,.rresp_o(hp2_axi_rresp)
     ,.rvalid_o(hp2_axi_rvalid)
     ,.rready_i(hp2_axi_rready)
     );
`endif

`ifdef SP0_ENABLE
  logic sp0_axi_tvalid, sp0_axi_tready;
  logic [C_SP0_AXI_DATA_WIDTH-1:0] sp0_axi_tdata;
  logic [(C_SP0_AXI_DATA_WIDTH/8)-1:0] sp0_axi_tkeep;
  logic sp0_axi_tlast;
  bsg_nonsynth_dpi_to_axis
   #(.data_width_p(C_SP0_AXI_DATA_WIDTH))
   axis6
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_o(sp0_axi_tdata)
     ,.tvalid_o(sp0_axi_tvalid)
     ,.tkeep_o(sp0_axi_tkeep)
     ,.tlast_o(sp0_axi_tlast)
     ,.tready_i(sp0_axi_tready)
     );
`endif

`ifdef SP1_ENABLE
  logic sp1_axi_tvalid, sp1_axi_tready;
  logic [C_SP1_AXI_DATA_WIDTH-1:0] sp1_axi_tdata;
  logic [(C_SP1_AXI_DATA_WIDTH/8)-1:0] sp1_axi_tkeep;
  logic sp1_axi_tlast;
  bsg_nonsynth_dpi_to_axis
   #(.data_width_p(C_SP1_AXI_DATA_WIDTH))
   axis7
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_o(sp1_axi_tdata)
     ,.tvalid_o(sp1_axi_tvalid)
     ,.tkeep_o(sp1_axi_tkeep)
     ,.tlast_o(sp1_axi_tlast)
     ,.tready_i(sp1_axi_tready)
     );
`endif

`ifdef SP2_ENABLE
  logic sp2_axi_tvalid, sp2_axi_tready;
  logic [C_SP2_AXI_DATA_WIDTH-1:0] sp2_axi_tdata;
  logic [(C_SP2_AXI_DATA_WIDTH/8)-1:0] sp2_axi_tkeep;
  logic sp2_axi_tlast;
  bsg_nonsynth_dpi_to_axis
   #(.data_width_p(C_SP2_AXI_DATA_WIDTH))
   axis8
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_o(sp2_axi_tdata)
     ,.tvalid_o(sp2_axi_tvalid)
     ,.tkeep_o(sp2_axi_tkeep)
     ,.tlast_o(sp2_axi_tlast)
     ,.tready_i(sp2_axi_tready)
     );
`endif

`ifdef MP0_ENABLE
  logic mp0_axi_tvalid, mp0_axi_tready;
  logic [C_MP0_AXI_DATA_WIDTH-1:0] mp0_axi_tdata;
  logic [(C_MP0_AXI_DATA_WIDTH/8)-1:0] mp0_axi_tkeep;
  logic mp0_axi_tlast;
  bsg_nonsynth_axis_to_dpi
   #(.data_width_p(C_MP0_AXI_DATA_WIDTH))
   axis9
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_i(mp0_axi_tdata)
     ,.tvalid_i(mp0_axi_tvalid)
     ,.tkeep_i(mp0_axi_tkeep)
     ,.tready_o(mp0_axi_tready)
     ,.tlast_i(mp0_axi_tlast)
     );
`endif

`ifdef MP1_ENABLE
  logic mp1_axi_tvalid, mp1_axi_tready;
  logic [C_MP1_AXI_DATA_WIDTH-1:0] mp1_axi_tdata;
  logic [(C_MP1_AXI_DATA_WIDTH/8)-1:0] mp1_axi_tkeep;
  logic mp1_axi_tlast;
  bsg_nonsynth_axis_to_dpi
   #(.data_width_p(C_MP1_AXI_DATA_WIDTH))
   axis10
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_i(mp1_axi_tdata)
     ,.tvalid_i(mp1_axi_tvalid)
     ,.tkeep_i(mp1_axi_tkeep)
     ,.tready_o(mp1_axi_tready)
     ,.tlast_i(mp1_axi_tlast)
     );
`endif

`ifdef MP2_ENABLE
  logic mp2_axi_tvalid, mp2_axi_tready;
  logic [C_MP2_AXI_DATA_WIDTH-1:0] mp2_axi_tdata;
  logic [(C_MP2_AXI_DATA_WIDTH/8)-1:0] mp2_axi_tkeep;
  logic mp2_axi_tlast;
  bsg_nonsynth_axis_to_dpi
   #(.data_width_p(C_MP2_AXI_DATA_WIDTH))
   axis11
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.tdata_i(mp2_axi_tdata)
     ,.tvalid_i(mp2_axi_tvalid)
     ,.tkeep_i(mp2_axi_tkeep)
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
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to trace.fst...\n", $time);
           $dumpfile("trace.fst");
           $dumpvars();
         end
     end
`else
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
`ifdef VCS
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $vcdplusfile("vcdplus.vpd");
           $vcdpluson();
           $vcdplusautoflushon();
         end
`endif
`ifdef XCELIUM
         begin
           $shm_open("dump.shm");
           $shm_probe("ASM");
         end
`endif
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
     @(posedge aclk);
     #1;
   endtask
`endif

   export "DPI-C" function bsg_dpi_time;
   function int bsg_dpi_time();
     return $time;
   endfunction

endmodule

