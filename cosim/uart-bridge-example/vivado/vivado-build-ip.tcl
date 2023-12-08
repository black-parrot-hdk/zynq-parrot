
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl

set part                $::env(PART)
set flist               "flist.vcs"

vivado_create_and_package_ip top top $part $flist

