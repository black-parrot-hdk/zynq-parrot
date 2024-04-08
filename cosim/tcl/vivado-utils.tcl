
proc vivado_env_default { var def } {
    if {[info exists ::env(${var})]} {
        return $::env(${var})
    } else {
        return ${def}
    }
}

proc vivado_read_xdc { xdc_dir boardname } {
    set file_name [file normalize "${xdc_dir}/board.${boardname}.xdc"]
    set file_added [add_files -norecurse -fileset [get_filesets constrs_1] [list "${file_name}"]]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*${file_name}"]]
    set_property -name "file_type" -value "XDC" -objects ${file_obj}
}

proc vivado_find_hwh { proj_bd } {
    set hwh_files [exec find -name *_bd_1.hwh]

    foreach h ${hwh_files} {
        set f [open ${h}]

        set search1 "*processing_system7_0*"
        set search2 "*zynq_ultra_ps_e_0*"
        while {[gets ${f} line] >= 0} {
            if {[string match ${search1} ${line}]} {
                puts "PS found: ${search1} ${h}\n"
                return ${h}
            }
            if {[string match ${search2} ${line}]} {
                puts "PS found: ${search2} ${h}\n"
                return ${h}
            }
        }
    }

    return [get_files ${proj_bd}.hwh]
}

# TODO: Generalize
proc vivado_gen_map { proj_hwh proj_map } {
    set f [open ${proj_hwh} "r"]
    set m [open ${proj_map} "w"]
    set search "*MEMRANGE*"
    while {[gets ${f} line] >= 0} {
        if {[string match ${search} ${line}]} {
            regexp -nocase -line -- {BASEVALUE="(.*?)"} ${line} value base
            regexp -nocase -line -- {([A-Z][A-Z][0-9])_AXI} ${line} value port
            puts "Found Port ${port}: ${base}"
            puts -nonewline $m "-D${port}_ADDR_BASE=${base} "
        }
    }
    close $m
    close $f
}

proc vivado_create_bd_design { proj_bd } {
    create_bd_design ${proj_bd}
    open_bd_design ${proj_bd}.bd
    set_property ip_repo_paths ip_repo [current_project]
    update_ip_catalog
}

proc vivado_save_bd_design { proj_name proj_bd } {
    regenerate_bd_layout
    assign_bd_address
    validate_bd_design
    set wrap_file [make_wrapper -force -top -files [get_files ${proj_bd}.bd]]
    add_files ${wrap_file} -fileset sources_1
    set_property synth_checkpoint_mode None [get_files ${proj_bd}.bd]
    set_property top [get_files ${wrap_file}] [get_filesets sources_1]
    update_compile_order -quiet -fileset sources_1
    save_bd_design
}

proc vivado_elab_wrap { do_elab proj_bd } {
    if {${do_elab}} {
        set_property synth_checkpoint_mode None [get_files ${proj_bd}.bd]
        generate_target all [get_files ${proj_bd}.bd]
        synth_design -rtl -rtl_skip_constraints -rtl_skip_mlo -name rtl_1
    }
}

proc vivado_synth_wrap { do_synth threads } {
    if {${do_synth}} {
        set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
        set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
        launch_runs synth_1 -jobs ${threads}
        wait_on_run synth_1
        open_run synth_1 -name synth_1
    }
}

proc vivado_impl_wrap { do_impl threads } {
    if {${do_impl}} {
        launch_runs impl_1 -to_step write_bitstream -jobs ${threads}
        wait_on_run impl_1
        open_run impl_1 -name impl_1
    }
}

proc vivado_save_handoff { do_handoff proj_name proj_bd } {
    if {${do_handoff}} {
        file copy ${proj_name}.runs/impl_1/${proj_bd}_wrapper.bit ${proj_bd}.bit
        file copy ${proj_name}.runs/impl_1/${proj_bd}_wrapper.tcl ${proj_bd}.tcl
        file copy [vivado_find_hwh ${proj_bd}] ${proj_bd}.hwh
        vivado_gen_map ${proj_bd}.hwh ${proj_bd}.map
    }
}

proc vivado_add_bd_parameter { name def } {
    ipx::add_user_parameter ${name} [ipx::current_core]
    set_property value_resolve_type user [ipx::get_user_parameters ${name} -of_objects [ipx::current_core]]
    ipgui::add_param -name "${name}" -component [ipx::current_core]
    set_property display_name {} [ipgui::get_guiparamspec -name "${name}" -component [ipx::current_core] ]
    set_property tooltip {} [ipgui::get_guiparamspec -name "${name}" -component [ipx::current_core] ]
    set_property widget {textEdit} [ipgui::get_guiparamspec -name "${name}" -component [ipx::current_core] ]
    set_property value_format long [ipx::get_user_parameters "${name}" -of_objects [ipx::current_core]]
    set_property value ${def} [ipx::get_user_parameters "${name}" -of_objects [ipx::current_core]]
}

proc vivado_parse_flist { flist_path } {
    set f [split [string trim [read [open $flist_path r]]] "\n"]
    set files [list]
    set dirs [list]
    foreach x $f {
        if {![string match "" $x]} {
            if {[string match "#*" $x]} {
                continue
            } elseif {[string match "+incdir+*" $x]} {
                set trimchars "+incdir+"
                set temp [string trimleft $x $trimchars]
                set expanded [subst $temp]
                lappend dirs $expanded
            } else {
                set expanded [subst $x]
                lappend files $expanded
            }
        }
    }

    set_property include_dirs $dirs [get_filesets sources_1]
    add_files -fileset sources_1 -scan_for_includes $files
    set_property -quiet file_type "SystemVerilog" [get_files *pkg*]
    set_property -quiet file_type "SystemVerilog" [get_files *.v]
    set_property -quiet file_type "SystemVerilog" [get_files *.sv]
    set_property -quiet file_type "Verilog Header" [get_files *.vi]
    set_property -quiet file_type "Verilog Header" [get_files *.vh]
    set_property -quiet file_type "Verilog Header" [get_files *.svh]
    set_property -quiet file_type "Verilog" [get_files top.v]
    update_compile_order -quiet -fileset sources_1
}

proc vivado_customize_ip { proj_bd ip_name ip_script args } {
    ipx::unload_core ip_repo/${ip_name}/component.xml
    ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory ip_repo ip_repo/${ip_name}/component.xml

    source -verbose ${ip_script}
    vivado_ipx_customize ${args}

    set_property core_revision 1 [ipx::current_core]
    ipx::update_source_project_archive -component [ipx::current_core]
    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    ipx::move_temp_component_back -component [ipx::current_core]
    close_project -delete
    set_property ip_repo_paths ip_repo [current_project]
    update_ip_catalog
}

proc vivado_package_ip { proj_bd ip_name ip_script } {
    ipx::package_project -root_dir ip_repo/${ip_name} -vendor user.org -library user -taxonomy /UserIP -import_files -module ${proj_bd}
    set_property display_name ${ip_name}_v1_0 [ipx::current_core]
    set_property description ${ip_name}_v1_0 [ipx::current_core]
    set_property name ${ip_name} [ipx::current_core]
    ipx::add_file_group -type xilinx_blockdiagram {} [ipx::current_core]
    file mkdir ip_repo/${ip_name}/bd
    file copy -force ${ip_script} ip_repo/${ip_name}/bd/bd.tcl
    ipx::add_file bd/bd.tcl [ipx::get_file_groups xilinx_blockdiagram -of_objects [ipx::current_core]]
    ipx::save_core [ipx::current_core]
    set_property ip_repo_paths ip_repo [current_project]
    update_ip_catalog
}

proc vivado_create_ip_proj { proj_name proj_bd ip_name part ip_script args } {
    create_project -force ${proj_name} [pwd] -part ${part}
    vivado_create_bd_design ${proj_bd}
    source -verbose ${ip_script}
    vivado_create_ip ${args}
    vivado_save_bd_design ${proj_name} ${proj_bd}
}

