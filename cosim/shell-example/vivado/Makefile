TOP   := $(shell git rev-parse --show-toplevel)
CURR  := $(shell pwd)
include $(TOP)/Makefile.common

#############################
# Project Settings
#############################
PART       ?= xc7z020clg400-1
TOP_MODULE ?= top
BASENAME   ?= shell

#############################
# Modify base flist
#############################
BASE_FLIST   ?= $(abspath ../flist.vcs)
FLIST        ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "+incdir+$(COSIM_DIR)/include/vivado" >> $@

include $(TOP)/cosim/mk/Makefile.vivado

