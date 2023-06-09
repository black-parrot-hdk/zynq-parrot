
source $::env(COSIM_TCL_DIR)/vivado-utils.tcl

set part              $::env(PART)
set manycore_flist    "flist.vcs"

vivado_create_and_package_ip hammerblade top $part $manycore_flist
