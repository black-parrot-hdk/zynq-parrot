SDK_DIR=../cosim/import/black-parrot-sdk
NBF_DIR=../cosim/import/black-parrot/bp_common/software/py

NBF_NCPUS ?= 1

NCORES=20

export PATH := $(SDK_DIR)/install/bin/:$(PATH)
CROSS_COMPILE ?= riscv64-unknown-elf-dramfs-
RISCV_OBJCOPY ?= $(CROSS_COMPILE)objcopy
SED ?= sed

# RISC_V DRAM starts at 0x8000_0000; this sets the stack at 64MB
# when building the RISCV binaries, bounding total used memory

# 64 MB  - 4096
# TOP_OF_MEM_RISC_V=0x83FFF000
# 120 MB - 4096
TOP_OF_MEM_RISC_V=0x877FF000

FILTER_OUT = $(foreach v,$(2),$(if $(findstring $(1),$(v)),,$(v)))

# test command avoids error if $(SDK_DIR)/prog does not yet exist
all-riscv-binaries:=$(shell test -d $(SDK_DIR)/prog && find $(SDK_DIR)/prog -iname "*.riscv")
riscv-dont-run=arch.mk Config.in
$(warning filtering $(riscv-dont-run))
riscv-binaries=$(filter-out $(addprefix %,$(addsuffix .riscv,$(riscv-dont-run))),$(all-riscv-binaries))
$(warning $(riscv-binaries))

all-nbf-binaries:=$(shell find . -iname "*.nbf")
nbf-dont-run = bootrom 181.mcf 454.calculix 458.sjeng 471.omnetpp
$(warning filtering $(nbf-dont-run))
nbf-files=$(call FILTER_OUT,$(addprefix %,$(addsuffix .nbf,$(nbf-dont-run))),$(all-nbf-binaries))
$(warning $(nbf-files))


nothing:

checkout_tools:
	cd ../cosim/import; git submodule update --init black-parrot-sdk

#build once (x86 server); takes about 15 minutes
build_tools: checkout_tools
	$(MAKE) -j $(NCORES) -C $(SDK_DIR) panic_room PLATFORM=zynqparrot

#build these after you build the tools (x86 server)
build_beebs: build_libs
	cd $(SDK_DIR); git submodule update --init beebs
	$(MAKE) -j $(NCORES) -C $(SDK_DIR) beebs

build_bp-tests: build_libs
	cd $(SDK_DIR); git submodule update --init bp-tests
	$(MAKE) -j $(NCORES) -C $(SDK_DIR) bp-tests

build_riscv-tests: build_libs
	cd $(SDK_DIR); git submodule update --init riscv-tests
	$(MAKE) -j $(NCORES) -C $(SDK_DIR) riscv-tests

build_progs: build_libs
	$(MAKE) -j $(NCORES) -C $(SDK_DIR) prog

build_linux: build_libs
	$(MAKE) -j $(NCORES) -C $(SDK_DIR) linux OPENSBI_NCPUS=$(NBF_NCPUS)

# run this after you build the beebs to create nbf files (x86 server)
generate_and_packup_nbf: $(riscv-binaries:.riscv=.nbf)
	mkdir -p nbf
	-mv -f $^ nbf

#tar -cJf nbf.tar.xz nbf

# run on Zynq board
# expects that you transfer the nbf bundle over to the Zynq board and place in the same directory
unpack_nbf:
	tar -xJf nbf.tar.xz

# run on x86 server
# needs access to spec2000-private and spec2006-private
build_spec: build_libs
	cd $(SDK_DIR); git submodule update --init spec2000
	cd $(SDK_DIR); git submodule update --init spec2006
	$(MAKE) -C $(SDK_DIR)/spec2000 spec2000
	$(MAKE) -C $(SDK_DIR)/spec2006 spec2006
	$(MAKE) -C $(SDK_DIR) -j1 spec2000
	$(MAKE) -C $(SDK_DIR) -j1 spec2006

# run on x86 server
clean_software:
	-rm -rf $(SDK_DIR)/install/touchfiles/prog/bedrock.*
	-rm -rf $(SDK_DIR)/install/touchfiles/prog/bootrom.*
	-rm -rf $(SDK_DIR)/install/touchfiles/prog/perch.*
	-rm -rf $(SDK_DIR)/install/touchfiles/prog/beebs.*
	-rm -rf $(SDK_DIR)/install/touchfiles/prog/spec2000.*
	-rm -rf $(SDK_DIR)/install/touchfiles/prog/spec2006.*
	-$(MAKE) -C ../cosim/import/fpga clean
	-$(MAKE) -C $(SDK_DIR) prog_clean
	-$(MAKE) -C $(SDK_DIR) tidy_progs
	-rm -rf nbf

#
# before you load the bitstream, be sure to copy the .b64 file to ../cosim/black-parrot-example
# on the zynq board and run the unpack_bitstream make rule there
#

# do this the first time you try to run after you have rebooted the Zynq, before the bitstream has been loaded
# run on Zynq
load_bitstream:
	$(MAKE) -C ../cosim/black-parrot-example/fpga load_bitstream

# run on zynq
print_clocks:
	$(MAKE) -C ../cosim/black-parrot-example/fpga $@

# run on zynq, suggest 20.set_clocks to set to 20 MHz. Decimal places okay too.
%.set_clock:
	$(MAKE) -C ../cosim/black-parrot-example/fpga $@

# do this if you have already used the bitstream; it transfers over the pointer to the DRAM address space
# run on Zynq
reload_bitstream_keep_dram:
	$(MAKE) -C ../cosim/black-parrot-example/fpga reload_bitstream_keep_dram


# run all of the nbfs on Zynq
# note: assumes the .b64 file has been unpacked in ../cosim/black-parrot-example/fpga
#

run_all_fpga_nbf: $(nbf-files:.nbf=.fpga.log)

# run all of the nbfs in simulation, usually on your x86 build machine
#
# use -j <n cpus> to parallelize
#
run_all_verilator_nbf: $(nbf-files:.nbf=.verilator.log)

# run on Zynq
summarize:
	grep --files-without-match PASS nbf/*.log
	grep FAIL nbf/*.log

# run on Zynq or X86
clean_logs:
	rm -rf nbf/*.log

# run on x86
build_libs: build_tools
	cd $(SDK_DIR); git submodule update --init bedrock
	$(MAKE) -C $(SDK_DIR) -j1 bedrock
	cd $(SDK_DIR); git submodule update --init perch
	$(MAKE)  -C $(SDK_DIR) -j1 perch
	cd $(SDK_DIR); git submodule update --init bootrom
	$(MAKE)  -C $(SDK_DIR) -j1 bootrom

# run on x86
VPATH := $(wildcard ../cosim/import/black-parrot-sdk/prog/*)
%.nbf: %.riscv
	$(RISCV_OBJCOPY) -O verilog $< $*.mem
	$(SED) -i "s/@8/@0/g" $*.mem
	python $(NBF_DIR)/nbf.py --config --mem $*.mem --ncpus $(NBF_NCPUS) > $@
	-rm $*.mem

# if you want to run one test, then you can do:

# make nbf/<testname>.fpga.log to run on fpga (Zynq)


%.fpga.log: %.nbf
	$(MAKE) -C ../cosim/black-parrot-example/fpga run NBF_FILE=$(abspath $<) | tee $*.fpga.log

%.fpga.rerun: %.nbf
	-rm $*.fpga.log
	make $*.fpga.log

# make nbf/<testname>.verilator.log to run on verilator (probably x86)

%.verilator.log: %.nbf
	$(MAKE) FREE_DRAM=0 -C ../cosim/black-parrot-example/verilator run NBF_FILE=$(abspath $<) | tee $*.verilator.log

%.verilator.rerun: %.nbf
	-rm $*.verilator.log
	make $*.verilator.log
