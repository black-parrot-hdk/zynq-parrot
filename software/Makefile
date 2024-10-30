TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(SOFTWARE_DIR)/mk/Makefile.env

.DEFAULT_GOAL := help

help: ## Show this help
	  @$(EGREP) -h '\s##\s' $(MAKEFILE_LIST) \
		  | $(AWK) 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'

# We build these on host because there's no problem
bp-progs:
	$(eval BP_SDK_PROG_DIR = $(SOFTWARE_DIR)/prog)
	$(ENV_SETUP) && $(MAKE) -C $(BLACKPARROT_SDK_DIR) bedrock linker
	$(ENV_SETUP) && $(MAKE) -C $(BLACKPARROT_SDK_DIR) prog_lite;
	# Linux build doesn't work with ENV SETUP currently
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) linux;

riscv64: ## BlackParrot riscv64-unknown-elf-dramfs toolchain
riscv64: $(TARGET_RISCV64)
%/bin/riscv64-unknown-elf-dramfs-gcc: $(TARGET_RISCV64_DEPS) | $(TARGET_ENV)
	$(eval RISCV64_BUILD_DIR := $(TARGET_WORK)/riscv64_build)
	$(eval RISCV64_SOURCE_DIR := $(BLACKPARROT_SDK_DIR)/riscv-gnu-toolchain)
	$(eval RISCV64_CONFIGURE_FLAGS := --disable-linux --disable-gdb --disable-qemu-system)
	$(eval RISCV64_CONFIGURE_FLAGS += --with-multilib-generator="rv64g-lp64d--;rv64gcb-lp64d--")
	$(eval RISCV64_CONFIGURE_FLAGS += --with-cmodel=medany --with-tune=bsg_blackparrot)
	$(eval export NEWLIB_TUPLE=riscv64-unknown-elf-dramfs)
	$(MKDIR) $(@D) $(RISCV64_BUILD_DIR)
	$(CD) $(RISCV64_BUILD_DIR); $(ENV_SETUP) && \
		$(RISCV64_SOURCE_DIR)/configure --prefix=$(TARGET_SDK) $(RISCV64_CONFIGURE_FLAGS); \
		$(MAKE) CFLAGS_FOR_TARGET_EXTRA="-mstrict-align -mcmodel=medany"; \
		$(CP) $(TARGET_SDK)/riscv64-unknown-elf-dramfs/bin/dramfs_mklfs $(TARGET_SDK)/bin/dramfs_mklfs; \

riscv32: ## HammerBlade riscv32-unknown-elf-dramfs toolchain
riscv32: $(TARGET_RISCV32)
%/bin/riscv32-unknown-elf-dramfs-gcc: $(TARGET_RISCV32_DEPS) | $(TARGET_ENV)
	$(eval RISCV32_BUILD_DIR := $(TARGET_WORK)/riscv32_build)
	$(eval RISCV32_SOURCE_DIR := $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain)
	$(eval RISCV32_CONFIGURE_FLAGS := --disable-linux --disable-gdb)
	$(eval RISCV32_CONFIGURE_FLAGS += --with-abi=ilp32f --with-arch=rv32imaf)
	$(eval RISCV32_CONFIGURE_FLAGS += --with-tune=bsg_vanilla_2020)
	$(eval export RISCV_INSTALL_DIR=$(TARGET_SDK))
	$(MKDIR) $(@D) $(RISCV32_BUILD_DIR)
	$(CP) $(BSG_MANYCORE_DIR)/software/riscv-tools/Makefile $(RISCV32_BUILD_DIR)
	$(CD) $(RISCV32_BUILD_DIR); $(ENV_SETUP) && \
		$(MAKE) checkout-deps; \
		$(MAKE) build-deps;
	$(CD) $(RISCV32_BUILD_DIR); $(ENV_SETUP) && \
		$(RISCV32_SOURCE_DIR)/configure --prefix=$(TARGET_SDK) $(RISCV32_CONFIGURE_FLAGS); \
		$(MAKE) CFLAGS_FOR_TARGET_EXTRA='-fno-common'

dromajo: ## For co-simulation libraries
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

openocd: ## Experimental build to allow us to run gdbserver on remote
openocd: $(TARGET_OPENOCD)
%/bin/openocd: $(TARGET_OPENOCD_DEPS) | $(TARGET_ENV)
	$(eval OPENOCD_BUILD_DIR := $(TARGET_WORK)/openocd_build)
	$(eval OPENOCD_SOURCE_DIR := $(OPENOCD_BUILD_DIR)/riscv-openocd)
	$(eval OPENOCD_DEPS_DIR := $(TARGET_WORK)/openocd_deps)
	$(MKDIR) $(@D) $(OPENOCD_BUILD_DIR)
	$(GCLONE) -b riscv https://github.com/riscv-collab/riscv-openocd $(OPENOCD_SOURCE_DIR)
	$(CD) $(OPENOCD_SOURCE_DIR); $(ENV_SETUP) && \
		PATH=$(OPENOCD_DEPS_DIR)/bin:$(PATH) \
			./bootstrap; \
		$(CP) {build-aux/,}config.guess;
	$(CD) $(OPENOCD_SOURCE_DIR); $(ENV_SETUP) && \
		OPENOCD_CONFIG=--enable-remote-bitbang \
			./contrib/cross-build.sh $(TARGET_CC);
	$(CP) $(OPENOCD_BUILD_DIR)/riscv-openocd/$(TARGET_CC)-root/usr/bin/openocd $@

pynq: ## Official Xilinx pynq libraries and header files
pynq: $(TARGET_PYNQ)
%/lib/libpynq.a: $(TARGET_PYNQ_DEPS) | $(TARGET_ENV)
	$(eval export PYNQ_BUILD_DIR := $(TARGET_WORK)/pynq_build)
	$(MKDIR) $(@D) $(PYNQ_BUILD_DIR)
	$(GCLONE) -b image_v2.6.0 https://github.com/Xilinx/PYNQ.git $(PYNQ_BUILD_DIR)/PYNQ
	$(GCLONE) -b master https://github.com/mesham/pynq_api.git $(PYNQ_BUILD_DIR)/pynq_api
	$(CD) $(PYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && $(SED_I) "/^CC/d" makefile;
	$(CD) $(PYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && $(SED_I) "s#^CFLAGS.*#CFLAGS = $$CFLAGS -I$(PYNQ_BUILD_DIR)/PYNQ/sdbuild/packages/libsds/libcma#g" makefile;
	$(CD) $(PYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && $(MAKE) all;
	$(CD) $(PYNQ_BUILD_DIR)/pynq_api; $(ENV_SETUP) && \
		$(CP) ./libpynq.a $(@D); \
		$(CP) ./libpynq.so $(@D); \
		$(CP) ./src/pynq_api.h $(@D);

verilator: ## Open-source RTL simulator for alternative co-simulation
verilator: $(TARGET_VERILATOR)
%/bin/verilator: export VERILATOR_BUILD_DIR := $(TARGET_WORK)/verilator_build
%/bin/verilator: export VERILATOR_SOURCE_DIR := $(BLACKPARROT_TOOLS_DIR)/verilator
%/bin/verilator: $(TARGET_VERILATOR_DEPS) | $(TARGET_ENV)
	$(MKDIR) $(@D) $(VERILATOR_BUILD_DIR)
	$(CD) $(VERILATOR_SOURCE_DIR); $(ENV_SETUP) && \
		$(AUTORECONF) -i
	$(CD) $(VERILATOR_BUILD_DIR); $(ENV_SETUP) && \
		$(VERILATOR_SOURCE_DIR)/configure \
			--prefix=$(TARGET_SDK) \
			--build=$(HOST_CC) \
			--host=$(TARGET_CC) \
			--target=$(TARGET_CC); \
		$(MAKE) all && $(MAKE) installbin installdata install-msg

environment-reconfig: ## Reconfigure the environment in-place, w/o rebuilding
environment-reconfig:
	@if [ -f "$(TARGET_ENV)" ]; then \
		$(ECHO) "Saving $(TARGET_ENV) to $(TARGET_ENV).old"; \
	fi
	$(MV) $(TARGET_ENV){,.old}
	$(MAKE) $(TARGET_ENV)

environment-setup: ## Creates the SDK environment for a specific TARGET_NAME
environment-setup: $(TARGET_ENV)
environment-setup-%: | $(TARGET_DIRS)
	$(eval XSA_BUILD_DIR := $(TARGET_WORK)/xsa_build)
	$(eval XSA_FILE := $(XSA_BUILD_DIR)/basic.xsa)
	$(eval PETALINUX_PROJ := $(TARGET_SDK)/petalinux_proj)
	$(MKDIR) $(@D) $(XSA_BUILD_DIR)
	$(CD) $(XSA_BUILD_DIR); \
		$(VIVADO_RUN) -source $(TARGET_TCL);
	$(CD) $(TARGET_SDK); \
		$(PETALINUX_RUN)-create --type project --template $(TARGET_TEMPLATE) --name $(notdir $(PETALINUX_PROJ)); \
		$(PETALINUX_RUN)-config --verbose --silentconfig --get-hw-description $(XSA_FILE) --project $(notdir $(PETALINUX_PROJ)); \
		$(PETALINUX_RUN)-build --sdk --project $(notdir $(PETALINUX_PROJ));
	$(CD) $(PETALINUX_PROJ); \
		$(PETALINUX_RUN)-package --sysroot --sdk=images/linux/sdk.sh; \
		$(MV) images/linux/sdk/environment-setup-* $@

all: ## Make all targets for SDK
#all: pynq dromajo openocd verilator riscv32 riscv64
all: pynq dromajo openocd verilator

clean.%: ## Cleans the work directory for a specific TARGET_NAME
clean.%:
	if [[ "$*" =~ ^[a-zA-Z0-9]+$$ ]] ; then \
		echo "Cleaning $*"; \
		$(RMRF) $(SOFTWARE_INSTALL_DIR)/$*/work; \
	fi

clean.all: ## Cleans all target work and install directories
clean.all:
	$(RMRF) $(wildcard $(SOFTWARE_INSTALL_DIR)/*/work)

bleach.%: ## Cleans the work directory for a specific TARGET_NAME
bleach.%:
	if [[ "$*" =~ ^[a-zA-Z0-9]+$$ ]] ; then \
		echo "Bleaching $*"; \
		$(RMRF) $(SOFTWARE_INSTALL_DIR)/$*; \
	fi

bleach.all: ## Bleaches all target work and install directories
bleach.all:
	$(RMRF) $(wildcard $(SOFTWARE_INSTALL_DIR)/*)

