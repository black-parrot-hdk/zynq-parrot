
proc vivado_parse_flist {flist_path} {
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
            } else {
                set expanded [subst $x]
                lappend flist $expanded
            }
        }
    }

    #puts $flist
    #puts $dir_list
    #
    return [list $flist $dir_list]
}

