# clk250 -> clk125
create_generated_clock -name gtx_clk -source [get_pins {blackparrot_bd_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[1]}] -divide_by 2 [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/clock_downsampler/clk_r_o_reg/Q]
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

# Set false paths for clk250 reset sync chain
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/reset_clk250_sync_r_reg[0]/PRE]
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/reset_clk250_sync_r_reg[1]/PRE]
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/reset_clk250_sync_r_reg[2]/PRE]
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/reset_clk250_sync_r_reg[3]/PRE]

# Set false paths for idelayctrl reset sync chain
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/iodelay_control/reset_iodelay_sync_r_reg[0]/PRE]
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/iodelay_control/reset_iodelay_sync_r_reg[1]/PRE]
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/iodelay_control/reset_iodelay_sync_r_reg[2]/PRE]
set_false_path -to [get_pins blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/iodelay_control/reset_iodelay_sync_r_reg[3]/PRE]

# Set max delay for speed_reg sync under eth_mac_1g_rgmii_fifo
set_max_delay -datapath_only -from [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/eth_mac_1g_rgmii_inst/speed_reg_reg[0]/C}] -to [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/speed_sync_reg_1_reg[0]/D}] 8.000
set_max_delay -datapath_only -from [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/eth_mac_1g_rgmii_inst/speed_reg_reg[1]/C}] -to [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/speed_sync_reg_1_reg[1]/D}] 8.000

# Set max delay for TX/RX debug info
set_max_delay -datapath_only -from [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/tx_sync_reg_1_reg[0]/C}] -to [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/tx_sync_reg_2_reg[0]/D}] 8.000
set_max_delay -datapath_only -from [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/rx_sync_reg_1_reg[0]/C}] -to [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/rx_sync_reg_2_reg[0]/D}] 8.000
set_max_delay -datapath_only -from [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/rx_sync_reg_1_reg[1]/C}] -to [get_pins {blackparrot_bd_1_i/top_0/inst/top_fpga_inst/eth_axil/eth_ctr_wrapper/eth_ctr/eth/mac/rx_sync_reg_2_reg[1]/D}] 8.000


