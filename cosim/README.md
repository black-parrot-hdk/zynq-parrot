Examples:

- shell-example -- basic example of the BSG Zynq Shell. Runs in verilator and FPGA.
- double-shell-example -- two shells that talk to each other, demonstrating both ports on the Zynq chip. Runs in verilator and FPGA.
- blackparrot-example -- appears to be working example of BlackParrot. Runs in Verilator and FPGA.

For this repo to work, make sure to submodule init/update:

- imports/basejump\_stl
- imports/black-parrot
- imports/black-parrot/external/basejump\_stl
- imports/black-parrot/external/HardFloat

See (this document)[https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.souq55b38m0y] for an introduction to using Zynq and Vivado.

All of the FPGA versions here build automatically from script, and do not require any other repos excpet the submodules above.
