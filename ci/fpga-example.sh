#!/bin/bash
examplepath=$(git rev-parse --show-toplevel)/cosim/$1-example/zynq

make -C $examplepath clean
make -C $examplepath unpack_bitstream
make -C $examplepath unpack_run
make -C $examplepath build
make -C $examplepath run

