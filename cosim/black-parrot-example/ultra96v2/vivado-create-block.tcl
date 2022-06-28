set project_name $::env(BASENAME)_bd_proj
set project_part $::env(PART)

create_project -force ${project_name} [pwd] -part ${project_part}
create_bd_design "blackparrot_bd_1"
update_compile_order -fileset sources_1
open_bd_design {${project_name}.srcs/sources_1/bd/blackparrot_bd_1/blackparrot_bd_1.bd}
set_property ip_repo_paths fpga_build [current_project]
update_ip_catalog

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0
set_property -dict [list CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {50}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1} CONFIG.PSU__MAXIGP0__DATA_WIDTH {32}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {1} CONFIG.PSU__MAXIGP1__DATA_WIDTH {32}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1} CONFIG.PSU__SAXIGP2__DATA_WIDTH {64}] [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 {0}] [get_bd_cells zynq_ultra_ps_e_0]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram
set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
set_property -dict [ list \
   CONFIG.ECC_TYPE {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
] $axi_bram_ctrl_0
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto"} [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
endgroup

create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
set_property CONFIG.ADVANCED_PROPERTIES {__experimental_features__ {disable_low_area_mode 1}} [get_bd_cells smartconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_2
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_2]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins top_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_1/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_2/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins top_0/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins smartconnect_0/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins smartconnect_1/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins smartconnect_2/aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]

connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins top_0/s00_axi]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD] [get_bd_intf_pins smartconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins top_0/s01_axi]
connect_bd_intf_net [get_bd_intf_pins top_0/m00_axi] [get_bd_intf_pins smartconnect_2/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_2/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
connect_bd_intf_net [get_bd_intf_pins top_0/m01_axi] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (50 MHz)" }  [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (50 MHz)" }  [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (50 MHz)" }  [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/zynq_ultra_ps_e_0/pl_clk0 (50 MHz)" }  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]

create_bd_addr_seg -range 0x00002000 -offset 0x10000000 [get_bd_addr_spaces top_0/m01_axi] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0

assign_bd_address
set_property offset 0x400000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_top_0_reg0}]
set_property offset 0x500000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_top_0_reg01}]
set_property range 4K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_top_0_reg0}]
set_property range 1G [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_top_0_reg01}]
validate_bd_design

make_wrapper -files [get_files ${project_name}.srcs/sources_1/bd/blackparrot_bd_1/blackparrot_bd_1.bd] -top
add_files -norecurse ${project_name}.srcs/sources_1/bd/blackparrot_bd_1/hdl/blackparrot_bd_1_wrapper.v
set_property verilog_define $::env(SV_DEFINES) [current_fileset]

save_bd_design

# change this to a 0 to have it stop before synthesis and implementation
# so you can inspect the design with the GUI

if {1} {
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
}

puts "Completed. Type start_gui to enter vivado GUI; quit to exit"

exit
