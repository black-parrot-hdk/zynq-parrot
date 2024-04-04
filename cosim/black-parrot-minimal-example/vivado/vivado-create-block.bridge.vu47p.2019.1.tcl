set project_name $::env(BASENAME)_bd_proj
set project_part $::env(PART)
set project_bd   $::env(BASENAME)_bd_1
set tcl_dir      $::env(CURR_TCL_DIR)

create_project -force ${project_name} [pwd] -part ${project_part}
create_bd_design "${project_bd}"
update_compile_order -fileset sources_1
open_bd_design ${project_name}.srcs/sources_1/bd/${project_bd}/${project_bd}.bd}
set_property  ip_repo_paths  ip_repo [current_project]
update_ip_catalog

startgroup
create_bd_cell -type ip -vlnv user.org:user:uart:1.0 uart_0
endgroup
startgroup
create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins top_0/aresetn]
endgroup

assign_bd_address

save_bd_design

# Change to 0 to have it stop before synthesis / implementation
# so you can inspect the design with the GUI

if {0} {
  launch_runs synth_1 -jobs 4
  wait_on_run synth_1
  open_run synth_1 -name synth_1
  source ${tcl_dir}/additional_constraints.tcl
}

if {0} {
  launch_runs impl_1 -to_step write_bitstream -jobs 4
  wait_on_run impl_1
}

puts "Completed. Type start_gui to enter vivado GUI; quit to exit"
