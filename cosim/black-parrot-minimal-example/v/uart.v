
`include "bsg_defines.sv"

module uart
 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH = 10
    , parameter integer C_M01_AXI_DATA_WIDTH = 32
    , parameter integer C_M01_AXI_ADDR_WIDTH = 28
    , parameter integer UART_BASE_ADDR = 32'h1100000
   )
   (input                                    clk
    , input                                  reset

    , output [C_M01_AXI_ADDR_WIDTH-1:0]      m_axil_awaddr
    , output [2:0]                           m_axil_awprot
    , output                                 m_axil_awvalid
    , input                                  m_axil_awready

    , output [C_M01_AXI_DATA_WIDTH-1:0]      m_axil_wdata
    , output [(C_M01_AXI_DATA_WIDTH>>3)-1:0] m_axil_wstrb
    , output                                 m_axil_wvalid
    , input                                  m_axil_wready

    , input [1:0]                            m_axil_bresp
    , input                                  m_axil_bvalid
    , output                                 m_axil_bready

    , output [C_M01_AXI_ADDR_WIDTH-1:0]      m_axil_araddr
    , output [2:0]                           m_axil_arprot
    , output                                 m_axil_arvalid
    , input                                  m_axil_arready

    , input [C_M01_AXI_DATA_WIDTH-1:0]       m_axil_rdata
    , input [1:0]                            m_axil_rresp
    , input                                  m_axil_rvalid
    , output                                 m_axil_rready

    , output [C_S00_AXI_ADDR_WIDTH-1:0]      gp_axil_awaddr
    , output [2:0]                           gp_axil_awprot
    , output                                 gp_axil_awvalid
    , input                                  gp_axil_awready

    , output [C_S00_AXI_DATA_WIDTH-1:0]      gp_axil_wdata
    , output [(C_S00_AXI_DATA_WIDTH>>3)-1:0] gp_axil_wstrb
    , output                                 gp_axil_wvalid
    , input                                  gp_axil_wready

    , input [1:0]                            gp_axil_bresp
    , input                                  gp_axil_bvalid
    , output                                 gp_axil_bready

    , output [C_S00_AXI_ADDR_WIDTH-1:0]      gp_axil_araddr
    , output [2:0]                           gp_axil_arprot
    , output                                 gp_axil_arvalid
    , input                                  gp_axil_arready

    , input [C_S00_AXI_DATA_WIDTH-1:0]       gp_axil_rdata
    , input [1:0]                            gp_axil_rresp
    , input                                  gp_axil_rvalid
    , output                                 gp_axil_rready
    );

    bsg_zynq_uart_bridge
     #(.m_axil_data_width_p(C_M01_AXI_DATA_WIDTH)
       ,.m_axil_addr_width_p(C_M01_AXI_ADDR_WIDTH)
       ,.gp_axil_data_width_p(C_S00_AXI_DATA_WIDTH)
       ,.gp_axil_addr_width_p(C_S00_AXI_ADDR_WIDTH)
       ,.uart_base_addr_p(UART_BASE_ADDR)
       )
     uart
      (.clk_i(clk)
       ,.reset_i(reset)

       ,.m_axil_awaddr_o(m_axil_awaddr)
       ,.m_axil_awprot_o(m_axil_awprot)
       ,.m_axil_awvalid_o(m_axil_awvalid)
       ,.m_axil_awready_i(m_axil_awready)

       ,.m_axil_wdata_o(m_axil_wdata)
       ,.m_axil_wstrb_o(m_axil_wstrb)
       ,.m_axil_wvalid_o(m_axil_wvalid)
       ,.m_axil_wready_i(m_axil_wready)

       ,.m_axil_bresp_i(m_axil_bresp)
       ,.m_axil_bvalid_i(m_axil_bvalid)
       ,.m_axil_bready_o(m_axil_bready)

       ,.m_axil_araddr_o(m_axil_araddr)
       ,.m_axil_arprot_o(m_axil_arprot)
       ,.m_axil_arvalid_o(m_axil_arvalid)
       ,.m_axil_arready_i(m_axil_arready)

       ,.m_axil_rdata_i(m_axil_rdata)
       ,.m_axil_rresp_i(m_axil_rresp)
       ,.m_axil_rvalid_i(m_axil_rvalid)
       ,.m_axil_rready_o(m_axil_rready)

       ,.gp_axil_awaddr_o(gp_axil_awaddr)
       ,.gp_axil_awprot_o(gp_axil_awprot)
       ,.gp_axil_awvalid_o(gp_axil_awvalid)
       ,.gp_axil_awready_i(gp_axil_awready)

       ,.gp_axil_wdata_o(gp_axil_wdata)
       ,.gp_axil_wstrb_o(gp_axil_wstrb)
       ,.gp_axil_wvalid_o(gp_axil_wvalid)
       ,.gp_axil_wready_i(gp_axil_wready)

       ,.gp_axil_bresp_i(gp_axil_bresp)
       ,.gp_axil_bvalid_i(gp_axil_bvalid)
       ,.gp_axil_bready_o(gp_axil_bready)

       ,.gp_axil_araddr_o(gp_axil_araddr)
       ,.gp_axil_arprot_o(gp_axil_arprot)
       ,.gp_axil_arvalid_o(gp_axil_arvalid)
       ,.gp_axil_arready_i(gp_axil_arready)

       ,.gp_axil_rdata_i(gp_axil_rdata)
       ,.gp_axil_rresp_i(gp_axil_rresp)
       ,.gp_axil_rvalid_i(gp_axil_rvalid)
       ,.gp_axil_rready_o(gp_axil_rready)
       );

endmodule

