source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc init { cellpath otherInfo } {

}

proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

proc vivado_create_ip { args } {
    set vpackages [lindex [lindex ${args} 0] 0]
    set vsources [lindex [lindex ${args} 0] 1]
    set vincludes [lindex [lindex ${args} 0] 2]
    set aclk_freq_mhz [lindex [lindex ${args} 0] 3]

    set aclk_freq_hz [expr round(${aclk_freq_mhz}*1e6)]

    vivado_create_design ${vpackages} ${vsources} ${vincludes}
    create_bd_cell -type module -reference top -name top

    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type rst aresetn
    make_bd_intf_pins_external [get_bd_intf_pins top/gp0_axi] -name "gp0_axi"
    make_bd_intf_pins_external [get_bd_intf_pins top/gp1_axi] -name "gp1_axi"
    set_property CONFIG.ASSOCIATED_BUSIF {gp0_axi:gp1_axi} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports gp0_axi]

    connect_bd_net [get_bd_pins top/aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins top/aresetn] [get_bd_ports aresetn]
}

proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
}

