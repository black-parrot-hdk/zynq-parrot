
proc init { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]

    # Connect I/O ports
    if {[get_bd_intf_port -quiet usb_uart] == {}} {
        make_bd_pins_external -name "sys_clock" [get_bd_pins ${cellpath}/sys_clock]
        make_bd_pins_external -name "sys_resetn" [get_bd_pins ${cellpath}/sys_resetn]
        make_bd_intf_pins_external -name "ddr3_sdram" [get_bd_intf_pins ${cellpath}/ddr3_sdram]
        make_bd_intf_pins_external -name "usb_uart" [get_bd_intf_pins ${cellpath}/usb_uart]
    }
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
    set gp0_data_width [lindex [lindex ${args} 0] 2]
    set gp0_addr_width [lindex [lindex ${args} 0] 3]
    set gp1_data_width [lindex [lindex ${args} 0] 4]
    set gp1_addr_width [lindex [lindex ${args} 0] 5]
    set hp0_data_width [lindex [lindex ${args} 0] 6]
    set hp0_addr_width [lindex [lindex ${args} 0] 7]

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

    lappend file_list "${BASEJUMP_STL_DIR}/bsg_axi/bsg_axi_pkg.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_serial_in_parallel_out.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_reset_en.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_round_robin_n_to_1.sv"
    lappend file_list "${BP_SUB_DIR}/axi/v/bsg_axil_fifo_master.sv"
    lappend file_list "${BP_SUB_DIR}/zynq/v/bsg_axil_uart_bridge.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_circular_ptr.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_counter_clear_up.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_en.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_reset.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_misc/bsg_mux.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_mem_1r1w_synth.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_mem/bsg_mem_1r1w.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_one_fifo.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_parallel_in_serial_out.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_round_robin_1_to_n.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_serial_in_parallel_out_full.sv"
    lappend file_list "${BASEJUMP_STL_DIR}/bsg_dataflow/bsg_two_fifo.sv"

    add_files -norecurse ${file_list}
    set_property file_type SystemVerilog [get_files ${file_list}]
    set_property include_dirs ${dir_list} [get_fileset sources_1]
    add_files -norecurse "${BP_SUB_DIR}/zynq/v/uart_bridge_top.v"
    update_compile_order -fileset sources_1

	set vps_freq_mhz 250.0
	set SYS_CLOCK_HZ 100000000
	set uart_baud 921600

    create_bd_port -dir I -type clk -freq_hz $SYS_CLOCK_HZ sys_clock
    create_bd_port -dir I -type rst sys_resetn 
    create_bd_port -dir O -type rst aresetn
    create_bd_port -dir O -type clk aclk
    create_bd_port -dir O -type clk rt_clk

    create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0
    set_property CONFIG.C_BUF_TYPE {BUFG} [get_bd_cells util_ds_buf_0]
    connect_bd_net [get_bd_ports sys_clock] [get_bd_pins util_ds_buf_0/BUFG_I]

    set GP0_AXI [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 GP0_AXI]
    set_property -dict [list \
		CONFIG.PROTOCOL {AXI4LITE} \
		CONFIG.DATA_WIDTH ${gp0_data_width} \
		CONFIG.ADDR_WIDTH ${gp0_addr_width} \
	] $GP0_AXI

    set GP1_AXI [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 GP1_AXI]
    set_property -dict [list \
        CONFIG.PROTOCOL {AXI4LITE} \
        CONFIG.DATA_WIDTH ${gp1_data_width} \
        CONFIG.ADDR_WIDTH ${gp1_addr_width} \
    ] $GP1_AXI

    #set HP0_AXI [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 HP0_AXI]
    #set_property -dict [list \
    #    CONFIG.PROTOCOL {AXI4LITE} \
    #    CONFIG.DATA_WIDTH ${hp0_data_width} \
    #    CONFIG.ADDR_WIDTH ${hp0_addr_width} \
    #] $HP0_AXI

	set clk_wiz_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0]
	set_property -dict [list \
        CONFIG.RESET_BOARD_INTERFACE {reset} \
        CONFIG.RESET_PORT {resetn} \
        CONFIG.RESET_TYPE {ACTIVE_LOW} \
		CONFIG.CLKOUT1_USED {true} \
		CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $vps_freq_mhz \
		CONFIG.CLKOUT2_USED {true} \
		CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $aclk_freq_mhz \
		CONFIG.CLKOUT3_USED {true} \
		CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $rtclk_freq_mhz \
	] $clk_wiz_0
	connect_bd_net [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins clk_wiz_0/clk_in1]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out3] [get_bd_ports rt_clk]
	connect_bd_net [get_bd_pins clk_wiz_0/resetn] [get_bd_ports sys_resetn]

    set proc_sys_reset_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0]
	connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins clk_wiz_0/clk_out1]
	connect_bd_net [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_ports sys_resetn]

    set proc_sys_reset_1 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1]
	connect_bd_net [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_ports aresetn]
	connect_bd_net [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_ports sys_resetn]

    set bridge_0 [create_bd_cell -type module -reference uart_bridge_top bridge_0]
	connect_bd_net [get_bd_pins bridge_0/aclk] [get_bd_pins clk_wiz_0/clk_out1]
	connect_bd_net [get_bd_pins bridge_0/aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

    set axi_uartlite_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0]
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart
    connect_bd_intf_net [get_bd_intf_ports usb_uart] /axi_uartlite_0/UART
    connect_bd_intf_net [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins bridge_0/uart_axil]
    connect_bd_net [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins clk_wiz_0/clk_out1]
	set_property -dict [list \
	  CONFIG.USE_BOARD_FLOW {true} \
	  CONFIG.UARTLITE_BOARD_INTERFACE {usb_uart} \
	  CONFIG.C_BAUDRATE $uart_baud \
	  CONFIG.C_S_AXI_ACLK_FREQ_HZ_d $vps_freq_mhz \
	] $axi_uartlite_0
    connect_bd_net [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

    set axi_smc_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_0]
    set_property -dict [list \
        CONFIG.NUM_CLKS {2} \
        CONFIG.NUM_SI {1} \
        CONFIG.NUM_MI {2} \
    ] $axi_smc_0
    connect_bd_net [get_bd_pins axi_smc_0/aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins axi_smc_0/aresetn] [get_bd_ports aresetn]
    connect_bd_net [get_bd_pins axi_smc_0/aclk1] [get_bd_pins clk_wiz_0/clk_out1]
    connect_bd_intf_net [get_bd_intf_pins axi_smc_0/S00_AXI] [get_bd_intf_pins bridge_0/ui_axil]
    connect_bd_intf_net [get_bd_intf_pins axi_smc_0/M00_AXI] [get_bd_intf_ports GP0_AXI]
    connect_bd_intf_net [get_bd_intf_pins axi_smc_0/M01_AXI] [get_bd_intf_ports GP1_AXI]

    set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]

    create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0
    connect_bd_net [get_bd_pins system_ila_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
    connect_bd_net [get_bd_pins system_ila_0/resetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
    connect_bd_intf_net [get_bd_intf_pins system_ila_0/SLOT_0_AXI] [get_bd_intf_pins bridge_0/uart_axil]

    #set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI:HP0_AXI} [get_bd_ports aclk]
    #set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]

#    connect_bd_net [get_bd_pins bridge_0/aresetn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]

#
#    set proc_sys_reset_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0]
#    connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_ports "aclk"]
#    connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_ports "aresetn"]
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
#    connect_bd_net [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins clk_wiz_0/clk_in1]
#    connect_bd_net [get_bd_ports aclk] [get_bd_pins clk_wiz_0/clk_out2]
#    connect_bd_net [get_bd_ports rt_clk] [get_bd_pins clk_wiz_0/clk_out3]
#    connect_bd_net [get_bd_ports sys_resetn] [get_bd_pins clk_wiz_0/resetn]
#    connect_bd_net [get_bd_pins proc_sys_reset_0/dcm_locked] [get_bd_pins clk_wiz_0/locked]
#
#    set mig_7series_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0 ]
#    set ddr3_sdram [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr3_sdram ]
#    set_property -dict [list \
#        CONFIG.BOARD_MIG_PARAM {ddr3_sdram} \
#        CONFIG.XML_INPUT_FILE $::env(COSIM_XDC_DIR)/mig.artya7.prj \
#    ] $mig_7series_0
#    connect_bd_intf_net -intf_net mig_7series_0_DDR3 [get_bd_intf_ports ddr3_sdram] [get_bd_intf_pins mig_7series_0/DDR3]
#    connect_bd_net [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins mig_7series_0/sys_clk_i]
#    connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins mig_7series_0/clk_ref_i]
#    connect_bd_net [get_bd_ports sys_resetn] [get_bd_pins mig_7series_0/sys_rst]
#    connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins proc_sys_reset_0/ext_reset_in]
#
#    set proc_sys_reset_1 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1]
#    connect_bd_net [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins mig_7series_0/ui_clk]
#    connect_bd_net [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins mig_7series_0/ui_clk_sync_rst]
#    connect_bd_net [get_bd_pins mig_7series_0/mmcm_locked] [get_bd_pins proc_sys_reset_1/dcm_locked]
#    connect_bd_net [get_bd_pins mig_7series_0/aresetn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
#
#    set axi_uartlite_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0]
#    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 usb_uart
#    set_property -dict [list \
#      CONFIG.USE_BOARD_FLOW {true} \
#      CONFIG.UARTLITE_BOARD_INTERFACE {usb_uart} \
#      CONFIG.C_BAUDRATE {9600} \
#    ] $axi_uartlite_0
#    connect_bd_intf_net [get_bd_intf_ports usb_uart] /axi_uartlite_0/UART
#    connect_bd_net [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
# 
#    set smartconnect_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
#    set_property -dict [list \
#      CONFIG.NUM_CLKS {2} \
#      CONFIG.NUM_MI {2} \
#      CONFIG.NUM_SI {1} \
#      CONFIG.HAS_ARESETN {0} \
#    ] $smartconnect_0
#    set smartconnect_1 [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
#    set_property -dict [list \
#      CONFIG.NUM_CLKS {2} \
#      CONFIG.NUM_SI {1} \
#      CONFIG.HAS_ARESETN {0} \
#    ] $smartconnect_1
#    create_bd_cell -type module -reference uart_bridge_top bridge_0
#
#    connect_bd_net [get_bd_pins mig_7series_0/ui_clk] \
#        [get_bd_pins smartconnect_0/aclk] \
#        [get_bd_pins smartconnect_1/aclk1] \
#        [get_bd_pins bridge_0/aclk] \
#        [get_bd_pins axi_uartlite_0/s_axi_aclk]
#    connect_bd_net [get_bd_ports aclk] \
#        [get_bd_pins smartconnect_0/aclk1] \
#        [get_bd_pins smartconnect_1/aclk]
#
#    connect_bd_intf_net [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins mig_7series_0/S_AXI]
#    connect_bd_intf_net [get_bd_intf_pins bridge_0/uart_axil] [get_bd_intf_pins axi_uartlite_0/S_AXI]
#    connect_bd_intf_net [get_bd_intf_pins bridge_0/ui_axil] [get_bd_intf_pins smartconnect_0/S00_AXI]
#    connect_bd_net [get_bd_pins bridge_0/aresetn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
#
#    make_bd_intf_pins_external -name "GP0_AXI" [get_bd_intf_pins smartconnect_0/M00_AXI]
#    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP0_AXI]
#    set_property CONFIG.DATA_WIDTH ${gp0_data_width} [get_bd_intf_ports GP0_AXI]
#    set_property CONFIG.ADDR_WIDTH ${gp0_addr_width} [get_bd_intf_ports GP0_AXI]
#
#    make_bd_intf_pins_external -name "GP1_AXI" [get_bd_intf_pins smartconnect_0/M01_AXI]
#    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP1_AXI]
#    set_property CONFIG.DATA_WIDTH ${gp1_data_width} [get_bd_intf_ports GP1_AXI]
#    set_property CONFIG.ADDR_WIDTH ${gp1_addr_width} [get_bd_intf_ports GP1_AXI]
#
#    make_bd_intf_pins_external -name "HP0_AXI" [get_bd_intf_pins smartconnect_1/S00_AXI]
#    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports HP0_AXI]
#    set_property CONFIG.DATA_WIDTH ${hp0_data_width} [get_bd_intf_ports HP0_AXI]
#    set_property CONFIG.ADDR_WIDTH ${hp0_addr_width} [get_bd_intf_ports HP0_AXI]
#    set_property CONFIG.ID_WIDTH 6 [get_bd_intf_ports HP0_AXI]
#
#    set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI:HP0_AXI} [get_bd_ports aclk]
#    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
}

# ZynqParrot hook for customization of BD
proc vivado_ipx_customize { args } {
    set core [ipx::current_core]

    set gp0_name GP0_ENABLE
    set gp0_intf [ipx::get_bus_interfaces GP0_AXI -of_objects $core]
    set gp0_param [ipx::add_user_parameter $gp0_name $core]
    set_property -dict [list \
        value_resolve_type {user} \
        value_format {bool} \
        value {false} \
    ] $gp0_param
    set gp0_gui [ipgui::add_param -name $gp0_name -component $core]
    set_property -dict [list \
        display_name $gp0_name \
        widget {checkBox} \
    ] $gp0_gui
    set_property enablement_dependency {$GP0_ENABLE == 1} $gp0_intf

    set gp1_name GP1_ENABLE
    set gp1_intf [ipx::get_bus_interfaces GP1_AXI -of_objects $core]
    set gp1_param [ipx::add_user_parameter $gp1_name $core]
    set_property -dict [list \
        value_resolve_type {user} \
        value_format {bool} \
        value {false} \
    ] $gp1_param
    set gp1_gui [ipgui::add_param -name $gp1_name -component $core]
    set_property -dict [list \
        display_name $gp1_name \
        widget {checkBox} \
    ] $gp1_gui
    set_property enablement_dependency {$GP1_ENABLE == 1} $gp1_intf

    #set hp0_name HP0_ENABLE
    #set hp0_intf [ipx::get_bus_interfaces HP0_AXI -of_objects $core]
    #set hp0_param [ipx::add_user_parameter $hp0_name $core]
    #set_property -dict [list \
    #    value_resolve_type {user} \
    #    value_format {bool} \
    #    value {false} \
    #] $hp0_param
    #set hp0_gui [ipgui::add_param -name $hp0_name -component $core]
    #set_property -dict [list \
    #    display_name $hp0_name \
    #    widget {checkBox} \
    #] $hp0_gui
    #set_property enablement_dependency {$HP0_ENABLE == 1} $hp0_intf

    set rtclk_name RTCLK_ENABLE
    set rtclk_intf [ipx::get_ports rt_clk -of_objects $core]
    set rtclk_param [ipx::add_user_parameter $rtclk_name $core]
    set_property -dict [list \
        value_resolve_type {user} \
        value_format {bool} \
        value {false} \
    ] $rtclk_param
    set rtclk_gui [ipgui::add_param -name $rtclk_name -component $core]
    set_property -dict [list \
        display_name ${rtclk_name} \
        widget {checkBox} \
    ] $rtclk_gui
    set_property enablement_dependency {$RTCLK_ENABLE == 1} $rtclk_intf
}

