# ----------------------------------------------------------------------------
# FMC Expansion Connector - Bank 34
# ----------------------------------------------------------------------------


set_property PACKAGE_PIN M19 [get_ports rgmii_rx_clk_i]
set_property PACKAGE_PIN K18 [get_ports {eth_phy_resetn_o}]
set_property PACKAGE_PIN M20 [get_ports rgmii_rx_ctl_i]
set_property PACKAGE_PIN P17 [get_ports {rgmii_rxd_i[0]}]
set_property PACKAGE_PIN P18 [get_ports {rgmii_rxd_i[1]}]
set_property PACKAGE_PIN N22 [get_ports {rgmii_rxd_i[2]}]
set_property PACKAGE_PIN P22 [get_ports {rgmii_rxd_i[3]}]
set_property PACKAGE_PIN T17 [get_ports rgmii_tx_ctl_o]
set_property PACKAGE_PIN M22 [get_ports rgmii_tx_clk_o]
set_property PACKAGE_PIN M21 [get_ports {rgmii_txd_o[0]}]
set_property PACKAGE_PIN J21 [get_ports {rgmii_txd_o[1]}]
set_property PACKAGE_PIN J22 [get_ports {rgmii_txd_o[2]}]
set_property PACKAGE_PIN T16 [get_ports {rgmii_txd_o[3]}]



set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_resetn_o}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxd_i[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxd_i[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxd_i[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rxd_i[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txd_o[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txd_o[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txd_o[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_txd_o[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_rx_clk_i]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_rx_ctl_i]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_tx_clk_o]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_tx_ctl_o]
