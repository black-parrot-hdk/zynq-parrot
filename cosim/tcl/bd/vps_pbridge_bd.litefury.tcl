
# Vivado hook for BD initialization
proc init { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]
}

# Vivado hook for after parameters propagate in BD
# https://support.xilinx.com/s/question/0D52E00006lLgeLSAS/how-to-make-cs00axiaddrwidth-dependent-on-address-editor?language=en_US
proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

# ZynqParrot hook for population of BD
proc vivado_create_ip { args } {
    set aclk_freq_mhz  [lindex [lindex ${args} 0] 0]
    set rtclk_freq_mhz [lindex [lindex ${args} 0] 1]
    set gp0_enable     [lindex [lindex ${args} 0] 2]
    set gp0_data_width [lindex [lindex ${args} 0] 3]
    set gp0_addr_width [lindex [lindex ${args} 0] 4]
    set gp1_enable     [lindex [lindex ${args} 0] 5]
    set gp1_data_width [lindex [lindex ${args} 0] 6]
    set gp1_addr_width [lindex [lindex ${args} 0] 7]
    set hp0_enable     [lindex [lindex ${args} 0] 8]
    set hp0_data_width [lindex [lindex ${args} 0] 9]
    set hp0_addr_width [lindex [lindex ${args} 0] 10]

    set sysclk_freq_mhz 200 ;# must be 200 MHz

    set dir_list [list]
    set file_list [list]

    set BASEJUMP_STL_DIR $::env(BASEJUMP_STL_DIR)
    set BP_SUB_DIR $::env(BP_SUB_DIR)
    set DESIGN_VSRC_DIR $::env(DESIGN_VSRC_DIR)
    set COSIM_VSRC_DIR $::env(COSIM_VSRC_DIR)

    lappend dir_list "${BASEJUMP_STL_DIR}/bsg_misc"
    lappend dir_list "${BASEJUMP_STL_DIR}/bsg_tag"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_defines.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_tag/bsg_tag.svh"

#    add_files -norecurse ${file_list}
#    set_property file_type SystemVerilog [get_files ${file_list}]
#    set_property include_dirs ${dir_list} [get_fileset sources_1]
#    add_files -norecurse "${BP_SUB_DIR}/zynq/v/uart_bridge_top.v"
#    update_compile_order -fileset sources_1
#
#    create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0
#    set_property CONFIG.C_BUF_TYPE {BUFG} [get_bd_cells util_ds_buf_0]
#    make_bd_pins_external -name "sys_clock" [get_bd_pins util_ds_buf_0/BUFG_I]
#
#    set proc_sys_reset_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0]
#    make_bd_pins_external -name "aresetn" [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
#    make_bd_pins_external -name "reset" [get_bd_pins proc_sys_reset_0/ext_reset_in]
#    set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports "reset"]
#
#    set clk_wiz_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
#    set_property -dict [list \
#        CONFIG.RESET_BOARD_INTERFACE {reset} \
#        CONFIG.RESET_PORT {resetn} \
#        CONFIG.RESET_TYPE {ACTIVE_LOW} \
#        CONFIG.CLKOUT1_USED {true} \
#        CONFIG.CLKOUT2_USED {true} \
#        CONFIG.CLKOUT3_USED {true} \
#        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $sysclk_freq_mhz \
#        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $aclk_freq_mhz \
#        CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $rtclk_freq_mhz \
#    ] $clk_wiz_0
#    set_property CONFIG.PRIM_SOURCE {No_buffer} [get_bd_cells clk_wiz_0]
#    make_bd_pins_external -name "aclk" [get_bd_pins clk_wiz_0/clk_out2]
#    make_bd_pins_external -name "rt_clk" [get_bd_pins clk_wiz_0/clk_out3]
#    connect_bd_net [get_bd_ports reset] [get_bd_pins clk_wiz_0/resetn]
#    connect_bd_net [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins clk_wiz_0/clk_in1]
#
#    set mig_7series_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0]
#    apply_board_connection -board_interface "ddr3_sdram" -ip_intf "mig_7series_0/mig_ddr_interface" -diagram [current_bd_design]
#    # patch buggy automation
#    delete_bd_objs [get_bd_ports "sys_clk_i clk_ref_i"]
#    delete_bd_objs [get_bd_nets "sys_clk_i_1 clk_ref_i_1"]
#    connect_bd_net [get_bd_ports reset] [get_bd_pins mig_7series_0/sys_rst]
#    connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins mig_7series_0/clk_ref_i]
#    connect_bd_net [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins mig_7series_0/sys_clk_i]
#    set_property CONFIG.XML_INPUT_FILE $::env(COSIM_XDC_DIR)/mig.artya7.prj [get_bd_cells mig_7series_0]
#
#    # Invert reset to active low
#    set toggle_0 [create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic:1.0 toggle_0]
#    set_property -dict [list \
#      CONFIG.C_OPERATION {not} \
#      CONFIG.C_SIZE {1} \
#    ] $toggle_0
#
#    set axi_uartlite_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0]
#    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart
#    set_property -dict [list \
#      CONFIG.USE_BOARD_FLOW {true} \
#      CONFIG.UARTLITE_BOARD_INTERFACE {usb_uart} \
#      CONFIG.C_BAUDRATE {230400} \
#    ] $axi_uartlite_0
#    connect_bd_intf_net [get_bd_intf_ports usb_uart] /axi_uartlite_0/UART
# 
#    # Create instance: smartconnect_0, and set properties
#    set smartconnect_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
#    set_property -dict [list \
#      CONFIG.NUM_CLKS {2} \
#      CONFIG.NUM_MI {2} \
#      CONFIG.NUM_SI {1} \
#      CONFIG.HAS_ARESETN {0} \
#    ] $smartconnect_0
#    make_bd_intf_pins_external -name "GP0_AXI" [get_bd_intf_pins smartconnect_0/M00_AXI]
#    make_bd_intf_pins_external -name "GP1_AXI" [get_bd_intf_pins smartconnect_0/M01_AXI]
#    # Create instance: smartconnect_1, and set properties
#    set smartconnect_1 [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
#    set_property -dict [list \
#      CONFIG.NUM_CLKS {2} \
#      CONFIG.NUM_SI {1} \
#      CONFIG.HAS_ARESETN {0} \
#    ] $smartconnect_1
#    make_bd_intf_pins_external -name "HP0_AXI" [get_bd_intf_pins smartconnect_1/S00_AXI]
#  
#    # Create instance uart bridge
#    create_bd_cell -type module -reference uart_bridge_top bridge_0
#
#    connect_bd_net [get_bd_pins mig_7series_0/ui_clk] \
#        [get_bd_pins smartconnect_0/aclk] \
#        [get_bd_pins smartconnect_1/aclk1] \
#        [get_bd_pins bridge_0/aclk] \
#        [get_bd_pins axi_uartlite_0/s_axi_aclk]
#    connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins toggle_0/Op1]
#    connect_bd_net [get_bd_pins toggle_0/Res] \
#        [get_bd_pins bridge_0/aresetn] \
#        [get_bd_pins axi_uartlite_0/s_axi_aresetn] \
#        [get_bd_pins mig_7series_0/aresetn]
#    connect_bd_net [get_bd_ports aclk] \
#        [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
#        [get_bd_pins smartconnect_0/aclk1] \
#        [get_bd_pins smartconnect_1/aclk]
#
#    connect_bd_intf_net [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
#    connect_bd_intf_net [get_bd_intf_pins bridge_0/uart_axil] [get_bd_intf_pins axi_uartlite_0/S_AXI]
#    connect_bd_intf_net [get_bd_intf_pins bridge_0/ui_axil] [get_bd_intf_pins smartconnect_0/S00_AXI]
#
#    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP0_AXI]
#    set_property CONFIG.DATA_WIDTH ${gp0_data_width} [get_bd_intf_ports GP0_AXI]
#    set_property CONFIG.ADDR_WIDTH ${gp0_addr_width} [get_bd_intf_ports GP0_AXI]
#
#    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP1_AXI]
#    set_property CONFIG.DATA_WIDTH ${gp1_data_width} [get_bd_intf_ports GP1_AXI]
#    set_property CONFIG.ADDR_WIDTH ${gp1_addr_width} [get_bd_intf_ports GP1_AXI]
#
#    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports HP0_AXI]
#    set_property CONFIG.DATA_WIDTH ${hp0_data_width} [get_bd_intf_ports HP0_AXI]
#    set_property CONFIG.ADDR_WIDTH ${hp0_addr_width} [get_bd_intf_ports HP0_AXI]
#    set_property CONFIG.ID_WIDTH 6 [get_bd_intf_ports HP0_AXI]
#
#    set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI:HP0_AXI} [get_bd_ports aclk]
#    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
#
#    # TODO: Deduce the offset
#    assign_bd_address -target_address_space [get_bd_addr_spaces /bridge_0/ui_axil] \
#        [get_bd_addr_segs GP0*] -range 4K -offset 0x00000000
#    assign_bd_address -target_address_space [get_bd_addr_spaces /bridge_0/ui_axil] \
#        [get_bd_addr_segs GP1*] -range 128M -offset 0x8000000
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {

}

