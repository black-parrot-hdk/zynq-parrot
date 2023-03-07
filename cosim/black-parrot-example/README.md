This shows a simple example of the proposed [BSG](http://bsg.ai) methodology for accelerating BlackParrot (or other accelerators) simulation on FPGA. There is a unified interface for a control program (implemented as "host code") to interact with the hardware device; which has both Verilator and Zynq PS (== ARM core) support.

See (this document)[https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit] for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

See the [other examples](https://github.com/black-parrot-hdk/zynq-parrot/tree/master/cosim) to see how the cosimulation and shell infrastructure work.

Some example instructions:

    # On x86, builds bitstream and pack to tarbell
    cd cosim/black-parrot-example/vivado
    make clean fpga_build pack_bitstream BOARDNAME=ultra96v2 VIVADO_VERSION=2020.1 VIVADO_MODE=batch

    # On FPGA, flash and run test
    cd cosim/black-parrot-example/fpga
    make unpack_bitstream load_bitstream run BOARDNAME=ultra96v2 VIVADO_VERSION=2020.1 VIVADO_MODE=batch NBF_FILE=<path_to_nbf>
