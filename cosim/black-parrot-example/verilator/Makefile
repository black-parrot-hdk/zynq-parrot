include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
NBF_FILE     ?= $(abspath ../prog.nbf)
ELF_FILE     ?= $(abspath ../prog.elf)
SIM_ARGS     += $(NBF_FILE)
HOST_PROGRAM ?= $(abspath ../ps.cpp)
ifdef PK
HOST_PROGRAM += $(abspath $(shell find ../htif/ -name '*.cc'))
endif

DROMAJO_COSIM ?= 0

# Set to +define+MULTICORE for other BP configs
VV_DEFS ?= 

BP_NCPUS ?= 1

SAMPLE_INTERVAL ?= 1
DRAM_LATENCY ?= 80

#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x400000000U -DGP0_ADDR_WIDTH=10 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x500000000U -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=TOP.top.axil1
CFLAGS += -DGP2_ENABLE -DGP2_ADDR_BASE=0x800000000U -DGP2_ADDR_WIDTH=28 -DGP2_DATA_WIDTH=32 -DGP2_HIER_BASE=TOP.top.axil3
CFLAGS += -DSCRATCHPAD_ENABLE
CFLAGS += -DWATCHDOG_ENABLE
CFLAGS += -DBP_NCPUS=$(BP_NCPUS)
CFLAGS += -DSAMPLE_INTERVAL=$(SAMPLE_INTERVAL)
CFLAGS += -DDRAM_LATENCY=$(DRAM_LATENCY)
#CFLAGS += -DDRAM_TEST
CFLAGS += $(INCLUDES)
ifeq ($(DROMAJO_COSIM),1)
CFLAGS += -I$(BP_TOOLS_DIR)/dromajo/include
endif
ifdef PK
CFLAGS += -DPK -I$(abspath ../htif/)
endif

# Enable backpressure, emulating context switches
#CFLAGS += -DSIM_BACKPRESSURE_ENABLE
#CFLAGS += -DSIM_BACKPRESSURE_SEED=1234
#CFLAGS += -DSIM_BACKPRESSURE_CHANCE=5
#CFLAGS += -DSIM_BACKPRESSURE_LENGTH=100

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
BP_FLIST   ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(abspath flist.vcs)
$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@

$(FLIST): $(BP_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_icg_pos.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem_dma.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.cpp" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_axil_to_dpi.v" >> $@
	if [ "$(DROMAJO_COSIM)" = "1" ]; then \
		echo "$(BLACKPARROT_DIR)/bp_top/test/common/bp_nonsynth_cosim.sv" >> $@; \
		echo "$(BLACKPARROT_DIR)/bp_top/test/common/dromajo_cosim.cpp" >> $@; \
		echo "$(BLACKPARROT_TOOLS_DIR)/install/lib/libdromajo_cosim.a" >> $@; \
		echo "+define+DROMAJO_COSIM" >> $@; \
		cp $(ELF_FILE) prog.elf; \
	fi

include $(TOP)/cosim/mk/Makefile.verilator

