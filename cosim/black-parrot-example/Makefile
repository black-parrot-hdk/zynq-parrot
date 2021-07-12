all:
	@echo "enter verilator dir to run ps.cpp with the simulated HW"
	@echo "enter fpga dir to build bit stream and pack it as .b64 file"
	@echo "copy in .b64 into fpga dir of zynq board and unpack, program the .bit file and t run ps.cpp with real HW"

clean:
	-make -C verilator clean
	-make -C fpga clean
