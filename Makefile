TOP  := $(shell git rev-parse --show-toplevel)

include $(TOP)/Makefile.config

export BP_RTL_DIR       := $(TOP)/import/black-parrot
export BP_TOOLS_DIR     := $(TOP)/import/black-parrot-tools
export BP_SDK_DIR       := $(TOP)/import/black-parrot-sdk
export BP_SUB_DIR       := $(TOP)/import/black-parrot-subsystems
export BSG_MANYCORE_DIR := $(TOP)/import/bsg_manycore

checkout:
	git fetch --all
	git submodule update --init
	$(MAKE) -C $(BP_RTL_DIR) checkout
	$(MAKE) -C $(BP_TOOLS_DIR) checkout
	$(MAKE) -C $(BP_SDK_DIR) checkout
	$(MAKE) -C $(BP_SUB_DIR) checkout
	$(MAKE) -C $(BSG_MANYCORE_DIR) checkout_submodules
	$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools checkout-all

prep_lite: checkout
	$(MAKE) -C $(BP_RTL_DIR) libs_lite
	$(MAKE) -C $(BP_TOOLS_DIR) tools_lite
	$(MAKE) -C $(BP_SDK_DIR) sdk_lite
	$(MAKE) -C $(BP_SDK_DIR) prog_lite
	$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-deps build-spike

prep: prep_lite
	$(MAKE) -C $(BP_RTL_DIR) libs
	$(MAKE) -C $(BP_TOOLS_DIR) tools
	$(MAKE) -C $(BP_SDK_DIR) sdk PLATFORM=$(PLATFORM)
	$(MAKE) -C $(BP_SDK_DIR) prog
	$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-gnu-tools

prep_bsg: prep
	$(MAKE) -C $(BP_RTL_DIR) libs_bsg
	$(MAKE) -C $(BP_TOOLS_DIR) tools_bsg
	$(MAKE) -C $(BP_SDK_DIR) sdk_bsg PLATFORM=$(PLATFORM)
	$(MAKE) -C $(BP_SDK_DIR) prog_bsg
	$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-llvm

## This target just wipes the whole repo clean.
#  Use with caution.
bleach_all:
	cd $(TOP); git clean -fdx; git submodule deinit -f .

