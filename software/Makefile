TOP ?= $(shell git rev-parse --show-toplevel)

include $(TOP)/Makefile.common
include $(TOP)/Makefile.config

include $(TOP)/software/mk/Makefile.env

.DEFAULT_GOAL := all

ifneq (,$(findstring Ubuntu,$(shell python -m platform)))
HOST_CC ?= x86_64-linux-gnu
else ifneq (,$(findstring centos,$(shell python -m platform)))
HOST_CC ?= x86_64-redhat-linux
else
$(error Unknown x86 host!)
endif

TARGET_NAME ?=
ifeq ($(TARGET_NAME),x86)
TARGET_CC        ?= $(HOST_CC)
TARGET_TEMPLATE  ?= zynq
TARGET_SDK       ?= $(SOFTWARE_INSTALL_DIR)/$(TARGET_NAME)
TARGET_WORK      ?= $(SOFTWARE_WORK_DIR)/$(TARGET_NAME)
# These files aren't used for native compilation, but we
#   stub them out to reuse the makefile targets
TARGET_PROJ      ?= $(TARGET_WORK)/dummy.proj
TARGET_XSA       ?= $(TARGET_WORK)/dummy.xsa
TARGET_TCL       ?= $(TARGET_WORK)/dummy.tcl
TARGET_ENV       ?= $(TARGET_SDK)/environment-setup-$(HOST_CC)

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/dummy.a
TARGET_OPENOCD ?= $(TARGET_SDK)/bin/openocd

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

test: $(TARGET_ENV)

else ifeq ($(TARGET_NAME),pynqz2)
TARGET_CC        ?= arm-xilinx-linux-gnueabi
TARGET_TEMPLATE  ?= zynq
TARGET_WORK      ?= $(PYNQZ2_WORK)
TARGET_SDK       ?= $(PYNQZ2_SDK)
TARGET_PROJ      ?= $(TARGET_NAME)_proj
TARGET_XSA       ?= $(TARGET_WORK)/$(TARGET_NAME)_basic.xsa
TARGET_TCL       ?= $(SOFTWARE_TCL_DIR)/vivado-gen-xsa-$(TARGET_NAME).tcl
TARGET_ENV       ?= $(PYNQZ2_ENV)

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/libpynq.a
TARGET_OPENOCD ?= $(TARGET_SDK)/bin/openocd
else ifeq ($(TARGET_NAME),ultra96v2)
TARGET_CC        ?= aarch64-xilinx-linux-gnueabi
TARGET_TEMPLATE  ?= zynqMP
TARGET_WORK      ?= $(ULTRA96V2_WORK)
TARGET_SDK       ?= $(ULTRA96V2_SDK)
TARGET_PROJ      ?= $(TARGET_NAME)_proj
TARGET_XSA       ?= $(TARGET_WORK)/$(TARGET_NAME)_basic.xsa
TARGET_TCL       ?= $(SOFTWARE_TCL_DIR)/vivado-gen-xsa-$(TARGET_NAME).tcl
TARGET_ENV       ?= $(ULTRA96V2_ENV)

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/libpynq.a
TARGET_OPENOCD ?= $(TARGET_SDK)/bin/openocd
else
$(error Unknown TARGET_NAME $(TARGET_NAME) for software)
endif

all: verilator pynq openocd

openocd: $(TARGET_OPENOCD)
%/bin/openocd: export OPENOCD_CONFIG=--enable-remote-bitbang
%/bin/openocd: export PATH:=$(TARGET_WORK)/autotools/bin:$(PATH)
%/bin/openocd: $(TARGET_ENV)
	mkdir -p $(@D)
	rm -rf $(TARGET_WORK)/riscv-openocd
	git clone --recurse-submodules -b riscv https://github.com/riscv-collab/riscv-openocd $(TARGET_WORK)/riscv-openocd
ifneq (,$(findstring centos,$(shell python -m platform)))
	cd $(TARGET_WORK)/riscv-openocd; wget -qO- http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz | tar xzv
	cd $(TARGET_WORK)/riscv-openocd; wget -qO- http://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz | tar xzv
	cd $(TARGET_WORK)/riscv-openocd; wget -qO- http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz | tar xzv
	cd $(TARGET_WORK)/riscv-openocd; wget -qO- https://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz | tar xzv
	cd $(TARGET_WORK)/riscv-openocd/automake-1.15; ./configure --prefix=$(TARGET_WORK)/autotools; make install
	cd $(TARGET_WORK)/riscv-openocd/autoconf-2.69; ./configure --prefix=$(TARGET_WORK)/autotools; make install
	cd $(TARGET_WORK)/riscv-openocd/libtool-2.4.6; ./configure --prefix=$(TARGET_WORK)/autotools; make install
	cd $(TARGET_WORK)/riscv-openocd/pkg-config-0.28; ./configure --prefix=$(TARGET_WORK)/autotools; make install
endif
	cd $(TARGET_WORK)/riscv-openocd; source $(TARGET_ENV) && ./bootstrap
	cd $(TARGET_WORK)/riscv-openocd; source $(TARGET_ENV) && cp $(TARGET_WORK)/riscv-openocd/{build-aux/,}config.guess
	cd $(TARGET_WORK)/; source $(TARGET_ENV) && \
		$(TARGET_WORK)/riscv-openocd/contrib/cross-build.sh $(TARGET_CC)
	cp $(TARGET_WORK)/$(TARGET_CC)-root/usr/bin/openocd $@

pynq: $(TARGET_PYNQ)
%/lib/libpynq.a: $(TARGET_ENV)
	mkdir -p $(@D)
	git clone --recurse-submodules -b image_v2.6.0 https://github.com/Xilinx/PYNQ.git $(TARGET_WORK)/PYNQ
	git clone --recurse-submodules -b master https://github.com/mesham/pynq_api.git $(TARGET_WORK)/pynq_api
	sed -i "/CC.*=/d" $(TARGET_WORK)/pynq_api/makefile
	sed -i "/CFLAGS.*=/d" $(TARGET_WORK)/pynq_api/makefile
	cd $(TARGET_WORK)/pynq_api; \
		source $(TARGET_ENV) && \
			CFLAGS="$$CFLAGS -I$(TARGET_WORK)/PYNQ/sdbuild/packages/libsds/libcma" \
			$(MAKE) all
	cp $(TARGET_WORK)/pynq_api/libpynq.a $(@D)
	cp $(TARGET_WORK)/pynq_api/libpynq.so $(@D)
	cp $(TARGET_WORK)/pynq_api/src/pynq_api.h $(@D)

verilator: $(TARGET_VERILATOR)
%/bin/verilator: $(TARGET_ENV)
	mkdir -p $(@D)
	cd $(BLACKPARROT_TOOLS_DIR)/verilator; \
		autoconf; ./configure \
		--target=$(TARGET_CC) \
		--host=$(HOST_CC) \
		--build=$(HOST_CC) \
		--prefix=$(TARGET_SDK)
	cd $(BLACKPARROT_TOOLS_DIR)/verilator; \
		source $(TARGET_ENV) && $(MAKE) && $(MAKE) install

environment-setup: $(TARGET_ENV)
environment-setup-%: $(TARGET_XSA)
	mkdir -p $(@D)
	cd $(<D); \
		$(PETALINUX_RUN)-create --type project --template $(TARGET_TEMPLATE) --name $(TARGET_PROJ)
	cd $(<D); \
		$(PETALINUX_RUN)-config --verbose --silentconfig --get-hw-description $< --project $(TARGET_PROJ)
	cd $(<D); \
		$(PETALINUX_RUN)-build --sdk --project $(TARGET_PROJ)
	cd $(<D)/$(TARGET_PROJ); \
		$(PETALINUX_RUN)-package --sysroot --sdk=images/linux/sdk.sh
	cd $(<D)/$(TARGET_PROJ); \
		mv images/linux/sdk/environment-setup-* $@

xsa: $(TARGET_XSA)
%.xsa:
	mkdir -p $(@D)
	cd $(@D); \
		$(VIVADO_RUN) -source $(TARGET_TCL)

clean:
	rm -rf $(TARGET_XSA)
	rm -rf $(TARGET_ENV)
	rm -rf $(TARGET_WORK)
	rm -rf $(SOFTWARE_INSTALL_DIR)/$(TARGET_NAME)

