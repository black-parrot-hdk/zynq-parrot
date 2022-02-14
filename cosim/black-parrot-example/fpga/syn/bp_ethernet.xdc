# clk250 -> clk125
set inst [get_cells -hier -filter {(ORIG_REF_NAME == gtx_clk_and_phy_tx_clk_generator || REF_NAME == gtx_clk_and_phy_tx_clk_generator)}]
create_generated_clock -name gtx_clk -source [get_pins {blackparrot_bd_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[1]}] -divide_by 2 [get_pins $inst/gtx_clk_gen/clk_r_o_reg/Q]
# clk250 -> 90-degree shifted clk125 for rgmii TX clk source
create_generated_clock -name rgmii_tx_clk -source [get_pins {blackparrot_bd_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[1]}] -edges {2 4 6} -edge_shift {0.000 0.000 0.000} [get_ports rgmii_tx_clk_o]
# RX clk source (125M)
create_clock -period 8.000 -name rgmii_rx_clk -waveform {0.000 4.000} [get_ports rgmii_rx_clk_i]

# Set input delay for RX RGMII
set RX_MAX_DELAY 3.500
set RX_MIN_DELAY 1.800

set_input_delay -clock [get_clocks rgmii_rx_clk] -max $RX_MAX_DELAY [get_ports rgmii_rxd*]
set_input_delay -clock [get_clocks rgmii_rx_clk] -min $RX_MIN_DELAY [get_ports rgmii_rxd*]
set_input_delay -clock [get_clocks rgmii_rx_clk] -clock_fall -max -add_delay $RX_MAX_DELAY [get_ports rgmii_rxd*]
set_input_delay -clock [get_clocks rgmii_rx_clk] -clock_fall -min -add_delay $RX_MIN_DELAY [get_ports rgmii_rxd*]

set_input_delay -clock [get_clocks rgmii_rx_clk] -max $RX_MAX_DELAY [get_ports rgmii_rx_ctl_i]
set_input_delay -clock [get_clocks rgmii_rx_clk] -min $RX_MIN_DELAY [get_ports rgmii_rx_ctl_i]
set_input_delay -clock [get_clocks rgmii_rx_clk] -clock_fall -max -add_delay $RX_MAX_DELAY [get_ports rgmii_rx_ctl_i]
set_input_delay -clock [get_clocks rgmii_rx_clk] -clock_fall -min -add_delay $RX_MIN_DELAY [get_ports rgmii_rx_ctl_i]

# Set output delay for TX RGMII 
set TX_MAX_DELAY  1.600
set TX_MIN_DELAY -1.600

set_output_delay -clock [get_clocks rgmii_tx_clk] -max $TX_MAX_DELAY [get_ports rgmii_txd*]
set_output_delay -clock [get_clocks rgmii_tx_clk] -min $TX_MIN_DELAY [get_ports rgmii_txd*]
set_output_delay -clock [get_clocks rgmii_tx_clk] -clock_fall -max -add_delay $TX_MAX_DELAY [get_ports rgmii_txd*]
set_output_delay -clock [get_clocks rgmii_tx_clk] -clock_fall -min -add_delay $TX_MIN_DELAY [get_ports rgmii_txd*]

set_output_delay -clock [get_clocks rgmii_tx_clk] -max $TX_MAX_DELAY [get_ports rgmii_tx_ctl_o]
set_output_delay -clock [get_clocks rgmii_tx_clk] -min $TX_MIN_DELAY [get_ports rgmii_tx_ctl_o]
set_output_delay -clock [get_clocks rgmii_tx_clk] -clock_fall -max -add_delay $TX_MAX_DELAY [get_ports rgmii_tx_ctl_o]
set_output_delay -clock [get_clocks rgmii_tx_clk] -clock_fall -min -add_delay $TX_MIN_DELAY [get_ports rgmii_tx_ctl_o]

# Set IOB packing for TX RGMII outputs in order to help meet timing
set_property IOB TRUE [get_ports rgmii_tx_clk_o]
set_property IOB TRUE [get_ports rgmii_tx_ctl_o]
set_property IOB TRUE [get_ports rgmii_txd_o[0]]
set_property IOB TRUE [get_ports rgmii_txd_o[1]]
set_property IOB TRUE [get_ports rgmii_txd_o[2]]
set_property IOB TRUE [get_ports rgmii_txd_o[3]]
