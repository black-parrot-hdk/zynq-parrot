## Dromajo FPGA-cosimulation
This repo is a cosimulation framework with:
- Dromajo VM on ARM PS of Ultra96 -- running prog.riscv
- BlackParrot on PL -- running prog.nbf

#### Instructions
- Download zynq-parrot from its repository [here](https://github.com/black-parrot-hdk/zynq-parrot) and follow the instructions to setup the repository from `zynq-parrot/cosim/README.md` (involves updating git submodules). If running on FPGA, you can safely skip this step (space implodes)
- Switch to ultra96 branch with `git checkout ultra96`
- **Make sure `zynq-parrot/cosim/black-parrot-example` runs without errors**
- Download this repository into `zynq-parrot/cosim/`
- Run: `sudo make` -- this builds Dromajo (and dependancies) and copies a modified top-level file to the imports directory.
- To revert this change after your checkout out of this repository, run `make clean_changes`.
- Make sure you're running Vivado 2022.2. If not, look into ultra96/vivado-create-block.tcl for comments on a few changes to still make it work.
- Generate the bitstream and, just like in black-parrot-example, package and copy the products to FPGA
- Download and setup zynq-parrot and zynq-parrot-dromajo repositories like above on the FPGA, only instead of sudo make, run `sudo make FPGA=1`. This skips a few unnecesary routines.
- Unpack the bitstream, copy over the required .nbf and .riscv files, load bitstream, compile and run program executable. Alternatively, run `init.sh beebs aha-compress` for a single line recompile, and run from scratch, an example test from beebs (alternative is riscv-tests). Or `script.sh beebs` (beebs or riscv-tests). For the fastest execution, disable all prints by commenting out: `CFLAGS += -DZYNQ_PS_DEBUG` in `./ultra96/Makefile`.

#### Setup block diagram/ current Status
[Google Sheets](https://docs.google.com/spreadsheets/d/11n7ljKPtfueUItfsVoOF03UhAW5oDQRrLBieNyRGGbs/edit?usp=sharing)

#### TODOs
- Increase AXI width to 64 or 128 (depending on how PS handles it) so fewer reads into PL per commit; should increase the cosim speed drastically as PS is the bottleneck with BP @50 MHz. Reads are slow and Dromajo execution isn't much of an overhead.
- In the block diagram, s00_axi_aclk and s01_axi_aclk are depicted separately, but in the code, they are sourced from the same clock; and hence the crossing is with respect to s01_axi_aclk. Separate this out to s00(for AXIL) and s01(for AXI).
- Unicore with/out async works. Check Multicode without async.
- Multicore with async hasn't been implemented.
- ps.cpp can be made a tiny bit more efficient by skipping unnecessary reads into PL based on the expected instruction in the cosimulation routine.
