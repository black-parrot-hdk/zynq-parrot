
proc init { cellpath otherInfo } {

}

proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

proc vivado_create_ip { args } {

    set vpackages [lindex [lindex ${args} 0] 0]
    set vsources [lindex [lindex ${args} 0] 1]
    set vincludes [lindex [lindex ${args} 0] 2]

    vivado_create_design ${vpackages} ${vsources} ${vincludes}
    create_bd_cell -type module -reference top -name top

    create_bd_port -dir I -type clk -freq_hz 100000000 aclk
    create_bd_port -dir I -type clk -freq_hz 10000000 rt_clk
    create_bd_port -dir I -type rst aresetn
    create_bd_port -dir O -type rst sys_resetn
    create_bd_port -dir O -type data tag_ck
    create_bd_port -dir O -type data tag_data

    make_bd_intf_pins_external [get_bd_intf_pins -hier gp0_axi] -name "gp0_axi"
    make_bd_intf_pins_external [get_bd_intf_pins -hier gp1_axi] -name "gp1_axi"
    make_bd_intf_pins_external [get_bd_intf_pins -hier gp2_axi] -name "gp2_axi"
    make_bd_intf_pins_external [get_bd_intf_pins -hier hp0_axi] -name "hp0_axi"
    make_bd_intf_pins_external [get_bd_intf_pins -hier hp1_axi] -name "hp1_axi"

    set_property CONFIG.ASSOCIATED_BUSIF {gp0_axi:gp1_axi:gp2_axi:hp0_axi:hp1_axi} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn:sys_resetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports gp0_axi]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports gp1_axi]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports gp2_axi]
    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports hp0_axi]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports hp1_axi]

    connect_bd_net [get_bd_pins top/aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins top/rt_clk] [get_bd_ports rt_clk]
    connect_bd_net [get_bd_pins top/aresetn] [get_bd_ports aresetn]
    connect_bd_net [get_bd_pins top/tag_ck] [get_bd_ports tag_ck]
    connect_bd_net [get_bd_pins top/tag_data] [get_bd_ports tag_data]
    connect_bd_net [get_bd_pins top/sys_resetn] [get_bd_ports sys_resetn]
}

proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.RT_CLK -of_objects [ipx::current_core]]
    ipx::infer_bus_interface tag_ck xilinx.com:signal:data_rtl:1.0 [ipx::current_core]
}

