
// TODO: This module will only work if the incoming axil stream
//   is not multiplexed between reads and writes. This is the case in BP.
//   More specifically, arvalid and awvalid should be mutex

`include "bsg_defines.v"

module bsg_axil_demux
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , parameter `BSG_INV_PARAM(split_addr_p)
   )
  (input                                 clk_i
   , input                               reset_i

   , input [addr_width_p-1:0]            s00_axil_awaddr
   , input [2:0]                         s00_axil_awprot
   , input                               s00_axil_awvalid
   , output logic                        s00_axil_awready

   , input [data_width_p-1:0]            s00_axil_wdata
   , input [(data_width_p/8)-1:0]        s00_axil_wstrb
   , input                               s00_axil_wvalid
   , output logic                        s00_axil_wready

   , output logic [1:0]                  s00_axil_bresp
   , output logic                        s00_axil_bvalid
   , input                               s00_axil_bready

   , input [addr_width_p-1:0]            s00_axil_araddr
   , input [2:0]                         s00_axil_arprot
   , input                               s00_axil_arvalid
   , output logic                        s00_axil_arready

   , output logic [data_width_p-1:0]     s00_axil_rdata
   , output logic [1:0]                  s00_axil_rresp
   , output logic                        s00_axil_rvalid
   , input                               s00_axil_rready

   , output logic [addr_width_p-1:0]     m00_axil_awaddr
   , output logic [2:0]                  m00_axil_awprot
   , output logic                        m00_axil_awvalid
   , input                               m00_axil_awready

   , output logic [data_width_p-1:0]     m00_axil_wdata
   , output logic [(data_width_p/8)-1:0] m00_axil_wstrb
   , output logic                        m00_axil_wvalid
   , input                               m00_axil_wready

   , input [1:0]                         m00_axil_bresp
   , input                               m00_axil_bvalid
   , output logic                        m00_axil_bready

   , output logic [addr_width_p-1:0]     m00_axil_araddr
   , output logic [2:0]                  m00_axil_arprot
   , output logic                        m00_axil_arvalid
   , input                               m00_axil_arready

   , input [data_width_p-1:0]            m00_axil_rdata
   , input [1:0]                         m00_axil_rresp
   , input                               m00_axil_rvalid
   , output logic                        m00_axil_rready

   , output logic [addr_width_p-1:0]     m01_axil_awaddr
   , output logic [2:0]                  m01_axil_awprot
   , output logic                        m01_axil_awvalid
   , input                               m01_axil_awready

   , output logic [data_width_p-1:0]     m01_axil_wdata
   , output logic [(data_width_p/8)-1:0] m01_axil_wstrb
   , output logic                        m01_axil_wvalid
   , input                               m01_axil_wready

   , input [1:0]                         m01_axil_bresp
   , input                               m01_axil_bvalid
   , output logic                        m01_axil_bready

   , output logic [addr_width_p-1:0]     m01_axil_araddr
   , output logic [2:0]                  m01_axil_arprot
   , output logic                        m01_axil_arvalid
   , input                               m01_axil_arready

   , input [data_width_p-1:0]            m01_axil_rdata
   , input [1:0]                         m01_axil_rresp
   , input                               m01_axil_rvalid
   , output logic                        m01_axil_rready
   );

  logic select_m00_r, select_m01_r;
  wire clear_selection = ((s00_axil_rvalid & s00_axil_rready) | (s00_axil_bvalid & s00_axil_bready));
  wire select_m00_n = ((s00_axil_arvalid && (s00_axil_araddr < split_addr_p))
                       || (s00_axil_awvalid && (s00_axil_awaddr < split_addr_p))
                       )
                      && ~select_m00_r
                      && ~select_m01_r;
  // Prioritize m00 statically. Could arbitrate, but this is low performance anyway
  wire select_m01_n = ((s00_axil_arvalid & (s00_axil_araddr >= split_addr_p))
                       || (s00_axil_awvalid & (s00_axil_awaddr >= split_addr_p))
                       )
                      && ~select_m00_n
                      && ~select_m00_r
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

  assign {m01_axil_awaddr, m00_axil_awaddr} = {2{s00_axil_awaddr}};
  assign {m01_axil_awprot, m00_axil_awprot} = {2{s00_axil_awprot}};
  assign m00_axil_awvalid = select_m00_r & s00_axil_awvalid;
  assign m01_axil_awvalid = select_m01_r & s00_axil_awvalid;
  assign s00_axil_awready = (select_m00_r & m00_axil_awready) | (select_m01_r & m01_axil_awready);

  assign {m01_axil_wdata, m00_axil_wdata} = {2{s00_axil_wdata}};
  assign {m01_axil_wstrb, m00_axil_wstrb} = {2{s00_axil_wstrb}};
  assign m00_axil_wvalid = select_m00_r & s00_axil_wvalid;
  assign m01_axil_wvalid = select_m01_r & s00_axil_wvalid;
  assign s00_axil_wready = (select_m00_r & m00_axil_wready) | (select_m01_r & m01_axil_wready);

  assign s00_axil_bresp  = select_m01_r ? m01_axil_bresp : m00_axil_bresp;
  assign s00_axil_bvalid = (select_m00_r & m00_axil_bvalid) | (select_m01_r & m01_axil_bvalid);
  assign m00_axil_bready = select_m00_r & s00_axil_bready;
  assign m01_axil_bready = select_m01_r & s00_axil_bready;

  assign {m01_axil_araddr, m00_axil_araddr} = {2{s00_axil_araddr}};
  assign {m01_axil_arprot, m00_axil_arprot} = {2{s00_axil_arprot}};
  assign m00_axil_arvalid = select_m00_r & s00_axil_arvalid;
  assign m01_axil_arvalid = select_m01_r & s00_axil_arvalid;
  assign s00_axil_arready = (select_m00_r & m00_axil_arready) | (select_m01_r & m01_axil_arready);

  assign s00_axil_rdata = select_m01_r ? m01_axil_rdata : m00_axil_rdata;
  assign s00_axil_rresp = select_m01_r ? m01_axil_rresp : m00_axil_rresp;
  assign s00_axil_rvalid = (select_m00_r & m00_axil_rvalid) | (select_m01_r & m01_axil_rvalid);
  assign m00_axil_rready = select_m00_r & s00_axil_rready;
  assign m01_axil_rready = select_m01_r & s00_axil_rready;

endmodule

`BSG_ABSTRACT_MODULE(bsg_axil_demux)

