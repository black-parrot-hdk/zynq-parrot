
proc init { cellpath otherInfo } {
    set cell_handle [get_bd_cells ${cellpath}]
}

# https://support.xilinx.com/s/question/0D52E00006lLgeLSAS/how-to-make-cs00axiaddrwidth-dependent-on-address-editor?language=en_US
proc post_propagate { cellpath otherInfo } {
    # standard parameter propagation here
}

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

    create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
    set_property -dict [ list \
      CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
      CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
      CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
      CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
    ] [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [ list \
      CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__DP__REF_CLK_SEL {Ref Clk3} \
      CONFIG.PSU__DP__LANE_SEL {Dual Lower} \
      CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {DPLL} \
      CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
      CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {DPLL} \
      CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {DPLL} \
    ] [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [ list \
      CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} \
      CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {200} \
      CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__SRCSEL {RPLL} \
      CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
      CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
      CONFIG.PSU__SD0__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__SD0__SLOT_TYPE {eMMC} \
      CONFIG.PSU__SD0__PERIPHERAL__IO {MIO 13 .. 22} \
      CONFIG.PSU__SD0__DATA_TRANSFER_MODE {8Bit} \
      CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__SD1__SLOT_TYPE {SD 2.0} \
      CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 46 .. 51} \
      CONFIG.PSU__SD1__GRP_CD__ENABLE {1} \
      CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 10 .. 11} \
      CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 38 .. 39} \
      CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__ENET0__GRP_MDIO__ENABLE {1} \
      CONFIG.PSU__ENET0__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {0} \
      CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__USB__RESET__MODE {Disable} \
      CONFIG.PSU__USB0__REF_CLK_SEL {Ref Clk2} \
      CONFIG.PSU__USB0__REF_CLK_FREQ {100} \
      CONFIG.PSU__FPGA_PL0_ENABLE {1} \
      CONFIG.PSU__FPGA_PL1_ENABLE {1} \
      CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
      CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
      CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {50} \
      CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {IOPLL} \
      CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE {1} \
      CONFIG.PSU_MIO_7_PULLUPDOWN {disable} \
      CONFIG.PSU_MIO_12_PULLUPDOWN {disable} \
      CONFIG.PSU_MIO_23_PULLUPDOWN {disable} \
    ] [get_bd_cells zynq_ultra_ps_e_0]

    set_property -dict [ list \
      CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400T} \
      CONFIG.PSU__DDRC__CWL {12} \
      CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
      CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
      CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
      CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
      CONFIG.PSU__DDRC__ECC {Enabled} \
      CONFIG.PSU__DDRC__PARITY_ENABLE {1} \
      CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
    ] [get_bd_cells zynq_ultra_ps_e_0]

    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1}] [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {1}] [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 {0}] [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__S_AXI_GP3 {1}] [get_bd_cells zynq_ultra_ps_e_0]

    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_1
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_2

    set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {1} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
    set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {1} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_1]
    set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {1} CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_2]

    create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0

    set_property CONFIG.CLKOUT2_USED true [get_bd_cells clk_wiz_0]
    set_property CONFIG.USE_LOCKED false [get_bd_cells clk_wiz_0]
    set_property CONFIG.USE_RESET false [get_bd_cells clk_wiz_0]
    set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ ${aclk_freq_mhz} [get_bd_cells clk_wiz_0]
    set_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ ${rtclk_freq_mhz} [get_bd_cells clk_wiz_0]

    create_bd_port -dir O -type clk aclk
    create_bd_port -dir O -type clk rt_clk
    create_bd_port -dir O -type rst aresetn
    connect_bd_net [get_bd_port aclk] [get_bd_pins clk_wiz_0/clk_out1]
    connect_bd_net [get_bd_port rt_clk] [get_bd_pins clk_wiz_0/clk_out2]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

    make_bd_intf_pins_external -name "GP0_AXI" [get_bd_intf_pins smartconnect_0/M00_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP0_AXI]
    set_property CONFIG.DATA_WIDTH ${gp0_data_width} [get_bd_intf_ports GP0_AXI]
    set_property CONFIG.ADDR_WIDTH ${gp0_addr_width} [get_bd_intf_ports GP0_AXI]

    make_bd_intf_pins_external -name "GP1_AXI" [get_bd_intf_pins smartconnect_1/M00_AXI]
    set_property CONFIG.PROTOCOL {AXI4LITE} [get_bd_intf_ports GP1_AXI]
    set_property CONFIG.DATA_WIDTH ${gp1_data_width} [get_bd_intf_ports GP1_AXI]
    set_property CONFIG.ADDR_WIDTH ${gp1_addr_width} [get_bd_intf_ports GP1_AXI]

    make_bd_intf_pins_external -name "HP0_AXI" [get_bd_intf_pins smartconnect_2/S00_AXI]
    set_property CONFIG.PROTOCOL {AXI4} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.DATA_WIDTH ${hp0_data_width} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.ADDR_WIDTH ${hp0_addr_width} [get_bd_intf_ports HP0_AXI]
    set_property CONFIG.ID_WIDTH 6 [get_bd_intf_ports HP0_AXI]

    set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]
    set_property CONFIG.ASSOCIATED_BUSIF {GP0_AXI:GP1_AXI:HP0_AXI} [get_bd_ports aclk]

    connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_0/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD] [get_bd_intf_pins smartconnect_1/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD] [get_bd_intf_pins smartconnect_2/M00_AXI]

    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk] [get_bd_ports aclk]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins clk_wiz_0/clk_in1]
    connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins proc_sys_reset_0/ext_reset_in]

    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_0/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_1/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins smartconnect_2/aclk]
    connect_bd_net [get_bd_port aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_0/aresetn]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_1/aresetn]
    connect_bd_net [get_bd_port aresetn] [get_bd_pins smartconnect_2/aresetn]

    set DP_AUX_OUT [ create_bd_port -dir O DP_AUX_OUT]
    connect_bd_net [get_bd_ports DP_AUX_OUT] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_out]
    set DP_AUX_OE [ create_bd_port -dir O DP_AUX_OE]
    connect_bd_net [get_bd_ports DP_AUX_OE] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_oe_n]
    set DP_AUX_IN [ create_bd_port -dir I DP_AUX_IN]
    connect_bd_net [get_bd_ports DP_AUX_IN] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_in]
    set DP_HPD [ create_bd_port -dir I DP_HPD]
    connect_bd_net [get_bd_ports DP_HPD] [get_bd_pins zynq_ultra_ps_e_0/dp_hot_plug_detect]
    set Clk100 [ create_bd_port -dir O -type clk Clk100]
    connect_bd_net [get_bd_ports Clk100] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
    set Clk50 [ create_bd_port -dir O -type clk Clk50]
    connect_bd_net [get_bd_ports Clk50] [get_bd_pins zynq_ultra_ps_e_0/pl_clk1]
    set Rst_N [ create_bd_port -dir O -type rst Rst_N]
    connect_bd_net [get_bd_ports Rst_N] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

    assign_bd_address -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] \
        [get_bd_addr_segs GP0*] -range 4K -offset 0x400000000
    assign_bd_address -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] \
        [get_bd_addr_segs GP1*] -range 1G -offset 0x500000000
	  assign_bd_address -target_address_space [get_bd_addr_spaces HP0_AXI] \
        [get_bd_addr_segs *HP1_DDR*]
	  exclude_bd_addr_seg [get_bd_addr_segs *HP1_LPS*] -target_address_space [get_bd_addr_spaces HP0_AXI]

    # Get rid of disabled ports, hope that synthesis is smart
	  # TODO: Conditional port enable
    if {${gp0_enable} == 0} {
        delete_bd_objs [get_bd_cells smartconnect_0]
        delete_bd_objs [get_bd_intf_ports GP0_AXI]
    }
    if {${gp1_enable} == 0} {
        delete_bd_objs [get_bd_cells smartconnect_1]
        delete_bd_objs [get_bd_intf_ports GP1_AXI]
    }
    if {${hp0_enable} == 0} {
        delete_bd_objs [get_bd_cells smartconnect_2]
        delete_bd_objs [get_bd_intf_ports HP0_AXI]
    }
}

proc vivado_ipx_customize { args } {

}

