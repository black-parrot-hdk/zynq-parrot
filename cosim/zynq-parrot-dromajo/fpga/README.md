Optionally, run: 
`$ make cmake3_install`
`$ make dromajo_install`
for installing Dromajo and its prerequisite in Linux on ARM PS.

For running a single test:
1. Unpack the tarball of bitstream and collaterals. For that copy the tar ball from your vivado build directory (on your host x86) to `../` and:
`make unpack_bitstream`
2. Load the bistream to the PL (or reload depending on your situation):
`make load_bitstream` or `make reload_bitstream_keep_dram`
3. Invoke the control program:
`make -B run`

For running regression routines:
`make test SUITE=<beebs> PROG=<aha-compress>` -- for single test
`make test_all SUITE=<beebs>` -- for regression against test suite


