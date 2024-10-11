
set bp_inst [join [get_cells -hier blackparrot]]

set bp_core_period [get_property PERIOD [get_clocks -of_object [get_pins $bp_inst/aclk]]]
set bp_rt_period [get_property PERIOD [get_clocks -of_object [get_pins $bp_inst/rt_clk]]]
set bp_min_period [expr $bp_rt_period < $bp_core_period ? $bp_rt_period : $bp_core_period]

set clint_inst [join [get_cells -hier -filter {(ORIG_REF_NAME == bp_me_clint_slice || REF_NAME == bp_me_clint_slice)}]]
if {[llength clint_inst] != 1} {
  error "More than one bp_me_clint_slice instance has been found"
}
create_generated_clock -name ds_by_16_clk -source [get_pins $clint_inst/ds/aclk] -divide_by 16 [get_pins $clint_inst/ds/clk_r_o_reg/Q]

# In BP, there is a 4-1 clock multiplexer that selects between 3 clocks and 1'b0 as the mtime clock.
# (The 4-1 clock mux)
#
#
#        |\
#    +---| \ (rtc_mux1)
#        | |-+
#    +---| / |  |\
#        |/  +--| \ (rtc_mux3)
#               | |---+
#        |\  +--| /
#    +---| \ |  |/
#        | |-+
#    +---| / (rtc_mux2)
#        |/
#
# 'join' converts a list into a string
#set rtc_mux1 [join [get_cells -hier *bufgmux_ctrl1]]
#set rtc_mux2 [join [get_cells -hier *bufgmux_ctrl2]]
#set rtc_mux3 [join [get_cells -hier *bufgmux_ctrl3]]

set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[0]]
set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[1]]

# max delay for the bufgmux_ctrl primitives
#set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*] $bp_min_period
#set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*] $bp_min_period
#set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*] $bp_min_period

#set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*]
#set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*]
#set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*]

# Create generated clock for the bit banging clock
set bb_inst [join [get_cells -hier -filter {(ORIG_REF_NAME == bsg_tag_bitbang || REF_NAME == bsg_tag_bitbang)}]]
create_generated_clock -name bb_clk -source [get_pins $bb_inst/aclk] -edges {3 5 7} [get_pins $bb_inst/tag_clk_reg/data_r_reg[0]/Q]

# FPGA Pin Locations

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


set clk250_source_pin {blackparrot_bd_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[2]}
