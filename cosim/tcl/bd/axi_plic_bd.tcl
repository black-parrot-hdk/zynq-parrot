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
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_assert.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_assert_dummy_macros.svh"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_assert_sec_cm.svh"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_flop_macros.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_defines.sv"

    lappend file_list "${BASEJUMP_STL_DIR}/bsg_axi/bsg_axi_pkg.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_buf.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_reset.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_en.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_edge_detect.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_scan.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_async/bsg_sync_sync.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_encode_one_hot.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_priority_encode.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_priority_encode_one_hot_out.sv"

    lappend file_list "${BLACKPARROT_SUB_DIR}/axi/v/bsg_axil_fifo_master.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/axi/v/bsg_axil_fifo_client.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/bsg_axil_plic.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/bsg_irq_to_axil.sv"

    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_one_fifo.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/top_pkg.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_util_pkg.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_subreg_pkg.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_mubi_pkg.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_reg_we_check.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_subreg.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_subreg_arb.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_subreg_ext.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_max_tree.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/prim_onehot_check.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/rv_plic_reg_pkg.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/rv_plic.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/rv_plic_gateway.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/rv_plic_target.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/gen/rv_plic_reg_top.sv"

    add_files -norecurse ${file_list}
    set_property file_type SystemVerilog [get_files ${file_list}]
    add_files -norecurse "${BLACKPARROT_SUB_DIR}/zynq/v/plic_top.v"
    set_property include_dirs ${dir_list} [get_fileset sources_1]
    set_property top plic_top [get_fileset sources_1]
    update_compile_order -fileset sources_1

    create_bd_cell -type module -reference plic_top -name top
    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type rst aresetn
    # Should depend on parameter
    create_bd_port -dir I -from 1 -to 0 -type intr INTR
    connect_bd_net [get_bd_ports aclk] [get_bd_pins top/aclk]
    connect_bd_net [get_bd_ports aresetn] [get_bd_pins top/aresetn]
    connect_bd_net [get_bd_ports INTR] [get_bd_pins top/intr_src_i]
    make_bd_intf_pins_external -name "M_AXI" [get_bd_intf_pins top/m_axil]
    make_bd_intf_pins_external -name "S_AXI" [get_bd_intf_pins top/s_axil]
    set_property CONFIG.ASSOCIATED_BUSIF {M_AXI:S_AXI} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports M_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports S_AXI]

    # Need to increase aperture size because of vivado bug
    assign_bd_address
    set_property range 256M [get_bd_addr_segs {top/m_axil/*}]
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
}

