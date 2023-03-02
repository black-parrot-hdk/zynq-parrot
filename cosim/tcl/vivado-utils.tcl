
proc vivado_parse_flist {flist_path} {
    set f [split [string trim [read [open $flist_path r]]] "\n"]
    set flist [list ]
    set dir_list [list ]
    set def_list [list ]
    foreach x $f {
        if {![string match "" $x]} {
            # If the item starts with +incdir+, directory files need to be added
            if {[string match "#*" $x]} {
                # get rid of comment line
            } elseif {[string match "+incdir+*" $x]} {
                set trimchars "+incdir+"
                set temp [string trimleft $x $trimchars]
                set expanded [subst $temp]
                lappend dir_list $expanded
            } elseif {[string match "+define+*" $x]} {
                set trimchars "+define+"
                set temp [string trimleft $x $trimchars]
                set expanded [subst $temp]
                lappend def_list $expanded
            } else {
                set expanded [subst $x]
                lappend flist $expanded
            }
        }
    }

    return [list $flist $dir_list $def_list]
}

proc vivado_create_and_package_ip { ip_name top_name part flist } {
  set ip_proj_name ${ip_name}_ip_proj

  set vlist          [vivado_parse_flist $flist]
  set vsources_list  [lindex $vlist 0]
  set vincludes_list [lindex $vlist 1]
  set vdefines_list  [lindex $vlist 2]

  #
  # create project and load in all the files
  #

  create_project -force ${ip_proj_name} [pwd] -part ${part}

  puts ${vsources_list}
  puts ${vdefines_list}

  add_files -norecurse ${vsources_list}
  set_property file_type SystemVerilog [get_files ${vsources_list}]
  set_property include_dirs ${vincludes_list} [current_fileset]
  set_property verilog_define ${vdefines_list} [current_fileset]

  set_property top ${top_name} [current_fileset]

  update_compile_order -fileset sources_1

  ipx::package_project -root_dir ip_repo -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
  ipx::unload_core ip_repo/component.xml
  ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory ip_repo ip_repo/component.xml
  update_compile_order -fileset sources_1
  set_property previous_version_for_upgrade user.org:user:${ip_name}:1.0 [ipx::current_core]
  set_property core_revision 1 [ipx::current_core]
  ipx::create_xgui_files [ipx::current_core]
  ipx::update_checksums [ipx::current_core]
  ipx::save_core [ipx::current_core]
  ipx::move_temp_component_back -component [ipx::current_core]
  close_project -delete
  set_property  ip_repo_paths ip_repo [current_project]
  update_ip_catalog

  puts "Type start_gui to enter Vivado GUI; quit to exit"
}

