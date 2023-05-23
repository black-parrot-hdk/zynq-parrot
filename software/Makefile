TOP  := $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common

# NBF Configuration
SUITE ?= beebs
NBF_NCPUS ?= 1

CROSS_COMPILE ?= riscv64-unknown-elf-dramfs-
RISCV_OBJCOPY ?= $(CROSS_COMPILE)objcopy
SED ?= sed

suite-binaries:=$(shell test -d $(BLACKPARROT_SDK_DIR)/prog/$(SUITE) && find $(BLACKPARROT_SDK_DIR)/prog/$(SUITE) -iname "*.riscv")

checkout_tools:
	cd ../software/import; git submodule update --init $(BLACKPARROT_SDK_DIR)

#build once (x86 server); takes about 15 minutes
build_tools: checkout_tools
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) panic_room

# run on x86
build_libs: build_tools
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init bedrock
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) -j1 bedrock
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init perch
	$(MAKE)  -C $(BLACKPARROT_SDK_DIR) -j1 perch
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init bootrom
	$(MAKE)  -C $(BLACKPARROT_SDK_DIR) -j1 bootrom

# run on x86
# build these after you build the tools (x86 server)
build_beebs: build_libs
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init beebs
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) beebs

# run on x86
# build riscv binaries for $(SUITE) benchmark in SDK
build_suite: build_libs
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init $(SUITE)
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) -j1 $(SUITE)

# run on x86
#generates NBF files for $(SUITE) benchmarks at $(SOFTWARE_NBF_DIR)/$(SUITE)
generate_nbf: build_libs $(suite-binaries:.riscv=.nbf)
	mkdir -p $(SOFTWARE_NBF_DIR)/$(SUITE)
	-mv $(filter-out $<,$^) $(SOFTWARE_NBF_DIR)/$(SUITE)

# run on x86 server
# needs access to spec2000-private and spec2006-private
build_spec: build_libs
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init spec2000
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init spec2006
	cd $(BLACKPARROT_SDK_DIR); git submodule update --init spec2017
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) -j1 spec2000
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) -j1 spec2006
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) -j1 spec2017

# run on x86 server
clean_software:
	-rm -rf $(BLACKPARROT_SDK_DIR)/install/touchfiles/prog/bedrock.*
	-rm -rf $(BLACKPARROT_SDK_DIR)/install/touchfiles/prog/bootrom.*
	-rm -rf $(BLACKPARROT_SDK_DIR)/install/touchfiles/prog/perch.*
	-rm -rf $(BLACKPARROT_SDK_DIR)/install/touchfiles/prog/beebs.*
	-rm -rf $(BLACKPARROT_SDK_DIR)/install/touchfiles/prog/spec2000.*
	-rm -rf $(BLACKPARROT_SDK_DIR)/install/touchfiles/prog/spec2006.*
	-$(MAKE) -C ../cosim/import/fpga clean
	-$(MAKE) -C $(BLACKPARROT_SDK_DIR) prog_clean
	-$(MAKE) -C $(BLACKPARROT_SDK_DIR) tidy_progs
	-rm -rf nbf

# run on x86 server
clean_nbfs:
	-rm -rf $(SOFTWARE_NBF_DIR)

#
# before you load the bitstream, be sure to copy the .b64 file to ../cosim/black-parrot-example
# on the zynq board and run the unpack_bitstream make rule there
#

# do this the first time you try to run after you have rebooted the Zynq, before the bitstream has been loaded
# run on Zynq
load_bitstream:
	$(MAKE) -C ../cosim/black-parrot-example/fpga load_bitstream

# do this if you have already used the bitstream; it transfers over the pointer to the DRAM address space
# run on Zynq
reload_bitstream_keep_dram:
	$(MAKE) -C ../cosim/black-parrot-example/fpga reload_bitstream_keep_dram

# run on Zynq
summarize:
	grep --files-without-match PASS $(SOFTWARE_NBF_DIR)/*.log
	grep FAIL $(SOFTWARE_NBF_DIR)/*.log

# run on Zynq or X86
clean_logs:
	rm -rf $(SOFTWARE_NBF_DIR)/*.log

# run on x86
VPATH := $(wildcard $(BLACKPARROT_SDK_DIR)/prog/*)
%.nbf: %.riscv
	$(RISCV_OBJCOPY) -O verilog $< $*.mem
	$(SED) -i "s/@8/@0/g" $*.mem
	python $(BP_COMMON_DIR)/software/py/nbf.py --skip_zeros --config --boot_pc 0x80000000 --mem $*.mem --ncpus $(NBF_NCPUS) > $@
	-rm $*.mem

# if you want to run one test, then you can do:

# make nbf/<testname>.fpga.log to run on fpga (Zynq)


%.fpga.log: %.nbf
	$(MAKE) -C ../cosim/black-parrot-example/fpga run NBF_FILE=$(abspath $<) | tee -i $*.fpga.log

%.fpga.rerun: %.nbf
	-rm $*.fpga.log
	make $*.fpga.log

# make nbf/<testname>.verilator.log to run on verilator (probably x86)

%.verilator.log: %.nbf
	$(MAKE) FREE_DRAM=0 -C ../cosim/black-parrot-example/verilator run NBF_FILE=$(abspath $<) | tee -i $*.verilator.log

%.verilator.rerun: %.nbf
	-rm $*.verilator.log
	make $*.verilator.log

# make nbf/<testname>.vcs.log to run on vcs (probably x86)

%.vcs.log: %.nbf
	$(MAKE) FREE_DRAM=0 -C ../cosim/black-parrot-example/vcs run NBF_FILE=$(abspath $<) | tee -i $*.vcs.log

%.vcs.rerun: %.nbf
	-rm $*.vcs.log
	make $*.vcs.log
