
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl

set part              $::env(PART)
set watchdog_flist    "flist.watchdog.vcs"
set blackparrot_flist "flist.blackparrot.vcs"

vivado_create_and_package_ip watchdog watchdog $part $watchdog_flist
vivado_create_and_package_ip blackparrot top $part $blackparrot_flist
