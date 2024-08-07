
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl
source $::env(COSIM_TCL_DIR)/bsg-utils.tcl

set ip_name      $::env(BASENAME)
set ip_script    vivado-create-block.tcl
set proj_name    ${ip_name}_bd_proj
set proj_bd      ${ip_name}_bd_1
set part         $::env(PART)
set boardname    $::env(BOARDNAME)
set xdc_dir      $::env(COSIM_XDC_DIR)

set do_elab    $::env(ELAB)
set do_synth   $::env(SYNTH)
set do_impl    $::env(IMPL)
set do_handoff $::env(HANDOFF)
set threads    $::env(THREADS)

vivado_create_ip_proj ${proj_name} ${proj_bd} ${ip_name} ${part} ${ip_script}

vivado_elab_wrap ${do_elab} ${proj_bd}
vivado_read_xdc ${xdc_dir} ${boardname}

vivado_synth_wrap ${do_synth} ${threads}
vivado_constrain_ip ${ip_name}

vivado_impl_wrap ${do_impl} ${threads}
vivado_save_handoff ${do_handoff} ${proj_name} ${proj_bd}

