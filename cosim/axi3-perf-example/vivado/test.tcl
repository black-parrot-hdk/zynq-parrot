

proc find_ps_hwh { proj_bd } {
    set hwh_files [get_files *hwh]

    foreach f ${hwh_files} {
        set data [split [read [open ${f} "r"]]]

        set search1 "processing_system7_0"
        set search2 "zynq_ultra_ps_e_0"
        foreach line ${data} {
            if {[string match ${search1} ${line}]} {
                return ${f}
            }
            if {[string match ${search2} ${line}]} {
                return ${f}
            }
        }
    }

    return [get_files ${proj_bd}.hwh]
}

