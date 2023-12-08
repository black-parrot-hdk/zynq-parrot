include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
#CFLAGS += -DZYNQ_PL_DEBUG
#CFLAGS += -DZYNQ_PS_DEBUG
#CFLAGS += -DVERIFY_NBF
CFLAGS += -DNUM_FINISH=1
CFLAGS += -I$(BSG_REPLICANT_DIR)/libraries

DEFINES += GP0_ENABLE
DEFINES += GP0_ADDR_BASE=0x40000000U GP0_ADDR_WIDTH=10 GP0_DATA_WIDTH=32
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += HP0_ENABLE
DEFINES += HP0_ADDR_BASE=0x00000000U HP0_DATA_WIDTH=64 HP0_ADDR_WIDTH=32
DEFINES += AXI_MEM_ENABLE

SIM_ARGS += +c_args=$(NBF_FILE)

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
MC_FLIST   ?= $(abspath flist.manycore.vcs)
FLIST      ?= $(abspath flist.vcs)

$(MC_FLIST): $(BSG_MANYCORE_DIR)/machines/arch_filelist.mk
	cp $^ $@
	sed -i "s/(/{/g" $@
	sed -i "s/)/}/g" $@
	sed -i "s/VINCLUDES += /+incdir+/g" $@
	sed -i "s/VHEADERS += //g" $@
	sed -i "s/VSOURCES += //g" $@

$(FLIST): $(MC_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_VSRC_DIR)" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axil.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axil_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@

include $(TOP)/cosim/mk/Makefile.vcs

