TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

checkout::
	@$(eval export BP_INSTALL_DIR)
	@$(eval export BP_RISCV_DIR)
	@$(MAKE) -C $(BP_RTL_DIR) checkout
	@$(MAKE) -C $(BP_TOOLS_DIR) checkout
	@$(MAKE) -C $(BP_SDK_DIR) checkout
	@$(MAKE) -C $(BP_SUB_DIR) checkout
	@$(MAKE) -C $(BSG_MANYCORE_DIR) checkout_submodules
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools checkout-llvm
	@# initialize basejump_stl
	@git -C $(BASEJUMP_STL_DIR) submodule update --init imports/DRAMSim3
	@# workaround for missing qemu upstream
	@[ ! -d $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain ] && git clone https://github.com/bespoke-silicon-group/riscv-gnu-toolchain
	@git -C $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain checkout bsg_custom_git_modules
	@git -C $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-binutils
	@git -C $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-glibc
	@git -C $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-gcc
	@git -C $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain submodule update --init riscv-newlib
	@git -C $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain config submodule.qemu.update none

prep_lite: ## Minimal preparation for simulation
prep_lite: checkout
	@$(eval export BP_INSTALL_DIR)
	@$(eval export BP_RISCV_DIR)
	@$(MAKE) -C $(BP_RTL_DIR) libs_lite
	@$(MAKE) -C $(BP_TOOLS_DIR) tools_lite
	@$(MAKE) -C $(BP_SDK_DIR) tools_lite
	@$(MAKE) -C $(BP_SDK_DIR) prog_lite
	@$(MAKE) -C $(BP_SUB_DIR) gen_lite

prep: ## Standard preparation for simulation
prep: prep_lite
	@$(eval export BP_INSTALL_DIR)
	@$(eval export BP_RISCV_DIR)
	@$(MAKE) -C $(BP_RTL_DIR) libs
	@$(MAKE) -C $(BP_TOOLS_DIR) tools
	@$(MAKE) -C $(BP_SDK_DIR) tools
	@$(MAKE) -C $(BP_SDK_DIR) prog
	@$(MAKE) -C $(BP_SUB_DIR) gen
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-gnu-tools

prep_bsg: ## Extra preparation for BSG users
prep_bsg: prep
	@$(eval export BP_INSTALL_DIR)
	@$(eval export BP_RISCV_DIR)
	@$(MAKE) -C $(BP_RTL_DIR) libs_bsg
	@$(MAKE) -C $(BP_TOOLS_DIR) tools_bsg
	@$(MAKE) -C $(BP_SDK_DIR) tools_bsg
	@$(MAKE) -C $(BP_SDK_DIR) prog_bsg
	@$(MAKE) -C $(BP_SUB_DIR) gen_bsg
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-llvm

