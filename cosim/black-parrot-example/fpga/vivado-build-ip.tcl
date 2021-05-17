# vivado -mode tcl

source vivado_parse_bp_vcs_flist.tcl

set flist_path [vivado_parse_bp_vcs_flist ../flist.vcs ../../import/black-parrot ../../import/black-parrot/external/basejump_stl ../../import/black-parrot/external/HardFloat ../../common/v]


set flist    [lindex $flist_path 0]
set dirlist  [lindex $flist_path 1]

puts $flist
puts $dirlist

set project_top_module top

set project_name black_parrot_ip_proj


#
# create project and load in all the files
#

create_project -force ${project_name} [pwd] -part xc7z020clg400-1

foreach {i} ${flist} {
    set filename [file normalize ${i}]
    puts "Adding $filename"
    add_files -norecurse $filename
    #set_property file_type {Verilog Header} [get_files ${basejump_path}${i}]
    set_property file_type SystemVerilog [get_files ${i}]
}

quit

foreach {i} ${basejump_list} {
    add_files -norecurse ${basejump_path}${i}
    set_property file_type SystemVerilog [get_files ${basejump_path}${i}]

}

foreach {i} ${project_list} {
    add_files -norecurse ${i}
    set_property file_type SystemVerilog [get_files ${i}]
}

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

puts "Type start_gui to enter Vivado GUI; quit to exit and continue"


