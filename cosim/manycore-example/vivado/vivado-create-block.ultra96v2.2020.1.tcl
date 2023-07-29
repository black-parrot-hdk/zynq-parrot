set project_name $::env(BASENAME)_bd_proj
set project_part $::env(PART)
set project_bd   $::env(BASENAME)_bd_1

create_project -force ${project_name} [pwd] -part ${project_part}
create_bd_design "${project_bd}"
update_compile_order -fileset sources_1
open_bd_design ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd
set_property ip_repo_paths ip_repo [current_project]
update_ip_catalog

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0
set_property -dict [list CONFIG.PSU__FPGA_PL0_ENABLE {1}  CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {40}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1} CONFIG.PSU__MAXIGP0__DATA_WIDTH {32}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {0}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 {0}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1} CONFIG.PSU__SAXIGP3__DATA_WIDTH {64}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__DDRC__BUS_WIDTH {32 Bit} CONFIG.PSU__DDRC__DEVICE_CAPACITY {16384 MBits} CONFIG.PSU__DDRC__MEMORY_TYPE {LPDDR 4} CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16}] [get_bd_cells zynq_ultra_ps_e_0]
endgroup

create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
set_property -dict [list CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_pins /zynq_ultra_ps_e_0/pl_clk0]]] [get_bd_pins top_0/aclk]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
set_property CONFIG.ADVANCED_PROPERTIES {__experimental_features__ {disable_low_area_mode 1}} [get_bd_cells smartconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins top_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_1/aresetn]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins top_0/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins smartconnect_0/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins smartconnect_1/aclk]

connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins top_0/s00_axi]
connect_bd_intf_net [get_bd_intf_pins top_0/m00_axi] [get_bd_intf_pins smartconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (40 MHz)" }  [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (40 MHz)" }  [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (40 MHz)" }  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
endgroup

assign_bd_address
set_property offset 0x400000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_top_0_reg0}]
set_property range 4K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_top_0_reg0}]
validate_bd_design

make_wrapper -files [get_files ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd] -top
add_files -norecurse ${project_name}.srcs/sources_1/bd/${project_bd}/hdl/${project_bd}_wrapper.v

save_bd_design

# Change to 0 to have it stop before synthesis / implementation
# so you can inspect the design with the GUI

if {1} {
  launch_runs synth_1 -jobs 16
  wait_on_run synth_1
}

if {1} {
  launch_runs impl_1 -to_step write_bitstream -jobs 16
  wait_on_run impl_1
}

puts "Completed. Type start_gui to enter vivado GUI; quit to exit"
