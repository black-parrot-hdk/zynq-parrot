
##### FX #####
proc bsg_clint_constraints { clint_inst cdc_delay } {
  puts "constraining clint_inst: $clint_inst"

  create_generated_clock -name ${clint_inst}_ds_by_16_clk -source [get_pins $clint_inst/ds/aclk] -divide_by 16 [get_pins $clint_inst/ds/clk_r_o_reg/Q]

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
  set rtc_mux1 [join [get_cells -hier *BUFGMUX_CTRL_m_3_2]]
  set rtc_mux2 [join [get_cells -hier *BUFGMUX_CTRL_m_1_0]]
  set rtc_mux3 [join [get_cells -hier *BUFGMUX_CTRL_m]]

  set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[0]]
  set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[1]]

  # max delay for the bufgmux_ctrl primitives
  set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*] $cdc_delay
  set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*] $cdc_delay
  set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*] $cdc_delay

  set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*]
  set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*]
  set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*]
}

proc bsg_blss_constraints { blss_inst cdc_delay } {
  puts "constraining blss_inst: $blss_inst"
  foreach launch_reg [get_cells $blss_inst/*/bsg_SYNC_LNCH_r_reg[*]] {
    # ASYNC_REG should have been applied in RTL
    regexp {([\w/.\[\]]+)/[\w]+\[([0-9]+)\]} $launch_reg -> path index

    set source_cell [get_cells $path/bsg_SYNC_LNCH_r_reg[$index]]
    set dest_cell  [get_cells $path/hard_sync_int1_r_reg[$index]]
    # max delay between launch flop and sync_1 flop
    set_max_delay -from $source_cell -to $dest_cell -datapath_only $cdc_delay
  }
}

##### MAIN #####

set bp_inst [join [get_cells -hier blackparrot]]

set clock_pins [get_pins -of_object $bp_inst -filter {name=~"*clk*"}]
set bp_periods [get_property PERIOD [get_clocks -of_object $clock_pins]]
set global_min_period [lindex $bp_periods 0]
foreach p $bp_periods {
    if {$p < $global_min_period} {
        set global_min_period $p
    }
}

set all_blss [get_cells -hier -filter {(ORIG_REF_NAME == bsg_launch_sync_sync || REF_NAME == bsg_launch_sync_sync)}]
foreach blss $all_blss {
  bsg_blss_constraints $blss $global_min_period
}

set all_clint [get_cells -hier -filter {(ORIG_REF_NAME == bp_me_clint_slice || REF_NAME == bp_me_clint_slice)}]
foreach clint $all_clint {
  bsg_clint_constraints $clint $global_min_period
}

