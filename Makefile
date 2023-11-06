TOP  := $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common

checkout:
	cd $(TOP); git submodule update --init --recursive --checkout $(COSIM_IMPORT_DIR)
	cd $(TOP); git submodule update --init --recursive --checkout $(SOFTWARE_IMPORT_DIR)

BOOST_URL ?= https://boostorg.jfrog.io/artifactory/main/release/1.82.0/source/boost_1_82_0.tar.gz
BOOST_BUILD_DIR ?= boost_1_82_0
$(BOOST_BUILD_DIR): checkout
	$(WGET) -c $(BOOST_URL) -O - | $(TAR) -xz

boost: $(BOOST_BUILD_DIR)
	rm -rf $(BOOST_ROOT)
	cd $<; \
		./bootstrap.sh --prefix=$(BOOST_ROOT)
	cd $<; \
		./b2 --prefix=$(BOOST_ROOT) \
			toolset=gcc \
			cxxflags="-std=c++14" \
			linkflags="-std=c++14" \
			install
	rm -rf $<

prep: boost
	# BlackParrot
	$(MAKE) -C $(BLACKPARROT_DIR) libs
	$(MAKE) -C $(BLACKPARROT_TOOLS_DIR) tools
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) sdk
	$(MAKE) -C $(BLACKPARROT_SDK_DIR) prog

prep_bsg: prep
	# BlackParrot
	$(MAKE) -C $(BLACKPARROT_TOOLS_DIR) tools_bsg
	$(MAKE) -j1 -C $(BLACKPARROT_SDK_DIR) spec2000 spec2006 spec2017
	# Manycore
	$(MAKE) -C $(BSG_MANYCORE_DIR) tools

bleach_all:
	cd $(TOP); git clean -fdx; git submodule deinit -f .

