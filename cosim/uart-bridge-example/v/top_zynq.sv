
`timescale 1 ps / 1 ps

module top_zynq #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_M01_AXI_DATA_WIDTH = 32,
   parameter integer C_M01_AXI_ADDR_WIDTH = 28,
   parameter integer C_M02_AXI_DATA_WIDTH = 32,
   parameter integer C_M02_AXI_ADDR_WIDTH = 28,
   parameter integer UART_BASE_ADDR = 32'h1100000
   )
   (
    // Users to add ports here
    input aclk
    , input aresetn

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

    ,output wire [C_M02_AXI_ADDR_WIDTH-1 : 0]    m02_axi_awaddr
    ,output wire [2 : 0]                         m02_axi_awprot
    ,output wire                                 m02_axi_awvalid
    ,input wire                                  m02_axi_awready
    ,output wire [C_M02_AXI_DATA_WIDTH-1 : 0]    m02_axi_wdata
    ,output wire [(C_M02_AXI_DATA_WIDTH/8)-1:0]  m02_axi_wstrb
    ,output wire                                 m02_axi_wvalid
    ,input wire                                  m02_axi_wready
    ,input wire [1 : 0]                          m02_axi_bresp
    ,input wire                                  m02_axi_bvalid
    ,output wire                                 m02_axi_bready
    ,output wire [C_M02_AXI_ADDR_WIDTH-1 : 0]    m02_axi_araddr
    ,output wire [2 : 0]                         m02_axi_arprot
    ,output wire                                 m02_axi_arvalid
    ,input wire                                  m02_axi_arready
    ,input wire [C_M02_AXI_DATA_WIDTH-1 : 0]     m02_axi_rdata
    ,input wire [1 : 0]                          m02_axi_rresp
    ,input wire                                  m02_axi_rvalid
    ,output wire                                 m02_axi_rready
    );

    localparam num_regs_ps_to_pl_lp = 1;
    localparam num_regs_pl_to_ps_lp = 1;
    localparam num_fifo_ps_to_pl_lp = 1;
    localparam num_fifo_pl_to_ps_lp = 1;

    ///////////////////////////////////////////////////////////////////////////////////////
    // csr_data_lo:
    //
    // 0: reset uart bridge
    //
    logic [1:0][num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
    logic [1:0][num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

    ///////////////////////////////////////////////////////////////////////////////////////
    // csr_data_li:
    //
    // 0: none
    //
    logic [1:0][num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

    ///////////////////////////////////////////////////////////////////////////////////////
    // pl_to_ps_fifo_data_li:
    //
    // 0: From uart shell
    //
    logic [1:0][num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
    logic [1:0][num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;

    ///////////////////////////////////////////////////////////////////////////////////////
    // ps_to_pl_fifo_data_lo:
    //
    // 0: To axi shell
    //
    logic [1:0][num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
    logic [1:0][num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo, ps_to_pl_fifo_yumi_li;

    // Connect Shell to AXI Bus Interface S00_AXI
    bsg_zynq_pl_shell #
      (
       // need to update C_S00_AXI_ADDR_WIDTH accordingly
       .num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
       ) zps0
        (
         .csr_data_new_o(csr_data_new_lo[0])
         ,.csr_data_o(csr_data_lo[0])
         ,.csr_data_i(csr_data_li[0])

         ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li[0])
         ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li[0])
         ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo[0])

         ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo[0])
         ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo[0])
         ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li[0])

         ,.S_AXI_ACLK   (aclk)
         ,.S_AXI_ARESETN(aresetn)
         ,.S_AXI_AWADDR (s00_axi_awaddr)
         ,.S_AXI_AWPROT (s00_axi_awprot)
         ,.S_AXI_AWVALID(s00_axi_awvalid)
         ,.S_AXI_AWREADY(s00_axi_awready)
         ,.S_AXI_WDATA  (s00_axi_wdata)
         ,.S_AXI_WSTRB  (s00_axi_wstrb)
         ,.S_AXI_WVALID (s00_axi_wvalid)
         ,.S_AXI_WREADY (s00_axi_wready)
         ,.S_AXI_BRESP  (s00_axi_bresp)
         ,.S_AXI_BVALID (s00_axi_bvalid)
         ,.S_AXI_BREADY (s00_axi_bready)
         ,.S_AXI_ARADDR (s00_axi_araddr)
         ,.S_AXI_ARPROT (s00_axi_arprot)
         ,.S_AXI_ARVALID(s00_axi_arvalid)
         ,.S_AXI_ARREADY(s00_axi_arready)
         ,.S_AXI_RDATA  (s00_axi_rdata)
         ,.S_AXI_RRESP  (s00_axi_rresp)
         ,.S_AXI_RVALID (s00_axi_rvalid)
         ,.S_AXI_RREADY (s00_axi_rready)
         );

    ///////////////////////////////////////////////////////////////////////////////////////
    // csr_data_lo:
    //
    // 0: loopback
    //

    ///////////////////////////////////////////////////////////////////////////////////////
    // csr_data_li:
    //
    // 0: loopback
    //

    ///////////////////////////////////////////////////////////////////////////////////////
    // pl_to_ps_fifo_data_li:
    //
    // 0: From axi shell
    //

    ///////////////////////////////////////////////////////////////////////////////////////
    // ps_to_pl_fifo_data_lo:
    //
    // 0: To axi shell
    //

    // Connect Shell to AXI Bus Interface S00_AXI
    logic [C_S00_AXI_ADDR_WIDTH-1 : 0]    gp0_axi_awaddr;
    logic [2 : 0]                         gp0_axi_awprot;
    logic                                 gp0_axi_awvalid;
    logic                                 gp0_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1 : 0]    gp0_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0]  gp0_axi_wstrb;
    logic                                 gp0_axi_wvalid;
    logic                                 gp0_axi_wready;
    logic [1 : 0]                         gp0_axi_bresp;
    logic                                 gp0_axi_bvalid;
    logic                                 gp0_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1 : 0]    gp0_axi_araddr;
    logic [2 : 0]                         gp0_axi_arprot;
    logic                                 gp0_axi_arvalid;
    logic                                 gp0_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1 : 0]    gp0_axi_rdata;
    logic [1 : 0]                         gp0_axi_rresp;
    logic                                 gp0_axi_rvalid;
    logic                                 gp0_axi_rready;
    bsg_zynq_pl_shell #
      (
       // need to update C_S00_AXI_ADDR_WIDTH accordingly
       .num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
       ) zps1
        (
         .csr_data_new_o(csr_data_new_lo[1])
         ,.csr_data_o(csr_data_lo[1])
         ,.csr_data_i(csr_data_li[1])

         ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li[1])
         ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li[1])
         ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo[1])

         ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo[1])
         ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo[1])
         ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li[1])

         ,.S_AXI_ACLK   (aclk)
         ,.S_AXI_ARESETN(aresetn)
         ,.S_AXI_AWADDR (gp0_axi_awaddr)
         ,.S_AXI_AWPROT (gp0_axi_awprot)
         ,.S_AXI_AWVALID(gp0_axi_awvalid)
         ,.S_AXI_AWREADY(gp0_axi_awready)
         ,.S_AXI_WDATA  (gp0_axi_wdata)
         ,.S_AXI_WSTRB  (gp0_axi_wstrb)
         ,.S_AXI_WVALID (gp0_axi_wvalid)
         ,.S_AXI_WREADY (gp0_axi_wready)
         ,.S_AXI_BRESP  (gp0_axi_bresp)
         ,.S_AXI_BVALID (gp0_axi_bvalid)
         ,.S_AXI_BREADY (gp0_axi_bready)
         ,.S_AXI_ARADDR (gp0_axi_araddr)
         ,.S_AXI_ARPROT (gp0_axi_arprot)
         ,.S_AXI_ARVALID(gp0_axi_arvalid)
         ,.S_AXI_ARREADY(gp0_axi_arready)
         ,.S_AXI_RDATA  (gp0_axi_rdata)
         ,.S_AXI_RRESP  (gp0_axi_rresp)
         ,.S_AXI_RVALID (gp0_axi_rvalid)
         ,.S_AXI_RREADY (gp0_axi_rready)
         );

    // criss-cross between two AXI slave ports the data and valid signals
    assign pl_to_ps_fifo_data_li[0] = ps_to_pl_fifo_data_lo[1];
    assign pl_to_ps_fifo_v_li[0] = ps_to_pl_fifo_v_lo[1];
    assign ps_to_pl_fifo_yumi_li[0] = pl_to_ps_fifo_v_li[1] & pl_to_ps_fifo_ready_lo[1];

    assign pl_to_ps_fifo_data_li[1] = ps_to_pl_fifo_data_lo[0];
    assign pl_to_ps_fifo_v_li[1] = ps_to_pl_fifo_v_lo[0];
    assign ps_to_pl_fifo_yumi_li[1] = pl_to_ps_fifo_v_li[0] & pl_to_ps_fifo_ready_lo[0];

	assign csr_data_li[1] = csr_data_lo[1];

    wire bridge_resetn = csr_data_lo[0];
    bsg_axil_uart_bridge
     #(.m_axil_data_width_p(C_M01_AXI_DATA_WIDTH)
       ,.m_axil_addr_width_p(C_M01_AXI_ADDR_WIDTH)
       ,.uart_base_addr_p(UART_BASE_ADDR)
       ,.gp0_axil_data_width_p(C_S00_AXI_DATA_WIDTH)
       ,.gp0_axil_addr_width_p(C_S00_AXI_ADDR_WIDTH)
       )
     bridge
      (.clk_i(aclk)
       ,.reset_i(~bridge_resetn)

       ,.m_axil_awaddr_o(m01_axi_awaddr)
       ,.m_axil_awprot_o(m01_axi_awprot)
       ,.m_axil_awvalid_o(m01_axi_awvalid)
       ,.m_axil_awready_i(m01_axi_awready)

       ,.m_axil_wdata_o(m01_axi_wdata)
       ,.m_axil_wstrb_o(m01_axi_wstrb)
       ,.m_axil_wvalid_o(m01_axi_wvalid)
       ,.m_axil_wready_i(m01_axi_wready)

       ,.m_axil_bresp_i(m01_axi_bresp)
       ,.m_axil_bvalid_i(m01_axi_bvalid)
       ,.m_axil_bready_o(m01_axi_bready)

       ,.m_axil_araddr_o(m01_axi_araddr)
       ,.m_axil_arprot_o(m01_axi_arprot)
       ,.m_axil_arvalid_o(m01_axi_arvalid)
       ,.m_axil_arready_i(m01_axi_arready)

       ,.m_axil_rdata_i(m01_axi_rdata)
       ,.m_axil_rresp_i(m01_axi_rresp)
       ,.m_axil_rvalid_i(m01_axi_rvalid)
       ,.m_axil_rready_o(m01_axi_rready)

       ,.gp0_axil_awaddr_o(gp0_axi_awaddr)
       ,.gp0_axil_awprot_o(gp0_axi_awprot)
       ,.gp0_axil_awvalid_o(gp0_axi_awvalid)
       ,.gp0_axil_awready_i(gp0_axi_awready)

       ,.gp0_axil_wdata_o(gp0_axi_wdata)
       ,.gp0_axil_wstrb_o(gp0_axi_wstrb)
       ,.gp0_axil_wvalid_o(gp0_axi_wvalid)
       ,.gp0_axil_wready_i(gp0_axi_wready)

       ,.gp0_axil_bresp_i(gp0_axi_bresp)
       ,.gp0_axil_bvalid_i(gp0_axi_bvalid)
       ,.gp0_axil_bready_o(gp0_axi_bready)

       ,.gp0_axil_araddr_o(gp0_axi_araddr)
       ,.gp0_axil_arprot_o(gp0_axi_arprot)
       ,.gp0_axil_arvalid_o(gp0_axi_arvalid)
       ,.gp0_axil_arready_i(gp0_axi_arready)

       ,.gp0_axil_rdata_i(gp0_axi_rdata)
       ,.gp0_axil_rresp_i(gp0_axi_rresp)
       ,.gp0_axil_rvalid_i(gp0_axi_rvalid)
       ,.gp0_axil_rready_o(gp0_axi_rready)
       );

endmodule

