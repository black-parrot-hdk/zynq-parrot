# vivado -mode tcl

set project_basename   $::env(BASENAME)
set project_name       ${project_basename}_ip_proj
set project_top_module $::env(TOP_MODULE)
set project_part       $::env(PART)

source $::env(COSIM_TCL_DIR)/vivado-parse-flist.tcl

set vlist [vivado_parse_flist "flist.vcs"]
set vsources_list  [lindex $vlist 0]
set vincludes_list [lindex $vlist 1]
set vdefines_list  [lindex $vlist 2]

#
# create project and load in all the files
#

create_project -force ${project_name} [pwd] -part ${project_part}

puts ${vsources_list}
puts ${vdefines_list}

add_files -norecurse ${vsources_list}
set_property file_type SystemVerilog [get_files ${vsources_list}]
set_property include_dirs ${vincludes_list} [current_fileset]
set_property verilog_define ${vdefines_list} [current_fileset]

set_property top ${project_top_module} [current_fileset]

update_compile_order -fileset sources_1

ipx::package_project -root_dir fpga_build -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core fpga_build/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory fpga_build fpga_build/component.xml
update_compile_order -fileset sources_1
set_property previous_version_for_upgrade user.org:user:top:1.0 [ipx::current_core]
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete
set_property  ip_repo_paths fpga_build [current_project]
update_ip_catalog

puts "Type start_gui to enter Vivado GUI; quit to exit"


