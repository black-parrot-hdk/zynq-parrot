Examples:

- **simple-example**: demonstrates how to use the Vivado GUI, Zynq board, etc. Useful to know for getting unstuck with the other directories. =)
- **shell-example**: basic example of the BSG Zynq Shell. Runs in verilator and FPGA.
- **double-shell-example**: two shells that talk to each other, demonstrating both ports on the Zynq chip. Runs in verilator and FPGA.
- **blackparrot-example**: working example of BlackParrot. Runs in Verilator and FPGA.
- **dram-example**: tests the software running on ARM that allocates DRAM space out of the ARM Linux available memory for the PL

*For this repo to work, make sure to git submodule update --init the following directories*

- import/black-parrot
- import/black-parrot-sdk
- import/black-parrot/external/basejump\_stl
- import/black-parrot/external/HardFloat

See (this document)[https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.souq55b38m0y] for an introduction to using Zynq and Vivado. We highly suggest that you use the ethernet connection to the board.

All of the FPGA versions here build automatically from script (except simple-example), and do not require any other repos except the submodules above.

See (this document)[https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit] for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.
