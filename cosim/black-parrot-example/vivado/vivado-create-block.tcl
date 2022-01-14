source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

proc bsg_clint_constraints { top_inst clint_inst cdc_delay } {
  puts "constraining clint_inst: $clint_inst"

  create_generated_clock -name ${clint_inst}_ds_by_16_clk -source [get_pins $top_inst/ds_clk] -divide_by 16 [get_pins $clint_inst/ds/clk_r_o_reg/Q]

  # In BP, there is a 4-1 clock multiplexer that selects between 3 clocks and 1'b0 as the mtime clock.
  # (The 4-1 clock mux)
  #
  #
  #        |\
  #    +---| \ (rtc_mux1)
  #        | |-+
  #    +---| / |  |\
  #        |/  +--| \ (rtc_mux3)
  #               | |---+
  #        |\  +--| /
  #    +---| \ |  |/
  #        | |-+
  #    +---| / (rtc_mux2)
  #        |/
  #
  # 'join' converts a list into a string
  set rtc_mux1 [join [get_cells -hier *BUFGMUX_CTRL_m_3_2]]
  set rtc_mux2 [join [get_cells -hier *BUFGMUX_CTRL_m_1_0]]
  set rtc_mux3 [join [get_cells -hier *BUFGMUX_CTRL_m]]

  set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of [get_pins $rtc_mux1/O]]
  set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of [get_pins $rtc_mux2/O]]
  set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of [get_pins $rtc_mux3/O]]

  set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[0]]
  set_case_analysis 0 [get_pins $clint_inst/rtc_mux/sel_i[1]]

  # max delay for the bufgmux_ctrl primitives
  set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*] $cdc_delay
  set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*] $cdc_delay
  set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*] $cdc_delay

  set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*]
  set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*]
  set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*]
}

proc vivado_create_ip { args } {
    set vdefines [lindex [lindex ${args} 0] 0]
    set_property verilog_define ${vdefines} [current_fileset]

    create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
    create_bd_cell -type ip -vlnv user.org:user:vps:1.0 vps_0
    create_bd_cell -type ip -vlnv user.org:user:bram:1.0 bram_0
    create_bd_cell -type ip -vlnv user.org:user:watchdog:1.0 watchdog_0

    connect_bd_net [get_bd_pins vps_0/aclk] [get_bd_pins top_0/aclk]
    connect_bd_net [get_bd_pins vps_0/aresetn] [get_bd_pins top_0/aresetn]
    connect_bd_net [get_bd_pins vps_0/ds_clk] [get_bd_pins top_0/ds_clk]
    connect_bd_net [get_bd_pins vps_0/rt_clk] [get_bd_pins top_0/rt_clk]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP0_AXI] [get_bd_intf_pins top_0/s00_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/GP1_AXI] [get_bd_intf_pins top_0/s01_axi]
    connect_bd_intf_net [get_bd_intf_pins vps_0/HP0_AXI] [get_bd_intf_pins top_0/m00_axi]

    connect_bd_net [get_bd_pins top_0/tag_ck] [get_bd_pins watchdog_0/tag_clk]
    connect_bd_net [get_bd_pins top_0/tag_data] [get_bd_pins watchdog_0/tag_data]

    connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins watchdog_0/aclk]
    connect_bd_net [get_bd_pins top_0/aclk] [get_bd_pins bram_0/aclk]
    connect_bd_net [get_bd_pins top_0/sys_resetn] [get_bd_pins watchdog_0/aresetn]
    connect_bd_net [get_bd_pins top_0/sys_resetn] [get_bd_pins bram_0/aresetn]
    connect_bd_intf_net [get_bd_intf_pins top_0/m01_axi] [get_bd_intf_pins bram_0/S_AXI]
    connect_bd_intf_net [get_bd_intf_pins top_0/s02_axi] [get_bd_intf_pins watchdog_0/M_AXI]

    assign_bd_address
}

proc vivado_constrain_ip { args } {
    set aclk [get_clocks -of_objects [get_pins blackparrot_bd_1_i/vps_0/aclk]]
    set ds_clk [get_clocks -of_objects [get_pins blackparrot_bd_1_i/vps_0/ds_clk]]
    set rt_clk [get_clocks -of_objects [get_pins blackparrot_bd_1_i/vps_0/rt_clk]]

    set top_inst [get_cells -hier top_fpga_inst]
    create_generated_clock -name bp_clk -source [get_pins -of_objects ${ds_clk}] -divide_by 1 [get_nets ${top_inst}/bp_clk]

    set_clock_groups -logically_exclusive -group ${aclk} -group ${ds_clk} -group ${rt_clk}

    set clk_periods [get_property PERIOD [list ${aclk} ${ds_clk} ${rt_clk}]]

    set global_min_period [lindex ${clk_periods} 0]
    foreach p ${clk_periods} {
        if {${p} < ${global_min_period}} {
            set global_min_period ${p}
        }
    }

    set all_clint [get_cells -quiet -hier -filter {(ORIG_REF_NAME == bp_me_clint_slice || REF_NAME == bp_me_clint_slice)}]
    foreach clint ${all_clint} {
      bsg_clint_constraints ${top_inst} ${clint} ${global_min_period}
    }

    constrain_sync ${global_min_period}
}

