source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc vivado_create_ip { args } {
    set flist [lindex [lindex ${args} 0] 0]
    set aclk_freq_mhz [lindex [lindex ${args} 0] 1]

    set aclk_freq_hz [expr round(${aclk_freq_mhz}*1e6)]

    vivado_parse_flist flist.vcs
    create_bd_cell -type module -reference top -name top

    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type rst aresetn
    make_bd_intf_pins_external [get_bd_intf_pins top/gp0_axi] -name "gp0_axi"
    make_bd_intf_pins_external [get_bd_intf_pins top/hp0_axi] -name "hp0_axi"
    set_property CONFIG.ASSOCIATED_BUSIF {gp0_axi:hp0_axi} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports gp0_axi]
    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports hp0_axi]

    connect_bd_net [get_bd_pins top/aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins top/aresetn] [get_bd_ports aresetn]

    set hp0_seg_offset 0x0
    set hp0_addr_width [get_property CONFIG.ADDR_WIDTH [get_bd_ports top/hp0_axi]]
    set hp0_seg_size [expr 1 << ${hp0_addr_width}]
    assign_bd_address -target_address_space [get_bd_addr_spaces top/hp0_axi] [get_bd_addr_segs m00*] -range ${hp0_seg_size} -offset ${hp0_seg_offset}

    assign_bd_address
}

proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
}

