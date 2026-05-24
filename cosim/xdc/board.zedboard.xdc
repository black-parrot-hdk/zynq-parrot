## Clock
#set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports {sys_clk}]
#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {sys_clk}]

## Buttons
#set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS25} [get_ports {sys_resetn}]

## LEDs
#set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
#set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
#set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
#set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
