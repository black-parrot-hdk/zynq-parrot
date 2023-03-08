
module watchdog
 #(// The period of the watchdog (default to 1s @25MHz)
     parameter integer WATCHDOG_PERIOD      = 25000000
   , parameter integer C_S02_AXI_DATA_WIDTH = 32
   , parameter integer C_S02_AXI_ADDR_WIDTH = 28
   )
  (input                                        aclk
   , input                                      aresetn

   , input                                      tag_clk
   , input                                      tag_data

   //====================== AXI-4 LITE =========================
   // WRITE ADDRESS CHANNEL SIGNALS
   , output [C_S02_AXI_ADDR_WIDTH-1:0]          m_axil_awaddr
   , output [2:0]                               m_axil_awprot
   , output                                     m_axil_awvalid
   , input                                      m_axil_awready

   // WRITE DATA CHANNEL SIGNALS
   , output [C_S02_AXI_DATA_WIDTH-1:0]          m_axil_wdata
   , output [(C_S02_AXI_DATA_WIDTH>>3)-1:0]     m_axil_wstrb
   , output                                     m_axil_wvalid
   , input                                      m_axil_wready

   // WRITE RESPONSE CHANNEL SIGNALS
   , input [1:0]                                m_axil_bresp
   , input                                      m_axil_bvalid
   , output                                     m_axil_bready

   // READ ADDRESS CHANNEL SIGNALS
   , output [C_S02_AXI_ADDR_WIDTH-1:0]          m_axil_araddr
   , output [2:0]                               m_axil_arprot
   , output                                     m_axil_arvalid
   , input                                      m_axil_arready

   // READ DATA CHANNEL SIGNALS
   , input [C_S02_AXI_DATA_WIDTH-1:0]           m_axil_rdata
   , input [1:0]                                m_axil_rresp
   , input                                      m_axil_rvalid
   , output                                     m_axil_rready
   );

  bsg_axil_watchdog
   #(.watchdog_period_p(WATCHDOG_PERIOD)
     ,.axil_data_width_p(C_S02_AXI_DATA_WIDTH)
     ,.axil_addr_width_p(C_S02_AXI_ADDR_WIDTH)
     )
   watchdog
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.tag_clk_i(tag_clk)
     ,.tag_data_i(tag_data)
        
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
     );

endmodule

