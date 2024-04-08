source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc vivado_create_ip { args } {

    create_bd_cell -type ip -vlnv user.org:user:top:1.0 dut_0
    create_bd_cell -type ip -vlnv user.org:user:vps:1.0 vps_0

    connect_bd_net [get_bd_pins vps_0/aclk] [get_bd_pins dut_0/aclk]
    connect_bd_net [get_bd_pins vps_0/aresetn] [get_bd_pins dut_0/aresetn]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP0_AXI] [get_bd_intf_pins dut_0/s00_axi]
}

proc vivado_constrain_ip { args } {

}

