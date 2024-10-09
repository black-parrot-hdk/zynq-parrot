source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl


proc vivado_create_ip { args } {

    set bram_enable [lindex [lindex ${args} 0] 0]
    set watchdog_enable [lindex [lindex ${args} 0] 1]
    set debug_enable [lindex [lindex ${args} 0] 2]

    create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
    create_bd_cell -type ip -vlnv user.org:user:vps:1.0 vps_0

    connect_bd_net [get_bd_pins vps_0/aclk] [get_bd_pins top_0/aclk]
    connect_bd_net [get_bd_pins vps_0/aresetn] [get_bd_pins top_0/aresetn]
    connect_bd_net [get_bd_pins vps_0/rt_clk] [get_bd_pins top_0/rt_clk]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP0_AXI] [get_bd_intf_pins top_0/gp0_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP1_AXI] [get_bd_intf_pins top_0/gp1_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/HP0_AXI] [get_bd_intf_pins top_0/hp0_axi]

    if {$bram_enable == 1} {
        create_bd_cell -type ip -vlnv user.org:user:bram:1.0 bram_0
        connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins bram_0/aclk]
        connect_bd_net [get_bd_pins top_0/sys_resetn] [get_bd_pins bram_0/aresetn]
        connect_bd_intf_net [get_bd_intf_pins bram_0/S_AXI] [get_bd_intf_pins top_0/m01_axi]
    }
    if {$watchdog_enable == 1} {
        create_bd_cell -type ip -vlnv user.org:user:watchdog:1.0 watchdog_0
        connect_bd_net [get_bd_pins top_0/tag_ck] [get_bd_pins watchdog_0/tag_clk]
        connect_bd_net [get_bd_pins top_0/tag_data] [get_bd_pins watchdog_0/tag_data]
        connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins watchdog_0/aclk]
        connect_bd_net [get_bd_pins top_0/sys_resetn] [get_bd_pins watchdog_0/aresetn]
        connect_bd_intf_net [get_bd_intf_pins watchdog_0/M_AXI] [get_bd_intf_pins top_0/s02_axi]
    }
    if {$debug_enable == 1} {
	    create_bd_cell -type ip -vlnv user.org:user:debug:1.0 debug_0
        connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins debug_0/aclk]
        connect_bd_net [get_bd_pins top_0/sys_resetn] [get_bd_pins debug_0/aresetn]

		# Reconnect GP1 to crossbar / debug unit
		delete_bd_objs [get_bd_intf_net vps_0_GP1_AXI]
		create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
		set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
        connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins smartconnect_0/aclk]
        connect_bd_net [get_bd_pins top_0/aresetn] [get_bd_pins smartconnect_0/aresetn]
		connect_bd_intf_net [get_bd_intf_pins vps_0/GP1_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
		connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins top_0/s01_axi]
        # Prioritize s01 to fix offsets
        assign_bd_address
		connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins debug_0/S_AXI]
        connect_bd_intf_net [get_bd_intf_pins top_0/s02_axi] [get_bd_intf_pins debug_0/M_AXI] 
    }

    assign_bd_address
}

proc vivado_constrain_ip { args } {
    set aclk [get_clocks -of_objects [get_pins blackparrot_bd_1_i/vps_0/aclk]]
    set rt_clk [get_clocks -of_objects [get_pins blackparrot_bd_1_i/vps_0/rt_clk]]

    set_clock_groups -logically_exclusive -group ${aclk} -group ${rt_clk}

    set clk_periods [get_property PERIOD [list ${aclk} ${rt_clk}]]

    set global_min_period [lindex ${clk_periods} 0]
    foreach p ${clk_periods} {
        if {${p} < ${global_min_period}} {
            set global_min_period ${p}
        }
    }

    constrain_sync ${global_min_period}
}

