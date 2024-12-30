COEMU ?= 1
# change SPIKE_COEMU to 0 for DROMAJO_COEMU
SPIKE_COEMU ?= 1
ifeq ($(SPIKE_COEMU),1)
DROMAJO_COEMU ?= 0
else
DROMAJO_COEMU ?= 1
endif

include ../Makefile.design

#############################
# Accelerator Software Settings
#############################

DROMAJO_COSIM ?= 0

BP_NCPUS ?= 1

#CFLAGS += -DDRAM_TEST
#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DBP_NCPUS=$(BP_NCPUS)
ifeq ($(DROMAJO_COSIM),1)
CFLAGS += -I$(BP_TOOLS_DIR)/dromajo/include
endif

MAIN_SDK = $(HOME)/zynq-farm/new/zynq-parrot/import/black-parrot-sdk/install

ifeq ($(COEMU),1)
  ifeq ($(DROMAJO_COEMU),1)
    CINCLUDES += -I$(BP_TOOLS_DIR)/dromajo/include
    LDFLAGS += -L$(BP_TOOLS_DIR)/dromajo/build_x86 -ldromajo_cosim
  endif
  ifeq ($(SPIKE_COEMU),1)
    CINCLUDES += -I$(MAIN_SDK)/include
    LDFLAGS += -L$(MAIN_SDK)/lib -lriscv -lsoftfloat -lfesvr -Wl,-rpath=$(HOME)/riscv-tools/riscv-isa-sim/build
  endif
endif


DEFINES += GP0_ADDR_BASE=0x400000000U
DEFINES += GP0_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ADDR_BASE=0x500000000U
DEFINES += GP1_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil1
DEFINES += GP2_ADDR_BASE=0x800000000U
DEFINES += GP2_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil2
DEFINES += HP0_ADDR_BASE=0x0000000U
# watchdog cannot function if clock gating is enabled
#DEFINES += WATCHDOG_ENABLE
DEFINES += AXI_MEM_ENABLE
DEFINES += HP1_ADDR_BASE=0x1000000U
DEFINES += HP1_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil4
DEFINES += SCRATCHPAD_ENABLE
DEFINES += BUFFER_ENABLE
DEFINES += MP0_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axis9

SIM_ARGS += $(NBF_FILE) $(ELF_FILE)
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
	echo "$(BASEJUMP_STL_DIR)/bsg_misc/bsg_icg_pos.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.cpp" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axi_mem_dma.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axil.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axil_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axis_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@
	if [ "$(COV_EN)" = "1" ]; then \
	  if [ "$(RAND_COV)" = "0" ]; then \
	    sed -i "/top_zynq.sv/d" $@ ;\
	    echo "$(INSTRUMENTATION_DIR)/instrumented_top_zynq.sv" >> $@ ;\
	  fi \
	fi
	if [ "$(DROMAJO_COSIM)" = "1" ]; then \
		echo "$(BLACKPARROT_DIR)/bp_top/test/common/bp_nonsynth_cosim.sv" >> $@; \
		echo "$(BLACKPARROT_DIR)/bp_top/test/common/dromajo_cosim.cpp" >> $@; \
		echo "$(BLACKPARROT_TOOLS_DIR)/install/lib/libdromajo_cosim.a" >> $@; \
		echo "+define+DROMAJO_COSIM" >> $@; \
		cp $(ELF_FILE) prog.elf; \
	fi

include ../Makefile.cov
include $(TOP)/cosim/mk/Makefile.verilator
