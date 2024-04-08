
set project_name $::env(BASENAME)_bd_proj
set project_part $::env(PART)
set project_bd   $::env(BASENAME)_bd_1
set boardname    $::env(BOARDNAME)
set xdc_dir      $::env(COSIM_XDC_DIR)
set xdc_file     ${xdc_dir}/board.${boardname}.xdc

set do_synth $::env(SYNTH)
set do_impl  $::env(IMPL)
set threads  $::env(THREADS)

set uart_baud $::env(UART_BAUD)

create_project -force ${project_name} [pwd] -part ${project_part}
create_bd_design "${project_bd}"
save_bd_design

#### Create ports
create_bd_port -dir I -type rst reset_rtl_0
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 diff_clock_rtl_0
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart_rtl_0
###
#### Instantiate Xilinx IP
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
###
#### Set properties of Xilinx IP
set_property CONFIG.FREQ_HZ 200000000 [get_bd_intf_ports diff_clock_rtl_0]
set_property -dict [list CONFIG.PRIMITIVE {Auto} CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {300} CONFIG.CLKOUT1_DRIVES {Buffer} CONFIG.CLKOUT2_DRIVES {Buffer} CONFIG.CLKOUT3_DRIVES {Buffer} CONFIG.CLKOUT4_DRIVES {Buffer} CONFIG.CLKOUT5_DRIVES {Buffer} CONFIG.CLKOUT6_DRIVES {Buffer} CONFIG.CLKOUT7_DRIVES {Buffer} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false} CONFIG.MMCM_BANDWIDTH {OPTIMIZED} CONFIG.MMCM_CLKFBOUT_MULT_F {9} CONFIG.MMCM_COMPENSATION {AUTO} CONFIG.MMCM_CLKOUT0_DIVIDE_F {18} CONFIG.MMCM_CLKOUT1_DIVIDE {3} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT1_JITTER {159.475} CONFIG.CLKOUT1_PHASE_ERROR {105.461} CONFIG.CLKOUT2_JITTER {111.879} CONFIG.CLKOUT2_PHASE_ERROR {105.461} CONFIG.AUTO_PRIMITIVE {PLL}] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
###
#### Instantiate user IP
set_property  ip_repo_paths  ip_repo [current_project]
update_ip_catalog
create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
###
#### Create port connections
connect_bd_intf_net [get_bd_intf_ports uart_rtl_0] [get_bd_intf_pins axi_uartlite_0/UART]
connect_bd_intf_net [get_bd_intf_ports diff_clock_rtl_0] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
connect_bd_net [get_bd_ports reset_rtl_0] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_ports reset_rtl_0] [get_bd_pins proc_sys_reset_1/ext_reset_in]
###
#### Create clock/reset structure for core clock
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins top_0/aresetn] 
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins top_0/aclk] 
#### Create clock/reset structure for uart clock
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins clk_wiz_0/clk_out2]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axi_uartlite_0/s_axi_aclk]
###
#### Create BD ADDR range for UART
create_bd_addr_seg -range 0x00002000 -offset 0x1100000 [get_bd_addr_spaces top_0/m01_axi] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
#### Create CDC
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins top_0/m01_axi]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
connect_bd_net [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins clk_wiz_0/clk_out2]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
###
#### Rename ports to match .xdc
set_property name refclk_i [get_bd_intf_ports diff_clock_rtl_0]
set_property name rstn [get_bd_ports reset_rtl_0]
set_property name uart [get_bd_intf_ports uart_rtl_0]
###
#### Create block design
assign_bd_address
validate_bd_design
# Need to set baud after validation because of vivado bug
set_property -dict [list CONFIG.C_BAUDRATE ${uart_baud}] [get_bd_cells axi_uartlite_0]
validate_bd_design

make_wrapper -files [get_files ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd] -top
add_files -norecurse ${project_name}.srcs/sources_1/bd/${project_bd}/hdl/${project_bd}_wrapper.v
save_bd_design
###
#### Read .xdc
set file_name "[file normalize "${xdc_dir}/board.${boardname}.xdc"]"
set file_added [add_files -norecurse -fileset [get_filesets constrs_1] [list "${file_name}"]]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*${file_name}"]]
set_property -name "file_type" -value "XDC" -objects ${file_obj}
###
#### Change to 0 to have it stop before synthesis / implementation
#### so you can inspect the design with the GUI

vivado_synth_wrap ${do_synth} ${threads}
vivado_impl_wrap ${do_impl} ${threads}

