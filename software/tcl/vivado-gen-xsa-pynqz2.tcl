
proc vivado_create_xsa { proj_name proj_bd part } {
    create_project -force ${proj_name} [pwd] -part ${part}
    create_bd_design ${proj_bd}
    open_bd_design ${proj_bd}.bd
    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
    apply_bd_automation [get_bd_cells processing_system7_0] \
        -rule xilinx.com:bd_rule:processing_system7 \
        -config { make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
    generate_target all [get_files ${proj_bd}.bd]
    write_hw_platform -fixed -force -file basic.xsa
    save_bd_design
}

if {[info exists ::argv0] && $::argv0 eq [info script]} {
    vivado_create_xsa pynqz2_xsa_proj zynq_bd xc7z020clg400-1
}

