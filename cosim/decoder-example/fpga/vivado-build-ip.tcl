# vivado -mode tcl


set basejump_path ../../import/basejump_stl/

set basejump_list { bsg_misc/bsg_dff_reset_en.v bsg_dataflow/bsg_fifo_1r1w_small.v bsg_dataflow/bsg_flow_counter.v bsg_misc/bsg_counter_up_down.v bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v bsg_dataflow/bsg_two_fifo.v bsg_dataflow/bsg_fifo_1r1w_small_hardened.v bsg_misc/bsg_decode_with_v.v bsg_misc/bsg_decode.v bsg_misc/bsg_mux_one_hot.v bsg_dataflow/bsg_fifo_tracker.v bsg_misc/bsg_circular_ptr.v bsg_mem/bsg_mem_1r1w.v bsg_mem/bsg_mem_1r1w_synth.v}

set basejump_headers {  bsg_misc/bsg_defines.v }

set project_list { ../verilator/example_axi_v1_0_S00_AXI.v ../verilator/top.v}

set project_top_module top

set project_name fartcloud

puts ${basejump_list}

#
# create project and load in all the files
#

create_project -force ${project_name} [pwd] -part xc7z020clg400-1

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

ipx::package_project -root_dir /home/profmbt/zp4/zynq-parrot/cosim/decoder-example/fpga/fpga_build -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core /home/profmbt/zp4/zynq-parrot/cosim/decoder-example/fpga/fpga_build/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory /home/profmbt/zp4/zynq-parrot/cosim/decoder-example/fpga/fpga_build /home/profmbt/zp4/zynq-parrot/cosim/decoder-example/fpga/fpga_build/component.xml
update_compile_order -fileset sources_1
set_property previous_version_for_upgrade user.org:user:top:1.0 [ipx::current_core]
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete
set_property  ip_repo_paths  /home/profmbt/zp4/zynq-parrot/cosim/decoder-example/fpga/fpga_build [current_project]
update_ip_catalog


#
# this will package the source code into an "IP block"
# (matches "Create and Package IP" menu item in the GUI)
#

#ipx::package_project -root_dir fpga_build/ -vendor bsg.ai -library user -taxonomy /UserIP -import_files -set_current false

#ipx::unload_core fpga_build/component.xml
#ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory fpga_build fpga_build/component.xml

#current_project fartcloud
#set_property core_revision 2 [ipx::current_core]
#ipx::update_source_project_archive -component [ipx::current_core]
#ipx::create_xgui_files [ipx::current_core]
#ipx::update_checksums [ipx::current_core]
#ipx::save_core [ipx::current_core]

#create_bd_design "design_1"
#startgroup
#create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
#endgroup

#apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]


# launch synthesis
#launch_runs synth_1 -jobs 4

# wait for synthesis to complete
#wait_on_run synth_1

puts "Type start_gui to enter Vivado GUI; quit to exit"


