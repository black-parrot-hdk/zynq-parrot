set project_name $::env(BASENAME)_bd_proj
set project_part $::env(PART)
set project_bd   $::env(BASENAME)_bd_1
set tcl_dir      $::env(TCL_DIR)
set eth_dir  $::env(ETH_DIR)

create_project -force ${project_name} [pwd] -part ${project_part}
create_bd_design "${project_bd}"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP1 {1}] [get_bd_cells processing_system7_0]
# 20 MHZ clock for BP core
set_property -dict [list CONFIG.PCW_EN_CLK0_PORT {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {20}] [get_bd_cells processing_system7_0]
# 0.4 MHZ clock for BP RTC
set_property -dict [list CONFIG.PCW_EN_CLK1_PORT {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {0.4}] [get_bd_cells processing_system7_0]
# 250 MHZ clock for Ethernet
set_property -dict [list CONFIG.PCW_EN_CLK2_PORT {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {250}] [get_bd_cells processing_system7_0]
# 200 MHZ clock for the iodelay primitives in Ethernet
set_property -dict [list CONFIG.PCW_EN_CLK3_PORT {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {200}] [get_bd_cells processing_system7_0]

set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
open_bd_design ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd}
set_property  ip_repo_paths  fpga_build [current_project]
update_ip_catalog

startgroup
create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
set_property -dict [list CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_pins /processing_system7_0/FCLK_CLK0]]] [get_bd_pins top_0/aclk]
set_property -dict [list CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_pins /processing_system7_0/FCLK_CLK1]]] [get_bd_pins top_0/rt_clk]
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1
endgroup
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_1]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins top_0/s00_axi]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP1] [get_bd_intf_pins smartconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins top_0/s01_axi]
connect_bd_intf_net [get_bd_intf_pins top_0/m00_axi] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins top_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_1/aresetn]
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (20 MHz)" }  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
endgroup

# Instantiate smartconnect_2
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_2
set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_2]
connect_bd_net [get_bd_pins smartconnect_2/aclk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins smartconnect_2/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

# Instantiate smartconnect_3
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_3
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_3]
connect_bd_net [get_bd_pins smartconnect_3/aclk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins smartconnect_3/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

connect_bd_intf_net [get_bd_intf_pins top_0/m01_axi] [get_bd_intf_pins smartconnect_2/S00_AXI]

connect_bd_net [get_bd_pins top_0/rt_clk] [get_bd_pins processing_system7_0/FCLK_CLK1]

# with other versions of vivado, it may have different names for the slave segment
# in the gui you can open the address editor, right click on the interface (s00_axi or s01_axi)
# and select "Address Segment Properties..." to see what name to use in these commands.

# Instantiate the Ethernet module
create_bd_cell -type ip -vlnv user.org:user:ethernet_axil_wrapper:1.0 ethernet_axil_wrapper_0
connect_bd_intf_net [get_bd_intf_pins smartconnect_2/M00_AXI] [get_bd_intf_pins ethernet_axil_wrapper_0/s00_axi]
connect_bd_net [get_bd_pins ethernet_axil_wrapper_0/aclk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins ethernet_axil_wrapper_0/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

# Instantiate the RISC-V PLIC module
create_bd_cell -type ip -vlnv user.org:user:rv_plic_axil_wrapper:1.0 rv_plic_axil_wrapper_0
connect_bd_intf_net [get_bd_intf_pins smartconnect_2/M01_AXI] [get_bd_intf_pins rv_plic_axil_wrapper_0/s00_axi]
connect_bd_net [get_bd_pins rv_plic_axil_wrapper_0/aclk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins rv_plic_axil_wrapper_0/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

connect_bd_intf_net [get_bd_intf_pins rv_plic_axil_wrapper_0/m00_axi] [get_bd_intf_pins smartconnect_3/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins top_0/s02_axi] [get_bd_intf_pins smartconnect_3/M00_AXI]
connect_bd_net [get_bd_pins rv_plic_axil_wrapper_0/intr_src_i] [get_bd_pins ethernet_axil_wrapper_0/irq_o]

# Connect 250MHZ and 200MHZ clocks
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins ethernet_axil_wrapper_0/clk250_i]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins top_0/clk250_i]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK3] [get_bd_pins ethernet_axil_wrapper_0/iodelay_ref_clk_i]

# Connect reset signals
connect_bd_net [get_bd_pins top_0/clk250_reset_o] [get_bd_pins ethernet_axil_wrapper_0/clk250_reset_i]
connect_bd_net [get_bd_pins top_0/tx_clk_gen_reset_o] [get_bd_pins ethernet_axil_wrapper_0/tx_clk_gen_reset_i]
connect_bd_net [get_bd_pins top_0/tx_reset_o] [get_bd_pins ethernet_axil_wrapper_0/tx_reset_i]
connect_bd_net [get_bd_pins top_0/rx_reset_o] [get_bd_pins ethernet_axil_wrapper_0/rx_reset_i]

# Connect tx_clk and rx_clk (for Ethernet)
connect_bd_net [get_bd_pins ethernet_axil_wrapper_0/tx_clk_o] [get_bd_pins top_0/tx_clk_i]
connect_bd_net [get_bd_pins ethernet_axil_wrapper_0/rx_clk_o] [get_bd_pins top_0/rx_clk_i]

# Create external pins for RGMII
make_bd_pins_external -name rgmii_rx_clk_i [get_bd_pins ethernet_axil_wrapper_0/rgmii_rx_clk_i]
make_bd_pins_external -name rgmii_rxd_i    [get_bd_pins ethernet_axil_wrapper_0/rgmii_rxd_i]
make_bd_pins_external -name rgmii_rx_ctl_i [get_bd_pins ethernet_axil_wrapper_0/rgmii_rx_ctl_i]
make_bd_pins_external -name rgmii_tx_clk_o [get_bd_pins ethernet_axil_wrapper_0/rgmii_tx_clk_o]
make_bd_pins_external -name rgmii_txd_o    [get_bd_pins ethernet_axil_wrapper_0/rgmii_txd_o]
make_bd_pins_external -name rgmii_tx_ctl_o [get_bd_pins ethernet_axil_wrapper_0/rgmii_tx_ctl_o]
create_bd_port -dir O -type rst eth_phy_resetn_o
connect_bd_net [get_bd_ports eth_phy_resetn_o] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

create_bd_addr_seg -range 0x00001000 -offset 0x40000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs top_0/s00_axi/reg0] SEG_top_0_reg0
create_bd_addr_seg -range 0x40000000 -offset 0x80000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs top_0/s01_axi/reg0] SEG_top_0_reg1
create_bd_addr_seg -range 0x100000000 -offset 0x0 [get_bd_addr_spaces rv_plic_axil_wrapper_0/m00_axi] [get_bd_addr_segs top_0/s02_axi/reg0] SEG_top_0_reg2
create_bd_addr_seg -range 0x2000 -offset 0x20000000 [get_bd_addr_spaces top_0/m01_axi] [get_bd_addr_segs ethernet_axil_wrapper_0/s00_axi/reg0] SEG_top_0_reg3
create_bd_addr_seg -range 0x4000000 -offset 0x10000000 [get_bd_addr_spaces top_0/m01_axi] [get_bd_addr_segs rv_plic_axil_wrapper_0/s00_axi/reg0] SEG_top_0_reg4
assign_bd_address

validate_bd_design
make_wrapper -files [get_files ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd] -top
add_files -norecurse ${project_name}.srcs/sources_1/bd/${project_bd}/hdl/${project_bd}_wrapper.v
delete_bd_objs [get_bd_nets reset_rtl_0_1] [get_bd_ports reset_rtl_0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
save_bd_design

# Change to 0 to have it stop before synthesis / implementation
# so you can inspect the design with the GUI

if {1} {
  launch_runs synth_1 -jobs 4
  wait_on_run synth_1
  open_run synth_1 -name synth_1
  source ${eth_dir}/../syn/zedboard/zedboard.tcl
  source ${tcl_dir}/additional_constraints.tcl
}

if {0} {
  launch_runs impl_1 -to_step write_bitstream -jobs 4
  wait_on_run impl_1
}

puts "Completed. Type start_gui to enter vivado GUI; quit to exit"
