
proc bsg_blss_constraints { blss_inst cdc_delay } {
    puts "constraining blss_inst: $blss_inst"
    foreach launch_reg [get_cells -quiet $blss_inst/*/bsg_SYNC_LNCH_r_reg[*]] {
        # ASYNC_REG should have been applied in RTL
        regexp {([\w/.\[\]]+)/[\w]+\[([0-9]+)\]} $launch_reg -> path index

        set source_cell [get_cells $path/bsg_SYNC_LNCH_r_reg[$index]]
        set dest_cell  [get_cells $path/hard_sync_int1_r_reg[$index]]
        # max delay between launch flop and sync_1 flop
        set_max_delay -from $source_cell -to $dest_cell -datapath_only $cdc_delay
    }
}

proc bsg_bss_constraints { bss_inst cdc_delay } {
    puts "constraining bss_inst: $bss_inst"
    foreach launch_reg [get_cells -quiet $bss_inst/*/bsg_SYNC_1_r[*]] {
        regexp {([\w/.\[\]]+)/[\w]+\[([0-9]+)\]} $launch_reg -> path index
        set dest_cell  [get_cells $path/bsg_SYNC_1_r[$index]]
        set_max_delay -from $src_clk -to $dest_cell -datapath_only $cdc_delay
    }
}

proc constrain_sync { global_min_period } {
    set all_bss [get_cells -quiet -hier -filter {(ORIG_REF_NAME == bsg_sync_sync || REF_NAME == bsg_sync_sync)}]
    foreach bss $all_bss {
        bsg_bss_constraints $bss $global_min_period
    }

    set all_blss [get_cells -quiet -hier -filter {(ORIG_REF_NAME == bsg_launch_sync_sync || REF_NAME == bsg_launch_sync_sync)}]
    foreach blss $all_blss {
        bsg_blss_constraints $blss $global_min_period
    }
}

