
# User variables
set FPGA_CLK_P   refclk_i_clk_p
set FPGA_CLK_N   refclk_i_clk_n
set FPGA_RESETN  rstn
set FPGA_UART_RX uart_rxd
set FPGA_UART_TX uart_txd

# Clock
set_property PACKAGE_PIN   BH45     [get_ports ${FPGA_CLK_N}]
set_property PACKAGE_PIN   BH44     [get_ports ${FPGA_CLK_P}]
set_property IOSTANDARD    LVDS     [get_ports ${FPGA_CLK_P}]

set_property DIFF_TERM_ADV TERM_100 [get_ports ${FPGA_CLK_P}]

# Reset
set_property PACKAGE_PIN BG43 [get_ports ${FPGA_RESETN}]
set_property IOSTANDARD LVCMOS18 [get_ports ${FPGA_RESETN}]
set_property PULLTYPE PULLUP [get_ports ${FPGA_RESETN}]

# UART
# Note: FPGA_UART_RX should be an input port on the FPGA, FPGA_UART_TX should be an output port on the FPGA
set_property PACKAGE_PIN BE10     [get_ports ${FPGA_UART_RX}]
set_property PACKAGE_PIN BF3      [get_ports ${FPGA_UART_TX}]
set_property IOSTANDARD  LVCMOS18 [get_ports "${FPGA_UART_RX} ${FPGA_UART_TX}"]

