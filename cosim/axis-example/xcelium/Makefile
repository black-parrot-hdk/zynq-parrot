include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += GP0_ADDR_BASE=0x43C00000
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += SP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axis6
DEFINES += MP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axis9
DEFINES += BUFFER_ENABLE

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
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axil_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axil.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axis_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axis.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@

include $(TOP)/cosim/mk/Makefile.xcelium

