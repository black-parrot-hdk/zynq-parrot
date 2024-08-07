TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.config

include $(TOP)/software/mk/Makefile.env

.DEFAULT_GOAL := all
TARGET_NAME ?=

ifeq ($(TARGET_NAME),x86)
TARGET_CC        ?= x86_64-linux-gnu
TARGET_TEMPLATE  ?= zynq
TARGET_SDK       ?= $(SOFTWARE_INSTALL_DIR)/$(TARGET_NAME)
TARGET_WORK      ?= $(SOFTWARE_WORK_DIR)/$(TARGET_NAME)
# These files aren't used for native compilation, but we
#   stub them out to reuse the makefile targets
TARGET_PROJ      ?= $(TARGET_WORK)/dummy.proj
TARGET_XSA       ?= $(TARGET_WORK)/dummy.xsa
TARGET_TCL       ?= $(TARGET_WORK)/dummy.tcl
TARGET_ENV       ?= $(TARGET_SDK)/dummy.environment-setup-x86

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
TARGET_PYNQ ?= $(TARGET_SDK)/lib/dummy.a

dummy.%:
	mkdir -p $(TARGET_WORK)
	mkdir -p $(TARGET_SDK)
	touch $@

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
else
$(error Unknown TARGET_NAME $(TARGET_NAME) for software)
endif

all: verilator pynq

pynq: $(TARGET_PYNQ)
%/lib/libpynq.a: $(TARGET_ENV)
	mkdir -p $(@D)
	git clone -b image_v2.6.0 https://github.com/Xilinx/PYNQ.git $(TARGET_WORK)/PYNQ
	git clone -b master https://github.com/mesham/pynq_api.git $(TARGET_WORK)/pynq_api
	sed -i "/CC.*=/d" $(TARGET_WORK)/pynq_api/makefile
	sed -i "/CFLAGS.*=/d" $(TARGET_WORK)/pynq_api/makefile
	cd $(TARGET_WORK)/pynq_api; \
		source $(TARGET_ENV) && \
			CFLAGS="$$CFLAGS -I$(TARGET_WORK)/PYNQ/sdbuild/packages/libsds/libcma" \
			$(MAKE) all
	cp $(TARGET_WORK)/pynq_api/libpynq.a $(@D)
	cp $(TARGET_WORK)/pynq_api/libpynq.so $(@D)
	cp $(TARGET_WORK)/pynq_api/src/pynq_api.h $(@D)

HOST_CC ?= x86_64-linux-gnu
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
	rm -rf $(SOFTWARE_INSTALL_DIR)/$(TARGET_NAME)

