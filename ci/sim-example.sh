#!/bin/bash
source $(dirname $0)/functions.sh

tool=$1
example=$2

simdir=$bsg_top/cosim/$example-example/$tool

make -C $simdir run

