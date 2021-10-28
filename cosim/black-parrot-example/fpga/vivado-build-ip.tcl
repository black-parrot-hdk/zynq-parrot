# vivado -mode tcl

source vivado_parse_bp_vcs_flist.tcl

set flist_filename  flist.vcs

#set flist_includelist [vivado_parse_bp_vcs_flist $flist_filename ../../import/black-parrot ../../import/black-parrot/external/basejump_stl ../../import/black-parrot/external/HardFloat ../../v]

set flist    [lindex $flist_includelist 0]
set includelist  [lindex $flist_includelist 1]

#puts $flist
#puts $includelist

set project_top_module top

set project_name blackparrot_ip_proj

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

set_property include_dirs ${includelist} [current_fileset]
set_property top ${project_top_module} [current_fileset]

update_compile_order -fileset sources_1
synth_design -include_dirs $includelist -flatten_hierarchy none

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


