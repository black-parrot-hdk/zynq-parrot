This directory contains:

1) support for cross-compiling RISC-V programs on X86 and NBF generation.

2) support for running these programs on bitstreams on the Zynq PL.

To generate NBF files for a specific benchmark suite run `make generate_nbf SUITE=<suite>`. The output files will be placed at `nbf/$(SUITE).`

For other target about setting up the SDK or running programs on FPGA or simulation read the Makefile.
