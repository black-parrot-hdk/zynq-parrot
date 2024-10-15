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

    set BASEJUMP_ML_ATOMS "${BLACKPARROT_SUB_DIR}/zynq/import/basejump_ml_atoms/atoms"

    lappend dir_list "${BASEJUMP_STL_DIR}/bsg_misc"
    lappend dir_list "${BASEJUMP_ML_ATOMS}/include"

    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_defines.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/include/bsg_mla_defines.svh"
    lappend file_list "${BASEJUMP_ML_ATOMS}/include/bsg_mla_csr_pkg.svh"

    lappend file_list "${BASEJUMP_ML_ATOMS}/misc/bsg_mla_dff_with_v.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/misc/bsg_mla_fifo_1r1w_small_alloc.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/misc/bsg_mla_valid_yumi_1_to_n.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/misc/bsg_mla_fifo_reorder_cam.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/csr/bsg_mla_csr.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/dma/bsg_mla_dma_controller_addr_gen.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/dma/bsg_mla_dma_controller_core.sv"
    lappend file_list "${BASEJUMP_ML_ATOMS}/dma/bsg_mla_dma_controller.sv"

    lappend file_list "${BASEJUMP_STL_DIR}/bsg_axi/bsg_axi_pkg.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_en.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_decode.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_decode_with_v.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_reset_set_clear.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_circular_ptr.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_circular_ptr.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_mux_one_hot.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_mem_1r1w_one_hot.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_mem_1r1w.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_mem_1r1w_synth.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/hard/ultrascale_plus/bsg_mem/bsg_mem_1r1w_sync.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_reset.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_reset_en.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_counter_up_down.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_cam_1r1w_unmanaged.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_cam_1r1w_tag_array.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_tracker.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_reorder.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_1r1w_small.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_1r1w_small_hardened.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_one_fifo.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_two_fifo.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/axi/v/bsg_axil_fifo_client.sv"
    lappend file_list "${BLACKPARROT_SUB_DIR}/zynq/v/bsg_axil_dma.sv"

    add_files -norecurse ${file_list}
    set_property file_type SystemVerilog [get_files ${file_list}]
    add_files -norecurse "${BLACKPARROT_SUB_DIR}/zynq/v/dma_top.v"
    set_property include_dirs ${dir_list} [get_fileset sources_1]
    set_property top dma_top [get_fileset sources_1]
    update_compile_order -fileset sources_1

    create_bd_cell -type module -reference dma_top -name top
    create_bd_port -dir I -type clk -freq_hz ${aclk_freq_hz} aclk
    create_bd_port -dir I -type rst aresetn
    create_bd_port -dir O -type data INTR
    connect_bd_net [get_bd_ports aclk] [get_bd_pins top/aclk]
    connect_bd_net [get_bd_ports aresetn] [get_bd_pins top/aresetn]
    make_bd_intf_pins_external -name "M_AXI" [get_bd_intf_pins top/m_axil]
    make_bd_intf_pins_external -name "S_AXI" [get_bd_intf_pins top/s_axil]
    set_property CONFIG.ASSOCIATED_BUSIF {M_AXI:S_AXI} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports M_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports S_AXI]
    connect_bd_net [get_bd_ports INTR] [get_bd_pins top/interrupt_o]

    # Need to increase aperture size because of vivado bug
    assign_bd_address
    set_property range 256M [get_bd_addr_segs {top/m_axil/*}]
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {
    ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.ACLK -of_objects [ipx::current_core]]
}

