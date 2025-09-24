#!/bin/bash
source $(dirname $0)/functions.sh

tool=$1
example=$2

simdir=$bsg_top/cosim/$example-example/$tool

bsg_run_task "Building the simulation model" make -C $simdir build
bsg_run_task "Running the simulation model" make -C $simdir run

bsg_sentinel_cont "bsg_zynq_pl: done() called, exiting"
bsg_pass $(basename $0)

