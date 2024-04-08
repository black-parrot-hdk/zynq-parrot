Xilinx PYNQ Z2:

Neon mode (4-way 32-bit SIMD writes from PS to PL):  3.32 xfers per microsecond * 4 words/xfer * 4 bytes/word = 53 mbytes/second @ 166 MHz
Single word mode (1-way 32-bit writes from PS to PL): 7.86 xfers per microsecond * 1 word/xfer * 4 bytes/word = 31 mbytes/second @ 166 MHz

The AXI-lite converter does not support 200 MHz operation, so we cannot clock it faster.

Make sure to update the makefile to point at wherever you have mapped the address of the accelerator using IPI.

(See this [tutorial](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#.).)

Note: you still need to use the Python3 Pynq environment to load the bit file, but we provide a make rule for that.
