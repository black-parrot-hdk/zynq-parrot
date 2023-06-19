This shows a simple example of the proposed [BSG](http://bsg.ai) methodology for accelerating BlackParrot (or other accelerators) simulation on FPGA. There is a unified interface for a control program (implemented as "host code") to interact with the hardware device; which has both Verilator and Zynq PS (== ARM core) support.

See (this document)[https://docs.google.com/document/d/1mBLb9BgQSIv25p59MPj0a4c-TfvwlfqXeuFlZFBVzAY/edit] for the architecture of the BSG ZynqParrot shell and how it is integrated with BlackParrot.

See the [other examples](https://github.com/black-parrot-hdk/zynq-parrot/tree/master/cosim) to see how the cosimulation and shell infrastructure work.
