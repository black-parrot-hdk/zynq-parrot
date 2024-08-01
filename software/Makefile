TOP  := $(shell git rev-parse --show-toplevel)
CURR := $(shell pwd)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.config

include $(TOP)/software/mk/Makefile.env

TARGET_NAME ?=

ifeq ($(TARGET_NAME),x86)
TARGET_CC        ?= x86_64-linux-gnu
TARGET_TEMPLATE  ?= zynq
TARGET_SDK       ?= $(SOFTWARE_WORK_DIR)/x86
TARGET_PROJ      ?= $(SOFTWARE_WORK_DIR)/dummy.proj
TARGET_XSA       ?= $(SOFTWARE_WORK_DIR)/dummy.xsa
TARGET_TCL       ?= $(SOFTWARE_WORK_DIR)/dummy.tcl
TARGET_ENV       ?= $(TARGET_SDK)/dummy.environment-setup-x86

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator

else ifeq ($(TARGET_NAME),pynqz2)
TARGET_CC        ?= arm-xilinx-linux-gnueabi
TARGET_TEMPLATE  ?= zynq
TARGET_SDK       ?= $(PYNQZ2_SDK)
TARGET_PROJ      ?= $(TARGET_NAME)_proj
TARGET_XSA       ?= $(SOFTWARE_WORK_DIR)/$(TARGET_NAME)_basic.xsa
TARGET_TCL       ?= $(SOFTWARE_TCL_DIR)/vivado-gen-xsa-$(TARGET_NAME).tcl
TARGET_ENV       ?= $(PYNQZ2_ENV)

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
else ifeq ($(TARGET_NAME),ultra96v2)
TARGET_CC        ?= aarch64-xilinx-linux-gnueabi
TARGET_TEMPLATE  ?= zynqMP
TARGET_SDK       ?= $(ULTRA96V2_SDK)
TARGET_PROJ      ?= $(TARGET_NAME)_proj
TARGET_XSA       ?= $(SOFTWARE_WORK_DIR)/$(TARGET_NAME)_basic.xsa
TARGET_TCL       ?= $(SOFTWARE_TCL_DIR)/vivado-gen-xsa-$(TARGET_NAME).tcl
TARGET_ENV       ?= $(ULTRA96V2_ENV)

TARGET_VERILATOR ?= $(TARGET_SDK)/bin/verilator
else
$(error Unknown TARGET_NAME $(TARGET_NAME) for software)
endif

all: $(TARGET_VERILATOR)

dummy.%:
	touch $@

HOST_CC ?= x86_64-linux-gnu
%/bin/verilator: $(TARGET_ENV)
	mkdir -p $(TARGET_SDK)
	cd $(BLACKPARROT_TOOLS_DIR)/verilator; \
		autoconf; ./configure \
		--target=$(TARGET_CC) \
		--host=$(HOST_CC) \
		--build=$(HOST_CC) \
		--prefix=$(TARGET_SDK)
	cd $(BLACKPARROT_TOOLS_DIR)/verilator; \
		source $(TARGET_ENV) && $(MAKE) && $(MAKE) install

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

%.xsa:
	mkdir -p $(@D)
	cd $(@D); \
		$(VIVADO_RUN) -source $(TARGET_TCL)

clean:
	rm -rf $(SOFTWARE_WORK_DIR)

