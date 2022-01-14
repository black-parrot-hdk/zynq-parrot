include ../Makefile.design

#############################
# Accelerator Software Settings
#############################

DROMAJO_COSIM ?= 0

BP_NCPUS ?= 1

# AXI to core clock downsampling factor
CLK_DIV ?= 2

# Sampling gate enable and interval
SAMPLE_GATE_EN ?= 1
SAMPLE_INTRVL ?= 1

# DRAM constant delay enable and latency
DRAM_GATE_EN ?= 1
DRAM_LATENCY ?= 80

#CFLAGS += -DDRAM_TEST
#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DBP_NCPUS=$(BP_NCPUS)
CFLAGS += -DSAMPLE_GATE_EN=$(SAMPLE_GATE_EN)
CFLAGS += -DSAMPLE_INTRVL=$(SAMPLE_INTRVL)
CFLAGS += -DDRAM_GATE_EN=$(DRAM_GATE_EN)
CFLAGS += -DDRAM_LATENCY=$(DRAM_LATENCY)
ifeq ($(DROMAJO_COSIM),1)
CFLAGS += -I$(BP_TOOLS_DIR)/dromajo/include
endif

DEFINES += CLK_DIV=$(CLK_DIV)
DEFINES += GP0_ENABLE
DEFINES += GP0_ADDR_BASE=0x400000000U GP0_ADDR_WIDTH=10 GP0_DATA_WIDTH=32
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ENABLE
DEFINES += GP1_ADDR_BASE=0x500000000U GP1_ADDR_WIDTH=30 GP1_DATA_WIDTH=32
DEFINES += GP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil1
DEFINES += GP2_ENABLE
DEFINES += GP2_ADDR_BASE=0x800000000U GP2_ADDR_WIDTH=28 GP2_DATA_WIDTH=32
DEFINES += GP2_HIER_BASE=bsg_nonsynth_zynq_testbench.axil2
# watchdog cannot function if clock gating is enabled
ifndef SAMPLE_GATE_EN
ifndef DRAM_GATE_EN
DEFINES += WATCHDOG_ENABLE
endif
endif
DEFINES += HP0_ENABLE
DEFINES += HP0_ADDR_BASE=0x0000000U HP0_ADDR_WIDTH=32 HP0_DATA_WIDTH=64
DEFINES += AXI_MEM_ENABLE
DEFINES += HP1_ENABLE
DEFINES += HP1_ADDR_BASE=0x1000000U HP1_ADDR_WIDTH=32 HP1_DATA_WIDTH=32
DEFINES += HP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil4
DEFINES += SCRATCHPAD_ENABLE

SIM_ARGS += +c_args=$(NBF_FILE)

# Enable backpressure, emulating context switches
#CFLAGS += -DSIM_BACKPRESSURE_ENABLE
#CFLAGS += -DSIM_BACKPRESSURE_SEED=1234
#CFLAGS += -DSIM_BACKPRESSURE_CHANCE=20
#CFLAGS += -DSIM_BACKPRESSURE_LENGTH=1000

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
BP_FLIST   ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(abspath flist.vcs)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(CURR_VSRC_DIR)/bp_common_pkg.sv" $@

$(FLIST): $(BP_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_VSRC_DIR)" >> $@
	echo "+incdir+$(COSIM_DIR)/include/vcs" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_icg_pos.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axil.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axil_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@
	if [ "$(DROMAJO_COSIM)" = "1" ]; then \
		echo "$(BLACKPARROT_DIR)/bp_top/test/common/bp_nonsynth_cosim.sv" >> $@; \
		echo "$(BLACKPARROT_DIR)/bp_top/test/common/dromajo_cosim.cpp" >> $@; \
		echo "$(BLACKPARROT_TOOLS_DIR)/install/lib/libdromajo_cosim.a" >> $@; \
		echo "+define+DROMAJO_COSIM" >> $@; \
		cp $(ELF_FILE) prog.elf; \
	fi

include $(TOP)/cosim/mk/Makefile.vcs

