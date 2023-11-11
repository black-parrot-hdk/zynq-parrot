
proc program_fpga {basename devicename xvc_url} {
    open_hw

    # connect to local hardware server
    connect_hw_server

    # open hardware target with Xilinx virtual cable (xvc)
    # in case open target is unsuccessful, close target and open again 
    open_hw_target -quiet -xvc_url ${xvc_url}
    after 1000
    close_hw_target
    after 1000
    open_hw_target -xvc_url ${xvc_url}

    set hw_device [get_hw_devices ${devicename}]

    # set programming file
    set_property PROGRAM.FILE ${basename}_bd_1.bit ${hw_device}

    # program FPGA
    puts "Estimated programming time: 2.5 minutes"
    program_hw_devices -verbose ${hw_device}

    # exit
    close_hw_target
}

if {$::argv0 eq [info script]} {
    set basename  $::env(BASENAME)
    set boardname $::env(BOARDNAME)
    set xvc_url   $::env(XVC_URL)

    if {${boardname} == "vu47p"} {
        set devicename xcvu47p_0
    } else {
        puts "Unknown board for xvc programming"
        return
    }

    program_fpga ${basename} ${devicename} ${xvc_url}
}

