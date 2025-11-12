#!/bin/bash
source $(dirname $0)/functions.sh

example=$1

syndir=$bsg_top/cosim/$example-example/vivado

bsg_run_task "Building the IP repo" make -C $syndir ip_package
bsg_sentinel_cont "  IP Catalog is up to date"
bsg_run_task "Generating the bitstream" make -C $syndir fpga_build
bsg_sentinel_cont " for timing report"
bsg_run_task "Packing the bitstream" make -C $syndir pack_bitstream

bsg_pass $(basename $0)

