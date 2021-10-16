Support for rapid design iteration of BlackParrot on Zynq FPGAs.

See cosim directory for more instructions.

Suggested projects for contributors:

- We would like to support OpenOCD to our Zynq Shell. 
- One route:
  - We could use an open-source standin for the Xilinx AXI-to-JTAG debug bridge
  - We could then OpenOCD over AXI on Zynq: https://review.openocd.org/c/openocd/+/6594
- Another route (probably better):
  - Use https://github.com/chipsalliance/rocket-chip/blob/master/src/main/resources/csrc/remote_bitbang.cc
  - Rewrite remote_bitbang_t::execute_command() to just use memory mapped addresses for Zynq.
  - Hookup the corresponding memory mapped signals to zynq.
