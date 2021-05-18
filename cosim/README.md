Examples:

- shell_example -- basic example of the BSG Zynq Shell. Runs in verilator and FPGA.
- double_shell_example -- two shells that talk to each other, demonstrating both ports on the Zynq chip. Runs in verilator and FPGA.
- black_parrot_example -- not-yet-totally working example of BlackParrot. Partially runs in Verilator and FPGA.

For this repo to work, make sure to submodule init/update:

- imports/basejump_stl
- imports/black_parrot
- imports/black_parrot/external/basejump_stl
- imports/black_parrot/external/HardFloat

See (this document)[https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.souq55b38m0y] for an introduction to using Zynq and Vivado.

All of the FPGA versions here build automatically from script, and do not require any other repos excpet the submodules above.
