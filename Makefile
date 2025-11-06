TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

checkout::
	@$(eval export BP_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(eval export BP_RISCV_DIR=$(ZP_RISCV_DIR))
	@$(eval export RISCV_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(MAKE) -C $(BP_RTL_DIR) checkout
	@$(MAKE) -C $(BP_TOOLS_DIR) checkout
	@$(MAKE) -C $(BP_SDK_DIR) checkout
	@$(MAKE) -C $(BP_SUB_DIR) checkout
	@$(MAKE) -C $(BSG_MANYCORE_DIR) checkout_submodules
	@# initialize basejump_stl
	@git -C $(BASEJUMP_STL_DIR) submodule update --init --recursive
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools checkout-riscv-gnu-tools
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools checkout-llvm

prep_lite: ## Minimal preparation for simulation
prep_lite:
	@$(eval export BP_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(eval export BP_RISCV_DIR=$(ZP_RISCV_DIR))
	@$(eval export RISCV_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(MAKE) -C $(BP_RTL_DIR) libs_lite
	@$(MAKE) -C $(BP_TOOLS_DIR) tools_lite
	@$(MAKE) -C $(BP_SDK_DIR) tools_lite
	@$(MAKE) -C $(BP_SDK_DIR) prog_lite
	@$(MAKE) -C $(BP_SUB_DIR) gen_lite

prep: ## Standard preparation for simulation
prep: prep_lite
	@$(eval export BP_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(eval export BP_RISCV_DIR=$(ZP_RISCV_DIR))
	@$(eval export RISCV_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(MAKE) -C $(BP_RTL_DIR) libs
	@$(MAKE) -C $(BP_TOOLS_DIR) tools
	@$(MAKE) -C $(BP_SDK_DIR) tools
	@$(MAKE) -C $(BP_SDK_DIR) prog
	@$(MAKE) -C $(BP_SUB_DIR) gen
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-gnu-tools

prep_bsg: ## Extra preparation for BSG users
prep_bsg: prep
	@$(eval export BP_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(eval export BP_RISCV_DIR=$(ZP_RISCV_DIR))
	@$(eval export RISCV_INSTALL_DIR=$(ZP_INSTALL_DIR))
	@$(MAKE) -C $(BP_RTL_DIR) libs_bsg
	@$(MAKE) -C $(BP_TOOLS_DIR) tools_bsg
	@$(MAKE) -C $(BP_SDK_DIR) tools_bsg
	@$(MAKE) -C $(BP_SDK_DIR) prog_bsg
	@$(MAKE) -C $(BP_SUB_DIR) gen_bsg
	@$(MAKE) -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-llvm

