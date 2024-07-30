Make sure to update the makefile to point at wherever you have mapped the address of the accelerator using IPI. (See this [tutorial](https://docs.google.com/document/d/1U9XIxLkjbI1vQR5hxjk8SzqqQ3sM2hCMUXfoK3tGwBU/edit#.
).)

Note: you still use the Python3 Pynq environment and code to load the .bit file.

Read the Makefile comments to see what you can do in this directory!

Brief instructions:
1. copy `bsg\_bootrom.bin` into the `black-parrot-example/v/` directory
2. copy the bitstream archive into the `black-parrot-example/` directory
3. copy NBF files for programs into `black-parrot-example/zynq/`
4. try the commands below

```
make unpack_bitstream
make load_bitstream
make run PROG=hello_world # replace hello_world with the stem of some .nbf file
```

