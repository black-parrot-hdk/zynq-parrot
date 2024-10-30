# Overview

ZynqParrot enables rapid design iteration of Accelerators (including the BlackParrot RISC-V processor) on Zynq FPGAs.

See [The ZynqParrot Co-simulation Development Flow](https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit) for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

# ZynqParrot Repository Overview
- **cosim/** contains a set of cosimulation examples of increasing complexity. These examples can be
  run on various simulators as well as Zynq-based FPGAs, which is ideal for prototyping accelerators.
- **software/** contains software infrastructure for generating tests used in cosimulation
  examples. For example, RISC-V compilers and programs for the BlackParrot RISC-V processor.

## Prerequisites

### CentOS 7+

To install most dependencies, execute the following command:

    sudo yum install autoconf automake bash bc binutils bison bzip2 cpio dtc expat-devel file flex gawk gcc gcc-c++ git gmp-devel gzip gtkwave java-1.8.0-openjdk-headless libmpc-devel libuuid-devel make mpfr-devel patch patchutils perl perl-ExtUtils-MakeMaker python3 python3-pip rsync sed tar tcl texinfo unzip vim-common virtualenv which zlib-devel

On CentOS 7, some tools provided by the base repository are too old to satisfy the requirements.
We suggest using the [Software Collections](https://wiki.centos.org/AdditionalResources/Repositories/SCL)
(SCL) to obtain newer versions.

    sudo yum install centos-release-scl scl-utils
    sudo yum install devtoolset-9 rh-git218
    scl enable devtoolset-9 rh-git218 bash

To automatically enable these tools from SCL on new terminals, add the following line to ~/.bashrc:

    source scl_source enable devtoolset-9 rh-git218

Moreover, the `cmake` package on CentOS 7 is CMake 2 while we need CMake 3. We suggest installing CMake 3 from EPEL:

    sudo yum install epel-release
    sudo yum install cmake3

On CentOS 8 and later, the `cmake` package is CMake 3 and works well without `CMAKE=cmake3`:

    sudo yum install cmake

### Ubuntu

    sudo apt-get install autoconf automake autotools-dev cmake curl default-jre libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev wget byacc device-tree-compiler python gtkwave uuid-dev vim-common virtualenv python-yaml

We need the `orderedmultidict` Python package too, but it is not packaged by default. Installing it from PyPI works:

    pip install --user orderedmultidict

BlackParrot has been tested extensively on CentOS 7. We have many users who have used Ubuntu for
development. If not on a relatively recent version of these OSes, we suggest using a
Docker image.

## Build the toolchains

    # Clone the latest repo
    git clone https://github.com/black-parrot-hdk/zynq-parrot.git
    cd zynq-parrot

    # make checkout will checkout submodules needed for all of the examples. Users who just want
    #   to try out simple examples and not a full RISC-V program need only run this as preparation
    make checkout

    # make prep is a meta-target which will build the RISC-V toolchains, programs and microcode
    #   needed for a full BlackParrot evaluation setup.
    # Users who are changing code can use the targets in tagged submodules as appropriate
    # For faster builds, make prep -j is parallelizable!
    # To get started as fast as possible, use 'make prep_lite' which installs a minimal set of tools
    # BSG users should instead use 'make prep_bsg', which sets up the bsg CAD environment
    make prep

**See [cosim](https://github.com/black-parrot-hdk/zynq-parrot/tree/master/cosim) directory for a
list of cosimulation examples.**

# Suggested projects for contributors to the BlackParrot example:

- We would like to support OpenOCD to our Zynq Shell. 
- One route:
  - We could use an open-source standin for the Xilinx AXI-to-JTAG debug bridge
  - We could then OpenOCD over AXI on Zynq: https://review.openocd.org/c/openocd/+/6594
- Another route (probably better):
  - Use https://github.com/chipsalliance/rocket-chip/blob/master/src/main/resources/csrc/remote_bitbang.cc
  - Rewrite remote_bitbang_t::execute_command() to just use memory mapped addresses for Zynq.
  - Hookup the corresponding memory mapped signals to zynq.

