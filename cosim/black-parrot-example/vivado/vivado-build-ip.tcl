
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

set boardname   $::env(BOARDNAME)
set ip_script   $::env(CURR_TCL_DIR)/bd.tcl
set ip_name     top
set proj_name   ${ip_name}_ip_proj
set proj_bd     ${ip_name}_bd_1
set part        $::env(PART)
set flist       "flist.vcs"
set aclk_mhz    $::env(ACLK_MHZ)
set rtclk_mhz   $::env(RTCLK_MHZ)
vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script} \
    ${flist} \
    ${aclk_mhz} \
    ${rtclk_mhz}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

set boardname   $::env(BOARDNAME)
set ip_script   $::env(COSIM_TCL_DIR)/bd/vps_zynq_bd.${boardname}.tcl
set ip_name     vps
set proj_name   ${ip_name}_ip_proj
set proj_bd     ${ip_name}_bd_1
set part        $::env(PART)

set aclk_mhz       [vivado_env_default ACLK_MHZ 50]
set rtclk_mhz      [vivado_env_default RTCLK_MHZ 8]
set gp0_enable     [vivado_env_default GP0_ENABLE 0]
set gp0_data_width [vivado_env_default GP0_DATA_WIDTH 32]
set gp0_addr_width [vivado_env_default GP0_ADDR_WIDTH 32]
set gp1_enable     [vivado_env_default GP1_ENABLE 0]
set gp1_data_width [vivado_env_default GP1_DATA_WIDTH 32]
set gp1_addr_width [vivado_env_default GP1_ADDR_WIDTH 32]
set hp0_enable     [vivado_env_default HP0_ENABLE 0]
set hp0_data_width [vivado_env_default HP0_DATA_WIDTH 32]
set hp0_addr_width [vivado_env_default HP0_ADDR_WIDTH 32]

vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script} \
    ${aclk_mhz} \
    ${rtclk_mhz} \
    ${gp0_enable} \
    ${gp0_data_width} \
    ${gp0_addr_width} \
    ${gp1_enable} \
    ${gp1_data_width} \
    ${gp1_addr_width} \
    ${hp0_enable} \
    ${hp0_data_width} \
    ${hp0_addr_width}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

set boardname   $::env(BOARDNAME)
set ip_script   $::env(COSIM_TCL_DIR)/bd/axi_bram_bd.tcl
set ip_name     bram
set proj_name   ${ip_name}_ip_proj
set proj_bd     ${ip_name}_bd_1
set part        $::env(PART)
vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script} \
    ${aclk_mhz}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

set boardname   $::env(BOARDNAME)
set ip_script   $::env(COSIM_TCL_DIR)/bd/axi_watchdog_bd.tcl
set ip_name     watchdog
set proj_name   ${ip_name}_ip_proj
set proj_bd     ${ip_name}_bd_1
set part        $::env(PART)
vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script} \
    ${aclk_mhz}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

set boardname   $::env(BOARDNAME)
set ip_script   $::env(COSIM_TCL_DIR)/bd/axi_debug_bd.tcl
set ip_name     debug
set proj_name   ${ip_name}_ip_proj
set proj_bd     ${ip_name}_bd_1
set part        $::env(PART)
vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script} \
    ${aclk_mhz}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

