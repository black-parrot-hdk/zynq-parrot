
module top
  #(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH = 10
    , parameter integer C_M01_AXI_DATA_WIDTH = 32
    , parameter integer C_M01_AXI_ADDR_WIDTH = 28
    , parameter integer UART_BASE_ADDR = 32'h1100000
    , parameter integer __DUMMY = 0
    )
   (
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire                                   aclk
    ,input wire                                  aresetn

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

   top_zynq #
     (.C_S00_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH)
      ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ,.C_M01_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH)
      ,.C_M01_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH)
      ,.UART_BASE_ADDR(UART_BASE_ADDR)
      )
     top_fpga_inst
     (.aclk            (aclk)
      ,.aresetn        (aresetn)

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

endmodule

