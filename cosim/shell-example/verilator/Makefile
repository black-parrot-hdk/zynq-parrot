include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += GP0_ADDR_BASE=0x43C00000
DEFINES += GP0_HIER_BASE=TOP.bsg_nonsynth_zynq_testbench.axil0

# Enable backpressure, emulating context switches
#CFLAGS += -DSIM_BACKPRESSURE_ENABLE
#CFLAGS += -DSIM_BACKPRESSURE_SEED=1234
#CFLAGS += -DSIM_BACKPRESSURE_CHANCE=20
#CFLAGS += -DSIM_BACKPRESSURE_LENGTH=1000

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST      ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axil.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@

include $(COSIM_MK_DIR)/Makefile.verilator

