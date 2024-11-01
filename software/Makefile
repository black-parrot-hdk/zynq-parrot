TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

.PHONY: bp-progs
bp-progs: ## Build test program suite for BlackParrot
bp-progs: $(SOFTWARE_DIR)/prog | $(TARGET_ENV)
ifeq ($(TARGET_NAME),x86)
	@$(eval export BP_SDK_PROG_DIR = $^)
	@$(ENV_SETUP) && $(MAKE) -C $(BLACKPARROT_SDK_DIR) bedrock linker
	@$(ENV_SETUP) && $(MAKE) -C $(BLACKPARROT_SDK_DIR) prog_lite;
	@$(ENV_SETUP) && $(MAKE) -C $(BLACKPARROT_SDK_DIR) linux;
else
	@$(error bp-progs should only be run on x86)
endif

.PHONY: riscv64
riscv64: ## BlackParrot riscv64-unknown-elf-dramfs toolchain
riscv64: $(TARGET_RISCV64)
%/bin/riscv64-unknown-elf-dramfs-gcc: $(TARGET_RISCV64_DEPS) | $(TARGET_ENV)
	@$(eval RISCV64_BUILD_DIR := $(TARGET_WORK)/riscv64_build)
	@$(eval RISCV64_SOURCE_DIR := $(BLACKPARROT_SDK_DIR)/riscv-gnu-toolchain)
	@$(eval RISCV64_CONFIGURE_FLAGS := --disable-linux --disable-gdb --disable-qemu-system)
	@$(eval RISCV64_CONFIGURE_FLAGS += --with-multilib-generator="rv64g-lp64d--;rv64gcb-lp64d--")
	@$(eval RISCV64_CONFIGURE_FLAGS += --with-cmodel=medany --with-tune=bsg_blackparrot)
	@$(eval export NEWLIB_TUPLE=riscv64-unknown-elf-dramfs)
	@$(MKDIR) $(@D) $(RISCV64_BUILD_DIR)
	@$(CD) $(RISCV64_BUILD_DIR); $(ENV_SETUP) && \
		$(RISCV64_SOURCE_DIR)/configure $${CONFIGURE_FLAGS} $(RISCV64_CONFIGURE_FLAGS); \
		$(MAKE) CFLAGS_FOR_TARGET_EXTRA="-mstrict-align -mcmodel=medany"; \
		$(CP) $(TARGET_SDK)/riscv64-unknown-elf-dramfs/bin/dramfs_mklfs $(TARGET_SDK)/bin/dramfs_mklfs;

.PHONY: riscv32
riscv32: ## HammerBlade riscv32-unknown-elf-dramfs toolchain
riscv32: $(TARGET_RISCV32)
%/bin/riscv32-unknown-elf-dramfs-gcc: $(TARGET_RISCV32_DEPS) | $(TARGET_ENV)
	@$(eval RISCV32_BUILD_DIR := $(TARGET_WORK)/riscv32_build)
	@$(eval RISCV32_SOURCE_DIR := $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain)
	@$(eval RISCV32_CONFIGURE_FLAGS := --disable-linux --disable-gdb)
	@$(eval RISCV32_CONFIGURE_FLAGS += --with-abi=ilp32f --with-arch=rv32imaf)
	@$(eval RISCV32_CONFIGURE_FLAGS += --with-tune=bsg_vanilla_2020)
	@$(eval export RISCV_INSTALL_DIR=$(TARGET_SDK))
	@$(MKDIR) $(@D) $(RISCV32_BUILD_DIR)
	@$(CD) $(RISCV32_BUILD_DIR); $(ENV_SETUP) && \
		$(RISCV32_SOURCE_DIR)/configure $${CONFIGURE_FLAGS} $(RISCV32_CONFIGURE_FLAGS); \
		$(MAKE) CFLAGS_FOR_TARGET_EXTRA='-fno-common'
	@$(ECHO) "Successfully built $@!"

.PHONY: dromajo
dromajo: ## RISC-V co-simulation libraries and binary
dromajo: $(TARGET_DROMAJO)
%/bin/dromajo: $(TARGET_DROMAJO_DEPS) | $(TARGET_ENV)
	$(eval DROMAJO_BUILD_DIR := $(TARGET_WORK)/dromajo_build)
	$(eval DROMAJO_SOURCE_DIR := $(BLACKPARROT_TOOLS_DIR)/dromajo)
	$(MKDIR) $(@D) $(DROMAJO_BUILD_DIR)
	$(CD) $(DROMAJO_BUILD_DIR); $(ENV_SETUP) && \
	   $(CMAKE) -S $(BLACKPARROT_TOOLS_DIR)/dromajo -DCMAKE_BUILD_TYPE=Release; \
	   $(FINDHERE) -name "flags.make" -exec $(SED_I) "s/-march=native -mtune=native//g" {} \;
	$(CD) $(TARGET_WORK)/dromajo_build; $(ENV_SETUP) && \
	   $(MAKE) VLEN=0; \
	   $(CP) dromajo $(TARGET_SDK)/bin; \
	   $(CP) libdromajo_cosim.a $(TARGET_SDK)/lib; \
	   $(CP) $(BLACKPARROT_TOOLS_DIR)/dromajo/include/dromajo_cosim.h $(TARGET_SDK)/include;
	$(ECHO) "Successfully built $@!"

.PHONY: openocd
openocd: ## Experimental build to allow us to run gdbserver on remote
openocd: $(TARGET_OPENOCD)
%/bin/openocd: $(TARGET_OPENOCD_DEPS) | $(TARGET_ENV)
	@$(eval OPENOCD_BUILD_DIR := $(TARGET_WORK)/openocd_build)
	@$(eval OPENOCD_SOURCE_DIR := $(OPENOCD_BUILD_DIR)/riscv-openocd)
	@$(eval OPENOCD_DEPS_DIR := $(TARGET_WORK)/openocd_deps)
	@$(eval OPENOCD_CONFIGURE_FLAGS := "--enable-remote-bitbang")
	@$(eval unexport MAKEFLAGS)
	@$(MKDIR) $(@D) $(OPENOCD_BUILD_DIR)
	@$(GCLONE) -b riscv https://github.com/riscv-collab/riscv-openocd $(OPENOCD_SOURCE_DIR)
	@$(CD) $(OPENOCD_SOURCE_DIR); $(ENV_SETUP) && \
		PATH=$(OPENOCD_DEPS_DIR)/bin:$${PATH} \
			./bootstrap; \
		$(CP) {build-aux/,}config.guess;
	@$(CD) $(OPENOCD_SOURCE_DIR); $(ENV_SETUP) && \
		./configure $${CONFIGURE_FLAGS} $(OPENOCD_CONFIGURE_FLAGS); \
		$(MAKE) all; \
		$(MAKE) install
	@$(CP) $(OPENOCD_SOURCE_DIR)/src/$(@F) $(TARGET_SDK)/bin/$(@F)
	@$(ECHO) "Successfully built $@!"

.PHONY: libpynq
libpynq: ## Official Xilinx pynq libraries and header files
libpynq: $(TARGET_LIBPYNQ)
%/lib/libpynq.a: $(TARGET_LIBPYNQ_DEPS) | $(TARGET_ENV)
	@$(eval export LIBPYNQ_BUILD_DIR := $(TARGET_WORK)/pynq_build)
	@$(MKDIR) $(@D) $(LIBPYNQ_BUILD_DIR)
	@$(GCLONE) -b image_v2.6.0 https://github.com/Xilinx/PYNQ.git $(LIBPYNQ_BUILD_DIR)/PYNQ
	@$(GCLONE) -b master https://github.com/mesham/pynq_api.git $(LIBPYNQ_BUILD_DIR)/pynq_api
	@$(CD) $(LIBPYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && $(SED_I) "/^CC/d" makefile;
	@$(CD) $(LIBPYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && $(SED_I) "s#^CFLAGS.*#CFLAGS = $$CFLAGS -I$(LIBPYNQ_BUILD_DIR)/PYNQ/sdbuild/packages/libsds/libcma#g" makefile;
	@$(CD) $(LIBPYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && $(MAKE) all;
	@$(CD) $(LIBPYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && \
		$(CP) ./libpynq.a $(@D); \
		$(CP) ./libpynq.so $(@D); \
		$(CP) ./src/pynq_api.h $(@D);
	@$(ECHO) "Successfully built $@!"

.PHONY: verilator
verilator: ## Open-source RTL simulator for alternative co-simulation
verilator: $(TARGET_VERILATOR)
%/bin/verilator: export VERILATOR_BUILD_DIR := $(TARGET_WORK)/verilator_build
%/bin/verilator: $(TARGET_VERILATOR_DEPS) | $(TARGET_ENV)
	@$(eval export VERILATOR_BUILD_DIR := $(TARGET_WORK)/verilator_build)
	@$(eval export VERILATOR_SOURCE_DIR := $(BLACKPARROT_TOOLS_DIR)/verilator)
	@$(MKDIR) $(@D) $(VERILATOR_BUILD_DIR)
	@$(CD) $(VERILATOR_SOURCE_DIR); $(ENV_SETUP) && \
		$(AUTOCONF)
	@$(CD) $(VERILATOR_BUILD_DIR); $(ENV_SETUP) && \
		$(VERILATOR_SOURCE_DIR)/configure $${CONFIGURE_FLAGS};
	@$(CD) $(VERILATOR_BUILD_DIR); $(ENV_SETUP) && \
		$(MAKE) all && $(MAKE) installbin installdata install-msg
	@$(ECHO) "Successfully built $@!"

.PHONY: environment-reconfig
environment-reconfig: ## Reconfigure the environment in-place, w/o rebuilding
environment-reconfig:
	@if [ -f "$(TARGET_ENV)" ]; then \
		$(ECHO) "Saving $(TARGET_ENV) to $(TARGET_ENV).old"; \
		$(MV) $(TARGET_ENV){,.old}; \
	fi
	@$(MAKE) $(TARGET_ENV)
	@$(ECHO) "Successfully regenerated $@!"

# Note:
#   sudo ln -s /usr/arm-linux-gnueabihf/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3
#   https://stackoverflow.com/questions/47787562/u-boot-lib-ld-linux-armhf-so-3-no-such-file-or-directory
.PHONY: environment-setup
environment-setup: ## Creates the SDK environment for a specific TARGET_NAME
environment-setup: $(TARGET_ENV)
environment-setup-%:
	@$(eval XSA_BUILD_DIR := $(TARGET_WORK)/xsa_build)
	@$(eval XSA_FILE := $(XSA_BUILD_DIR)/basic.xsa)
	@$(eval PETALINUX_PROJ := $(TARGET_SDK)/petalinux_proj)
	@$(MKDIR) $(@D) $(TARGET_SDK)/bin $(TARGET_SDK)/lib $(TARGET_SDK)/include $(XSA_BUILD_DIR)
	@$(CD) $(XSA_BUILD_DIR); \
		$(VIVADO_RUN) -mode batch -source $(TARGET_TCL);
	@$(CD) $(TARGET_SDK); \
		$(PETALINUX_RUN)-create --type project --template $(TARGET_TEMPLATE) --name $(notdir $(PETALINUX_PROJ)); \
		$(PETALINUX_RUN)-config --verbose --silentconfig --get-hw-description $(XSA_FILE) --project $(notdir $(PETALINUX_PROJ)); \
		$(PETALINUX_RUN)-build --sdk --project $(notdir $(PETALINUX_PROJ));
	#@$(CD) $(PETALINUX_PROJ); \
	#	$(PETALINUX_RUN)-package --sysroot --sdk=images/linux/sdk.sh; \
	#	$(MV) images/linux/sdk/environment-setup-* $@;
	#@$(ECHO) "#######################################" >> $@
	#@$(ECHO) "# Extra Environment Manipulation ######" >> $@
	#@$(ECHO) "#######################################" >> $@
	#@$(ECHO) "# unset default exported variables for submake" >> $@
	#@$(ECHO) "# but keep threads " >> $@
	#@$(ECHO) "unset SHELL" >> $@
	#@$(ECHO) "# append new paths MAKEFLAGS for submake" >> $@
	#@$(ECHO) "export PATH=\"\$${TARGET_SDK}/bin:\$${PATH}"\" >> $@
	#@$(ECHO) "export CONFIGURE_FLAGS=\"\$${CONFIGURE_FLAGS} --prefix=$(TARGET_SDK)\"" >> $@
	#@$(ECHO) "" >> $@
	#@$(MKEXE) $@
	#@$(ECHO) "Successfully built $@!"

.PHONY: all
all: ## Make all targets for SDK
all: libpynq dromajo openocd verilator riscv32 riscv64
	@$(ECHO) "Successfully built:"
	@$(ECHO) "	$^"
	@$(ECHO) "for SDK:"
	@$(ECHO) "$(TARGET_SDK)!"

.PHONY: clean.%
clean.%: ## Cleans the work directory for a specific TARGET_NAME
clean.%:
	if [[ "$*" =~ ^[a-zA-Z0-9]+$$ ]]; then \
		echo "Cleaning $*"; \
		$(RMRF) $(SOFTWARE_INSTALL_DIR)/$*/work; \
	fi

.PHONY: clean.all
clean.all: ## Cleans all target work and install directories
clean.all:
	@$(RMRF) $(wildcard $(SOFTWARE_INSTALL_DIR)/*/work)

.PHONY: bleach.%
bleach.%: ## Cleans the work directory for a specific TARGET_NAME
bleach.%:
	@if [[ "$*" =~ ^[a-zA-Z0-9]+$$ ]]; then \
		$(ECHO) "Bleaching $*"; \
		$(RMRF) $(SOFTWARE_INSTALL_DIR)/$*; \
	fi

.PHONY: bleach.all
bleach.all: ## Bleaches all target work and install directories
bleach.all:
	@for d in $(SOFTWARE_INSTALL_DIR)/*; do \
		$(ECHO) "Bleaching $$d"; \
		$(RMRF) $(wildcard $(SOFTWARE_INSTALL_DIR)/*); \
	done


