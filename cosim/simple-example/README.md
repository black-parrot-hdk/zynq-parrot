This directory contains a simple example of cosimulation of a
AXI-lite block in the FPGA logic (aka PL=programmable logic).
It employs verilator, and a simple AXI-Lite Read and Write API
that can be easily reproduced when running on the actual PS.


- ps.cpp: portable host code, can run in cosim or on PL

- bp_zynq_pl.h: cosim-implementation of bp_zynq_pl API
                another implementation will be created for PS 

- top.v:  wrapper for Xilinx IPI block

- example_axi_v1_0_S00_AXI: example accelerator to live in PL

