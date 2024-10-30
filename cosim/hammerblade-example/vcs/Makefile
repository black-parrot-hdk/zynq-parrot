include ../Makefile.design

#############################
# Accelerator Software Settings
#############################

NUM_MC_FINISH ?= 1
NUM_BP_FINISH ?= 1

#CFLAGS += -DZYNQ_PL_DEBUG
#CFLAGS += -DZYNQ_PS_DEBUG
#CFLAGS += -DVERIFY_NBF
CFLAGS += -DNUM_MC_FINISH=$(NUM_MC_FINISH)
CFLAGS += -DNUM_BP_FINISH=$(NUM_BP_FINISH)
CFLAGS += -I$(BSG_REPLICANT_DIR)/libraries

DEFINES += GP0_ADDR_BASE=0x40000000U
DEFINES += GP0_HIER_BASE=bsg_nonsynth_zynq_testbench.axil0
DEFINES += GP1_ADDR_BASE=0x80000000U
DEFINES += GP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil1
DEFINES += HP0_ADDR_BASE=0x00000000U
DEFINES += AXI_MEM_ENABLE
DEFINES += HP1_ADDR_BASE=0x1000000U
DEFINES += HP1_HIER_BASE=bsg_nonsynth_zynq_testbench.axil4
DEFINES += SCRATCHPAD_ENABLE
DEFINES += BSG_MANYCORE_MACHINE_LOADER_COORD_X=2 BSG_MANYCORE_MACHINE_LOADER_COORD_Y=0

SIM_ARGS += +c_args=$(NBF_FILE)

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
MC_FLIST   ?= $(abspath flist.manycore.vcs)
BP_FLIST   ?= $(abspath flist.blackparrot.vcs)
FLIST      ?= $(abspath flist.vcs)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@
	sed -i "/bp_common_pkg.sv/d" $@
	sed -i "1i $(DESIGN_VSRC_DIR)/bp_common_pkg.sv" $@

$(MC_FLIST): $(BSG_MANYCORE_DIR)/machines/arch_filelist.mk
	cp $^ $@
	sed -i "s/(/{/g" $@
	sed -i "s/)/}/g" $@
	sed -i "s/VINCLUDES += /+incdir+/g" $@
	sed -i "s/VHEADERS += //g" $@
	sed -i "s/VSOURCES += //g" $@

$(FLIST): $(BP_FLIST) $(MC_FLIST) $(BASE_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(DESIGN_VSRC_DIR)" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_dpi_to_axil.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_axil_to_dpi.sv" >> $@
	echo "$(COSIM_VSRC_DIR)/bsg_nonsynth_zynq_testbench.sv" >> $@
	# Remove duplicates, TODO: detect automatically
	sed -i "/import\/basejump_stl.*bsg_cache_pkg.sv/d" $@
	sed -i "/import\/basejump_stl.*bsg_noc_pkg.sv/d" $@
	sed -i "/import\/basejump_stl.*bsg_wormhole_router_pkg.sv/d" $@

include $(COSIM_MK_DIR)/Makefile.vcs

