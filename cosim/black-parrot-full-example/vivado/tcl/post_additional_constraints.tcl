###################### Default max delay ######################
# Set default max delay between each async clock groups to 0 in order to catch unnoticed paths
# set_max_delay is used instead of set_clock_groups in order to have safer constraints
# Async groups:
# 1. clk_fpga_0 (20 MHZ) (BP's clk, ds_by_16_clk)
# 2. clk_fpga_1 (0.4 MHZ) (BP's RTC)
# 2. clk_fpga_2 (250 MHZ) (clk250, gtx_clk, rgmii_tx_clk)
# 4. clk_fpga_3 (200 MHZ for iodelayctl)
# 5. rgmii_rx_clk (from Ethernet PHY)
set cd0 [join [get_clocks -include_generated_clocks clk_fpga_0]]
set cd1 [join [get_clocks -include_generated_clocks clk_fpga_1]]
set cd2 [join [get_clocks -include_generated_clocks clk_fpga_2]]
set cd3 [join [get_clocks -include_generated_clocks clk_fpga_3]]
set cd4 [join [get_clocks -include_generated_clocks rgmii_rx_clk]]
set_max_delay -from [get_clocks $cd0] -to [get_clocks "$cd1 $cd2 $cd3 $cd4"] -datapath_only 0.0
set_max_delay -from [get_clocks $cd1] -to [get_clocks "$cd0 $cd2 $cd3 $cd4"] -datapath_only 0.0
set_max_delay -from [get_clocks $cd2] -to [get_clocks "$cd0 $cd1 $cd3 $cd4"] -datapath_only 0.0
set_max_delay -from [get_clocks $cd3] -to [get_clocks "$cd0 $cd1 $cd2 $cd4"] -datapath_only 0.0
set_max_delay -from [get_clocks $cd4] -to [get_clocks "$cd0 $cd1 $cd2 $cd3"] -datapath_only 0.0

################# bsg_launch_sync_sync #################
foreach blss_inst [get_cells -hier -filter {(ORIG_REF_NAME == bsg_launch_sync_sync || REF_NAME == bsg_launch_sync_sync)}] {
  puts "blss_inst: $blss_inst"
  foreach launch_reg [get_cells $blss_inst/*/bsg_SYNC_LNCH_r_reg[*]] {
    # ASYNC_REG should have been applied in RTL
    regexp {([\w/.\[\]]+)/[\w]+\[([0-9]+)\]} $launch_reg -> path index

    set source_cell [get_cells $path/bsg_SYNC_LNCH_r_reg[$index]]
    set dest_cell  [get_cells $path/bsg_SYNC_1_r_reg[$index]]
    set write_clk [get_clocks -of_objects [get_pins $source_cell/C]]
    set read_clk [get_clocks -of_objects [get_pins $dest_cell/C]]
    set read_clk_period  [get_property -min PERIOD $read_clk]
    set write_clk_period [get_property -min PERIOD $write_clk]
    set min_clk_period [expr $read_clk_period < $write_clk_period ? $read_clk_period : $write_clk_period]
    # max delay between launch flop and sync_1 flop
    set_max_delay -from $source_cell -to $dest_cell -datapath_only $min_clk_period
  }
}

################## bsg_tag_client #################
foreach tag_inst [get_cells -hier -filter {(ORIG_REF_NAME == bsg_tag_client || REF_NAME == bsg_tag_client)}] {
    set source_cell [get_cells $tag_inst/tag_data_reg/data_r_reg[0]]
    set dest_cell [get_cells $tag_inst/recv/data_r_reg[0]]
    set write_clk [get_clocks -of_objects [get_pins $source_cell/C]]
    set read_clk [get_clocks -of_objects [get_pins $dest_cell/C]]
    set read_clk_period  [get_property -min PERIOD $read_clk]
    set write_clk_period [get_property -min PERIOD $write_clk]
    set min_clk_period [expr $read_clk_period < $write_clk_period ? $read_clk_period : $write_clk_period]
    set_max_delay -from $source_cell -to $dest_cell -datapath_only $min_clk_period
}

