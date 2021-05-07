This directory contains a simple example of cosimulation of a
a host program (which would run in the Zynq PS system)
communicating with an AXI-lite block that would run 
in the FPGA logic (aka PL=programmable logic).

It employs verilator, and a simple AXI-Lite Read and Write API
that can be easily re-implemented to run on the actual PS system

- ps.cpp: portable host program, can run in cosim or on PL, controls accelerator

- bp_zynq_pl.h: mostly design-independent cosim-implementation of bp_zynq_pl API (another implementation will be created for PS)

- example_axi_v1_0_S00_AXI.v: example accelerator to live in PL, suitable for Xilinx IPI integration

- top.v:  wrapper for Xilinx IPI block



