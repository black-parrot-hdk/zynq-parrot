
# ZynqParrot Examples

Examples have a standard structure designed to click into the ZynqParrot build system.
They are provided to demonstrate various ZynqParrot features such as AXI-lite connections or DRAM.

To add a new design, copy shell-example and modify it for your IP.

## Collateral

- Makefile.design: Design-specific settings and configurations for all backends.
- Makefile.hardware: Design-specific verilog files for compiling the design.
- ps.cpp: Co-simulation code that runs on PS on FPGA or in simulation to control the accelerator.
- ps.hpp: PL/PS register map definitions.
- v/: Source files for this specific example.
- tcl/: TCL scripts used to synthesize the example.
- xdc/: XDC constraints used to synthesize the example.

## Backends

Examples can run in hardware or co-simulation by entering the appropriate backend directory.

"make help" displays targets for a given backend and "make clean" removes temporary build files.

- verilator / vcs
  - build: Creates an simulation executable.
  - run: Runs the simulation executable (TRACE=1 to trace).
  - view: Opens the simulation waveform with GTKWave or DVE.
- vivado
  - ip\_package: Packages the IP before synthesis.
  - fpga\_build: Creates an FPGA bitstream.
  - pack\_bitstream: Packs the build outputs to a single file.
  - open: Opens the toplevel block diagram of the project.
  - open\_ip.%: Opens the block diagram for a specific IP project.
- zynq
  - unpack\_bitstream: Unpacks the bitstream on target.
  - load\_bitstream: Loads the bitstream to the target using pynq API.
  - build: Builds the control program for the co-emulation.
  - run: Runs the control program on the PS.

** Note: Not all backends are supported for all targets. **

## Provided Examples

### Simple Example

Demonstrates how to use the Vivado GUI, Zynq board, etc.
Useful to know for getting unstuck with the other directories. =)

### Shell Example

Shows how to use the basic P-Shell.

### Double Shell Example

Shows two P-Shells that talk to each other, demonstrating both ports on the Zynq chip.

### DRAM Example

Shows software running on ARM that allocates DRAM space out of the Zynq PS and communicates with the Zynq PL.

### AXIS Example

Shows an AXI-Stream interface for high performance PS communication.

### BlackParrot Minimal Example

Shows control of an instantiated BlackParrot core driven by the P-Shell interface.

### BlackParrot Full Example

Shows control of an instantiated BlackParrot core using direct MMIO.

### Manycore Example

Shows control of an instantiated manycore driven by the P-Shell interface.

### HammerBlade Example

Shows control of an instantiated BlackParrot+Manycore driven by the P-Shell interface.

