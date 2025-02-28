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
    set rtclk_freq_mhz [lindex [lindex ${args} 0] 4]

    set aclk_freq_hz [expr round(${aclk_freq_mhz}*1e6)]
    set rtclk_freq_hz [expr round(${rtclk_freq_mhz}*1e6)]

    vivado_create_design ${vpackages} ${vsources} ${vincludes}
    create_bd_cell -type module -reference top -name top

    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type clk -freq_hz ${rtclk_freq_hz} rt_clk
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

    set hp0_seg_offset 0x0
    set hp0_addr_width [get_property CONFIG.ADDR_WIDTH [get_bd_intf_ports hp0_axi]]
    set hp0_seg_size [expr 1 << ${hp0_addr_width}]
    assign_bd_address -target_address_space [get_bd_addr_spaces top/hp0_axi] [get_bd_addr_segs hp0*] -offset ${hp0_seg_offset} -range ${hp0_seg_size}

    set hp1_seg_offset 0x0
    set hp1_addr_width [get_property CONFIG.ADDR_WIDTH [get_bd_intf_ports hp1_axi]]
    set hp1_seg_size [expr 1 << ${hp1_addr_width}]
    assign_bd_address -target_address_space [get_bd_addr_spaces top/hp1_axi] [get_bd_addr_segs hp1*] -offset ${hp1_seg_offset} -range ${hp1_seg_size}

    assign_bd_address
}

proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.RT_CLK -of_objects [ipx::current_core]]
    ipx::infer_bus_interface tag_ck xilinx.com:signal:data_rtl:1.0 [ipx::current_core]
}

