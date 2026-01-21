
set boardname   $::env(BOARDNAME)
set ip_script   $::env(DESIGN_TCL_DIR)/bd.tcl
set ip_name     top
set proj_name   ${ip_name}_ip_proj
set proj_bd     ${ip_name}_bd_1
set part        $::env(PART)
set vpackages   $::env(VPACKAGES)
set vsources    $::env(VSOURCES)
set vincludes   $::env(VINCLUDES)
vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script} \
   ${vpackages} \
   ${vsources} \
   ${vincludes}
vivado_package_ip ${proj_bd} ${ip_name} ${ip_script}
vivado_customize_ip ${proj_bd} ${ip_name} ${ip_script}

