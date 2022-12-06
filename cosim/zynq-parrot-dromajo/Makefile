TOP  := $(shell git rev-parse --show-toplevel)
include ../mk/Makefile.common

SHELL = /bin/bash

.PHONY: cmake3_install dromajo_install all
.DEFAULT_GOAL := all

cmake3_install:
	echo "(Re-)downloading cmake3 for Dromajo installation"
	rm -rf ./install/
	mkdir -p ./install/
	# this is the latest version at the time that also works with the utilized APIs
	if [ -z "$(FPGA)" ]; then \
		echo "Installing x86_64 variant"; \
		wget https://github.com/Kitware/CMake/releases/download/v3.25.0/cmake-3.25.0-linux-x86_64.sh -P ./install/; \
		chmod +x ./install/cmake-3.25.0-linux-x86_64.sh; \
		./install/cmake-3.25.0-linux-x86_64.sh --prefix=./install/ --include-subdir --skip-license; \
	else \
		echo "Installing aarch64 variant"; \
		wget https://github.com/Kitware/CMake/releases/download/v3.25.0/cmake-3.25.0-linux-aarch64.sh -P ./install/; \
		chmod +x ./install/cmake-3.25.0-linux-aarch64.sh; \
		./install/cmake-3.25.0-linux-aarch64.sh --prefix=./install/ --include-subdir --skip-license; \
	fi
	echo "Done installing cmake3"

dromajo_install: cmake3_install
	echo "Updating Dromajo submodule"
	cd $(BLACKPARROT_TOOLS_DIR); git submodule update --init dromajo
	echo "Installing Dromajo..."
	mkdir -p $(BLACKPARROT_TOOLS_DIR)/dromajo/build
	export PATH=$(shell pwd)/install/cmake-3.25.0-linux-aarch64/bin:$$PATH; \
	cmake -S $(BLACKPARROT_TOOLS_DIR)/dromajo -B $(BLACKPARROT_TOOLS_DIR)/dromajo/build -DCMAKE_BUILD_TYPE=Release
	$(MAKE) -C $(BLACKPARROT_TOOLS_DIR)/dromajo/build

all: dromajo_install
	if [ -z "$(FPGA)" ]; then \
		echo "Make sure you have updated the git submodules in <root>/cosim/import/* as per <root>/cosim/README.md"; \
		cp files/x86_host/bp_axi_top.sv ../import/black-parrot-subsystems/axi/v/bp_axi_top.sv; \
	fi
	# extracting riscv-tests and beebs testsuite
	tar -xzf files/common/beebs.tar.gz -C .
	tar -xzf files/common/riscv-tests.tar.gz -C .
