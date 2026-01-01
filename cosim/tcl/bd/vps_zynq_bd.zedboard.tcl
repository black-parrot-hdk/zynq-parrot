
# Vivado hook for BD initialization
proc init { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]

    # Connect I/O ports
    if {[get_bd_intf_port -quiet FIXED_IO] == {}} {
        create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO
        create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR
        connect_bd_intf_net [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins ${cellpath}/FIXED_IO]
        connect_bd_intf_net [get_bd_intf_ports DDR] [get_bd_intf_pins ${cellpath}/DDR]
    }
}

# Vivado hook for after parameters propagate in BD
# https://support.xilinx.com/s/question/0D52E00006lLgeLSAS/how-to-make-cs00axiaddrwidth-dependent-on-address-editor?language=en_US
proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

# ZynqParrot hook for population of BD
proc vivado_create_ip { args } {
    set aclk_freq_mhz  [lindex [lindex ${args} 0] 0]
    set rtclk_freq_mhz [lindex [lindex ${args} 0] 1]
    set gp0_enable     [lindex [lindex ${args} 0] 2]
    set gp0_data_width [lindex [lindex ${args} 0] 3]
    set gp0_addr_width [lindex [lindex ${args} 0] 4]
    set gp1_enable     [lindex [lindex ${args} 0] 5]
    set gp1_data_width [lindex [lindex ${args} 0] 6]
    set gp1_addr_width [lindex [lindex ${args} 0] 7]
    set hp0_enable     [lindex [lindex ${args} 0] 8]
    set hp0_data_width [lindex [lindex ${args} 0] 9]
    set hp0_addr_width [lindex [lindex ${args} 0] 10]

    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0
    set_property CONFIG.PCW_EN_CLK0_PORT {1} [get_bd_cells processing_system7_0]
    set_property CONFIG.PCW_USE_M_AXI_GP0 {1} [get_bd_cells processing_system7_0]
    set_property CONFIG.PCW_USE_M_AXI_GP1 {1} [get_bd_cells processing_system7_0]
    set_property CONFIG.PCW_USE_S_AXI_HP0 {1} [get_bd_cells processing_system7_0]
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable"} [get_bd_cells processing_system7_0]

    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_2

    set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_0]
    set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_1]
    set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_2]

    create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0

    set_property CONFIG.CLKOUT2_USED true [get_bd_cells clk_wiz_0]
    set_property CONFIG.USE_LOCKED false [get_bd_cells clk_wiz_0]
    set_property CONFIG.USE_RESET false [get_bd_cells clk_wiz_0]
    set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ ${aclk_freq_mhz} [get_bd_cells clk_wiz_0]
    set_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ ${rtclk_freq_mhz} [get_bd_cells clk_wiz_0]

    make_bd_pins_external -name "aclk" [get_bd_pins clk_wiz_0/clk_out1]
    make_bd_pins_external -name "rt_clk" [get_bd_pins clk_wiz_0/clk_out2]
    make_bd_pins_external -name "aresetn" [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
    make_bd_intf_pins_external -name "GP0_AXI" [get_bd_intf_pins smartconnect_0/M00_AXI]
    make_bd_intf_pins_external -name "GP1_AXI" [get_bd_intf_pins smartconnect_1/M00_AXI]
    make_bd_intf_pins_external -name "HP0_AXI" [get_bd_intf_pins smartconnect_2/S00_AXI]

    connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins smartconnect_0/S00_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP0_AXI]
    set_property CONFIG.DATA_WIDTH ${gp0_data_width} [get_bd_intf_ports GP0_AXI]
    set_property CONFIG.ADDR_WIDTH ${gp0_addr_width} [get_bd_intf_ports GP0_AXI]

    connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP1] [get_bd_intf_pins smartconnect_1/S00_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP1_AXI]
    set_property CONFIG.DATA_WIDTH ${gp1_data_width} [get_bd_intf_ports GP1_AXI]
    set_property CONFIG.ADDR_WIDTH ${gp1_addr_width} [get_bd_intf_ports GP1_AXI]

    connect_bd_intf_net [get_bd_intf_pins processing_system7_0/S_AXI_HP0] [get_bd_intf_pins smartconnect_2/M00_AXI]
    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.DATA_WIDTH ${hp0_data_width} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.ADDR_WIDTH ${hp0_addr_width} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.ID_WIDTH 6 [get_bd_intf_ports HP0_AXI]

    connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]

    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_0/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_1/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_2/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_0/aresetn]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_1/aresetn]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_2/aresetn]

    set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI:HP0_AXI} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]

    # TODO: Deduce the offset
    assign_bd_address -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
        [get_bd_addr_segs GP0*] -range 4K -offset 0x40000000 
    assign_bd_address -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
        [get_bd_addr_segs GP1*] -range 1G -offset 0x80000000

    # Get rid of disabled ports, hope that synthesis is smart
    # TODO: Conditional port enable
    if {${gp0_enable} == 0} {
        delete_bd_objs [get_bd_cells smartconnect_0]
        delete_bd_objs [get_bd_intf_ports GP0_AXI]
	}
    if {${gp1_enable} == 0} {
        delete_bd_objs [get_bd_cells smartconnect_1]
        delete_bd_objs [get_bd_intf_ports GP1_AXI]
	}
    if {${hp0_enable} == 0} {
        delete_bd_objs [get_bd_cells smartconnect_2]
        delete_bd_objs [get_bd_intf_ports HP0_AXI]
	}
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {

}
