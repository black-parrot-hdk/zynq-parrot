include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
NBF_FILE     ?= $(abspath ../prog.nbf)
RISCV_FILE   ?= $(abspath ../prog.riscv)
HOST_PROGRAM ?= $(abspath ../ps.cpp)
SIM_ARGS     += $(NBF_FILE) $(RISCV_FILE)

SKIP_DRAM ?= -DSKIP_DRAM_TESTING
BP_NCPUS ?= 1

#CFLAGS += -DZYNQ_PL_DEBUG
#CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000U -DGP0_ADDR_WIDTH=10 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000U -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=TOP.top.axil1
CFLAGS += -DHP0_ENABLE -DHP0_ADDR_BASE=0x1000000U -DHP0_ADDR_WIDTH=32 -DHP0_DATA_WIDTH=32 -DHP0_HIER_BASE=TOP.top.axil2
CFLAGS += -DSCRATCHPAD_ENABLE
CFLAGS += -DBP_NCPUS=$(BP_NCPUS)
CFLAGS += $(INCLUDES) $(SKIP_DRAM)
CINCLUDES += -I$(BLACKPARROT_TOOLS_DIR)/dromajo/build
CINCLUDES += -I$(BLACKPARROT_TOOLS_DIR)/dromajo/include
LDFLAGS += -L$(BLACKPARROT_TOOLS_DIR)/dromajo/build/ -ldromajo_cosim
# Enable backpressure
#CFLAGS += -DSIM_BACKPRESSURE_ENABLE
#CFLAGS += -DSIM_BACKPRESSURE_CHANCE=5
#CFLAGS += -DSIM_BACKPRESSURE_LENGTH=100

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST      ?= $(abspath flist.vcs)
$(FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_axil_to_dpi.v" >> $@
	# Replace hardened memory which is incorrectly inferred on some Xilinx FPGAs
	sed -i "/bsg_mem_1rw_sync_mask_write_bit.v/d" $@
	sed -i "/bsg_mem_1rw_sync_mask_write_bit_synth.v/d" $@
	echo "$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v" >> $@
	sed -i "s|.*/bsg_clkgate_optional.v|$(BASEJUMP_STL_DIR)/hard/ultrascale_plus/bsg_misc/bsg_clkgate_optional.v|" $@

include $(TOP)/cosim/mk/Makefile.verilator

#############################
# Regression routines
#############################
SUITE=
PROG=
test:
	mkdir -p $(SUITE)
	RISCV_FILE=$(BLACKPARROT_SDK_DIR)/prog/$(SUITE)/$(PROG).riscv
	echo $(RISCV_FILE)
	NBF_FILE=$(SOFTWARE_NBF_DIR)/$(SUITE)/$(PROG).nbf
	echo $(NBF_FILE)
	$(BLACKPARROT_SDK_DIR)/install/bin/riscv64-unknown-elf-dramfs-objdump -D $(SUITE)/$(PROG).riscv > $(SUITE)/$(PROG).dump
	echo "Cosimulating $(SUITE): $(PROG).riscv"
	$(MAKE) run
	mv run.log $(SUITE)/$(PROG).log
	ifeq ($(shell grep -cE "FAIL|MISMATCH" $(SUITE)/$(PROG).log), 0)
		echo PASS
	else
		echo FAIL or MISMATCH
		mv $(SUITE)/$(PROG).log $(SUITE)/FAIL_$(PROG).log
	endif

test_all:
	echo "Example usage: make SUITE=beebs [ PROG=aha-compress ]"
	mkdir -p $(SUITE)
	echo "Running regression with $(SUITE)"
	for f in $(BLACKPARROT_SDK_DIR)/prog/$(SUITE)/*.riscv; do \
		f1=$${f##*/}; \
		PROG=$${f1%%.*}; \
		NBF_FILE=$(SOFTWARE_NBF_DIR)/$(SUITE)/$(PROG); \
		NBF_FILE+='.nbf'; \
		RISCV_FILE=$$f; \
		echo Cosimulating $(SUITE)/$$PROG.riscv; \
		echo $(NBF_FILE); \
		echo $(RISCV_FILE); \
		$(MAKE) run; \
		mv run.log $(SUITE)/$(PROG).log; \
	done
