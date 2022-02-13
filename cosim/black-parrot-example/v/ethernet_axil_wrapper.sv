
`include "bsg_defines.v"
`include "bp_zynq_pl.vh"

module ethernet_axil_wrapper
  import bp_common_pkg::*;
#(
     // AXI CHANNEL PARAMS
      parameter axil_data_width_p = 32
    , parameter axil_addr_width_p = 32
)
(
      input  logic                         clk_i
    , input  logic                         reset_i
    , input  logic                         clk250_i
    , output logic                         reset_clk125_o
    // zynq-7000 specific: 200 MHZ for IDELAY tap value
    , input  logic                         iodelay_ref_clk_i

    //====================== AXI-4 LITE =========================
    // WRITE ADDRESS CHANNEL SIGNALS
    , input [axil_addr_width_p-1:0]        s_axil_awaddr_i
    , input [2:0]                          s_axil_awprot_i
    , input                                s_axil_awvalid_i
    , output logic                         s_axil_awready_o
 
    // WRITE DATA CHANNEL SIGNALS
    , input [axil_data_width_p-1:0]        s_axil_wdata_i
    , input [(axil_data_width_p>>3)-1:0]   s_axil_wstrb_i
    , input                                s_axil_wvalid_i
    , output logic                         s_axil_wready_o
 
    // WRITE RESPONSE CHANNEL SIGNALS
    , output logic [1:0]                   s_axil_bresp_o
    , output logic                         s_axil_bvalid_o
    , input                                s_axil_bready_i
 
    // READ ADDRESS CHANNEL SIGNALS
    , input [axil_addr_width_p-1:0]        s_axil_araddr_i
    , input [2:0]                          s_axil_arprot_i
    , input                                s_axil_arvalid_i
    , output logic                         s_axil_arready_o
 
    // READ DATA CHANNEL SIGNALS
    , output logic [axil_data_width_p-1:0] s_axil_rdata_o
    , output logic [1:0]                   s_axil_rresp_o
    , output logic                         s_axil_rvalid_o
    , input                                s_axil_rready_i

    //====================== Ethernet RGMII =========================
    , input  logic                         rgmii_rx_clk_i
    , input  logic [3:0]                   rgmii_rxd_i
    , input  logic                         rgmii_rx_ctl_i
    , output logic                         rgmii_tx_clk_o
    , output logic [3:0]                   rgmii_txd_o
    , output logic                         rgmii_tx_ctl_o

    //====================== Ethernet IRQ =========================
    , output logic                         irq_o
);

    // platform ("ZEDBOARD", "SIM")
`ifdef FPGA
    parameter PLATFORM = "ZEDBOARD";
`else
    parameter PLATFORM = "SIM";
`endif
    localparam size_width_lp = `BSG_WIDTH(`BSG_SAFE_CLOG2(axil_data_width_p/8));

    logic                         cmd_v_lo;
    logic                         cmd_ready_and_li;
    logic [axil_addr_width_p-1:0] cmd_addr_lo;
    logic                         cmd_wr_en_lo;
    logic [size_width_lp-1:0]     cmd_data_size_lo;
    logic [axil_data_width_p-1:0] cmd_wdata_lo;

    logic [axil_data_width_p-1:0] resp_fifo_li;
    logic                         resp_fifo_v_li;
    logic                         resp_fifo_ready_lo;
    logic                         resp_fifo_v_lo;
    logic [axil_data_width_p-1:0] resp_fifo_lo;
    logic                         resp_fifo_ready_and_li;
    logic                         resp_fifo_yumi_li;
    logic                         disable_r;

    logic                         rx_interrupt_pending_lo;
    logic                         tx_interrupt_pending_lo;

    wire write_en_li = cmd_v_lo & cmd_wr_en_lo;
    wire read_en_li = cmd_v_lo & ~cmd_wr_en_lo;
    logic read_en_lo;

    // Allow only 1 outstanding request
    bsg_dff_reset_set_clear #(
      .width_p(1)
      ,.clear_over_set_p(0)
    ) disable_reg (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.set_i(cmd_v_lo & cmd_ready_and_li)
      ,.clear_i(resp_fifo_yumi_li)
      ,.data_o(disable_r)
    );
    assign resp_fifo_yumi_li = resp_fifo_v_lo & resp_fifo_ready_and_li;
    assign cmd_ready_and_li = ~disable_r;
    assign resp_fifo_v_li = read_en_lo | write_en_li;

    // this tracks both read and write
    bsg_one_fifo #(
       .width_p(axil_data_width_p)
    ) resp_fifo (
       .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(resp_fifo_v_li)
      ,.ready_o(resp_fifo_ready_lo)
      ,.data_i(resp_fifo_li)
      ,.v_o(resp_fifo_v_lo)
      ,.data_o(resp_fifo_lo)
      ,.yumi_i(resp_fifo_yumi_li)
    );

    //synopsys translate_off
    always_ff @(posedge clk_i) begin
      if(~reset_i & (resp_fifo_v_li & ~resp_fifo_ready_lo))
        $display("ethernet_controller_wrapper.sv: read data dropped");
    end
    //synopsys translate_on

    axil_client_adaptor #(
       .axil_data_width_p(axil_data_width_p)
      ,.axil_addr_width_p(axil_addr_width_p)
    ) axil (
       .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.cmd_v_o(cmd_v_lo)
      ,.cmd_ready_and_i(cmd_ready_and_li)
      ,.cmd_addr_o(cmd_addr_lo)
      ,.cmd_wr_en_o(cmd_wr_en_lo)
      ,.cmd_data_size_o(cmd_data_size_lo)
      ,.cmd_wdata_o(cmd_wdata_lo)

      ,.resp_v_i(resp_fifo_v_lo)
      ,.resp_ready_and_o(resp_fifo_ready_and_li)
      ,.resp_rdata_i(resp_fifo_lo)

      ,.s_axil_awaddr_i
      ,.s_axil_awprot_i
      ,.s_axil_awvalid_i
      ,.s_axil_awready_o

      ,.s_axil_wdata_i
      ,.s_axil_wstrb_i
      ,.s_axil_wvalid_i
      ,.s_axil_wready_o

      ,.s_axil_bresp_o
      ,.s_axil_bvalid_o
      ,.s_axil_bready_i

      ,.s_axil_araddr_i
      ,.s_axil_arprot_i
      ,.s_axil_arvalid_i
      ,.s_axil_arready_o

      ,.s_axil_rdata_o
      ,.s_axil_rresp_o
      ,.s_axil_rvalid_o
      ,.s_axil_rready_i
    );

    ethernet_controller_wrapper #(
        .PLATFORM(PLATFORM)
       ,.data_width_p(axil_data_width_p)
    ) eth_ctr_wrapper (
        .clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.clk250_i(clk250_i)
       ,.reset_clk125_o(reset_clk125_o)
       ,.iodelay_ref_clk_i(iodelay_ref_clk_i)

       ,.addr_i(cmd_addr_lo)
       ,.write_en_i(write_en_li)
       ,.read_en_i(read_en_li)
       ,.op_size_i(cmd_data_size_lo)
       ,.write_data_i(cmd_wdata_lo)
       ,.read_data_o(resp_fifo_li) // sync read
       ,.read_data_v_o(read_en_lo)

       ,.rx_interrupt_pending_o(rx_interrupt_pending_lo)
       ,.tx_interrupt_pending_o(tx_interrupt_pending_lo)

       ,.rgmii_rx_clk_i(rgmii_rx_clk_i)
       ,.rgmii_rxd_i(rgmii_rxd_i)
       ,.rgmii_rx_ctl_i(rgmii_rx_ctl_i)
       ,.rgmii_tx_clk_o(rgmii_tx_clk_o)
       ,.rgmii_txd_o(rgmii_txd_o)
       ,.rgmii_tx_ctl_o(rgmii_tx_ctl_o)
    );

    assign irq_o = rx_interrupt_pending_lo | tx_interrupt_pending_lo;
endmodule
