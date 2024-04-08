
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl

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
    ${aclk_mhz}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

