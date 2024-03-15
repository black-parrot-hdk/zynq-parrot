## Dromajo FPGA-cosimulation
This repo is a cosimulation framework with:
- Dromajo VM on ARM PS of Ultra96 (or Pynq Z2) -- running prog.riscv
- BlackParrot on PL -- running prog.nbf

#### Instructions
- Download zynq-parrot from its repository [here](https://github.com/black-parrot-hdk/zynq-parrot) and follow the instructions to setup the repository from `zynq-parrot/cosim/README.md` (involves updating git submodules). If running on FPGA, you can safely skip this step (space implodes)
- **Make sure zynq-parrot/cosim/black-parrot-example runs without errors**
- Run zynq-parrot/cosim/zynq-parrot-dromajo similarly.
- Make sure you're running Vivado 2022.1. If not, there will be changes to some of the commands in the TCL script.
- Generate the bitstream and, just like in black-parrot-example, package and copy the products to FPGA
- Download and setup zynq-parrot like above on the FPGA. You can skip updating submodules if you're installing dromajo via the Makefile -- to install Dromajo (and a prerequisite cmake3) on FPGA please refer to zynq-parrot/cosim/zynq-parrot-dromajo/fpga/Makefile.
- Unpack the bitstream, copy over the required .nbf and .riscv files, load bitstream, compile and run program executable. Alternatively, run `init.sh beebs aha-compress` for a single line recompile, and run from scratch, an example test from beebs (alternative is riscv-tests). Or `script.sh beebs` (beebs or riscv-tests). For the fastest execution, disable all prints by commenting out: `CFLAGS += -DZYNQ_PS_DEBUG` in zynq-parrot/cosim/zynq-parrot-dromajo/fpga/Makefile

#### Setup block diagram/ current Status
[Google Sheets](https://docs.google.com/spreadsheets/d/11n7ljKPtfueUItfsVoOF03UhAW5oDQRrLBieNyRGGbs/edit?usp=sharing)

#### TODOs
- Increase AXIL width to 64 (depending on how PS handles it) so fewer reads into PL per commit; should increase the cosim speed as PS is the bottleneck with BP @50 MHz. Reads are slow and Dromajo execution isn't much of an overhead.
- In the block diagram, s00_axi_aclk and s01_axi_aclk are distinctly clocked, but in the code, they are sourced from the same clock; and hence the crossing is with respect to s01_axi_aclk. Separate this out to s00(for AXIL) and s01(for AXI) and m00, ...
- Unicore with/out async works. Check Multicode without async.
- ps.cpp can be made a tiny bit more efficient by skipping unnecessary reads into PL based on the expected instruction in the cosimulation routine -- this can also skip needing to read the metadata of commits -- obtainable via Draomjo VM APIs.
