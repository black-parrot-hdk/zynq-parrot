set project_name $::env(BASENAME)_bd_proj
set project_part $::env(PART)
set project_bd   $::env(BASENAME)_bd_1

create_project -force ${project_name} [pwd] -part ${project_part}
create_bd_design "${project_bd}"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
set_property -dict [list CONFIG.PCW_EN_CLK0_PORT {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {20}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64}] [get_bd_cells processing_system7_0]
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
open_bd_design ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd}
set_property  ip_repo_paths ip_repo [current_project]
update_ip_catalog

startgroup
create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
set_property -dict [list CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_pins /processing_system7_0/FCLK_CLK0]]] [get_bd_pins top_0/aclk]
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins top_0/s00_axi]
connect_bd_intf_net [get_bd_intf_pins top_0/m00_axi] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins top_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn]
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
endgroup

assign_bd_address

# with other versions of vivado, it may have different names for the slave segment
# in the gui you can open the address editor, right click on the interface (s00_axi or s01_axi)
# and select "Address Segment Properties..." to see what name to use in these commands.

set_property offset 0x40000000 [get_bd_addr_segs {processing_system7_0/Data/SEG_top_0_reg0}]
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_top_0_reg0}]

validate_bd_design
make_wrapper -files [get_files ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd] -top
add_files -norecurse ${project_name}.srcs/sources_1/bd/${project_bd}/hdl/${project_bd}_wrapper.v

save_bd_design

# change this to a 0 to have it stop before synthesis and implementation
# so you can inspect the design with the GUI

if {1} {
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
}

puts "Completed. Type start_gui to enter vivado GUI; quit to exit"
