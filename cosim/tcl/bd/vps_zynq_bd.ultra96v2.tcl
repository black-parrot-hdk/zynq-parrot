
proc init { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]
}

# https://support.xilinx.com/s/question/0D52E00006lLgeLSAS/how-to-make-cs00axiaddrwidth-dependent-on-address-editor?language=en_US
proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

proc vivado_create_ip { args } {
    set aclk_freq_mhz  [lindex [lindex ${args} 0] 0]
    set rtclk_freq_mhz [lindex [lindex ${args} 0] 1]
    set gp0_data_width [lindex [lindex ${args} 0] 2]
    set gp0_addr_width [lindex [lindex ${args} 0] 3]
    set gp1_data_width [lindex [lindex ${args} 0] 4]
    set gp1_addr_width [lindex [lindex ${args} 0] 5]
    set hp0_data_width [lindex [lindex ${args} 0] 6]
    set hp0_addr_width [lindex [lindex ${args} 0] 7]

    set zynq_ultra_ps_e_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0]
    set_property -dict [list \
        CONFIG.PSU__FPGA_PL0_ENABLE {1} \
        CONFIG.PSU__FPGA_PL1_ENABLE {1} \
        CONFIG.PSU__USE__M_AXI_GP0 {1} \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ ${aclk_freq_mhz} \
        CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ ${rtclk_freq_mhz} \
        CONFIG.PSU__USE__M_AXI_GP1 {1} \
        CONFIG.PSU__USE__M_AXI_GP2 {0} \
        CONFIG.PSU__USE__S_AXI_GP3 {1} \
    ] $zynq_ultra_ps_e_0

    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_2
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0

    set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_0]
    set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_1]
    set_property CONFIG.NUM_SI {1} [get_bd_cells smartconnect_2]

    make_bd_pins_external -name "aclk" [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
    make_bd_pins_external -name "rt_clk" [get_bd_pins zynq_ultra_ps_e_0/pl_clk1]
    make_bd_pins_external -name "aresetn" [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

    make_bd_intf_pins_external -name "GP0_AXI" [get_bd_intf_pins smartconnect_0/M00_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP0_AXI]
    set_property CONFIG.DATA_WIDTH ${gp0_data_width} [get_bd_intf_ports GP0_AXI]
    set_property CONFIG.ADDR_WIDTH ${gp0_addr_width} [get_bd_intf_ports GP0_AXI]

    make_bd_intf_pins_external -name "GP1_AXI" [get_bd_intf_pins smartconnect_1/M00_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP1_AXI]
    set_property CONFIG.DATA_WIDTH ${gp1_data_width} [get_bd_intf_ports GP1_AXI]
    set_property CONFIG.ADDR_WIDTH ${gp1_addr_width} [get_bd_intf_ports GP1_AXI]

    make_bd_intf_pins_external -name "HP0_AXI" [get_bd_intf_pins smartconnect_2/S00_AXI]
    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.DATA_WIDTH ${hp0_data_width} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.ADDR_WIDTH ${hp0_addr_width} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.ID_WIDTH 6 [get_bd_intf_ports HP0_AXI]

    connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_0/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD] [get_bd_intf_pins smartconnect_1/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD] [get_bd_intf_pins smartconnect_2/M00_AXI]

    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins proc_sys_reset_0/ext_reset_in]

    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_0/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_1/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_2/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_0/aresetn]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_1/aresetn]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_2/aresetn]

	exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces /HP0_AXI] \
        [get_bd_addr_segs *HP1_LPS*] 

    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI:HP0_AXI} [get_bd_ports aclk]

}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {
	set core [ipx::current_core]

    set gp0_enable [lindex [lindex ${args} 0] 0]
    set gp1_enable [lindex [lindex ${args} 0] 1]
    set hp0_enable [lindex [lindex ${args} 0] 2]
	set rtclk_enable [lindex [lindex ${args} 0] 3]

	set gp0_name GP0_ENABLE
	set gp0_intf [ipx::get_bus_interfaces GP0_AXI -of_objects $core]
    set gp0_param [ipx::add_user_parameter $gp0_name $core]
    set_property -dict [list \
		value_resolve_type {user} \
		value_format {bool} \
		value $gp0_enable \
	] $gp0_param
	set_property enablement_dependency {$GP0_ENABLE == 1} $gp0_intf

	set gp1_name GP1_ENABLE
	set gp1_intf [ipx::get_bus_interfaces GP1_AXI -of_objects $core]
    set gp1_param [ipx::add_user_parameter $gp1_name $core]
    set_property -dict [list \
		value_resolve_type {user} \
		value_format {bool} \
		value $gp1_enable \
	] $gp1_param
	set_property enablement_dependency {$GP1_ENABLE == 1} $gp1_intf

    set hp0_name HP0_ENABLE
    set hp0_intf [ipx::get_bus_interfaces HP0_AXI -of_objects $core]
    set hp0_param [ipx::add_user_parameter $hp0_name $core]
    set_property -dict [list \
        value_resolve_type {user} \
        value_format {bool} \
        value {false} \
    ] $hp0_param
    set_property enablement_dependency {$HP0_ENABLE == 1} $hp0_intf

    set rtclk_name RTCLK_ENABLE
	set rtclk_intf [ipx::get_ports rt_clk -of_objects $core]
    set rtclk_param [ipx::add_user_parameter $rtclk_name $core]
	set_property -dict [list \
	    value_resolve_type {user} \
		value_format {bool} \
		value $rtclk_enable \
	] $rtclk_param
    set_property enablement_dependency {$RTCLK_ENABLE == 1} $rtclk_intf
}

