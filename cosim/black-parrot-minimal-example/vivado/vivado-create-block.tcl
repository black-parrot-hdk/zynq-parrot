
proc vivado_create_ip { args } {
    create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
    create_bd_cell -type ip -vlnv user.org:user:vps:1.0 vps_0

    connect_bd_net [get_bd_pins vps_0/aclk] [get_bd_pins top_0/aclk]
    connect_bd_net [get_bd_pins vps_0/rt_clk] [get_bd_pins top_0/rt_clk]
    connect_bd_net [get_bd_pins vps_0/aresetn] [get_bd_pins top_0/aresetn]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP0_AXI] [get_bd_intf_pins top_0/gp0_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/HP0_AXI] [get_bd_intf_pins top_0/hp0_axi]

    assign_bd_address
}

proc vivado_constrain_ip { args } {
    set aclk [get_clocks *clk_out1*]
    set rt_clk [get_clocks *clk_out2*]

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

