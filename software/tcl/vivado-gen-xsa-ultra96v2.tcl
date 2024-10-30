
proc vivado_create_xsa { proj_name proj_bd part } {
    create_project -force ${proj_name} [pwd] -part ${part}
    create_bd_design ${proj_bd}
    open_bd_design ${proj_bd}.bd
    create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
    set_property -dict [list CONFIG.PSU__FPGA_PL0_ENABLE {1}] [get_bd_cells zynq_ultra_ps_e_0]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk]
    generate_target all [get_files ${proj_bd}.bd]
    write_hw_platform -fixed -force -file basic.xsa
    save_bd_design
}

if {[info exists ::argv0] && $::argv0 eq [info script]} {
    vivado_create_xsa ultra96v2_xsa_proj zynq_bd xczu3eg-sbva484-1-e
}

