TOP ?= $(shell git rev-parse --show-toplevel)

include $(TOP)/Makefile.common
include $(TOP)/Makefile.config

include $(TOP)/software/mk/Makefile.env

.DEFAULT_GOAL := all

TARGET_NAME ?= x86
ifeq ($(TARGET_NAME),x86)
TARGET_CC        ?= $(X86_CC)
TARGET_SDK       ?= $(X86_SDK)
TARGET_WORK      ?= $(X86_WORK)
# These files aren't used for native compilation, but we
#   stub them out to reuse the makefile targets
TARGET_TEMPLATE  ?= dummy
TARGET_PROJ      ?= $(TARGET_WORK)/dummy.proj
TARGET_XSA       ?= $(TARGET_WORK)/dummy.xsa
TARGET_TCL       ?= $(TARGET_WORK)/dummy.tcl
TARGET_ENV       ?= $(X86_ENV)

TARGET_RISCV64 ?= $(TARGET_SDK)/bin/riscv64-unknown-elf-dramfs-gcc
TARGET_RISCV32 ?= $(TARGET_SDK)/bin/riscv32-unknown-elf-dramfs-gcc
TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/dummy.a
TARGET_OPENOCD ?= $(TARGET_SDK)/bin/openocd
TARGET_DROMAJO ?= $(TARGET_SDK)/bin/dromajo

dummy.%:
	mkdir -p $(@D)
	mkdir -p $(TARGET_WORK)
	mkdir -p $(TARGET_SDK)
	touch $@

$(TARGET_ENV):
	mkdir -p $(@D)
	@$(eval reg_vars := $(filter-out .%,$(sort $(.VARIABLES))))
	@$(eval env_vars := $(foreach V, $(reg_vars), \
		$(if $(filter-out environment% default automatic undefined, $(origin $V)), \
			'$V="$($V)"')))
	for e in ${env_vars}; \
	 do \
		echo "$$e" >> $@; \
	 done
	sed -i "/CURDIR/d" $@
	sed -i "/CURR_/d" $@
	sed -i "/MAKE/d" $@
	sed -i "/PART/d" $@

else ifeq ($(TARGET_NAME),pynqz2)
TARGET_CC        ?= $(PYNQZ2_CC)
TARGET_WORK      ?= $(PYNQZ2_WORK)
TARGET_SDK       ?= $(PYNQZ2_SDK)
TARGET_TEMPLATE  ?= zynq
TARGET_PROJ      ?= $(TARGET_NAME)_proj
TARGET_XSA       ?= $(TARGET_WORK)/$(TARGET_NAME)_basic.xsa
TARGET_TCL       ?= $(SOFTWARE_TCL_DIR)/vivado-gen-xsa-$(TARGET_NAME).tcl
TARGET_ENV       ?= $(PYNQZ2_ENV)

TARGET_RISCV64 ?= $(TARGET_SDK)/bin/riscv64-unknown-elf-dramfs-gcc
TARGET_RISCV32 ?= $(TARGET_SDK)/bin/riscv32-unknown-elf-dramfs-gcc
TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/libpynq.a
TARGET_OPENOCD ?= $(TARGET_SDK)/bin/openocd
TARGET_DROMAJO ?= $(TARGET_SDK)/bin/dromajo
else ifeq ($(TARGET_NAME),ultra96v2)
TARGET_CC        ?= aarch64-xilinx-linux-gnueabi
TARGET_WORK      ?= $(ULTRA96V2_WORK)
TARGET_SDK       ?= $(ULTRA96V2_SDK)
TARGET_TEMPLATE  ?= zynqMP
TARGET_PROJ      ?= $(TARGET_NAME)_proj
TARGET_XSA       ?= $(TARGET_WORK)/$(TARGET_NAME)_basic.xsa
TARGET_TCL       ?= $(SOFTWARE_TCL_DIR)/vivado-gen-xsa-$(TARGET_NAME).tcl
TARGET_ENV       ?= $(ULTRA96V2_ENV)

TARGET_RISCV64 ?= $(TARGET_SDK)/bin/riscv64-unknown-elf-dramfs-gcc
TARGET_RISCV32 ?= $(TARGET_SDK)/bin/riscv32-unknown-elf-dramfs-gcc
TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/libpynq.a
TARGET_OPENOCD ?= $(TARGET_SDK)/bin/openocd
TARGET_DROMAJO ?= $(TARGET_SDK)/bin/dromajo
else
$(error Unknown TARGET_NAME $(TARGET_NAME) for software)
endif

all: verilator pynq openocd dromajo riscv32

riscv64: $(TARGET_RISCV64)
%/bin/riscv64-unknown-elf-dramfs-gcc: export RISCV64_SOURCE_DIR := $(BLACKPARROT_SDK_DIR)/riscv-gnu-toolchain
%/bin/riscv64-unknown-elf-dramfs-gcc: export RISCV64_BUILD_DIR := $(TARGET_WORK)/riscv64_build
%/bin/riscv64-unknown-elf-dramfs-gcc: export RISCV64_INSTALL_DIR := $(TARGET_SDK)
%/bin/riscv64-unknown-elf-dramfs-gcc: export NEWLIB_TUPLE := riscv64-unknown-elf-dramfs
%/bin/riscv64-unknown-elf-dramfs-gcc: | $(TARGET_ENV)
	mkdir -p $(@D) $(RISCV64_BUILD_DIR)
	cd $(RISCV64_BUILD_DIR); source $(TARGET_ENV) && \
		$(RISCV64_SOURCE_DIR)/configure \
		--prefix=$(TARGET_SDK) \
		--disable-linux --disable-gdb --with-abi=lp64d --disable-qemu-system --with-arch=rv64gcb --with-tune=bsg_blackparrot \
		--with-target-cflags="-mstrict-align -mcmodel=medany" \
		--with-target-cxxflags="-mstrict-align -mcmodel=medany"; \
		$(MAKE)
	cp $(RISCV64_INSTALL_DIR)/riscv64-unknown-elf-dramfs/bin/dramfs_mklfs $(TARGET_SDK)/bin/dramfs_mklfs

riscv32: $(TARGET_RISCV32)
%/bin/riscv32-unknown-elf-dramfs-gcc: export RISCV32_SOURCE_DIR := $(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-gnu-toolchain
%/bin/riscv32-unknown-elf-dramfs-gcc: export RISCV32_BUILD_DIR := $(TARGET_WORK)/riscv32_build
%/bin/riscv32-unknown-elf-dramfs-gcc: export RISCV32_INSTALL_DIR := $(TARGET_SDK)
%/bin/riscv32-unknown-elf-dramfs-gcc: | $(TARGET_ENV)
	mkdir -p $(@D) $(RISCV32_BUILD_DIR)
	cd $(RISCV32_BUILD_DIR); source $(TARGET_ENV) && \
		cp $(BSG_MANYCORE_DIR)/software/riscv-tools/Makefile .; \
		cp $(BSG_MANYCORE_DIR)/software/riscv-tools/spike.patch .; \
		cp $(BSG_MANYCORE_DIR)/software/riscv-tools/spike-gcc.patch .; \
		$(MAKE) build-deps;
	cd $(RISCV32_BUILD_DIR); source $(TARGET_ENV) && \
		$(RISCV32_SOURCE_DIR)/configure \
		--prefix=$(TARGET_SDK) \
		--disable-linux --disable-gdb --with-abi=ilp32f --with-arch=rv32imaf --with-tune=bsg_vanilla_2020; \
		$(MAKE) CFLAGS_FOR_TARGET_EXTRA='-fno-common'

dromajo: $(TARGET_DROMAJO)
%/bin/dromajo: export DROMAJO_BUILD_DIR := $(TARGET_WORK)/dromajo_build
%/bin/dromajo: export DROMAJO_INSTALL_DIR := $(TARGET_SDK)
%/bin/dromajo: | $(TARGET_ENV)
	mkdir -p $(@D) $(DROMAJO_BUILD_DIR)
	cd $(DROMAJO_BUILD_DIR); source $(TARGET_ENV) && \
		cmake -S $(BLACKPARROT_TOOLS_DIR)/dromajo -DCMAKE_BUILD_TYPE=Release; \
		find . -name "flags.make" -exec sed -i "s/-march=native -mtune=native//g" {} \;
	cd $(TARGET_WORK)/dromajo_build; source $(TARGET_ENV) && \
		$(MAKE) VLEN=0; \
		cp dromajo $(TARGET_SDK)/bin; \
		cp libdromajo_cosim.a $(TARGET_SDK)/lib; \
		cp $(BLACKPARROT_TOOLS_DIR)/dromajo/include/dromajo_cosim.h $(TARGET_SDK)/include;

openocd: $(TARGET_OPENOCD)
%/bin/openocd: export OPENOCD_BUILD_DIR := $(TARGET_WORK)/openocd_build
%/bin/openocd: export OPENOCD_AUTOTOOLS_DIR := $(TARGET_WORK)/autotools
%/bin/openocd: export OPENOCD_CONFIG := --enable-remote-bitbang
%/bin/openocd: | $(TARGET_ENV)
	mkdir -p $(@D) $(OPENOCD_BUILD_DIR)
	git clone --recurse-submodules -b riscv https://github.com/riscv-collab/riscv-openocd $(OPENOCD_BUILD_DIR)/riscv-openocd
ifneq (,$(findstring centos,$(shell python -m platform)))
	cd $(OPENOCD_BUILD_DIR)/; wget -qO- http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz | tar xzv
	cd $(OPENOCD_BUILD_DIR)/; wget -qO- http://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz | tar xzv
	cd $(OPENOCD_BUILD_DIR)/; wget -qO- http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz | tar xzv
	cd $(OPENOCD_BUILD_DIR)/; wget -qO- https://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz | tar xzv
	cd $(OPENOCD_BUILD_DIR)/automake-1.15;   ./configure --prefix=$(OPENOCD_AUTOTOOLS_DIR); make install
	cd $(OPENOCD_BUILD_DIR)/autoconf-2.69;   ./configure --prefix=$(OPENOCD_AUTOTOOLS_DIR); make install
	cd $(OPENOCD_BUILD_DIR)/libtool-2.4.6;   ./configure --prefix=$(OPENOCD_AUTOTOOLS_DIR); make install
	cd $(OPENOCD_BUILD_DIR)/pkg-config-0.28; ./configure --prefix=$(OPENOCD_AUTOTOOLS_DIR); make install
endif
	cd $(OPENOCD_BUILD_DIR)/riscv-openocd; source $(TARGET_ENV) && \
		PATH=$(OPENOCD_AUTOTOOLS_DIR)/bin:$(PATH) ./bootstrap; \
		cp {build-aux/,}config.guess;
	cd $(OPENOCD_BUILD_DIR)/riscv-openocd; source $(TARGET_ENV) && \
		./contrib/cross-build.sh $(TARGET_CC); \
		cp $(OPENOCD_BUILD_DIR)/riscv-openocd/$(TARGET_CC)-root/usr/bin/openocd $@

pynq: $(TARGET_PYNQ)
%/lib/libpynq.a: export PYNQ_BUILD_DIR := $(TARGET_WORK)/pynq_build
%/lib/libpynq.a: | $(TARGET_ENV)
	mkdir -p $(@D) $(PYNQ_BUILD_DIR)
	git clone --recurse-submodules -b image_v2.6.0 https://github.com/Xilinx/PYNQ.git $(PYNQ_BUILD_DIR)/PYNQ
	git clone --recurse-submodules -b master https://github.com/mesham/pynq_api.git $(PYNQ_BUILD_DIR)/pynq_api
	cd $(PYNQ_BUILD_DIR)/pynq_api; source $(TARGET_ENV) && \
		sed -i "/CC.*=/d" makefile; \
		sed -i "s#CFLAGS.*$$#$$CFLAGS -I$(TARGET_WORK)/PYNQ/sdbuild/packages/libsds/libcma#g" makefile; \
		$(MAKE) all;
	cd $(PYNQ_BUILD_DIR)/pynq_api; source $(TARGET_ENV) && \
		cp ./libpynq.a $(@D); \
		cp ./libpynq.so $(@D); \
		cp ./src/pynq_api.h $(@D);

verilator: $(TARGET_VERILATOR)
%/bin/verilator: export VERILATOR_BUILD_DIR := $(TARGET_WORK)/verilator_build
%/bin/verilator: export VERILATOR_SOURCE_DIR := $(BLACKPARROT_TOOLS_DIR)/verilator
%/bin/verilator: | $(TARGET_ENV)
	mkdir -p $(@D) $(VERILATOR_BUILD_DIR)
	cd $(VERILATOR_SOURCE_DIR); source $(TARGET_ENV) && \
		autoreconf -i
	cd $(VERILATOR_BUILD_DIR); source $(TARGET_ENV) && \
		$(VERILATOR_SOURCE_DIR)/configure --prefix=$(TARGET_SDK); \
		$(MAKE) all && $(MAKE) installbin installdata install-msg

environment-setup: | $(TARGET_ENV)
environment-setup-%: export PETALINUX_BUILD_DIR := $(TARGET_WORK)/petalinux_build
environment-setup-%: export PETALINUX_PROJ := $(PETALINUX_BUILD_DIR)/$(TARGET_PROJ)
environment-setup-%:
	mkdir -p $(@D) $(PETALINUX_BUILD_DIR)
	cd $(PETALINUX_BUILD_DIR); \
		$(VIVADO_RUN) -source $(TARGET_TCL)
	cd $(PETALINUX_BUILD_DIR); \
		$(PETALINUX_RUN)-create --type project --template $(TARGET_TEMPLATE) --name $(TARGET_PROJ); \
		$(PETALINUX_RUN)-config --verbose --silentconfig --get-hw-description $< --project $(TARGET_PROJ); \
		$(PETALINUX_RUN)-build --sdk --project $(TARGET_PROJ); \
	cd $(PETALINUX_BUILD_DIR)/$(TARGET_PROJ); \
		$(PETALINUX_RUN)-package --sysroot --sdk=images/linux/sdk.sh; \
		mv images/linux/sdk/environment-setup-* $@

clean:
	rm -rf $(TARGET_ENV)
	rm -rf $(TARGET_WORK)
	rm -rf $(SOFTWARE_INSTALL_DIR)/$(TARGET_NAME)

