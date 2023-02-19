include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
NBF_FILE     ?= $(abspath ../prog.nbf)
HOST_PROGRAM ?= $(abspath ../ps.cpp)
SIM_ARGS     += +c_args=$(NBF_FILE)

SKIP_DRAM ?= -DSKIP_DRAM_TESTING
BP_NCPUS ?= 1

#CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x40000000U -DGP0_ADDR_WIDTH=10 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000U -DGP1_ADDR_WIDTH=30 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=top.axil1
#CFLAGS += -DHP0_ENABLE -DHP0_ADDR_BASE=0x1000000U -DHP0_ADDR_WIDTH=32 -DHP0_DATA_WIDTH=32 -DHP0_HIER_BASE=top.axil2
CFLAGS += -DSCRATCHPAD_ENABLE
CFLAGS += -DBITBANG_ENABLE
CFLAGS += -DBP_NCPUS=$(BP_NCPUS)
CFLAGS += $(INCLUDES) $(SKIP_DRAM)

export CURR_DIR ?= $(shell pwd)
export AXI_DIR  ?= $(BLACKPARROT_SUB_DIR)/axi/v
export PLIC_DIR ?= $(BLACKPARROT_SUB_DIR)/rv_plic
export ETH_DIR  ?= $(BLACKPARROT_SUB_DIR)/ethernet_controller/rtl
#############################
# Modify base flist
#############################
BASE_FLIST      ?= $(abspath $(CURR_FLIST_DIR)/base_flist.vcs)
BP_FLIST        ?= $(abspath flist.blackparrot.vcs)
SIM_FLIST       ?= $(abspath $(CURR_DIR)/sim.vcs)

# Flist for Zynq-Parrot core (In simulation, only ZYNQ_CORE_FLIST is considered)
ZYNQ_CORE_FLIST  ?= $(abspath top_flist.vcs)

FLIST := $(ZYNQ_CORE_FLIST)

$(BP_FLIST): $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs
	cp $^ $@
	sed -i "s/BASEJUMP_STL_DIR/BP_BASEJUMP_STL_DIR/g" $@

# TODO: Need to swap ssio_ddr
$(ZYNQ_CORE_FLIST): $(BP_FLIST) $(BASE_FLIST) $(SIM_FLIST)
	cat $^ | envsubst > $@
	echo "+incdir+$(CURR_SRC_DIR)" >> $@
	echo "+incdir+$(BLACKPARROT_SUB_DIR)/rv_plic/" >> $@
	echo "$(CURR_SRC_DIR)/rgmii_loopback_sim/iddr_nonsynth.v" >> $@
	echo "$(CURR_SRC_DIR)/rgmii_loopback_sim/oddr_nonsynth.v" >> $@
	echo "$(CURR_SRC_DIR)/rgmii_loopback_sim/rgmii_loopback_nonsynth.sv" >> $@
	echo "$(CURR_SRC_DIR)/peripheral_nonsynth.sv" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_axi_mem.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v " >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v " >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_axil_to_dpi.v" >> $@

include $(TOP)/cosim/mk/Makefile.vcs

