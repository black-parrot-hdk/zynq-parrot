This directory contains a simple example of cosimulation of a
host program (which would run in the Zynq PS system)
communicating with an AXI-lite accelerator that would run 
in the FPGA logic (aka PL=programmable logic).

It employs verilator, and a simple AXI-Lite Read and Write API
that can be easily re-implemented to run on the actual PS system

- ps.cpp: portable host program, can run in cosim or on PL, controls accelerator

- bp_zynq_pl.h: mostly design-independent cosim-implementation of bp_zynq_pl API (another implementation will be created for PS)
  - Current API: 
    -   void axil_write(int address, int data, int wstrb);
    -    int axil_read(int address);
    -    bool done(void);

- example_axi_v1_0_S00_AXI.v: example accelerator to live in PL, suitable for Xilinx IPI integration (see this [class lab](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.4f0hegamev6v) for instructions on how to generate this): 

- top.v:  wrapper for Xilinx IPI block

- Makefile: you need to set a number of parameters, like the base address of your accelerator (from the IPI tool)

Tested with Verilator 4.202 2021-04-24 and GTKWave Analyzer v3.3.86 
