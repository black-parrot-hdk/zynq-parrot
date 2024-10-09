
`timescale 1 ps / 1 ps
`include "bsg_defines.sv"

module bsg_nonsynth_zynq_testbench;

`ifdef GP0_ENABLE
  localparam C_S00_AXI_DATA_WIDTH = `GP0_DATA_WIDTH;
  localparam C_S00_AXI_ADDR_WIDTH = `GP0_ADDR_WIDTH;
`endif
`ifdef GP1_ENABLE
  localparam C_S01_AXI_DATA_WIDTH = `GP1_DATA_WIDTH;
  localparam C_S01_AXI_ADDR_WIDTH = `GP1_ADDR_WIDTH;
`endif
`ifdef GP2_ENABLE
  localparam C_S02_AXI_DATA_WIDTH = `GP2_DATA_WIDTH;
  localparam C_S02_AXI_ADDR_WIDTH = `GP2_ADDR_WIDTH;
`endif
`ifdef HP0_ENABLE
  localparam C_M00_AXI_DATA_WIDTH = `HP0_DATA_WIDTH;
  localparam C_M00_AXI_ADDR_WIDTH = `HP0_ADDR_WIDTH;
`endif
`ifdef HP1_ENABLE
  localparam C_M01_AXI_DATA_WIDTH = `HP1_DATA_WIDTH;
  localparam C_M01_AXI_ADDR_WIDTH = `HP1_ADDR_WIDTH;
`endif
`ifdef HP2_ENABLE
  localparam C_M02_AXI_DATA_WIDTH = `HP2_DATA_WIDTH;
  localparam C_M02_AXI_ADDR_WIDTH = `HP2_ADDR_WIDTH;
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
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

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
`endif

`ifdef GP1_ENABLE
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
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

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
`endif

`ifdef GP2_ENABLE
  logic [C_S02_AXI_ADDR_WIDTH-1:0] s02_axi_awaddr;
  logic [2:0] s02_axi_awprot;
  logic s02_axi_awvalid, s02_axi_awready;
  logic [C_S02_AXI_DATA_WIDTH-1:0] s02_axi_wdata;
  logic [(C_S02_AXI_DATA_WIDTH/8)-1:0] s02_axi_wstrb;
  logic s02_axi_wvalid, s02_axi_wready;
  logic [1:0] s02_axi_bresp;
  logic s02_axi_bvalid, s02_axi_bready;
  logic [C_S02_AXI_ADDR_WIDTH-1:0] s02_axi_araddr;
  logic [2:0] s02_axi_arprot;
  logic s02_axi_arvalid, s02_axi_arready;
  logic [C_S02_AXI_DATA_WIDTH-1:0] s02_axi_rdata;
  logic [1:0] s02_axi_rresp;
  logic s02_axi_rvalid, s02_axi_rready;
`ifdef AXI_DMI_ENABLE
  import dm::*;

  hartinfo_t hartinfo;
  assign hartinfo = '{zero1      : '0
                      ,nscratch  : 2
                      ,zero0     : '0
                      ,dataaccess: 1'b1
                      ,datasize  : DataCount
                      ,dataaddr  : DataAddr
                      };

  localparam byte_offset_width_lp = `BSG_SAFE_CLOG2(C_S02_AXI_DATA_WIDTH/8);
  logic slave_req_li, slave_we_li;
  logic [C_S02_AXI_DATA_WIDTH-1:0] slave_addr_li;
  logic [C_S02_AXI_DATA_WIDTH/8-1:0] slave_be_li;
  logic [C_S02_AXI_DATA_WIDTH-1:0] slave_wdata_li;
  logic [C_S02_AXI_DATA_WIDTH-1:0] slave_rdata_lo;

  logic master_req_lo, master_we_lo, master_gnt_li;
  logic [C_S02_AXI_DATA_WIDTH-1:0] master_add_lo;
  logic [C_S02_AXI_DATA_WIDTH-1:0] master_wdata_lo;
  logic [C_S02_AXI_DATA_WIDTH/8-1:0] master_be_lo;

  logic master_r_valid_li;
  logic master_r_err_li, master_r_other_err_li;
  logic [C_S02_AXI_DATA_WIDTH-1:0] master_r_rdata_li;

  dmi_req_t dmi_req;
  dmi_resp_t dmi_resp;
  logic dmi_req_valid;
  logic dmi_req_ready;
  logic [6:0] dmi_req_addr;
  logic [1:0] dmi_req_op;
  logic [31:0] dmi_req_data;
  logic dmi_rsp_valid;
  logic dmi_rsp_ready;
  logic [31:0] dmi_rsp_data;
  logic [1:0] dmi_rsp_resp;
  logic dmi_rst_n;

  logic ndmreset;
  logic debug_req;
  dm_top
   #(.NrHarts(1) // Only support single core debugging for now
     ,.BusWidth(C_S02_AXI_DATA_WIDTH)
     ,.Xlen(64)
     // Forces portable debug rom
     ,.DmBaseAddress(1)
     )
   dm
    (.clk_i(aclk)
     ,.rst_ni(aresetn)
     ,.next_dm_addr_i('0)
     ,.ndmreset_ack_i(ndmreset)
     ,.testmode_i(1'b0) // unused
     ,.ndmreset_o(ndmreset)
     ,.dmactive_o() // unused, connect??
     ,.debug_req_o(debug_req)
     ,.unavailable_i('0) // unused
     ,.hartinfo_i(hartinfo)

     ,.slave_req_i(slave_req_li)
     ,.slave_we_i(slave_we_li)
     ,.slave_addr_i(slave_addr_li)
     ,.slave_be_i(slave_be_li)
     ,.slave_wdata_i(slave_wdata_li)
     ,.slave_rdata_o(slave_rdata_lo)

     ,.master_req_o(master_req_lo)
     ,.master_add_o(master_add_lo)
     ,.master_we_o(master_we_lo)
     ,.master_wdata_o(master_wdata_lo)
     ,.master_be_o(master_be_lo)
     ,.master_gnt_i(master_gnt_li)

     ,.master_r_valid_i(master_r_valid_li)
     ,.master_r_err_i(master_r_err_li)
     ,.master_r_other_err_i(master_r_other_err_li)
     ,.master_r_rdata_i(master_r_rdata_li)

     // DMI interface
     ,.dmi_rst_ni(dmi_rst_n)
     ,.dmi_req_valid_i(dmi_req_valid)
     ,.dmi_req_ready_o(dmi_req_ready)
     ,.dmi_req_i(dmi_req)

     ,.dmi_resp_valid_o(dmi_rsp_valid)
     ,.dmi_resp_ready_i(dmi_rsp_ready)
     ,.dmi_resp_o(dmi_resp)
     );

  dmidpi #(.Name("dmi0"), .ListenPort(44853)) dmi
   (.clk_i(aclk)
    ,.rst_ni(aresetn)

    ,.dmi_req_valid(dmi_req_valid)
    ,.dmi_req_ready(dmi_req_ready)
    ,.dmi_req_addr(dmi_req_addr)
    ,.dmi_req_op(dmi_req_op)
    ,.dmi_req_data(dmi_req_data)
    ,.dmi_rsp_valid(dmi_rsp_valid)
    ,.dmi_rsp_ready(dmi_rsp_ready)
    ,.dmi_rsp_data(dmi_rsp_data)
    ,.dmi_rsp_resp(dmi_rsp_resp)
    ,.dmi_rst_n(dmi_rst_n)
    ,.debug_req(debug_req)
   );

  assign dmi_req = '{addr: dmi_req_addr, op: dtm_op_e'(dmi_req_op), data: dmi_req_data};
  assign {dmi_rsp_data, dmi_rsp_resp} = {dmi_resp.data, dmi_resp.resp};

  logic [C_S02_AXI_DATA_WIDTH-1:0] m_fifo_data_li;
  logic [C_S02_AXI_ADDR_WIDTH-1:0] m_fifo_addr_li;
  logic m_fifo_ready_and_lo, m_fifo_v_li, m_fifo_w_li;
  logic [(C_S02_AXI_DATA_WIDTH/8)-1:0] m_fifo_wmask_li;
  logic [C_S02_AXI_DATA_WIDTH-1:0] m_fifo_data_lo;
  logic m_fifo_ready_and_li, m_fifo_v_lo;
  bsg_axil_fifo_master
   #(.axil_data_width_p(C_S02_AXI_DATA_WIDTH), .axil_addr_width_p(C_S02_AXI_ADDR_WIDTH))
   dmi_master_bridge
    (.clk_i(aclk)
     ,.reset_i(!aresetn)

     ,.data_i(m_fifo_data_li)
     ,.addr_i(m_fifo_addr_li)
     ,.v_i(m_fifo_v_li)
     ,.w_i(m_fifo_w_li)
     ,.wmask_i(m_fifo_wmask_li)
     ,.ready_and_o(m_fifo_ready_and_lo)

     ,.data_o(m_fifo_data_lo)
     ,.v_o(m_fifo_v_lo)
     ,.ready_and_i(m_fifo_ready_and_li)

     ,.m_axil_awaddr_o(s02_axi_awaddr)
     ,.m_axil_awprot_o(s02_axi_awprot)
     ,.m_axil_awvalid_o(s02_axi_awvalid)
     ,.m_axil_awready_i(s02_axi_awready)
     ,.m_axil_wdata_o(s02_axi_wdata)
     ,.m_axil_wstrb_o(s02_axi_wstrb)
     ,.m_axil_wvalid_o(s02_axi_wvalid)
     ,.m_axil_wready_i(s02_axi_wready)
     ,.m_axil_bresp_i(s02_axi_bresp)
     ,.m_axil_bvalid_i(s02_axi_bvalid)
     ,.m_axil_bready_o(s02_axi_bready)

     ,.m_axil_araddr_o(s02_axi_araddr)
     ,.m_axil_arprot_o(s02_axi_arprot)
     ,.m_axil_arvalid_o(s02_axi_arvalid)
     ,.m_axil_arready_i(s02_axi_arready)
     ,.m_axil_rdata_i(s02_axi_rdata)
     ,.m_axil_rresp_i(s02_axi_rresp)
     ,.m_axil_rvalid_i(s02_axi_rvalid)
     ,.m_axil_rready_o(s02_axi_rready)
     );

  assign m_fifo_data_li = master_wdata_lo;
  assign m_fifo_addr_li = master_add_lo;
  assign m_fifo_v_li = master_req_lo;
  assign m_fifo_w_li = master_we_lo;
  assign m_fifo_wmask_li = master_be_lo;
  assign master_gnt_li = m_fifo_ready_and_lo & m_fifo_v_li;

  assign master_r_valid_li = m_fifo_v_lo;
  assign master_r_err_li = '0;
  assign master_r_other_err_li = '0;
  assign master_r_rdata_li = m_fifo_data_lo;
  assign m_fifo_ready_and_li = 1'b1;
`else
  bsg_nonsynth_dpi_to_axil
   #(.addr_width_p(C_S02_AXI_ADDR_WIDTH), .data_width_p(C_S02_AXI_DATA_WIDTH))
   axil2
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_o(s02_axi_awaddr)
     ,.awprot_o(s02_axi_awprot)
     ,.awvalid_o(s02_axi_awvalid)
     ,.awready_i(s02_axi_awready)
     ,.wdata_o(s02_axi_wdata)
     ,.wstrb_o(s02_axi_wstrb)
     ,.wvalid_o(s02_axi_wvalid)
     ,.wready_i(s02_axi_wready)
     ,.bresp_i(s02_axi_bresp)
     ,.bvalid_i(s02_axi_bvalid)
     ,.bready_o(s02_axi_bready)

     ,.araddr_o(s02_axi_araddr)
     ,.arprot_o(s02_axi_arprot)
     ,.arvalid_o(s02_axi_arvalid)
     ,.arready_i(s02_axi_arready)
     ,.rdata_i(s02_axi_rdata)
     ,.rresp_i(s02_axi_rresp)
     ,.rvalid_i(s02_axi_rvalid)
     ,.rready_o(s02_axi_rready)
     );
`endif
`endif

`ifdef HP0_ENABLE
  logic [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr;
  logic                                 m00_axi_awvalid;
  logic                                 m00_axi_awready;
  logic [5:0]                           m00_axi_awid;
  logic                                 m00_axi_awlock;
  logic [3:0]                           m00_axi_awcache;
  logic [2:0]                           m00_axi_awprot;
  logic [7:0]                           m00_axi_awlen;
  logic [2:0]                           m00_axi_awsize;
  logic [1:0]                           m00_axi_awburst;
  logic [3:0]                           m00_axi_awqos;

  logic [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata;
  logic                                 m00_axi_wvalid;
  logic                                 m00_axi_wready;
  logic [5:0]                           m00_axi_wid;
  logic                                 m00_axi_wlast;
  logic [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb;

  logic                                 m00_axi_bvalid;
  logic                                 m00_axi_bready;
  logic [5:0]                           m00_axi_bid;
  logic [1:0]                           m00_axi_bresp;

  logic [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr;
  logic                                 m00_axi_arvalid;
  logic                                 m00_axi_arready;
  logic [5:0]                           m00_axi_arid;
  logic                                 m00_axi_arlock;
  logic [3:0]                           m00_axi_arcache;
  logic [2:0]                           m00_axi_arprot;
  logic [7:0]                           m00_axi_arlen;
  logic [2:0]                           m00_axi_arsize;
  logic [1:0]                           m00_axi_arburst;
  logic [3:0]                           m00_axi_arqos;

  logic [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata;
  logic                                 m00_axi_rvalid;
  logic                                 m00_axi_rready;
  logic [5:0]                           m00_axi_rid;
  logic                                 m00_axi_rlast;
  logic [1:0]                           m00_axi_rresp;

`ifdef AXI_MEM_ENABLE
  bsg_nonsynth_axi_mem
    #(.axi_id_width_p(6)
      ,.axi_addr_width_p(C_M00_AXI_ADDR_WIDTH)
      ,.axi_data_width_p(C_M00_AXI_DATA_WIDTH)
      ,.axi_len_width_p(8)
      ,.mem_els_p(2**28) // 256 MB
      ,.init_data_p('0)
    )
  axi_mem
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.axi_awid_i(m00_axi_awid)
     ,.axi_awaddr_i(m00_axi_awaddr)
     ,.axi_awlen_i(m00_axi_awlen)
     ,.axi_awburst_i(m00_axi_awburst)
     ,.axi_awvalid_i(m00_axi_awvalid)
     ,.axi_awready_o(m00_axi_awready)

     ,.axi_wdata_i(m00_axi_wdata)
     ,.axi_wstrb_i(m00_axi_wstrb)
     ,.axi_wlast_i(m00_axi_wlast)
     ,.axi_wvalid_i(m00_axi_wvalid)
     ,.axi_wready_o(m00_axi_wready)

     ,.axi_bid_o(m00_axi_bid)
     ,.axi_bresp_o(m00_axi_bresp)
     ,.axi_bvalid_o(m00_axi_bvalid)
     ,.axi_bready_i(m00_axi_bready)

     ,.axi_arid_i(m00_axi_arid)
     ,.axi_araddr_i(m00_axi_araddr)
     ,.axi_arlen_i(m00_axi_arlen)
     ,.axi_arburst_i(m00_axi_arburst)
     ,.axi_arvalid_i(m00_axi_arvalid)
     ,.axi_arready_o(m00_axi_arready)

     ,.axi_rid_o(m00_axi_rid)
     ,.axi_rdata_o(m00_axi_rdata)
     ,.axi_rresp_o(m00_axi_rresp)
     ,.axi_rlast_o(m00_axi_rlast)
     ,.axi_rvalid_o(m00_axi_rvalid)
     ,.axi_rready_i(m00_axi_rready)
     );
`else
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_M00_AXI_ADDR_WIDTH), .data_width_p(C_M00_AXI_DATA_WIDTH))
   axil3
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(m00_axi_awaddr)
     ,.awprot_i(m00_axi_awprot)
     ,.awvalid_i(m00_axi_awvalid)
     ,.awready_o(m00_axi_awready)
     ,.wdata_i(m00_axi_wdata)
     ,.wstrb_i(m00_axi_wstrb)
     ,.wvalid_i(m00_axi_wvalid)
     ,.wready_o(m00_axi_wready)
     ,.bresp_o(m00_axi_bresp)
     ,.bvalid_o(m00_axi_bvalid)
     ,.bready_i(m00_axi_bready)

     ,.araddr_i(m00_axi_araddr)
     ,.arprot_i(m00_axi_arprot)
     ,.arvalid_i(m00_axi_arvalid)
     ,.arready_o(m00_axi_arready)
     ,.rdata_o(m00_axi_rdata)
     ,.rresp_o(m00_axi_rresp)
     ,.rvalid_o(m00_axi_rvalid)
     ,.rready_i(m00_axi_rready)
     );
`endif
`endif

`ifdef HP1_ENABLE
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
`ifdef AXI_DMI_ENABLE

  logic [C_M01_AXI_DATA_WIDTH-1:0] c_fifo_data_lo;
  logic [C_M01_AXI_ADDR_WIDTH-1:0] c_fifo_addr_lo;
  logic c_fifo_ready_and_li, c_fifo_v_lo, c_fifo_w_lo;
  logic [(C_M01_AXI_DATA_WIDTH/8)-1:0] c_fifo_wmask_lo;
  logic [C_M01_AXI_DATA_WIDTH-1:0] c_fifo_data_li;
  logic c_fifo_ready_and_lo, c_fifo_v_li;
  bsg_axil_fifo_client
   #(.axil_data_width_p(C_M01_AXI_DATA_WIDTH), .axil_addr_width_p(C_M01_AXI_ADDR_WIDTH))
   dmi_client_bridge
    (.clk_i(aclk)
     ,.reset_i(!aresetn)

     ,.data_o(c_fifo_data_lo)
     ,.addr_o(c_fifo_addr_lo)
     ,.v_o(c_fifo_v_lo)
     ,.w_o(c_fifo_w_lo)
     ,.wmask_o(c_fifo_wmask_lo)
     ,.ready_and_i(c_fifo_ready_and_li)

     ,.data_i(c_fifo_data_li)
     ,.v_i(c_fifo_v_li)
     ,.ready_and_o(c_fifo_ready_and_lo)

     ,.s_axil_awaddr_i(m01_axi_awaddr)
     ,.s_axil_awprot_i(m01_axi_awprot)
     ,.s_axil_awvalid_i(m01_axi_awvalid)
     ,.s_axil_awready_o(m01_axi_awready)
     ,.s_axil_wdata_i(m01_axi_wdata)
     ,.s_axil_wstrb_i(m01_axi_wstrb)
     ,.s_axil_wvalid_i(m01_axi_wvalid)
     ,.s_axil_wready_o(m01_axi_wready)
     ,.s_axil_bresp_o(m01_axi_bresp)
     ,.s_axil_bvalid_o(m01_axi_bvalid)
     ,.s_axil_bready_i(m01_axi_bready)

     ,.s_axil_araddr_i(m01_axi_araddr)
     ,.s_axil_arprot_i(m01_axi_arprot)
     ,.s_axil_arvalid_i(m01_axi_arvalid)
     ,.s_axil_arready_o(m01_axi_arready)
     ,.s_axil_rdata_o(m01_axi_rdata)
     ,.s_axil_rresp_o(m01_axi_rresp)
     ,.s_axil_rvalid_o(m01_axi_rvalid)
     ,.s_axil_rready_i(m01_axi_rready)
     );

  assign slave_req_li = c_fifo_v_lo;
  assign slave_we_li = c_fifo_w_lo;
  assign slave_addr_li = c_fifo_addr_lo;
  assign slave_be_li = c_fifo_wmask_lo;
  assign slave_wdata_li = c_fifo_data_lo;
  assign c_fifo_ready_and_li = 1'b1;

  // Assume no backpressue
  bsg_dff
   #(.width_p(1))
   c_resp_reg
    (.clk_i(aclk)
     ,.data_i(slave_req_li)
     ,.data_o(c_fifo_v_li)
     );
  assign c_fifo_data_li = slave_rdata_lo;

`else
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_M01_AXI_ADDR_WIDTH), .data_width_p(C_M01_AXI_DATA_WIDTH))
   axil4
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(m01_axi_awaddr)
     ,.awprot_i(m01_axi_awprot)
     ,.awvalid_i(m01_axi_awvalid)
     ,.awready_o(m01_axi_awready)
     ,.wdata_i(m01_axi_wdata)
     ,.wstrb_i(m01_axi_wstrb)
     ,.wvalid_i(m01_axi_wvalid)
     ,.wready_o(m01_axi_wready)
     ,.bresp_o(m01_axi_bresp)
     ,.bvalid_o(m01_axi_bvalid)
     ,.bready_i(m01_axi_bready)

     ,.araddr_i(m01_axi_araddr)
     ,.arprot_i(m01_axi_arprot)
     ,.arvalid_i(m01_axi_arvalid)
     ,.arready_o(m01_axi_arready)
     ,.rdata_o(m01_axi_rdata)
     ,.rresp_o(m01_axi_rresp)
     ,.rvalid_o(m01_axi_rvalid)
     ,.rready_i(m01_axi_rready)
     );
`endif
`endif

`ifdef HP2_ENABLE
  logic [C_M02_AXI_ADDR_WIDTH-1:0] m02_axi_awaddr;
  logic [2:0] m02_axi_awprot;
  logic m02_axi_awvalid, m02_axi_awready;
  logic [C_M02_AXI_DATA_WIDTH-1:0] m02_axi_wdata;
  logic [(C_M02_AXI_DATA_WIDTH/8)-1:0] m02_axi_wstrb;
  logic m02_axi_wvalid, m02_axi_wready;
  logic [1:0] m02_axi_bresp;
  logic m02_axi_bvalid, m02_axi_bready;
  logic [C_M02_AXI_ADDR_WIDTH-1:0] m02_axi_araddr;
  logic [2:0] m02_axi_arprot;
  logic m02_axi_arvalid, m02_axi_arready;
  logic [C_M02_AXI_DATA_WIDTH-1:0] m02_axi_rdata;
  logic [1:0] m02_axi_rresp;
  logic m02_axi_rvalid, m02_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_M02_AXI_ADDR_WIDTH), .data_width_p(C_M02_AXI_DATA_WIDTH))
   axil5
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(m02_axi_awaddr)
     ,.awprot_i(m02_axi_awprot)
     ,.awvalid_i(m02_axi_awvalid)
     ,.awready_o(m02_axi_awready)
     ,.wdata_i(m02_axi_wdata)
     ,.wstrb_i(m02_axi_wstrb)
     ,.wvalid_i(m02_axi_wvalid)
     ,.wready_o(m02_axi_wready)
     ,.bresp_o(m02_axi_bresp)
     ,.bvalid_o(m02_axi_bvalid)
     ,.bready_i(m02_axi_bready)

     ,.araddr_i(m02_axi_araddr)
     ,.arprot_i(m02_axi_arprot)
     ,.arvalid_i(m02_axi_arvalid)
     ,.arready_o(m02_axi_arready)
     ,.rdata_o(m02_axi_rdata)
     ,.rresp_o(m02_axi_rresp)
     ,.rvalid_o(m02_axi_rvalid)
     ,.rready_i(m02_axi_rready)
     );
`endif

  top #(
`ifdef GP0_ENABLE
     .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
     .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
`endif
`ifdef GP1_ENABLE
     .C_S01_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH),
     .C_S01_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH),
`endif
`ifdef GP2_ENABLE
     .C_S02_AXI_DATA_WIDTH(C_S02_AXI_DATA_WIDTH),
     .C_S02_AXI_ADDR_WIDTH(C_S02_AXI_ADDR_WIDTH),
`endif
`ifdef HP0_ENABLE
     .C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
     .C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
`endif
`ifdef HP1_ENABLE
     .C_M01_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH),
     .C_M01_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH),
`endif
`ifdef HP2_ENABLE
     .C_M02_AXI_DATA_WIDTH(C_M02_AXI_DATA_WIDTH),
     .C_M02_AXI_ADDR_WIDTH(C_M02_AXI_ADDR_WIDTH),
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

