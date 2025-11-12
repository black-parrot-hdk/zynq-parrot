TOP ?= $(shell git rev-parse --show-toplevel)
include $(TOP)/Makefile.common
include $(TOP)/Makefile.env

ifneq (ultra96v2,$(BOARDNAME))
$(error Only ultra96v2 is supported for this target ($(BOARDNAME) given))
endif

#############################
# Accelerator Software Settings
#############################
include $(DESIGN_DIR)/Makefile.design
include $(COSIM_MK_DIR)/Makefile.vivado

