# Overview

zynq-parrot enables rapid design iteration of Accelerators (including the BlackParrot RISC-V processor) on Zynq FPGAs.

See [The ZynqParrot Co-simulation Development Flow](https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit) for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

**See [cosim](https://github.com/black-parrot-hdk/zynq-parrot/tree/master/cosim) directory for  instructions.**

# Suggested projects for contributors to the BlackParrot example:

- We would like to support OpenOCD to our Zynq Shell. 
- One route:
  - We could use an open-source standin for the Xilinx AXI-to-JTAG debug bridge
  - We could then OpenOCD over AXI on Zynq: https://review.openocd.org/c/openocd/+/6594
- Another route (probably better):
  - Use https://github.com/chipsalliance/rocket-chip/blob/master/src/main/resources/csrc/remote_bitbang.cc
  - Rewrite remote_bitbang_t::execute_command() to just use memory mapped addresses for Zynq.
  - Hookup the corresponding memory mapped signals to zynq.
