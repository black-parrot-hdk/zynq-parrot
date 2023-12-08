include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
#CFLAGS += -DZYNQ_PL_DEBUG
#CFLAGS += -DZYNQ_PS_DEBUG

DEFINES += UART_ENABLE
DEFINES += UART_BAUD=$(UART_BAUD)
DEFINES += UART_DEV="/dev/ttyUSB0"

include $(TOP)/cosim/mk/Makefile.bridge

