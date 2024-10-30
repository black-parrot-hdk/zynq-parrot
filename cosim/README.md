
# Guides
** Note: These guides are written for old versions of ZynqParrot. Please raise issues with updates! **
See [Tynqer with PYNQ](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.souq55b38m0y) for an introduction to using Zynq and Vivado. We highly suggest that you use the ethernet connection to the board.

See [The ZynqParrot Co-simulation Development Flow](https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit) for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

All of the FPGA versions here build automatically from script (except simple-example), and do not require any other repos except the submodules above.

# Example Designs

Design have a standard structure designed to click into the ZynqParrot build system. To add a new design, copy shell-example and modify.

## Collateral

- README.md: Description of the design
- Makefile.design: Design-specific settings and configurations for all backends
- ps.cpp: Co-simulation code that runs on PS on FPGA or in simulation to control the accelerator
- flist.vcs: SystemVerilog files used to build the design
- v/: Source files for this specific design
- tcl/: TCL scripts used to synthesize the design

## Backends

Designs can run in hardware or co-simulation by entering the appropriate backend directory

** Note: Not all backends are supported for all targets and should error out with an explicit message. **

### Simulation Backends

- verilator: FOSS SystemVerilog simulator https://github.com/verilator/verilator
- vcs: Synopsys SystemVerilog simulator
- xcelium: Cadence SystemVerilog simulator
- bridge: Experimental UART bridge, not supported

### Hardware Backends

- zynq: Runs PS code on ARM PS of Zynq chips
- bridge: Runs PS code over UART channel (Experimental!!)

# Provided Examples

- **simple-example**: demonstrates how to use the Vivado GUI, Zynq board, etc. Useful to know for getting unstuck with the other directories. =)
- **shell-example**: basic example of the BSG Zynq Shell.
- **double-shell-example**: two shells that talk to each other, demonstrating both ports on the Zynq chip.
- **dram-example**: tests the software running on ARM that allocates DRAM space out of the ARM Linux available memory for the PL.
- **axi3-perf-example**: tests the speedup achieved by using AXI3 directly instead of converting to AXI4.
- **axis-perf-example**: Demonstration of AXIS interface for high performance PS communication.
- **blackparrot-minimal-example**: working example of BlackParrot using a non-blocking FIFO interface for I/O.
- **blackparrot-example**: working example of BlackParrot using blocking interfaces on I/O.
- **manycore-example**: example of a small manycore driven by the zynq shell
- **hammerblade-example**: example of a BlackParrot+Manycore system driven by the Zynq Shell

