
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl

set ip_name           $::env(BASENAME)
set top_name          $::env(TOP_MODULE)
set part              $::env(PART)
set blackparrot_flist "flist.vcs"

vivado_create_and_package_ip $ip_name $top_name $part $blackparrot_flist

