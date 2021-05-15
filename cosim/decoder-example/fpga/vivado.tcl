# vivado -mode tcl

#create_project fartcloud [pwd] -part xc7z020clg400-1
set basejump_path ../../imports/basejump_stl/

set basejump_list { bsg_misc/bsg_dff_reset_en.v bsg_dataflow/bsg_fifo_1r1w_small.v bsg_dataflow/bsg_flow_counter.v bsg_misc/bsg_counter_up_down.v bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v bsg_dataflow/bsg_two_fifo.v bsg_dataflow/bsg_fifo_1r1w_small_hardened.v bsg_misc/bsg_decode_with_v.v bsg_misc/bsg_decode.v bsg_misc/bsg_mux_one_hot.v bsg_misc/bsg_defines.v}

foreach {i} basejump_list {
    add_files -norecurse ${basejump_path}${i}
    set_property file_type SystemVerilog [get_files ${basejump_path}${i}
}
