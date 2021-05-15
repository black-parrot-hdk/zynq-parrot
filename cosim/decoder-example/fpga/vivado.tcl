# vivado -mode tcl

set basejump_path ../../import/basejump_stl/

set basejump_list { bsg_misc/bsg_dff_reset_en.v bsg_dataflow/bsg_fifo_1r1w_small.v bsg_dataflow/bsg_flow_counter.v bsg_misc/bsg_counter_up_down.v bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v bsg_dataflow/bsg_two_fifo.v bsg_dataflow/bsg_fifo_1r1w_small_hardened.v bsg_misc/bsg_decode_with_v.v bsg_misc/bsg_decode.v bsg_misc/bsg_mux_one_hot.v bsg_dataflow/bsg_fifo_tracker.v bsg_misc/bsg_circular_ptr.v bsg_mem/bsg_mem_1r1w.v bsg_mem/bsg_mem_1r1w_synth.v}

set basejump_headers {  bsg_misc/bsg_defines.v }

set project_list { ../verilator/example_axi_v1_0_S00_AXI.v }

set project_top_module example_axi_v1_0_S00_AXI

puts ${basejump_list}

#
# create project and load in all the files
#

create_project -force fartcloud [pwd] -part xc7z020clg400-1

foreach {i} ${basejump_headers} {
    add_files -norecurse ${basejump_path}${i}
    set_property file_type {Verilog Header} [get_files ${basejump_path}${i}]
}

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


#
# this will package the source code into an "IP block"
# (matches "Create and Package IP" menu item in the GUI)
#

ipx::package_project -root_dir build/ -vendor bsg.ai -library user -taxonomy /UserIP -import_files -set-current false
ipx::unload_core build/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory build build/component.xml
current_project fartcloud
set_property core_revision 2 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]


# launch synthesis
#launch_runs synth_1 -jobs 4

# wait for synthesis to complete
#wait_on_run synth_1

puts "Type start_gui to enter Vivado GUI; quit to exit"


