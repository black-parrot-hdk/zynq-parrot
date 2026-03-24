# ----------------------------------------------------------------------------------------------------
# Copyright (c) 2025 by Enclustra GmbH, Switzerland.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this hardware, software, firmware, and associated documentation files (the
# "Product"), to deal in the Product without restriction, including without
# limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Product, and to permit persons to whom the
# Product is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Product.
#
# THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
# ----------------------------------------------------------------------------------------------------

#set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
 
# ----------------------------------------------------------------------------------
# Important! Do not remove this constraint!
# This property ensures that all unused pins are set to high impedance.
# If the constraint is removed, all unused pins have to be set to HiZ in the top level file.
#set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
# ----------------------------------------------------------------------------------

# Anios 0
#set_property -dict {PACKAGE_PIN G10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D0_P}]
#set_property -dict {PACKAGE_PIN F10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D1_N}]
#set_property -dict {PACKAGE_PIN H12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D2_P}]
#set_property -dict {PACKAGE_PIN G11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D3_N}]
#set_property -dict {PACKAGE_PIN J12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D4_P}]
#set_property -dict {PACKAGE_PIN H11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D5_N}]
#set_property -dict {PACKAGE_PIN J11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D6_P}]
#set_property -dict {PACKAGE_PIN J10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D7_N}]
#set_property -dict {PACKAGE_PIN K13   IOSTANDARD LVCMOS18  } [get_ports {IO0_D8_P}]
#set_property -dict {PACKAGE_PIN K12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D9_N}]
#set_property -dict {PACKAGE_PIN E13   IOSTANDARD LVCMOS18  } [get_ports {IO0_CLK_N}]
#set_property -dict {PACKAGE_PIN E14   IOSTANDARD LVCMOS18  } [get_ports {IO0_CLK_P}]
#set_property -dict {PACKAGE_PIN G13   IOSTANDARD LVCMOS18  } [get_ports {IO0_D10_P}]
#set_property -dict {PACKAGE_PIN F13   IOSTANDARD LVCMOS18  } [get_ports {IO0_D11_N}]
#set_property -dict {PACKAGE_PIN E10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D12_P}]
#set_property -dict {PACKAGE_PIN D10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D13_N}]
#set_property -dict {PACKAGE_PIN A12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D14_P}]
#set_property -dict {PACKAGE_PIN A11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D15_N}]
#set_property -dict {PACKAGE_PIN C12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D16_P}]
#set_property -dict {PACKAGE_PIN B11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D17_N}]
#set_property -dict {PACKAGE_PIN B10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D18_P}]
#set_property -dict {PACKAGE_PIN A10   IOSTANDARD LVCMOS18  } [get_ports {IO0_D19_N}]
#set_property -dict {PACKAGE_PIN D11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D20_P}]
#set_property -dict {PACKAGE_PIN C11   IOSTANDARD LVCMOS18  } [get_ports {IO0_D21_N}]
#set_property -dict {PACKAGE_PIN E12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D22_P}]
#set_property -dict {PACKAGE_PIN D12   IOSTANDARD LVCMOS18  } [get_ports {IO0_D23_N}]

# Anios 1
#set_property -dict {PACKAGE_PIN AG8   IOSTANDARD LVCMOS18  } [get_ports {IO1_D0_P}]
#set_property -dict {PACKAGE_PIN AH8   IOSTANDARD LVCMOS18  } [get_ports {IO1_D1_N}]
#set_property -dict {PACKAGE_PIN AJ10  IOSTANDARD LVCMOS18  } [get_ports {IO1_D2_P}]
#set_property -dict {PACKAGE_PIN AK10  IOSTANDARD LVCMOS18  } [get_ports {IO1_D3_N}]
#set_property -dict {PACKAGE_PIN AK9   IOSTANDARD LVCMOS18  } [get_ports {IO1_D4_P}]
#set_property -dict {PACKAGE_PIN AK8   IOSTANDARD LVCMOS18  } [get_ports {IO1_D5_N}]
#set_property -dict {PACKAGE_PIN AH9   IOSTANDARD LVCMOS18  } [get_ports {IO1_D6_P}]
#set_property -dict {PACKAGE_PIN AJ9   IOSTANDARD LVCMOS18  } [get_ports {IO1_D7_N}]
#set_property -dict {PACKAGE_PIN AF8   IOSTANDARD LVCMOS18  } [get_ports {IO1_D8_P}]
#set_property -dict {PACKAGE_PIN AF7   IOSTANDARD LVCMOS18  } [get_ports {IO1_D9_N}]
#set_property -dict {PACKAGE_PIN AG5   IOSTANDARD LVCMOS18  } [get_ports {IO1_CLK_N}]
#set_property -dict {PACKAGE_PIN AG6   IOSTANDARD LVCMOS18  } [get_ports {IO1_CLK_P}]
#set_property -dict {PACKAGE_PIN AF10  IOSTANDARD LVCMOS18  } [get_ports {IO1_D10_P}]
#set_property -dict {PACKAGE_PIN AG10  IOSTANDARD LVCMOS18  } [get_ports {IO1_D11_N}]
#set_property -dict {PACKAGE_PIN AK4   IOSTANDARD LVCMOS18  } [get_ports {IO1_D12_P}]
#set_property -dict {PACKAGE_PIN AK3   IOSTANDARD LVCMOS18  } [get_ports {IO1_D13_N}]
#set_property -dict {PACKAGE_PIN AH3   IOSTANDARD LVCMOS18  } [get_ports {IO1_D14_P}]
#set_property -dict {PACKAGE_PIN AH2   IOSTANDARD LVCMOS18  } [get_ports {IO1_D15_N}]
#set_property -dict {PACKAGE_PIN AJ2   IOSTANDARD LVCMOS18  } [get_ports {IO1_D16_P}]
#set_property -dict {PACKAGE_PIN AK2   IOSTANDARD LVCMOS18  } [get_ports {IO1_D17_N}]
#set_property -dict {PACKAGE_PIN AG1   IOSTANDARD LVCMOS18  } [get_ports {IO1_D18_P}]
#set_property -dict {PACKAGE_PIN AH1   IOSTANDARD LVCMOS18  } [get_ports {IO1_D19_N}]
#set_property -dict {PACKAGE_PIN AF3   IOSTANDARD LVCMOS18  } [get_ports {IO1_D20_P}]
#set_property -dict {PACKAGE_PIN AG3   IOSTANDARD LVCMOS18  } [get_ports {IO1_D21_N}]
#set_property -dict {PACKAGE_PIN AF2   IOSTANDARD LVCMOS18  } [get_ports {IO1_D22_P}]
#set_property -dict {PACKAGE_PIN AF1   IOSTANDARD LVCMOS18  } [get_ports {IO1_D23_N}]

# BUTTONS
#set_property -dict {PACKAGE_PIN K14   IOSTANDARD LVCMOS18  } [get_ports {BTN1_N}]

# Optional reference oscillator
# set_property PACKAGE_PIN N7    [get_ports {CLK_REF_N}] # GTH
# set_property PACKAGE_PIN N8    [get_ports {CLK_REF_P}] # GTH

# Clock Generator CLK1
# set_property PACKAGE_PIN E7    [get_ports {CLK_REF0_N}] # GTH
# set_property PACKAGE_PIN E8    [get_ports {CLK_REF0_P}] # GTH

# Clock Generator CLK2
# set_property PACKAGE_PIN R7    [get_ports {CLK_REF1_N}] # GTH
# set_property PACKAGE_PIN R8    [get_ports {CLK_REF1_P}] # GTH

# Clock Generator CLK3
# set_property PACKAGE_PIN J7    [get_ports {CLK_REF2_N}] # GTH
# set_property PACKAGE_PIN J8    [get_ports {CLK_REF2_P}] # GTH

# Clock Generator CLK0
#set_property -dict {PACKAGE_PIN F11   IOSTANDARD DIFF_SSTL18_I} [get_ports {CLK_USR_N}]
#set_property -dict {PACKAGE_PIN F12   IOSTANDARD DIFF_SSTL18_I} [get_ports {CLK_USR_P}]

# Display Port
#set_property -dict {PACKAGE_PIN AG9   IOSTANDARD LVCMOS18  } [get_ports {DP_HPD}]
#set_property -dict {PACKAGE_PIN AG4   IOSTANDARD LVCMOS18  } [get_ports {DP_AUX_IN}]
#set_property -dict {PACKAGE_PIN AH11  IOSTANDARD LVCMOS18  } [get_ports {DP_AUX_OE}]
#set_property -dict {PACKAGE_PIN AJ1   IOSTANDARD LVCMOS18  } [get_ports {DP_AUX_OUT}]

# FMC HPC Connector
#set_property -dict {PACKAGE_PIN Y3    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA02_N}]
#set_property -dict {PACKAGE_PIN Y4    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA02_P}]
#set_property -dict {PACKAGE_PIN AC13  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA03_N}]
#set_property -dict {PACKAGE_PIN AB13  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA03_P}]
#set_property -dict {PACKAGE_PIN Y1    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA04_N}]
#set_property -dict {PACKAGE_PIN Y2    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA04_P}]
#set_property -dict {PACKAGE_PIN AF13  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA05_N}]
#set_property -dict {PACKAGE_PIN AE13  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA05_P}]
# set_property PACKAGE_PIN M1    [get_ports {FMC_HA14_N}] # GTH
# set_property PACKAGE_PIN M2    [get_ports {FMC_HA14_P}] # GTH
# set_property PACKAGE_PIN P1    [get_ports {FMC_HA15_N}] # GTH
# set_property PACKAGE_PIN P2    [get_ports {FMC_HA15_P}] # GTH
# set_property PACKAGE_PIN R3    [get_ports {FMC_HA16_N}] # GTH
# set_property PACKAGE_PIN R4    [get_ports {FMC_HA16_P}] # GTH
#set_property -dict {PACKAGE_PIN AA2   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA02_N}]
#set_property -dict {PACKAGE_PIN AA3   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA02_P}]
#set_property -dict {PACKAGE_PIN AB1   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA03_N}]
#set_property -dict {PACKAGE_PIN AA1   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA03_P}]
#set_property -dict {PACKAGE_PIN AC3   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA04_N}]
#set_property -dict {PACKAGE_PIN AB3   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA04_P}]
#set_property -dict {PACKAGE_PIN AD1   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA05_N}]
#set_property -dict {PACKAGE_PIN AC1   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA05_P}]
#set_property -dict {PACKAGE_PIN AD2   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA06_N}]
#set_property -dict {PACKAGE_PIN AC2   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA06_P}]
#set_property -dict {PACKAGE_PIN AE2   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA07_N}]
#set_property -dict {PACKAGE_PIN AE3   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA07_P}]
#set_property -dict {PACKAGE_PIN AA5   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA08_N}]
#set_property -dict {PACKAGE_PIN AA6   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA08_P}]
#set_property -dict {PACKAGE_PIN AC4   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA09_N}]
#set_property -dict {PACKAGE_PIN AB4   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA09_P}]
#set_property -dict {PACKAGE_PIN AE5   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA10_N}]
#set_property -dict {PACKAGE_PIN AD5   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA10_P}]
#set_property -dict {PACKAGE_PIN AE4   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA11_N}]
#set_property -dict {PACKAGE_PIN AD4   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA11_P}]
#set_property -dict {PACKAGE_PIN AE10  IOSTANDARD LVCMOS18  } [get_ports {FMC_LA12_N}]
#set_property -dict {PACKAGE_PIN AD10  IOSTANDARD LVCMOS18  } [get_ports {FMC_LA12_P}]
#set_property -dict {PACKAGE_PIN AE9   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA13_N}]
#set_property -dict {PACKAGE_PIN AD9   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA13_P}]
#set_property -dict {PACKAGE_PIN AC9   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA14_N}]
#set_property -dict {PACKAGE_PIN AB9   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA14_P}]
#set_property -dict {PACKAGE_PIN AA7   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA15_N}]
#set_property -dict {PACKAGE_PIN AA8   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA15_P}]
#set_property -dict {PACKAGE_PIN AB10  IOSTANDARD LVCMOS18  } [get_ports {FMC_LA16_N}]
#set_property -dict {PACKAGE_PIN AB11  IOSTANDARD LVCMOS18  } [get_ports {FMC_LA16_P}]
#set_property -dict {PACKAGE_PIN K10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA19_N}]
#set_property -dict {PACKAGE_PIN L10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA19_P}]
#set_property -dict {PACKAGE_PIN L11   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA20_N}]
#set_property -dict {PACKAGE_PIN L12   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA20_P}]
#set_property -dict {PACKAGE_PIN M12   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA21_N}]
#set_property -dict {PACKAGE_PIN N12   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA21_P}]
#set_property -dict {PACKAGE_PIN M10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA22_N}]
#set_property -dict {PACKAGE_PIN N10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA22_P}]
#set_property -dict {PACKAGE_PIN P10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA23_N}]
#set_property -dict {PACKAGE_PIN P11   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA23_P}]
#set_property -dict {PACKAGE_PIN T10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA24_N}]
#set_property -dict {PACKAGE_PIN R10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA24_P}]
#set_property -dict {PACKAGE_PIN W10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA25_N}]
#set_property -dict {PACKAGE_PIN W11   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA25_P}]
#set_property -dict {PACKAGE_PIN V11   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA26_N}]
#set_property -dict {PACKAGE_PIN U11   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA26_P}]
#set_property -dict {PACKAGE_PIN U10   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA27_N}]
#set_property -dict {PACKAGE_PIN T11   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA27_P}]
#set_property -dict {PACKAGE_PIN V9    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA28_N}]
#set_property -dict {PACKAGE_PIN U9    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA28_P}]
#set_property -dict {PACKAGE_PIN U6    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA29_N}]
#set_property -dict {PACKAGE_PIN U7    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA29_P}]
#set_property -dict {PACKAGE_PIN U4    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA30_N}]
#set_property -dict {PACKAGE_PIN U5    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA30_P}]
#set_property -dict {PACKAGE_PIN W4    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA31_N}]
#set_property -dict {PACKAGE_PIN V4    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA31_P}]
#set_property -dict {PACKAGE_PIN Y5    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA32_N}]
#set_property -dict {PACKAGE_PIN W5    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA32_P}]
#set_property -dict {PACKAGE_PIN U1    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA33_N}]
#set_property -dict {PACKAGE_PIN T1    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA33_P}]
# set_property PACKAGE_PIN D5    [get_ports {FMC_DP0_C2M_N}] # GTH
# set_property PACKAGE_PIN D6    [get_ports {FMC_DP0_C2M_P}] # GTH
# set_property PACKAGE_PIN D1    [get_ports {FMC_DP0_M2C_N}] # GTH
# set_property PACKAGE_PIN D2    [get_ports {FMC_DP0_M2C_P}] # GTH
# set_property PACKAGE_PIN C7    [get_ports {FMC_DP1_C2M_N}] # GTH
# set_property PACKAGE_PIN C8    [get_ports {FMC_DP1_C2M_P}] # GTH
# set_property PACKAGE_PIN C3    [get_ports {FMC_DP1_M2C_N}] # GTH
# set_property PACKAGE_PIN C4    [get_ports {FMC_DP1_M2C_P}] # GTH
# set_property PACKAGE_PIN B5    [get_ports {FMC_DP2_C2M_N}] # GTH
# set_property PACKAGE_PIN B6    [get_ports {FMC_DP2_C2M_P}] # GTH
# set_property PACKAGE_PIN B1    [get_ports {FMC_DP2_M2C_N}] # GTH
# set_property PACKAGE_PIN B2    [get_ports {FMC_DP2_M2C_P}] # GTH
# set_property PACKAGE_PIN A7    [get_ports {FMC_DP3_C2M_N}] # GTH
# set_property PACKAGE_PIN A8    [get_ports {FMC_DP3_C2M_P}] # GTH
# set_property PACKAGE_PIN A3    [get_ports {FMC_DP3_M2C_N}] # GTH
# set_property PACKAGE_PIN A4    [get_ports {FMC_DP3_M2C_P}] # GTH
# set_property PACKAGE_PIN J3    [get_ports {FMC_DP4_C2M_N}] # GTH
# set_property PACKAGE_PIN J4    [get_ports {FMC_DP4_C2M_P}] # GTH
# set_property PACKAGE_PIN K1    [get_ports {FMC_DP4_M2C_N}] # GTH
# set_property PACKAGE_PIN K2    [get_ports {FMC_DP4_M2C_P}] # GTH
# set_property PACKAGE_PIN H5    [get_ports {FMC_DP5_C2M_N}] # GTH
# set_property PACKAGE_PIN H6    [get_ports {FMC_DP5_C2M_P}] # GTH
# set_property PACKAGE_PIN H1    [get_ports {FMC_DP5_M2C_N}] # GTH
# set_property PACKAGE_PIN H2    [get_ports {FMC_DP5_M2C_P}] # GTH
# set_property PACKAGE_PIN F5    [get_ports {FMC_DP6_C2M_N}] # GTH
# set_property PACKAGE_PIN F6    [get_ports {FMC_DP6_C2M_P}] # GTH
# set_property PACKAGE_PIN G3    [get_ports {FMC_DP6_M2C_N}] # GTH
# set_property PACKAGE_PIN G4    [get_ports {FMC_DP6_M2C_P}] # GTH
# set_property PACKAGE_PIN E3    [get_ports {FMC_DP7_C2M_N}] # GTH
# set_property PACKAGE_PIN E4    [get_ports {FMC_DP7_C2M_P}] # GTH
# set_property PACKAGE_PIN F1    [get_ports {FMC_DP7_M2C_N}] # GTH
# set_property PACKAGE_PIN F2    [get_ports {FMC_DP7_M2C_P}] # GTH
#set_property -dict {PACKAGE_PIN AJ12  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA17_N}]
#set_property -dict {PACKAGE_PIN AH12  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA17_P}]
#set_property -dict {PACKAGE_PIN AD6   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA00_CC_N}]
#set_property -dict {PACKAGE_PIN AC6   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA00_CC_P}]
#set_property -dict {PACKAGE_PIN AB5   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA01_CC_N}]
#set_property -dict {PACKAGE_PIN AB6   IOSTANDARD LVCMOS18  } [get_ports {FMC_LA01_CC_P}]
#set_property -dict {PACKAGE_PIN Y8    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA17_CC_N}]
#set_property -dict {PACKAGE_PIN Y9    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA17_CC_P}]
#set_property -dict {PACKAGE_PIN V8    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA18_CC_N}]
#set_property -dict {PACKAGE_PIN U8    IOSTANDARD LVCMOS18  } [get_ports {FMC_LA18_CC_P}]
#set_property -dict {PACKAGE_PIN AC8   IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK0_M2C_N}]
#set_property -dict {PACKAGE_PIN AB8   IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK0_M2C_P}]
#set_property -dict {PACKAGE_PIN W6    IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK1_M2C_N}]
#set_property -dict {PACKAGE_PIN W7    IOSTANDARD LVCMOS18  } [get_ports {FMC_CLK1_M2C_P}]
# set_property PACKAGE_PIN G7    [get_ports {FMC_GCLK0_M2C_N}] # GTH
# set_property PACKAGE_PIN G8    [get_ports {FMC_GCLK0_M2C_P}] # GTH
# set_property PACKAGE_PIN L7    [get_ports {FMC_GCLK1_M2C_N}] # GTH
# set_property PACKAGE_PIN L8    [get_ports {FMC_GCLK1_M2C_P}] # GTH

#set_property -dict {PACKAGE_PIN AE12  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA06_N}]
#set_property -dict {PACKAGE_PIN AD12  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA06_P}]
#set_property -dict {PACKAGE_PIN W1    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA07_N}]
#set_property -dict {PACKAGE_PIN W2    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA07_P}]
#set_property -dict {PACKAGE_PIN AD11  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA08_N}]
#set_property -dict {PACKAGE_PIN AC11  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA08_P}]
#set_property -dict {PACKAGE_PIN V1    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA09_N}]
#set_property -dict {PACKAGE_PIN V2    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA09_P}]
#set_property -dict {PACKAGE_PIN AA11  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA10_N}]
#set_property -dict {PACKAGE_PIN AA12  IOSTANDARD LVCMOS18  } [get_ports {FMC_HA10_P}]
#set_property -dict {PACKAGE_PIN U3    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA11_N}]
#set_property -dict {PACKAGE_PIN U2    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA11_P}]
#set_property -dict {PACKAGE_PIN AE1   IOSTANDARD LVCMOS18  } [get_ports {FMC_HA12_N}]
#set_property -dict {PACKAGE_PIN AE7   IOSTANDARD LVCMOS18  } [get_ports {FMC_HA12_P}]
#set_property -dict {PACKAGE_PIN N11   IOSTANDARD LVCMOS18  } [get_ports {FMC_HA13_N}]
#set_property -dict {PACKAGE_PIN Y10   IOSTANDARD LVCMOS18  } [get_ports {FMC_HA13_P}]
#set_property -dict {PACKAGE_PIN AD7   IOSTANDARD LVCMOS18  } [get_ports {FMC_HA00_CC_N}]
#set_property -dict {PACKAGE_PIN AC7   IOSTANDARD LVCMOS18  } [get_ports {FMC_HA00_CC_P}]
#set_property -dict {PACKAGE_PIN V6    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA01_CC_N}]
#set_property -dict {PACKAGE_PIN V7    IOSTANDARD LVCMOS18  } [get_ports {FMC_HA01_CC_P}]

# HDMI
#set_property -dict {PACKAGE_PIN B15   IOSTANDARD LVCMOS18  } [get_ports {HDMI_HPD}]
# set_property PACKAGE_PIN P5    [get_ports {HDMI_D0_N}] # GTH
# set_property PACKAGE_PIN P6    [get_ports {HDMI_D0_P}] # GTH
# set_property PACKAGE_PIN N3    [get_ports {HDMI_D1_N}] # GTH
# set_property PACKAGE_PIN N4    [get_ports {HDMI_D1_P}] # GTH
# set_property PACKAGE_PIN M5    [get_ports {HDMI_D2_N}] # GTH
# set_property PACKAGE_PIN M6    [get_ports {HDMI_D2_P}] # GTH
#set_property -dict {PACKAGE_PIN AK11  IOSTANDARD LVDS      } [get_ports {HDMI_CLK_N}]
#set_property -dict {PACKAGE_PIN AJ11  IOSTANDARD LVDS      } [get_ports {HDMI_CLK_P}]

# I2C FPGA
#set_property -dict {PACKAGE_PIN C14   IOSTANDARD LVCMOS18  } [get_ports {I2C_SCL_FPGA}]
#set_property -dict {PACKAGE_PIN C13   IOSTANDARD LVCMOS18  } [get_ports {I2C_SDA_FPGA}]

# I2C_MIPI_SEL
#set_property -dict {PACKAGE_PIN A15   IOSTANDARD LVCMOS18  } [get_ports {I2C_MIPI_SEL}]

# I2C PL
#set_property -dict {PACKAGE_PIN V3    IOSTANDARD LVCMOS18  } [get_ports {I2C_SCL}]
#set_property -dict {PACKAGE_PIN Y7    IOSTANDARD LVCMOS18  } [get_ports {I2C_SDA}]

# IO3
#set_property -dict {PACKAGE_PIN D15   IOSTANDARD LVCMOS18  } [get_ports {IO3_D0_P}]
#set_property -dict {PACKAGE_PIN D14   IOSTANDARD LVCMOS18  } [get_ports {IO3_D1_N}]
#set_property -dict {PACKAGE_PIN B14   IOSTANDARD LVCMOS18  } [get_ports {IO3_D2_P}]
#set_property -dict {PACKAGE_PIN A14   IOSTANDARD LVCMOS18  } [get_ports {IO3_D3_N}]
#set_property -dict {PACKAGE_PIN B13   IOSTANDARD LVCMOS18  } [get_ports {IO3_D4_P}]
#set_property -dict {PACKAGE_PIN A13   IOSTANDARD LVCMOS18  } [get_ports {IO3_D5_N}]
#set_property -dict {PACKAGE_PIN H14   IOSTANDARD LVCMOS18  } [get_ports {IO3_D6_P}]
#set_property -dict {PACKAGE_PIN H13   IOSTANDARD LVCMOS18  } [get_ports {IO3_D7_N}]

# IO4
#set_property -dict {PACKAGE_PIN K15   IOSTANDARD LVCMOS18  } [get_ports {IO4_D2_P}]
#set_property -dict {PACKAGE_PIN J15   IOSTANDARD LVCMOS18  } [get_ports {IO4_D3_N}]
#set_property -dict {PACKAGE_PIN G15   IOSTANDARD LVCMOS18  } [get_ports {IO4_D4_P}]
#set_property -dict {PACKAGE_PIN G14   IOSTANDARD LVCMOS18  } [get_ports {IO4_D5_N}]
#set_property -dict {PACKAGE_PIN F15   IOSTANDARD LVCMOS18  } [get_ports {IO4_D6_P}]
#set_property -dict {PACKAGE_PIN E15   IOSTANDARD LVCMOS18  } [get_ports {IO4_D7_N}]

# LED
#set_property -dict {PACKAGE_PIN AE8   IOSTANDARD LVCMOS18  } [get_ports {LED2_N_PWR_SYNC}]

# Oscillator 100 MHz
#set_property -dict {PACKAGE_PIN J14   IOSTANDARD LVCMOS18  } [get_ports {CLK_100_CAL}]

# SFP
# set_property PACKAGE_PIN L3    [get_ports {SFP_RX_N}] # GTH
# set_property PACKAGE_PIN L4    [get_ports {SFP_RX_P}] # GTH
# set_property PACKAGE_PIN K5    [get_ports {SFP_TX_N}] # GTH
# set_property PACKAGE_PIN K6    [get_ports {SFP_TX_P}] # GTH

# ST1 LED
#set_property -dict {PACKAGE_PIN AH4   IOSTANDARD LVCMOS18  } [get_ports {LED2}]
#set_property -dict {PACKAGE_PIN AJ4   IOSTANDARD LVCMOS18  } [get_ports {LED3}]
