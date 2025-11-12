# ZynqParrot Co-simulation / Co-emulation Environment

ZynqParrot enables rapid design iteration of Accelerators on Zynq FPGAs.
Additionally, it is considered a meta-repository of the BlackParrot processor [BlackParrot](https://www.github.com/black-parrot/black-parrot) and HammerBlade Manycore [HammerBlade](https://www.github.com/bespoke-silicon-group/bsg_manycore).

## Guides
** Note: These guides are written for old versions of ZynqParrot. Please raise issues with updates! **
See [Tynqer with PYNQ](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#heading=h.souq55b38m0y) for an introduction to using Zynq and Vivado. We highly suggest that you use the ethernet connection to the board.

See [The ZynqParrot Co-simulation Development Flow](https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit) for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

## Repository Overview

- **cosim/** contains a set of cosimulation examples of increasing complexity. These examples can be
  run on various simulators as well as Zynq-based FPGAs, which is ideal for prototyping accelerators.
- **software/** contains software infrastructure for generating tests used in cosimulation
  examples. For example, RISC-V compilers and programs for the BlackParrot RISC-V processor.
- **docker/** contains files needed for a Docker-based simulation environment

For most users, the following makefile targets will be the most useful:

    make prep_lite;     # minimal set of simulation preparation
    make prep;          # standard preparation
    make prep_bsg;      # additional preparation for BSG users

There are also common Makefile targets to maintain the repository:

    make checkout;       # checkout submodules. Should be done before building tools
    make help;           # prints information about documented targets
    make bleach_all;     # wipes the whole repo clean. Use with caution

And some lesser tested, maintenance operations

    make clean;          # cleans up submodule working directory
    make tidy;           # unpatches submodules
    make bleach;         # deinitializes submodules

## Getting Started

See the [cosim](https://github.com/black-parrot-hdk/zynq-parrot/tree/master/cosim) directory for a list of cosimulation examples.

See the [software](https://github.com/black-parrot-hdk/zynq-parrot/tree/master/software) directory to set up a development environment for ZynqParrot. This is intended for developers and not needed to run the examples themselves.

# Suggested projects for contributors:

- We would like to support OpenOCD to our Zynq Shell. 
    - One route:
        - We could use an open-source standin for the Xilinx AXI-to-JTAG debug bridge
        - We could then OpenOCD over AXI on Zynq: https://review.openocd.org/c/openocd/+/6594
    - Another route (probably better):
        - Use https://github.com/chipsalliance/rocket-chip/blob/master/src/main/resources/csrc/remote\_bitbang.cc
        - Rewrite remote\_bitbang\_t::execute\_command() to just use memory mapped addresses for Zynq.
        - Hookup the corresponding memory mapped signals to zynq.
  
