Checkout these examples in this directory:

- **simple-example**: demonstrates how to use the Vivado GUI, Zynq board, etc. Useful to know for getting unstuck with the other directories. =)
- **shell-example**: basic example of the BSG Zynq Shell.
- **double-shell-example**: two shells that talk to each other, demonstrating both ports on the Zynq chip.
- **dram-example**: tests the software running on ARM that allocates DRAM space out of the ARM Linux available memory for the PL.
- **axi3-perf-example**: tests the speedup achieved by using AXI3 directly instead of converting to AXI4.
- **blackparrot-minimal-example**: working example of BlackParrot using a non-blocking FIFO interface for I/O.
- **blackparrot-example**: working example of BlackParrot using blocking interfaces on I/O.
- **manycore-example**: example of a small manycore driven by the zynq shell
- **hammerblade-example**: example of a BlackParrot+Manycore system driven by the Zynq Shell
- **bridge-example**: an EXPERIMENTAL example of tunneling GP0 accesses through a UART (for non-Zynq FPGA)

See [Tynqer with PYNQ](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.souq55b38m0y) for an introduction to using Zynq and Vivado. We highly suggest that you use the ethernet connection to the board.

All of the FPGA versions here build automatically from script (except simple-example), and do not require any other repos except the submodules above.

See [The ZynqParrot Co-simulation Development Flow](https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit) for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

To install Verilator, see [Installation -- Verilator](https://verilator.org/guide/latest/install.html).

To have a more accurate VCS waveform dump, change the VCS option '-debug_pp' to '-debug_all' in mk/Makefile.vcs. Otherwise use '-debug_pp' to have faster simulation.
