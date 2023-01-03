TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)

BOARDNAME ?= ultra96v2

#############################
# Project Settings
#############################
ifeq ($(BOARDNAME),ultra96v2)
export PART       ?= xczu3eg-sbva484-1-e
else ifeq ($(BOARDNAME),pynqz2)
export PART       ?= xc7z020clg400-1
else
$(error Invalid BOARDNAME)
endif
export TOP_MODULE ?= top
export BASENAME   ?= blackparrot

#############################
# Accelerator Software Settings
#############################
export NBF_FILE     ?= $(abspath ../prog.nbf)
export HOST_PROGRAM ?= $(abspath ../ps.cpp)
export BASE_FLIST   ?= $(abspath ../flist.vcs)
export FLIST        ?= $(abspath flist.vcs)
export SIM_ARGS     += $(NBF_FILE)
export SIM_DEFINES  += -DFPGA

#SIM_DEFINES  +=-DSKIP_DRAM_TESTING

#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG

ifeq ($(BOARDNAME),ultra96v2)
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x400000000 -DGP0_ADDR_WIDTH=10
CFLAGS += -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x500000000 -DGP1_ADDR_WIDTH=30
else ifeq ifeq ($(BOARDNAME),pynqz2)
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000 -DGP0_ADDR_WIDTH=10
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=30
else
$(error Invalid BOARDNAME)
endif

CFLAGS += -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ADDR_SIZE_BYTES=0x30000000 -DGP1_DATA_WIDTH=32

CINCLUDES += -I$(BLACKPARROT_TOOLS_DIR)/dromajo/build
CINCLUDES += -I$(BLACKPARROT_TOOLS_DIR)/dromajo/include
CFLAGS += -L$(BLACKPARROT_TOOLS_DIR)/dromajo/build/ -ldromajo_cosim

include $(TOP)/cosim/mk/Makefile.fpga

#############################
# Modify base flist
#############################
$(FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	echo "+incdir+$(CURR_SRC_DIR)" > $@
	cat $^ | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/fpga" >> $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@
	# Replace bsg_mux with one that uses Xilinx macros for correct mapping of logic on clock-tree
	sed -i "s|.*/bsg_mux.v|$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_mux.v|" $@
	sed -i "s|.*/bsg_clkgate_optional.v|$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_clkgate_optional.v|" $@

.PHONY: cmake3_install dromajo_install

#############################
# ancillary routines
#############################
cmake3_install:
	echo "(Re-)downloading cmake3 for Dromajo installation"
	rm -rf ./install/
	mkdir -p ./install/
	# this is the latest version at the time that also works with the utilized APIs
	wget https://github.com/Kitware/CMake/releases/download/v3.25.0/cmake-3.25.0-linux-aarch64.sh -P ./install/; \
	chmod +x ./install/cmake-3.25.0-linux-aarch64.sh; \
	./install/cmake-3.25.0-linux-aarch64.sh --prefix=./install/ --include-subdir --skip-license; \
	echo "Done installing cmake3"

dromajo_install: cmake3_install
	echo "Make sure you have updated all the git submodules in <root>/cosim/import/* as per <root>/cosim/README.md"; \
	echo "Updating Dromajo submodule"
	cd $(BLACKPARROT_TOOLS_DIR); git submodule update --init dromajo
	echo "Installing Dromajo..."
	mkdir -p $(BLACKPARROT_TOOLS_DIR)/dromajo/build
	export PATH=$(shell pwd)/install/cmake-3.25.0-linux-aarch64/bin:$$PATH; \
	cmake -S $(BLACKPARROT_TOOLS_DIR)/dromajo -B $(BLACKPARROT_TOOLS_DIR)/dromajo/build -DCMAKE_BUILD_TYPE=Release
	$(MAKE) -C $(BLACKPARROT_TOOLS_DIR)/dromajo/build
