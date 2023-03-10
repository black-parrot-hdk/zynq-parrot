
##### FX #####

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
set bp_core_period [get_property PERIOD [get_clocks -of_object [get_pins $bp_inst/aclk]]]
foreach blss $all_blss {
  bsg_blss_constraints $blss $bp_core_period
}

