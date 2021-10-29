
// TODO: This module will only work if the incoming axil stream
//   is not multiplexed between reads and writes. This is the case in BP.
//   More specifically, arvalid and awvalid should be mutex

module bsg_axil_demux
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , parameter `BSG_INV_PARAM(split_addr_p)
   )
  (input                                 clk_i
   , input                               reset_i

   , input [addr_width_p-1:0]            s00_axi_awaddr
   , input [2:0]                         s00_axi_awprot
   , input                               s00_axi_awvalid
   , output logic                        s00_axi_awready

   , input [data_width_p-1:0]            s00_axi_wdata
   , input [(data_width_p/8)-1:0]        s00_axi_wstrb
   , input                               s00_axi_wvalid
   , output logic                        s00_axi_wready

   , output logic [1:0]                  s00_axi_bresp
   , output logic                        s00_axi_bvalid
   , input                               s00_axi_bready

   , input [addr_width_p-1:0]            s00_axi_araddr
   , input [2:0]                         s00_axi_arprot
   , input                               s00_axi_arvalid
   , output logic                        s00_axi_arready

   , output logic [data_width_p-1:0]     s00_axi_rdata
   , output logic [1:0]                  s00_axi_rresp
   , output logic                        s00_axi_rvalid
   , input                               s00_axi_rready

   , output logic [addr_width_p-1:0]     m00_axi_awaddr
   , output logic [2:0]                  m00_axi_awprot
   , output logic                        m00_axi_awvalid
   , input                               m00_axi_awready

   , output logic [data_width_p-1:0]     m00_axi_wdata
   , output logic [(data_width_p/8)-1:0] m00_axi_wstrb
   , output logic                        m00_axi_wvalid
   , input                               m00_axi_wready

   , input [1:0]                         m00_axi_bresp
   , input                               m00_axi_bvalid
   , output logic                        m00_axi_bready

   , output logic [addr_width_p-1:0]     m00_axi_araddr
   , output logic [2:0]                  m00_axi_arprot
   , output logic                        m00_axi_arvalid
   , input                               m00_axi_arready

   , input [data_width_p-1:0]            m00_axi_rdata
   , input [1:0]                         m00_axi_rresp
   , input                               m00_axi_rvalid
   , output logic                        m00_axi_rready

   , output logic [addr_width_p-1:0]     m01_axi_awaddr
   , output logic [2:0]                  m01_axi_awprot
   , output logic                        m01_axi_awvalid
   , input                               m01_axi_awready

   , output logic [data_width_p-1:0]     m01_axi_wdata
   , output logic [(data_width_p/8)-1:0] m01_axi_wstrb
   , output logic                        m01_axi_wvalid
   , input                               m01_axi_wready

   , input [1:0]                         m01_axi_bresp
   , input                               m01_axi_bvalid
   , output logic                        m01_axi_bready

   , output logic [addr_width_p-1:0]     m01_axi_araddr
   , output logic [2:0]                  m01_axi_arprot
   , output logic                        m01_axi_arvalid
   , input                               m01_axi_arready

   , input [data_width_p-1:0]            m01_axi_rdata
   , input [1:0]                         m01_axi_rresp
   , input                               m01_axi_rvalid
   , output logic                        m01_axi_rready
   );

  logic select_m00_r, select_m01_r;
  wire clear_selection = (s00_axi_rvalid | s00_axi_bvalid);
  wire select_m00_n = (s00_axi_arvalid & s00_axi_araddr <= split_addr_p)
                      || (s00_axi_awvalid & s00_axi_awaddr <= split_addr_p);
  // Prioritize m00 statically. Could arbitrate, but this is low performance anyway
  wire select_m01_n = ((s00_axi_arvalid & s00_axi_araddr <= split_addr_p)
                       || (s00_axi_awvalid & s00_axi_awaddr <= split_addr_p))
                      && ~select_m00_n
                      && ~select_m01_r;
  bsg_dff_reset_set_clear
   #(.width_p(2))
   select_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.set_i({select_m01_n, select_m00_n})
     ,.clear_i({2{clear_selection}})
     ,.data_o({select_m01_r, select_m00_r})
     );

  assign {m01_axi_awaddr, m00_axi_awaddr} = {2{s00_axi_awaddr}};
  assign {m01_axi_awprot, m00_axi_awprot} = {2{s00_axi_awprot}};
  assign m00_axi_awvalid = select_m00_r & s00_axi_awvalid;
  assign m01_axi_awvalid = select_m01_r & s00_axi_awvalid;
  assign s00_axi_awready = (select_m00_r & m00_axi_awready) | (select_m01_r & m01_axi_awready);

  assign {m01_axi_wdata, m00_axi_wdata} = {2{s00_axi_wdata}};
  assign {m01_axi_wstrb, m00_axi_wstrb} = {2{s00_axi_wstrb}};
  assign m00_axi_wvalid = select_m00_r & s00_axi_wvalid;
  assign m01_axi_wvalid = select_m01_r & s00_axi_wvalid;
  assign s00_axi_wready = (select_m00_r & m00_axi_wready) | (select_m01_r & m01_axi_wready);

  assign s00_axi_bresp  = select_m01_r ? m00_axi_bresp : m01_axi_bresp;
  assign s00_axi_bvalid = (select_m00_r & m00_axi_bvalid) | (select_m01_r & m01_axi_bvalid);
  assign m00_axi_bready = select_m00_r & s00_axi_bready;
  assign m01_axi_bready = select_m01_r & s00_axi_bready;

  assign {m01_axi_araddr, m00_axi_araddr} = {2{s00_axi_araddr}};
  assign {m01_axi_arprot, m00_axi_arprot} = {2{s00_axi_arprot}};
  assign m00_axi_arvalid = select_m00_r & s00_axi_arvalid;
  assign m01_axi_arvalid = select_m01_r & s00_axi_arvalid;
  assign s00_axi_arready = (select_m00_r & m00_axi_arready) | (select_m01_r & m01_axi_arready);

  assign s00_axi_rdata = select_m01_r ? m01_axi_rdata : m00_axi_rdata;
  assign s00_axi_rresp = select_m01_r ? m01_axi_rresp : m00_axi_rresp;
  assign s00_axi_rvalid = (select_m00_r & m00_axi_rvalid) | (select_m01_r & m01_axi_rvalid);
  assign m00_axi_rready = select_m00_r & s00_axi_rready;
  assign m01_axi_rready = select_m01_r & s00_axi_rready;

endmodule

`BSG_ABSTRACT_MODULE(bsg_axil_decoder)

