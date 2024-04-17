include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += HP1_ENABLE
DEFINES += HP1_ADDR_BASE=0 HP1_ADDR_WIDTH=28
DEFINES += HP1_DATA_WIDTH=32
DEFINES += HP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil4
DEFINES += UART_ENABLE

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST      ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "+incdir+$(CURR_VSRC_DIR)" >> $@
	echo "+incdir+$(COSIM_DIR)/include/vcs" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axil_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@

include $(TOP)/cosim/mk/Makefile.vcs

