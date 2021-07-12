
proc vivado_parse_bp_vcs_flist {flist_path BP_DIR BASEJUMP_STL_DIR HARDFLOAT_DIR BSG_ZYNQ_PL_SHELL_DIR} {

    set BP_COMMON_DIR $BP_DIR/bp_common
    set BP_BE_DIR $BP_DIR/bp_be
    set BP_ME_DIR $BP_DIR/bp_me
    set BP_FE_DIR $BP_DIR/bp_fe
    set BP_TOP_DIR $BP_DIR/bp_top
    set f [split [string trim [read [open $flist_path r]]] "\n"]
    set flist [list ]
    set dir_list [list ]
    foreach x $f {
        if {![string match "" $x]} {
            # If the item starts with +incdir+, directory files need to be added
            if {[string match "#" [string index $x 0]]} {
                # get rid of comment line
            } elseif {[string match "+" [string index $x 0]]} {
                set trimchars "+incdir+"
                set temp [string trimleft $x $trimchars]
                set expanded [subst $temp]
                lappend dir_list $expanded
            } elseif {[string match "*bsg_mem_1rw_sync_mask_write_bit.v" $x]} {
                # bitmasked memories are incorrectly inferred in Kintex 7 and Ultrascale+ FPGAs
                # this version maps into lutram correctly
                set replace_hard "$BASEJUMP_STL_DIR/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v"
                set expanded [subst $replace_hard]
                lappend flist $expanded
                puts $expanded
            } else {
                set expanded [subst $x]
                lappend flist $expanded
            }
        }
    }
    puts $flist
    puts $dir_list

    return [list $flist $dir_list]
}




