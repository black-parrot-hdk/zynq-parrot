source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc init { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]
}

proc post_propagate { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]
    # standard parameter propagation here
}

proc vivado_create_ip { args } {
    set aclk_freq_mhz  [lindex [lindex ${args} 0] 0]

    set aclk_freq_hz [expr round(${aclk_freq_mhz}*1e6)]

    set dir_list [list]
    set file_list [list]

    set BASEJUMP_STL_DIR $::env(BASEJUMP_STL_DIR)
    set BLACKPARROT_SUB_DIR $::env(BLACKPARROT_SUB_DIR)
    set CURR_VSRC_DIR $::env(CURR_VSRC_DIR)
    set COSIM_VSRC_DIR $::env(COSIM_VSRC_DIR)

    lappend dir_list "${BASEJUMP_STL_DIR}/bsg_misc"
    lappend dir_list "${BASEJUMP_STL_DIR}/bsg_dataflow"

    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_defines.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/bsg_axis_fifo.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_counter_up_down.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_1r1w_small.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.sv"

    add_files -norecurse ${file_list}
    set_property file_type SystemVerilog [get_files ${file_list}]
    add_files -norecurse "${BLACKPARROT_SUB_DIR}/zynq/v/fifo_top.v"
    set_property include_dirs ${dir_list} [get_fileset sources_1]
    set_property top fifo_top [get_fileset sources_1]
    update_compile_order -fileset sources_1

    create_bd_cell -type module -reference fifo_top -name top
    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type rst aresetn
    connect_bd_net [get_bd_ports aclk] [get_bd_pins top/aclk]
    connect_bd_net [get_bd_ports aresetn] [get_bd_pins top/aresetn]
    make_bd_intf_pins_external -name "M_AXIS" [get_bd_intf_pins top/m_axis]
    make_bd_intf_pins_external -name "S_AXIS" [get_bd_intf_pins top/s_axis]
    set_property CONFIG.ASSOCIATED_BUSIF {M_AXIS:S_AXIS} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4STREAM} [get_bd_intf_ports M_AXIS]
    set_property CONFIG.PROTOCOL {AXI4STREAM} [get_bd_intf_ports S_AXIS]
    #connect_bd_net [get_bd_ports tag_clk] [get_bd_pins top/tag_clk]
    #connect_bd_net [get_bd_ports tag_data] [get_bd_pins top/tag_data]

    ## Need to increase aperture size because of vivado bug
    #assign_bd_address
    #set_property range 256M [get_bd_addr_segs {top/m_axil/*}]
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
}

