This directory contains a simple example of cosimulation of a
host program (which would run in the Zynq PS system)
communicating with an AXI-lite accelerator that would run
in the FPGA logic (aka PL=programmable logic).

It employs verilator, and a simple AXI-Lite Read and Write API
that can be easily re-implemented to run on the actual PS system

- ps.cpp: portable host program, can run in cosim or on PL, controls accelerator

- cosim/include/verilator/bsg_zynq_pl.h: mostly design-independent cosim-implementation of bsg_zynq_pl API (another implementation has been created for PS)
  - Current API:
    -   void axil_write(int address, int data, int wstrb);
    -    int axil_read(int address);
    -    bool done(void);

- cosim/common/v/bsg_zynq_pl_shell.sv: BSG standardized shell for interfacing PS to PL

- top.v:  example accelerator to live in PL, suitable for Xilinx IPI integration
          (see this [class lab](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.4f0hegamev6v)
          for instructions on how to generate this); wrapper for Xilinx IPI block

- Makefile: you need to set a number of parameters, like the base address of your accelerator (from the IPI tool)

Tested with Verilator 4.202 2021-04-24 and GTKWave Analyzer v3.3.86
