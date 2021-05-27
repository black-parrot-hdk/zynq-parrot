SDK_DIR=../cosim/import/sdk
NBF_DIR=../cosim/import/black-parrot/bp_common/software/py

riscv-binaries=$(shell find ../. -iname "*.riscv")

$(warning $(shell find . -iname "*.nbf"))
nbf-files=$(filter-out ./nbf/hello_world.nbf,$(shell find . -iname "*.nbf"))

nothing:

build_tools:
	cd ../cosim/import; git submodule update --init sdk
	$(MAKE) -j 4 -C $(SDK_DIR) panic_room

build_libs: build_tools
	cd $(SDK_DIR); git submodule update --init bedrock
	$(MAKE) -C $(SDK_DIR) -j1 bedrock
	cd $(SDK_DIR); git submodule update --init perch
	$(MAKE)  -C $(SDK_DIR) -j1 perch
	cd $(SDK_DIR); git submodule update --init bootrom
	$(MAKE)  -C $(SDK_DIR) -j1 bootrom

build_beebs: build_libs
	cd $(SDK_DIR); git submodule update --init beebs
	$(MAKE) -C $(SDK_DIR) beebs

# needs access to spec2000-private and spec2006-private
build_spec: build_libs
	cd $(SDK_DIR); git submodule update --init spec2000
	cd $(SDK_DIR); git submodule update --init spec2006
	$(MAKE) -C $(SDK_DIR) -j1 spec2000
	$(MAKE) -C $(SDK_DIR) -j1 spec2006

clean_software:
	-rm -rf $(SDK_DIR)/install/touchfiles/bedrock.*
	-rm -rf $(SDK_DIR)/install/touchfiles/bootrom.*
	-rm -rf $(SDK_DIR)/install/touchfiles/perch.*
	-rm -rf $(SDK_DIR)/install/touchfiles/beebs.*
	-rm -rf $(SDK_DIR)/install/touchfiles/spec2000.*
	-rm -rf $(SDK_DIR)/install/touchfiles/spec2006.*
	$(MAKE) -C ../cosim/import/fpga clean
	$(MAKE) -C $(SDK_DIR) prog_clean
	$(MAKE) -C $(SDK_DIR) tidy_progs
	-rm -rf nbf

%.nbf: %.riscv
	$(SDK_DIR)/install/riscv64-unknown-elf-dramfs/bin/objcopy -O verilog $< $*.mem
	python $(NBF_DIR)/nbf.py --config --mem $*.mem > $@
	-rm $*.mem

packup_nbf: $(riscv-binaries:.riscv=.nbf)
	mkdir -p nbf
	-cp -f $^ nbf
	tar -cJf nbf.tar.xz nbf

# expects that you transfer the nbf bundle over to the Zynq board and place in the same directory
unpack_nbf:
	tar -xJf nbf.tar.xz

%.run-fpga: %.nbf
	$(MAKE) SKIP_DRAM_TESTING=1 FREE_DRAM=0 -C ../cosim/black-parrot-example/fpga run NBF_FILE=$(abspath $<) | tee $*.log

%.run-verilator: %.nbf
	$(MAKE) SKIP_DRAM_TESTING=1 FREE_DRAM=0 -C ../cosim/black-parrot-example/verilator run NBF_FILE=$(abspath $<)

# do this the first time you try to run after you have rebooted the Zynq, before the bitstream has been loaded
load_bitstream:
	$(MAKE) -C ../cosim/black-parrot-example/fpga load_bitstream

# do this if you have already used the bitstream; it transfers over the pointer to the DRAM address space
reload_bitstream_keep_dram:
	$(MAKE) -C ../cosim/black-parrot-example/fpga reload_bitstream_keep_dram


# run all of the nbfs
# note: assumes the .b64 file has been unpacked in ../cosim/black-parrot-example/fpga
#
run_all_fpga_nbf: $(nbf-files:.nbf=.run-fpga)

run_all_verilator_nbf: $(nbf-files:.nbf=.run-verilator)

