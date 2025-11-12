
proc init { cellpath otherInfo } {

}

proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

proc vivado_create_ip { args } {
    set aclk_freq_mhz  [lindex [lindex ${args} 0] 0]

    set aclk_freq_hz [expr round(${aclk_freq_mhz}*1e6)]

    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type rst aresetn

    create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram
    set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
    set_property -dict [ list \
        CONFIG.ECC_TYPE {0} \
        CONFIG.PROTOCOL {AXI4LITE} \
        CONFIG.SINGLE_PORT_BRAM {1} \
        ] $axi_bram_ctrl_0
    apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto"} [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]

    connect_bd_net [get_bd_port aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
    make_bd_intf_pins_external -name "S_AXI" [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
    set_property CONFIG.ASSOCIATED_BUSIF {S_AXI} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports S_AXI]
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
}

