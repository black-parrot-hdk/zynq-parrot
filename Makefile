TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

checkout::
	@$(MAKE) -C $(ZP_BP_RTL_DIR) checkout
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) checkout
	@$(MAKE) -C $(ZP_BP_SDK_DIR) checkout
	@$(MAKE) -C $(ZP_BP_SUB_DIR) checkout
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR) checkout_submodules
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools checkout-llvm
	@# initialize basejump_stl
	@git -C $(ZP_BASEJUMP_STL_DIR) submodule update --init imports/DRAMSim3
	@# workaround for missing qemu upstream
	@[ ! -d $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain ] && git clone https://github.com/bespoke-silicon-group/riscv-gnu-toolchain
	@git -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain checkout bsg_custom_git_modules
	@git -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-binutils
	@git -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-glibc
	@git -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-gcc
	@git -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-newlib
	@git -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain config submodule.qemu.update none

prep_lite: ## Minimal preparation for simulation
prep_lite:
	@$(MAKE) -C $(ZP_BP_RTL_DIR) libs_lite
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) tools_lite
	@$(MAKE) -C $(ZP_BP_SDK_DIR) tools_lite
	@$(MAKE) -C $(ZP_BP_SDK_DIR) prog_lite
	@$(MAKE) -C $(ZP_BP_SUB_DIR) gen_lite

prep: ## Standard preparation for simulation
prep: prep_lite
	@$(MAKE) -C $(ZP_BP_RTL_DIR) libs
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) tools
	@$(MAKE) -C $(ZP_BP_SDK_DIR) tools
	@$(MAKE) -C $(ZP_BP_SDK_DIR) prog
	@$(MAKE) -C $(ZP_BP_SUB_DIR) gen
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-gnu-tools

prep_bsg: ## Extra preparation for BSG users
prep_bsg: prep
	@$(MAKE) -C $(ZP_BP_RTL_DIR) libs_bsg
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) tools_bsg
	@$(MAKE) -C $(ZP_BP_SDK_DIR) tools_bsg
	@$(MAKE) -C $(ZP_BP_SDK_DIR) prog_bsg
	@$(MAKE) -C $(ZP_BP_SUB_DIR) gen_bsg
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools build-llvm

