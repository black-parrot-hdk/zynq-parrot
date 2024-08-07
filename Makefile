TOP  := $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common

checkout:
	cd $(TOP); git submodule update --init --recursive --checkout $(COSIM_IMPORT_DIR)
	cd $(TOP); git submodule update --init --recursive --checkout $(SOFTWARE_IMPORT_DIR)

prep: checkout
	# BlackParrot
	$(MAKE) -C $(BLACKPARROT_DIR) libs
	$(MAKE) -C $(BLACKPARROT_TOOLS_DIR) tools
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) sdk PLATFORM=$(PLATFORM)
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) prog

prep_bsg: prep
	# BlackParrot
	$(MAKE) -C $(BLACKPARROT_TOOLS_DIR) tools_bsg
	$(MAKE) -j1 -C $(BLACKPARROT_SDK_DIR) spec2000 spec2006 spec2017
	# Manycore
	$(MAKE) -C $(BSG_MANYCORE_DIR) tools

bleach_all:
	cd $(TOP); git clean -fdx; git submodule deinit -f .

