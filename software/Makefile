SDK_DIR=../cosim/import/sdk
NBF_DIR=../cosim/import/black-parrot/bp_common/software/py

riscv-binaries=$(shell find ../. -iname "*.riscv")
nbf-files=$(shell find . -iname "*.nbf")

$(warning $(riscv-binaries))

nothing:

build_tools:
	cd ../cosim/import; git submodule update --init sdk
	make -j 4 -C $(SDK_DIR) panic_room

build_software:
	cd $(SDK_DIR); git submodule update --init bedrock
	make -C $(SDK_DIR) -j1 bedrock
	cd $(SDK_DIR); git submodule update --init perch
	make  -C $(SDK_DIR) -j1 perch
	cd $(SDK_DIR); git submodule update --init bootrom
	make  -C $(SDK_DIR) -j1 bootrom
	cd $(SDK_DIR); git submodule update --init beebs
	make -C $(SDK_DIR) beebs

clean_software:
	-rm -rf $(SDK_DIR)/install/touchfiles/bedrock.*
	-rm -rf $(SDK_DIR)/install/touchfiles/bootrom.*
	-rm -rf $(SDK_DIR)/install/touchfiles/perch.*
	-rm -rf $(SDK_DIR)/install/touchfiles/beebs.*
	make -C ../cosim/import/fpga clean
	make -C $(SDK_DIR) prog_clean
	make -C $(SDK_DIR) tidy_progs
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

%.run: %.nbf
	make SKIP_DRAM_TESTING=1 -C ../cosim/black-parrot-example/fpga control-program NBF_FILE=$(abspath $<)
	make -C ../cosim/black-parrot-example/fpga run

# run all of the nbfs
# note: assumes the .b64 file has been unpacked in ../cosim/black-parrot-example/fpga
#
run_all_nbf: $(nbf-files:.nbf=.run)

