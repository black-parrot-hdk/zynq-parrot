include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
RISCV_FILE   ?= $(abspath ../prog.riscv)
NBF_FILE     ?= $(abspath ../prog.nbf)
HOST_PROGRAM ?= $(abspath ../ps.cpp)
SIM_ARGS     += $(NBF_FILE) $(RISCV_FILE)
export SIM_DEFINES  += -DFPGA

#SIM_DEFINES  +=-DSKIP_DRAM_TESTING

#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG

CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x400000000 -DGP0_ADDR_WIDTH=10
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x500000000 -DGP1_ADDR_WIDTH=30
CFLAGS += -DGP0_ADDR_SIZE_BYTES=4096 -DGP0_DATA_WIDTH=32
CFLAGS += -DGP1_ADDR_SIZE_BYTES=0x30000000 -DGP1_DATA_WIDTH=32

CINCLUDES += -I$(BLACKPARROT_TOOLS_DIR)/dromajo/build
CINCLUDES += -I$(BLACKPARROT_TOOLS_DIR)/dromajo/include
CFLAGS += -L$(BLACKPARROT_TOOLS_DIR)/dromajo/build/ -ldromajo_cosim

include $(TOP)/cosim/mk/Makefile.fpga

########################################
# ancillary routines to be run on ARM PS
########################################
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

#############################
# Regression routines
#############################
SUITE ?=
PROG  ?=
define logger
	if grep -q -e "FAIL" -e "MISMATCH" $(1); then \
		echo Cosimulation failed;                   \
		cp $(1) $(SUITE)/FAIL_$(PROG).log;          \
	elif grep -q "PASS" $(1); then                \
		echo Cosimulation passed;                   \
		cp $(1) $(SUITE)/PASS_$(PROG).log;          \
	else                                          \
		echo Cosimulation flopped;                  \
		cp $(1) $(SUITE)/FLOP_$(PROG).log;          \
	fi
endef

test:
	mkdir -p $(SUITE)
	$(eval RISCV_FILE=$(BLACKPARROT_SDK_DIR)/prog/$(SUITE)/$(PROG).riscv)
	$(eval NBF_FILE=$(SOFTWARE_NBF_DIR)/$(SUITE)/$(PROG).nbf)
	@echo "Cosimulating $(SUITE): $(PROG).riscv"
	make unpack_bitstream
	make load_bitstream
	$(MAKE) run 2>&1 > $(SUITE)/$(PROG).log
	@$(call logger, $(SUITE)/$(PROG).log)
