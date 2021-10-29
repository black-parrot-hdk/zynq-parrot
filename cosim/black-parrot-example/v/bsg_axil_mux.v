// TODO: This module will only work if the incoming axil streams
//   are not pipelined. This is the case in BP. More specifically,
//   once a request on S00 starts, another request should not come
//   in until the first is complete
module bsg_axil_mux
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
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

   , input [addr_width_p-1:0]            s01_axi_awaddr
   , input [2:0]                         s01_axi_awprot
   , input                               s01_axi_awvalid
   , output logic                        s01_axi_awready

   , input [data_width_p-1:0]            s01_axi_wdata
   , input [(data_width_p/8)-1:0]        s01_axi_wstrb
   , input                               s01_axi_wvalid
   , output logic                        s01_axi_wready

   , output logic [1:0]                  s01_axi_bresp
   , output logic                        s01_axi_bvalid
   , input                               s01_axi_bready

   , input [addr_width_p-1:0]            s01_axi_araddr
   , input [2:0]                         s01_axi_arprot
   , input                               s01_axi_arvalid
   , output logic                        s01_axi_arready

   , output logic [data_width_p-1:0]     s01_axi_rdata
   , output logic [1:0]                  s01_axi_rresp
   , output logic                        s01_axi_rvalid
   , input                               s01_axi_rready

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
   );

  logic select_s00_r, select_s01_r;
  wire clear_selection = (m00_axi_rvalid & m00_axi_rready) | (m01_axi_bvalid & m01_axi_bready);
  // Statically prioritize s00 for now
  wire select_s00_n = (s00_axi_rvalid | s00_axi_awvalid);
  wire select_s01_n = (s01_axi_rvalid | s01_axi_awvalid) & ~select_s01_n & ~select_s01_r;
  bsg_dff_reset_set_clear
   #(.width_p(2))
   select_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.set_i({select_s01_n, select_s00_n})
     ,.clear_i(2{clear_selection}})
     ,.data_o({select_s01_r, select_s00_r})
     );

  assign m00_axi_awaddr  = select_s01_r ? s01_axi_awaddr : s00_axi_awaddr;
  assign m00_axi_awprot  = select_s01_r ? s01_axi_awprot : s00_axi_awprot;
  assign m00_axi_awvalid = (select_s00_r & s00_axi_awvalid) || (select_s01_r & s01_axi_awvalid);
  assign s00_axi_awready = m00_axi_awready & select_s00_r;
  assign s01_axi_awready = m00_axi_awready & select_s01_r;

  assign m00_axi_wdata  = select_s01_r ? s01_axi_wdata : s00_axi_wdata;
  assign m00_axi_wstrb  = select_s01_r ? s01_axi_wstrb : s00_axi_wstrb;
  assign m00_axi_wvalid = (select_s01_r & s01_axi_wvalid) | (select_s01_r & s01_axi_wvalid);
  assign s00_axi_wready = m00_axi_wready & select_s00_r;
  assign s01_axi_wready = m00_axi_wready & select_s01_r;

  assign {s01_axi_bresp, s00_axi_bresp} = {2{m00_axi_bresp}};
  assign s00_axi_bvalid = select_s00_r & m00_axi_bvalid;
  assign s00_axi_bvalid = select_s01_r & m00_axi_bvalid;
  assign m00_axi_bready = (select_s00_r & s00_axi_bready) | (select_s01_r & s01_axi_bready);

  assign m00_axi_araddr  = select_s01_r ? s01_axi_araddr : s00_axi_araddr;
  assign m00_axi_arprot  = select_s01_r ? s01_axi_arprot : s00_axi_arprot;
  assign m00_axi_arvalid = (select_s00_r & s00_axi_arvalid) | (select_s01_r & s01_axi_arvalid);
  assign s00_axi_arready = select_s00_r & m00_axi_arready;
  assign s01_axi_arready = select_s01_r & m00_axi_arready;

  assign {s01_axi_rdata, s00_axi_rdata} = {2{m00_axi_rdata}};
  assign {s01_axi_rresp, s00_axi_rresp} = {2{m00_axi_rresp}};
  assign s00_axi_rvalid = select_s00_r & m00_axi_rvalid;
  assign s01_axi_rvalid = select_s01_r & m00_axi_rvalid;
  assign m00_axi_rready = (select_s00_r & s00_axi_rready) | (select_s01_r & s01_axi_rready);

endmodule

`BSG_ABSTRACT_MODULE(bsg_axil_mux)

