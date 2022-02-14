

// synopsys translate_on

module rgmii_loopback_nonsynth
(
    input  logic       rx_rst_i
  , input  logic       rgmii_rx_clk_i
  , input  logic [3:0] rgmii_rxd_i
  , input  logic       rgmii_rx_ctl_i

  , input  logic       tx_rst_i
  , input  logic       rgmii_tx_clk_i
  , output logic [3:0] rgmii_txd_o
  , output logic       rgmii_tx_ctl_o
);

  logic [7:0] gmii_rxd, gmii_txd;
  bit rx_ctl_rise, rx_ctl_fall;
  bit rx_valid, rx_valid_r;
  bit tx_valid, tx_valid_r;
  always @(posedge rgmii_rx_clk_i)
    rx_ctl_rise <= rgmii_rx_ctl_i;
  always @(negedge rgmii_rx_clk_i)
    rx_ctl_fall <= rgmii_rx_ctl_i;
  always @(posedge rgmii_rx_clk_i)
    rx_valid_r <= rx_ctl_rise & rx_ctl_fall;
  assign rx_valid = rx_valid_r;

  iddr_nonsynth #(.WIDTH(4))
   iddr (.clk(rgmii_rx_clk_i)
    ,.d(rgmii_rxd_i)
    ,.q1(gmii_rxd[3:0])
    ,.q2(gmii_rxd[7:4]));

  bsg_async_fifo #(.lg_size_p(4)
    ,.width_p(8))
   gmii_async_fifo (.w_clk_i(rgmii_rx_clk_i)
    ,.w_reset_i(rx_rst_i)
    ,.w_enq_i(rx_valid)
    ,.w_data_i(gmii_rxd)
    ,.w_full_o()

    ,.r_clk_i(~rgmii_tx_clk_i)
    ,.r_reset_i(tx_rst_i)
    ,.r_deq_i(tx_valid)
    ,.r_data_o(gmii_txd)
    ,.r_valid_o(tx_valid));

  oddr_nonsynth #(.WIDTH(4))
   oddr (.clk(~rgmii_tx_clk_i)
    ,.d1(gmii_txd[3:0])
    ,.d2(gmii_txd[7:4])
    ,.q(rgmii_txd_o));

  always @(negedge rgmii_tx_clk_i)
    tx_valid_r <= tx_valid;

  assign rgmii_tx_ctl_o = tx_valid_r;
endmodule

// synopsys translate_on
