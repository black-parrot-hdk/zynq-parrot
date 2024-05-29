
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc vivado_create_ip { args } {
    set flist [lindex [lindex ${args} 0] 0]
    set aclk_freq_mhz [lindex [lindex ${args} 0] 1]
    set rtclk_freq_mhz [lindex [lindex ${args} 0] 2]

    set aclk_freq_hz [expr round(${aclk_freq_mhz}*1e6)]
    set rtclk_freq_hz [expr round(${rtclk_freq_mhz}*1e6)]

    vivado_parse_flist flist.vcs
    create_bd_cell -type module -reference top -name top

    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type clk -freq_hz ${rtclk_freq_hz} rt_clk
    create_bd_port -dir I -type rst aresetn
    make_bd_intf_pins_external [get_bd_intf_pins top/s00_axi] -name "s00_axi"
    make_bd_intf_pins_external [get_bd_intf_pins top/m00_axi] -name "m00_axi"
    set_property CONFIG.ASSOCIATED_BUSIF {s00_axi:m00_axi} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports s00_axi]
    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports m00_axi]

    connect_bd_net [get_bd_pins top/aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins top/rt_clk] [get_bd_ports rt_clk]
    connect_bd_net [get_bd_pins top/aresetn] [get_bd_ports aresetn]

    set m00_addr_width [get_property CONFIG.ADDR_WIDTH [get_bd_ports top/m00_axi]]
    set m00_seg_size [expr 1 << ${m00_addr_width}]
    assign_bd_address -target_address_space top/m00_axi [get_bd_addr_segs m00*] -range ${m00_seg_size}
}

proc vivado_ipx_customize { args } {
	ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
	ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.RT_CLK -of_objects [ipx::current_core]]
}

