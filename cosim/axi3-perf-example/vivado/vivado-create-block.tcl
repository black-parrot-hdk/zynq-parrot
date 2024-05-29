source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc vivado_create_ip { args } {
	create_bd_cell -type ip -vlnv user.org:user:top:1.0 dut_0
	create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
	create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

	# THIS SETS THE CLOCK FREQUENCY; you may have to reduce it to 125 MHz to use the ILA
	set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {200}] [get_bd_cells processing_system7_0]
	apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config { make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
	apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk "/processing_system7_0/FCLK_CLK0" }  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
	apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]

	connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins dut_0/s00_axi]
	connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins dut_0/aclk]
	connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
	connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins dut_0/aresetn]

	# this inserts a handy ILA
	if {0} {
		create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0
		set_property CONFIG.C_SLOT 1 [get_bd_cells system_ila_0]
		set_property CONFIG.C_NUM_MONITOR_SLOTS 2 [get_bd_cells system_ila_0]
		connect_bd_intf_net [get_bd_intf_pins system_ila_0/SLOT_1_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
		connect_bd_intf_net [get_bd_intf_pins system_ila_0/SLOT_0_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
		connect_bd_net [get_bd_pins system_ila_0/clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
		connect_bd_net [get_bd_pins system_ila_0/resetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
	}
}

proc vivado_constrain_ip { args } {

}

