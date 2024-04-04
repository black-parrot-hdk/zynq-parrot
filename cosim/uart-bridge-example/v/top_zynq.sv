
`timescale 1 ps / 1 ps

module top_zynq #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_S00_AXI_DATA_WIDTH = 32,
   parameter integer C_S00_AXI_ADDR_WIDTH = 10,
   parameter integer C_M01_AXI_DATA_WIDTH = 32,
   parameter integer C_M01_AXI_ADDR_WIDTH = 28,
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
    );

    wire [C_S00_AXI_ADDR_WIDTH-1 : 0]    gp0_axil_awaddr;
    wire [2 : 0]                         gp0_axil_awprot;
    wire                                 gp0_axil_awvalid;
    wire                                 gp0_axil_awready;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0]    gp0_axil_wdata;
    wire [(C_S00_AXI_DATA_WIDTH/8)-1:0]  gp0_axil_wstrb;
    wire                                 gp0_axil_wvalid;
    wire                                 gp0_axil_wready;
    wire [1 : 0]                         gp0_axil_bresp;
    wire                                 gp0_axil_bvalid;
    wire                                 gp0_axil_bready;
    wire [C_S00_AXI_ADDR_WIDTH-1 : 0]    gp0_axil_araddr;
    wire [2 : 0]                         gp0_axil_arprot;
    wire                                 gp0_axil_arvalid;
    wire                                 gp0_axil_arready;
    wire [C_S00_AXI_DATA_WIDTH-1 : 0]    gp0_axil_rdata;
    wire [1 : 0]                         gp0_axil_rresp;
    wire                                 gp0_axil_rvalid;
    wire                                 gp0_axil_rready;
    bsg_zynq_uart_bridge
     #(.m_axil_data_width_p(C_M01_AXI_DATA_WIDTH)
       ,.m_axil_addr_width_p(C_M01_AXI_ADDR_WIDTH)
       ,.uart_base_addr_p(UART_BASE_ADDR)
       ,.gp0_axil_data_width_p(C_S00_AXI_DATA_WIDTH)
       ,.gp0_axil_addr_width_p(C_S00_AXI_ADDR_WIDTH)
       )
     bridge
      (.clk_i(aclk)
       ,.reset_i(~aresetn)

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

       ,.gp_axil_awaddr_o(gp0_axil_awaddr)
       ,.gp_axil_awprot_o(gp0_axil_awprot)
       ,.gp_axil_awvalid_o(gp0_axil_awvalid)
       ,.gp_axil_awready_i(gp0_axil_awready)

       ,.gp_axil_wdata_o(gp0_axil_wdata)
       ,.gp_axil_wstrb_o(gp0_axil_wstrb)
       ,.gp_axil_wvalid_o(gp0_axil_wvalid)
       ,.gp_axil_wready_i(gp0_axil_wready)

       ,.gp_axil_bresp_i(gp0_axil_bresp)
       ,.gp_axil_bvalid_i(gp0_axil_bvalid)
       ,.gp_axil_bready_o(gp0_axil_bready)

       ,.gp_axil_araddr_o(gp0_axil_araddr)
       ,.gp_axil_arprot_o(gp0_axil_arprot)
       ,.gp_axil_arvalid_o(gp0_axil_arvalid)
       ,.gp_axil_arready_i(gp0_axil_arready)

       ,.gp_axil_rdata_i(gp0_axil_rdata)
       ,.gp_axil_rresp_i(gp0_axil_rresp)
       ,.gp_axil_rvalid_i(gp0_axil_rvalid)
       ,.gp_axil_rready_o(gp0_axil_rready)
       );

    localparam num_regs_ps_to_pl_lp = 1;
    localparam num_regs_pl_to_ps_lp = 1;
    localparam num_fifo_ps_to_pl_lp = 1;
    localparam num_fifo_pl_to_ps_lp = 1;

    ///////////////////////////////////////////////////////////////////////////////////////
    // csr_data_lo:
    //
    // 0: none
    //
    logic [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
    logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

    ///////////////////////////////////////////////////////////////////////////////////////
    // csr_data_li:
    //
    // 0: last address written
    //
    logic [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

    ///////////////////////////////////////////////////////////////////////////////////////
    // pl_to_ps_fifo_data_li:
    //
    // 0: loopback data in
    //
    logic [num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
    logic [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;

    ///////////////////////////////////////////////////////////////////////////////////////
    // ps_to_pl_fifo_data_lo:
    //
    // 0: loopback data out
    //
    logic [num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
    logic [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo, ps_to_pl_fifo_yumi_li;

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
       ) zps
        (
         .csr_data_new_o(csr_data_new_lo)
         ,.csr_data_o(csr_data_lo)
         ,.csr_data_i(csr_data_li)

         ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
         ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
         ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

         ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
         ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
         ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

         ,.S_AXI_ACLK   (aclk)
         ,.S_AXI_ARESETN(aresetn)
         ,.S_AXI_AWADDR (gp0_axil_awaddr)
         ,.S_AXI_AWPROT (gp0_axil_awprot)
         ,.S_AXI_AWVALID(gp0_axil_awvalid)
         ,.S_AXI_AWREADY(gp0_axil_awready)
         ,.S_AXI_WDATA  (gp0_axil_wdata)
         ,.S_AXI_WSTRB  (gp0_axil_wstrb)
         ,.S_AXI_WVALID (gp0_axil_wvalid)
         ,.S_AXI_WREADY (gp0_axil_wready)
         ,.S_AXI_BRESP  (gp0_axil_bresp)
         ,.S_AXI_BVALID (gp0_axil_bvalid)
         ,.S_AXI_BREADY (gp0_axil_bready)
         ,.S_AXI_ARADDR (gp0_axil_araddr)
         ,.S_AXI_ARPROT (gp0_axil_arprot)
         ,.S_AXI_ARVALID(gp0_axil_arvalid)
         ,.S_AXI_ARREADY(gp0_axil_arready)
         ,.S_AXI_RDATA  (gp0_axil_rdata)
         ,.S_AXI_RRESP  (gp0_axil_rresp)
         ,.S_AXI_RVALID (gp0_axil_rvalid)
         ,.S_AXI_RREADY (gp0_axil_rready)
         );

  assign pl_to_ps_fifo_data_li = ps_to_pl_fifo_data_lo;
  assign pl_to_ps_fifo_v_li = ps_to_pl_fifo_v_lo;
  assign ps_to_pl_fifo_yumi_li = pl_to_ps_fifo_ready_lo & pl_to_ps_fifo_v_li;

  logic [C_S00_AXI_ADDR_WIDTH-1:0] last_write_addr_r;
  bsg_dff_reset_en
   #(.width_p(C_S00_AXI_ADDR_WIDTH))
   last_write_addr_reg
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.en_i(gp0_axil_awvalid & gp0_axil_awready)
     ,.data_i(gp0_axil_awaddr)
     ,.data_o(last_write_addr_r)
     );

  assign csr_data_li = last_write_addr_r;

endmodule

