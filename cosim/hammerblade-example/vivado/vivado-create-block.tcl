source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc vivado_create_ip { args } {
    create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
    create_bd_cell -type ip -vlnv user.org:user:vps:1.0 vps_0
    create_bd_cell -type ip -vlnv user.org:user:bram:1.0 bram_0

    connect_bd_net [get_bd_pins vps_0/aclk] [get_bd_pins top_0/aclk]
    connect_bd_net [get_bd_pins vps_0/aresetn] [get_bd_pins top_0/aresetn]
    connect_bd_net [get_bd_pins vps_0/rt_clk] [get_bd_pins top_0/rt_clk]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP0_AXI] [get_bd_intf_pins top_0/s00_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP1_AXI] [get_bd_intf_pins top_0/s01_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/HP0_AXI] [get_bd_intf_pins top_0/m00_axi]

    connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins bram_0/aclk]
    connect_bd_net [get_bd_pins top_0/aresetn] [get_bd_pins bram_0/aresetn]
    connect_bd_intf_net [get_bd_intf_pins top_0/m01_axi] [get_bd_intf_pins bram_0/S_AXI]

    assign_bd_address
}

proc vivado_constrain_ip { args } {

}

