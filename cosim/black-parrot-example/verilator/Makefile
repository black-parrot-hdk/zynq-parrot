include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
DROMAJO_COSIM ?= 0
BP_NCPUS ?= 1

ZYNQ_PL_DEBUG ?= 0
ZYNQ_PS_DEBUG ?= 1

CFLAGS += -DBP_NCPUS=$(BP_NCPUS)

# PL Debug
ifeq ($(ZYNQ_PL_DEBUG),1)
CFLAGS += -DZYNQ_PL_DEBUG
endif
# PS Debug
ifeq ($(ZYNQ_PS_DEBUG),1)
CFLAGS += -DZYNQ_PS_DEBUG
endif
# Cosim
ifeq ($(DROMAJO_COSIM),1)
CFLAGS += -I$(BP_TOOLS_DIR)/dromajo/include
CFLAGS += -DDROMAJO_COSIM
VV_OPTS += -LDFLAGS "-lpthread"
endif
# DRAM Test
ifneq ($(DRAM_TEST),)
CFLAGS += -DDRAM_TEST
endif
# Zero DRAM
ifneq ($(ZERO_DRAM),)
CFLAGS += -DZERO_DRAM
endif

DEFINES += GP0_ADDR_BASE=0x40000000U
DEFINES += GP0_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ADDR_BASE=0x80000000U
DEFINES += GP1_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil1
DEFINES += GP2_ADDR_BASE=0x80000000U
DEFINES += GP2_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil2
DEFINES += WATCHDOG_ENABLE
DEFINES += HP0_ADDR_BASE=0x0000000U
DEFINES += AXI_MEM_ENABLE
DEFINES += HP1_ADDR_BASE=0x1000000U
DEFINES += HP1_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil4
DEFINES += SCRATCHPAD_ENABLE

SIM_ARGS += $(NBF_FILE)

RUN_COLLATERAL = $(NBF_FILE) $(ELF_FILE)

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
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(CURR_VSRC_DIR)/bp_common_pkg.sv" $@

$(FLIST): $(BP_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_VSRC_DIR)" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.sv" >> $@
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

bootrom: $(CURR_VSRC_DIR)/bsg_bootrom.v

include $(TOP)/cosim/mk/Makefile.verilator

