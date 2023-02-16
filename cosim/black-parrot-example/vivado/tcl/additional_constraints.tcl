
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
set rtc_mux1 [join [get_cells -hier *bufgmux_ctrl1]]
set rtc_mux2 [join [get_cells -hier *bufgmux_ctrl2]]
set rtc_mux3 [join [get_cells -hier *bufgmux_ctrl3]]

set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[0]]
set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[1]]

# max delay for the bufgmux_ctrl primitives
set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*] $bp_min_period
set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*] $bp_min_period
set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*] $bp_min_period

set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*]
set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*]
set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*]

# Create generated clock for the bit banging clock
set bb_inst [join [get_cells -hier -filter {(ORIG_REF_NAME == bsg_tag_bitbang || REF_NAME == bsg_tag_bitbang)}]]
create_generated_clock -name bb_clk -source [get_pins $bb_inst/aclk] -edges {3 5 7} [get_pins $bb_inst/tag_clk_reg/data_r_reg[0]/Q]

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
