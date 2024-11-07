TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

checkout: ## checkout submodules, but not recursively
	@$(MKDIR) -p $(ZP_TOUCH_DIR)
	@$(GIT) fetch --all
	@$(GIT) submodule sync
	@$(GIT) submodule update --init
	@$(MAKE) -C $(ZP_BP_RTL_DIR) checkout
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) checkout
	@$(MAKE) -C $(ZP_BP_SDK_DIR) checkout
	@$(MAKE) -C $(ZP_BP_SUB_DIR) checkout
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR) checkout_submodules
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools checkout-all

apply_patches: ## applies patches to submodules
apply_patches: build.patch
$(eval $(call bsg_fn_build_if_new,patch,$(CURDIR),$(ZP_TOUCH_DIR)))
%/.patch_build: checkout
	@$(MAKE) -C $(ZP_BP_RTL_DIR) apply_patches
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) apply_patches
	@$(MAKE) -C $(ZP_BP_SDK_DIR) apply_patches
	@$(MAKE) -C $(ZP_BP_SUB_DIR) apply_patches
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools build-deps

prep_lite: ## Minimal preparation for simulation
prep_lite: apply_patches
	@$(eval export PLATFORM := zynqparrot)
	@$(MAKE) -C $(ZP_BP_RTL_DIR) libs_lite
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) tools_lite
	@$(MAKE) -C $(ZP_BP_SDK_DIR) sdk_lite
	@$(MAKE) -C $(ZP_BP_SDK_DIR) prog_lite
	@$(MAKE) -C $(ZP_BP_SUB_DIR) gen_lite

prep: ## Standard preparation for simulation
prep: prep_lite
	@$(eval export PLATFORM := zynqparrot)
	@$(MAKE) -C $(ZP_BP_RTL_DIR) libs
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) tools
	@$(MAKE) -C $(ZP_BP_SDK_DIR) sdk
	@$(MAKE) -C $(ZP_BP_SDK_DIR) prog
	@$(MAKE) -C $(ZP_BP_SUB_DIR) gen
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-gnu-tools

prep_bsg: ## Extra preparation for BSG users
prep_bsg: prep
	@$(eval export PLATFORM := zynqparrot)
	@$(MAKE) -C $(ZP_BP_RTL_DIR) libs_bsg
	@$(MAKE) -C $(ZP_BP_TOOLS_DIR) tools_bsg
	@$(MAKE) -C $(ZP_BP_SDK_DIR) sdk_bsg
	@$(MAKE) -C $(ZP_BP_SDK_DIR) prog_bsg
	@$(MAKE) -C $(ZP_BP_SUB_DIR) gen_bsg
	@$(MAKE) -C $(ZP_BSG_MANYCORE_DIR)/software/riscv-tools build-llvm

