Xilinx PYNQ Z2:

This directory demonstrates use of AXI3 (instead of AXI4), which eliminates the smart interconnect which adds latency.

Using a modified Linux kernel with pgprot_device set on 0x4..._.... addresses ---

Running at 200 MHz, it attains this throughput:

neon 4x32:: 3366548 microseconds for 16000000 xfers: 19.010571 words per microsecond = 76 MB/s
int32    :: 1538850 microseconds for 16000000 xfers: 10.397375 words per microsecond = 42 MB/s

Running at 125 MHz, it attains this throughput:

neon 4x32:: 4232078 microseconds for 16000000 xfers: 15.122595 words per microsecond = 60 MB/s
int32    :: 1923635 microseconds for 16000000 xfers: 8.317586 words per microsecond  = 32 MB/s

So the general equation is 64 ns (ARM overhead) + 8 cycles per double word transfer.


Future optimizations:
   -- This code could respond with AWREADY, WREADY, and BVALID more quickly.
   -- Support to Linux could be added for true device-ordered memory

Uncomment the ILA in the FPGA build script to view the transactions on the AXI bus.
