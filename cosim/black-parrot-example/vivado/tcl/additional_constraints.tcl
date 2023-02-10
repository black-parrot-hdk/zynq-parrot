
set bp_inst [join [get_cells -hier blackparrot]]

set bp_core_period [get_property PERIOD [get_clocks -of_object [get_pins $bp_inst/aclk]]]
set bp_rt_period [get_property PERIOD [get_clocks -of_object [get_pins $bp_inst/rt_clk]]]
set bp_min_period [expr $bp_rt_period < $bp_core_period ? $bp_rt_period : $bp_core_period]

set clint_inst [join [get_cells -hier -filter {(ORIG_REF_NAME == bp_me_clint_slice || REF_NAME == bp_me_clint_slice)}]]
if {[llength clint_inst] != 1} {
  error "More than one bp_me_clint_slice instance has been found"
}
create_generated_clock -name ds_by_16_clk -source [get_pins $clint_inst/ds/aclk] -divide_by 16 [get_pins $clint_inst/ds/clk_r_o_reg/Q]

# In BP, there is a 4-1 clock multiplexer that selects between 3 clocks and 1'b0 as the mtime clock.
# (The 4-1 clock mux)
#
#
#        |\
#    +---| \ (rtc_mux1)
#        | |-+
#    +---| / |  |\
#        |/  +--| \ (rtc_mux3)
#               | |---+
#        |\  +--| /
#    +---| \ |  |/
#        | |-+
#    +---| / (rtc_mux2)
#        |/
#
# 'join' converts a list into a string
set rtc_mux1 [join [get_cells -hier *bufgmux_ctrl1]]
set rtc_mux2 [join [get_cells -hier *bufgmux_ctrl2]]
set rtc_mux3 [join [get_cells -hier *bufgmux_ctrl3]]
#
# Ordinarily, we would create 2 generated clocks for rtc_mux1, 2 for rtc_mux2 and 4 for rtc_mux3 to
# consider all the 3 clocks during STA. For example, it could be something like
#
#   create_generated_clock -name rtc_mux1_src1 -divide_by 1 -add -master_clock clk1 \
#       -source [get_pins rtc_mux1/I0] [get_pins rtc_mux1/O]
#   create_generated_clock -name rtc_mux1_src2 -divide_by 1 -add -master_clock clk2 \
#       -source [get_pins rtc_mux1/I1] [get_pins rtc_mux1/O]
#   set_clock_groups -physically_exclusive -group rtc_mux1_src1 -group rtc_mux1_src2
#
#   create_generated_clock -name rtc_mux2_src1 -divide_by 1 -add -master_clock clk3 \
#       -source [get_pins rtc_mux2/I0] [get_pins rtc_mux2/O]
#   create_generated_clock -name rtc_mux2_src2 -divide_by 1 -add -master_clock clk4 \
#       -source [get_pins rtc_mux2/I1] [get_pins rtc_mux2/O]
#   set_clock_groups -physically_exclusive -group rtc_mux2_src1 -group rtc_mux2_src2
#
#   create_generated_clock -name rtc_mux3_src1 -divide_by 1 -add -master_clock rtc_mux1_src1 \
#       -source [get_pins rtc_mux3/I0] [get_pins rtc_mux3/O]
#   create_generated_clock -name rtc_mux3_src2 -divide_by 1 -add -master_clock rtc_mux1_src2 \
#       -source [get_pins rtc_mux3/I0] [get_pins rtc_mux3/O]
#   create_generated_clock -name rtc_mux3_src3 -divide_by 1 -add -master_clock rtc_mux2_src1 \
#       -source [get_pins rtc_mux3/I1] [get_pins rtc_mux3/O]
#   create_generated_clock -name rtc_mux3_src4 -divide_by 1 -add -master_clock rtc_mux2_src2 \
#       -source [get_pins rtc_mux3/I1] [get_pins rtc_mux3/O]
#   set_clock_groups -physically_exclusive -group rtc_mux3_src1 -group rtc_mux3_src2 -group rtc_mux3_src3 -group rtc_mux3_src4
#
# However, since
#   1. the w_reset_i pin of mtime_gray is wired to reset_i
#   2. the select for the 4-1 mux is initialized to 2'b00 when reset_i is high
#   3. clk_i is always faster than rt_clk_i
# , we should only consider clk_i for mtime clock. In order to do this, instead of creating all the generated clocks like
# the one in the above example, we only create necessary clocks for clk_i:
# clk_i running through rtc_mux1
create_generated_clock -name rtc_mux1_clk1 -divide_by 1 -source [get_pins $rtc_mux1/I0] -add -master_clock [get_clocks clk_fpga_0] [get_pins $rtc_mux1/O]
# clk_i running through rtc_mux3
create_generated_clock -name rtc_mux3_clk1 -divide_by 1 -source [get_pins $rtc_mux3/I0] -add -master_clock [get_clocks rtc_mux1_clk1] [get_pins $rtc_mux3/O]

# max delay for the bufgmux_ctrl primitives
set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*] $bp_min_period
set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*] $bp_min_period
set_max_delay -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*] $bp_min_period

set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux1/S*]
set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux2/S*]
set_false_path -hold -from [get_pins $clint_inst/mtimesel_reg/data_r_reg*/C] -to [get_pins $rtc_mux3/S*]

################# bsg_launch_sync_sync #################
foreach blss_inst [get_cells -hier -filter {(ORIG_REF_NAME == bsg_launch_sync_sync || REF_NAME == bsg_launch_sync_sync)}] {
  puts "blss_inst: $blss_inst"
  #foreach launch_reg [get_cells -regexp {$blss_inst/.*/bsg_SYNC_LNCH_r_reg\\[.*]}]
  foreach launch_reg [get_cells -regexp [format {%s/.*/bsg_SYNC_LNCH_r_reg\\[.*]} $blss_inst]] {
    # ASYNC_REG should have been applied in RTL
    regexp {([\w/.\[\]]+)/[\w]+\[([0-9]+)\]} $launch_reg -> path index

    set source_cell [get_cells $path/bsg_SYNC_LNCH_r_reg[$index]]
    set dest_cell  [get_cells $path/bsg_SYNC_1_r_reg[$index]]
    set write_clk [get_clocks -of_objects [get_pins $source_cell/C]]
    set read_clk [get_clocks -of_objects [get_pins $dest_cell/C]]
    set read_clk_period  [get_property -min PERIOD $read_clk]
    set write_clk_period [get_property -min PERIOD $write_clk]
    set min_clk_period [expr $read_clk_period < $write_clk_period ? $read_clk_period : $write_clk_period]
    # max delay between launch flop and sync_1 flop
    set_max_delay -from $source_cell -to $dest_cell -datapath_only $min_clk_period
  }
}
