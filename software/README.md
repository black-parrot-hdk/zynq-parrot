This directory contains:

1) support for cross-compiling RISC-V programs on X86 and

2) support for running these programs on bitstreams on the Zynq PL.


The eventual goal is to support having a build RISC-V tool chain on the board, and also running Verilator. So only bitstream build has to happen on X86. But this may require some cleverness to get it to build (larger flash card) and maybe that end users use a higher end (Ultra96V2) board so they can have 2 GB of memory, and faster ARM cores.

Note: GNU Awk (gawk) is required by the software build.
