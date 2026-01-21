

module top_zynq
 #(// Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_HP1_AXI_DATA_WIDTH     = 32

   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_HP1_AXI_ADDR_WIDTH   = 6
   )
  (input                                         aclk
   , input                                       aresetn

   , output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]     hp1_axi_awaddr
   , output wire [2 : 0]                          hp1_axi_awprot
   , output wire                                  hp1_axi_awvalid
   , input wire                                 hp1_axi_awready
   , output wire [C_HP1_AXI_DATA_WIDTH-1 : 0]     hp1_axi_wdata
   , output wire [(C_HP1_AXI_DATA_WIDTH/8)-1 : 0] hp1_axi_wstrb
   , output wire                                  hp1_axi_wvalid
   , input wire                                 hp1_axi_wready
   , input wire [1 : 0]                         hp1_axi_bresp
   , input wire                                 hp1_axi_bvalid
   , output wire                                  hp1_axi_bready
   , output wire [C_HP1_AXI_ADDR_WIDTH-1 : 0]     hp1_axi_araddr
   , output wire [2 : 0]                          hp1_axi_arprot
   , output wire                                  hp1_axi_arvalid
   , input wire                                 hp1_axi_arready
   , input wire [C_HP1_AXI_DATA_WIDTH-1 : 0]    hp1_axi_rdata
   , input wire [1 : 0]                         hp1_axi_rresp
   , input wire                                 hp1_axi_rvalid
   , output wire                                  hp1_axi_rready

   , input                                       intc0
   );

  localparam ui_data_width_lp = 32;
  localparam ui_addr_width_lp = 6;
  localparam ui_els_lp = 2**ui_addr_width_lp;

  logic [ui_addr_width_lp-1:0] ui_axil_awaddr;
  logic [2:0] ui_axil_awprot;
  logic ui_axil_awvalid, ui_axil_awready;
  logic [ui_data_width_lp-1:0] ui_axil_wdata;
  logic [(ui_data_width_lp/8)-1:0] ui_axil_wstrb;
  logic ui_axil_wvalid, ui_axil_wready;
  logic [1:0] ui_axil_bresp;
  logic ui_axil_bvalid, ui_axil_bready;
  logic [ui_addr_width_lp-1:0] ui_axil_araddr;
  logic [2:0] ui_axil_arprot;
  logic ui_axil_arvalid, ui_axil_arready;
  logic [ui_data_width_lp-1:0] ui_axil_rdata;
  logic [1:0] ui_axil_rresp;
  logic ui_axil_rvalid, ui_axil_rready;

  bsg_axil_uart_bridge
   #(.uart_axil_data_width_p(C_HP1_AXI_DATA_WIDTH)
     ,.uart_axil_addr_width_p(C_HP1_AXI_ADDR_WIDTH)
     ,.ui_axil_data_width_p(ui_data_width_lp)
     ,.ui_axil_addr_width_p(ui_addr_width_lp)
     )
   bridge
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.uart_axil_awaddr_o(hp1_axi_awaddr)
     ,.uart_axil_awprot_o(hp1_axi_awprot)
     ,.uart_axil_awvalid_o(hp1_axi_awvalid)
     ,.uart_axil_awready_i(hp1_axi_awready)

     ,.uart_axil_wdata_o(hp1_axi_wdata)
     ,.uart_axil_wstrb_o(hp1_axi_wstrb)
     ,.uart_axil_wvalid_o(hp1_axi_wvalid)
     ,.uart_axil_wready_i(hp1_axi_wready)

     ,.uart_axil_bresp_i(hp1_axi_bresp)
     ,.uart_axil_bvalid_i(hp1_axi_bvalid)
     ,.uart_axil_bready_o(hp1_axi_bready)

     ,.uart_axil_araddr_o(hp1_axi_araddr)
     ,.uart_axil_arprot_o(hp1_axi_arprot)
     ,.uart_axil_arvalid_o(hp1_axi_arvalid)
     ,.uart_axil_arready_i(hp1_axi_arready)

     ,.uart_axil_rdata_i(hp1_axi_rdata)
     ,.uart_axil_rresp_i(hp1_axi_rresp)
     ,.uart_axil_rvalid_i(hp1_axi_rvalid)
     ,.uart_axil_rready_o(hp1_axi_rready)

     ,.uart_interrupt_i(intc0)

     ,.ui_axil_awaddr_o(ui_axil_awaddr)
     ,.ui_axil_awprot_o(ui_axil_awprot)
     ,.ui_axil_awvalid_o(ui_axil_awvalid)
     ,.ui_axil_awready_i(ui_axil_awready)

     ,.ui_axil_wdata_o(ui_axil_wdata)
     ,.ui_axil_wstrb_o(ui_axil_wstrb)
     ,.ui_axil_wvalid_o(ui_axil_wvalid)
     ,.ui_axil_wready_i(ui_axil_wready)

     ,.ui_axil_bresp_i(ui_axil_bresp)
     ,.ui_axil_bvalid_i(ui_axil_bvalid)
     ,.ui_axil_bready_o(ui_axil_bready)

     ,.ui_axil_araddr_o(ui_axil_araddr)
     ,.ui_axil_arprot_o(ui_axil_arprot)
     ,.ui_axil_arvalid_o(ui_axil_arvalid)
     ,.ui_axil_arready_i(ui_axil_arready)

     ,.ui_axil_rdata_i(ui_axil_rdata)
     ,.ui_axil_rresp_i(ui_axil_rresp)
     ,.ui_axil_rvalid_i(ui_axil_rvalid)
     ,.ui_axil_rready_o(ui_axil_rready)
     );

  logic [ui_data_width_lp-1:0] c_wdata_lo;
  logic [ui_addr_width_lp-1:0] c_addr_lo;
  logic [(ui_data_width_lp/8)-1:0] c_wmask_lo;
  logic c_v_lo, c_w_lo, c_ready_and_li;
  logic [ui_data_width_lp-1:0] c_rdata_li;
  logic c_v_li, c_ready_and_lo;
  bsg_axil_fifo_client
   #(.axil_data_width_p(ui_data_width_lp)
     ,.axil_addr_width_p(ui_addr_width_lp)
     )
   fifo_client
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.data_o(c_wdata_lo)
     ,.addr_o(c_addr_lo)
     ,.v_o(c_v_lo)
     ,.w_o(c_w_lo)
     ,.wmask_o(c_wmask_lo)
     ,.ready_and_i(c_ready_and_li)

     ,.data_i(c_rdata_li)
     ,.v_i(c_v_li)
     ,.ready_and_o(c_ready_and_lo)

     ,.s_axil_awaddr_i(ui_axil_awaddr)
     ,.s_axil_awprot_i(ui_axil_awprot)
     ,.s_axil_awvalid_i(ui_axil_awvalid)
     ,.s_axil_awready_o(ui_axil_awready)

     ,.s_axil_wdata_i(ui_axil_wdata)
     ,.s_axil_wstrb_i(ui_axil_wstrb)
     ,.s_axil_wvalid_i(ui_axil_wvalid)
     ,.s_axil_wready_o(ui_axil_wready)

     ,.s_axil_bresp_o(ui_axil_bresp)
     ,.s_axil_bvalid_o(ui_axil_bvalid)
     ,.s_axil_bready_i(ui_axil_bready)

     ,.s_axil_araddr_i(ui_axil_araddr)
     ,.s_axil_arprot_i(ui_axil_arprot)
     ,.s_axil_arvalid_i(ui_axil_arvalid)
     ,.s_axil_arready_o(ui_axil_arready)

     ,.s_axil_rdata_o(ui_axil_rdata)
     ,.s_axil_rresp_o(ui_axil_rresp)
     ,.s_axil_rvalid_o(ui_axil_rvalid)
     ,.s_axil_rready_i(ui_axil_rready)
     );

  logic [ui_data_width_lp-1:0] ui_mem [0:ui_els_lp-1];
  logic req_v_r;
  wire req_set = c_ready_and_li & c_v_lo;
  wire req_clear = c_ready_and_lo & c_v_li;
  bsg_dff_reset_set_clear
   #(.width_p(1))
   req_v_reg
    (.clk_i(aclk)
     ,.reset_i(~aresetn)
     ,.set_i(req_set)
     ,.clear_i(req_clear)
     ,.data_o(req_v_r)
     );

  assign c_ready_and_li = ~req_v_r;
  assign c_v_li = req_v_r;

  always_ff @(posedge aclk)
    if (c_ready_and_li & c_v_lo & c_w_lo)
      ui_mem[c_addr_lo] <= c_wdata_lo;
    else if (c_ready_and_li & c_v_lo & ~c_w_lo)
      c_rdata_li <= ui_mem[c_addr_lo];

endmodule

