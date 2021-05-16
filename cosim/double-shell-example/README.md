This directory shows a more full-featured example of the proposed [BSG](http://bsg.ai) methodology for accelerating BlackParrot (or other accelerators) simulation on FPGA.  The interface provides a configurable number of read/write user CSRs, FIFOs for going from PS to PL (out) and from PL to PS (in). Each FIFO has a corresponding read-only CSR that tells you how many elements are available to read (in) or how many free slots are available to write (out).

There is a unified interface for a control program (implemented as "host code") to interact with the hardware device; which has both Verilator and Zynq PS (== ARM core) support:

- void axil_write(int address, int data, int wstrb);
- int axil_read(int address);
- bool done(void);
- void *allocate_dram(uint32_t len_in_bytes, unsigned long *physical_ptr);
- void free_dram(void *virtual_ptr);

If you restrict your interaction with the core to this interface, then you can debug your design in simulation, using waveforms, etc, and when it works, and easily move it to FPGA for speed. If you still have an issue with the FPGA, you can look at the waveforms in simulation to see what things should look like using the FPGA ILA (integrated logic analyzer.)

Directories:

- ps.cpp: user-written host code that interacts with accelerator device, both on FPGA and verilator cosimulation. 
  - interacts with both using the standard API described above.
- verilator: for simulating, uses the same AXI-lite verilog code as you use for the FPGA. Use this to debug and view waveforms with GTKWave before you run on FPGA and can't see what's going on easily!
- fpga: for building the bitstream, running on the Zynq chip, using the ARM core (PS) talking to the PL (FPGA logic), which has the bit stream downloaded. Do this after you have simulated!
