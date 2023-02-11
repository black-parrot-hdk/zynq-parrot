
`include "bsg_defines.v"
`include "bp_zynq_pl.vh"

module ethernet_axil_wrapper
  import bp_common_pkg::*;
#(
     // AXI CHANNEL PARAMS
      parameter axil_data_width_p = 32
    , parameter axil_addr_width_p = 32
    , localparam axil_mask_width_lp = axil_data_width_p>>3
`ifdef FPGA
    , localparam simulation_lp = 0
`else
    , localparam simulation_lp = 1
`endif
)
(
      input  logic                         clk_i
    , input  logic                         reset_i
    , input  logic                         clk250_i
    , input  logic                         clk250_reset_i
    , input  logic                         tx_clk_gen_reset_i

    , output logic                         tx_clk_o
    , input  logic                         tx_reset_i

    , output logic                         rx_clk_o
    , input  logic                         rx_reset_i

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
    , input [axil_mask_width_lp-1:0]       s_axil_wstrb_i
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
    localparam size_width_lp = `BSG_WIDTH(`BSG_SAFE_CLOG2(axil_mask_width_lp));

    logic [axil_data_width_p-1:0]       axil_data_lo;
    logic [axil_addr_width_p-1:0]       axil_addr_lo;
    logic                               axil_v_lo;
    logic                               axil_w_lo;
    logic [axil_mask_width_lp-1:0]      axil_wmask_lo;
    logic                               axil_ready_and_li;
    logic [axil_data_width_p-1:0]       axil_data_li;
    logic                               axil_v_li;
    logic                               axil_ready_and_lo;

    logic                         disable_r;

    logic                         rx_interrupt_pending_lo;
    logic                         tx_interrupt_pending_lo;

    // control signal
    logic output_fifo_ready_lo;
    logic [axil_data_width_p-1:0] output_fifo_data_li;
    logic request_en_r;
    wire  request_backpressured = ~output_fifo_ready_lo & request_en_r;
    assign axil_ready_and_li = ~request_backpressured;

    logic [axil_mask_width_lp-1:0]  write_mask_li;
    wire write_en_li = axil_v_lo & axil_w_lo & ~request_backpressured;
    wire read_en_li = axil_v_lo & ~axil_w_lo & ~request_backpressured;


    // complete wmask is up to 64 / 8 == 8 bits
    logic [7:0] write_mask_tmp;
    // Convert misaligned address from AXIL to aligned address with proper write mask
    always_comb
      begin
        write_mask_tmp = '0;
        write_mask_li  = '0;
        case (axil_wmask_lo)
          axil_mask_width_lp'('h1):
            write_mask_tmp = (8'h1 << axil_addr_lo[2:0]);
          axil_mask_width_lp'('h3):
            write_mask_tmp = (8'h3 << {axil_addr_lo[2:1], 1'b0});
          axil_mask_width_lp'('hF):
            write_mask_tmp = (8'hF << {axil_addr_lo[2], 2'b0});
          default: // axil_mask_width_lp'('hFF)
            write_mask_tmp = 8'hFF;
        endcase
        case (axil_mask_width_lp)
          4: write_mask_li = write_mask_tmp[3:0] | write_mask_tmp[7:4];
          8: write_mask_li = write_mask_tmp;
        endcase
      end

    //////////////////////////////////////////////
    // Stage 0 -> 1
    bsg_dff_reset_en
     #(.width_p(1))
      request_reg
       (.clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.en_i(~request_backpressured)
        ,.data_i(read_en_li | write_en_li)
        ,.data_o(request_en_r)
        );

    ethernet_controller_wrapper #(
        .data_width_p(axil_data_width_p)
       ,.simulation_p(simulation_lp)
    ) eth_ctr_wrapper (
        .clk_i
       ,.reset_i
       ,.clk250_i
       ,.clk250_reset_i
       ,.tx_clk_gen_reset_i
       ,.tx_clk_o
       ,.tx_reset_i
       ,.rx_clk_o
       ,.rx_reset_i
       ,.iodelay_ref_clk_i

       ,.addr_i(axil_addr_lo)
       ,.write_en_i(write_en_li)
       ,.read_en_i(read_en_li)
       ,.write_mask_i(write_mask_li)
       ,.write_data_i(axil_data_lo)
       ,.read_data_o(output_fifo_data_li) // sync read

       ,.rx_interrupt_pending_o(rx_interrupt_pending_lo)
       ,.tx_interrupt_pending_o(tx_interrupt_pending_lo)

       ,.rgmii_rx_clk_i(rgmii_rx_clk_i)
       ,.rgmii_rxd_i(rgmii_rxd_i)
       ,.rgmii_rx_ctl_i(rgmii_rx_ctl_i)
       ,.rgmii_tx_clk_o(rgmii_tx_clk_o)
       ,.rgmii_txd_o(rgmii_txd_o)
       ,.rgmii_tx_ctl_o(rgmii_tx_ctl_o)
    );

    //////////////////////////////////////////////
    // Stage 1 -> 2
    bsg_two_fifo
     #(.width_p(axil_data_width_p))
      output_fifo
      (.clk_i
       ,.reset_i
       ,.ready_o(output_fifo_ready_lo)
       ,.data_i(output_fifo_data_li)
       ,.v_i(request_en_r)
       ,.v_o(axil_v_li)
       ,.data_o(axil_data_li)
       ,.yumi_i(axil_ready_and_lo & axil_v_li)
       );

    //////////////////////////////////////////////
    // Stage 2 -> 3
    bsg_axil_fifo_client #(
       .axil_data_width_p(axil_data_width_p)
      ,.axil_addr_width_p(axil_addr_width_p)
      ,.fifo_els_p(2)
    ) axil (
       .clk_i
      ,.reset_i

      ,.data_o(axil_data_lo)
      ,.addr_o(axil_addr_lo)
      ,.v_o(axil_v_lo)
      ,.w_o(axil_w_lo)
      ,.wmask_o(axil_wmask_lo)
      ,.ready_and_i(axil_ready_and_li)

      ,.data_i(axil_data_li)
      ,.v_i(axil_v_li)
      ,.ready_and_o(axil_ready_and_lo)

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


    assign irq_o = rx_interrupt_pending_lo | tx_interrupt_pending_lo;
endmodule
