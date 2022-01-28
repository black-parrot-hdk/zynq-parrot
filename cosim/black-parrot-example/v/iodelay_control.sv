module iodelay_control(
    input logic clk_i
  , input logic reset_r_i
  , input logic iodelay_ref_clk_i
);

`ifdef FPGA
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    logic [3:0] reset_iodelay_sync_r;

    BUFG iodelay_ref_clk_bufg(
        .I(iodelay_ref_clk_i)
       ,.O(iodelay_ref_clk_lo)
    );
`else
    logic [3:0] reset_iodelay_sync_r;
    assign iodelay_ref_clk_lo = iodelay_ref_clk_i;
`endif

    logic       reset_iodelay_li;

    // reset sync logic for iodelay control
    always @(posedge iodelay_ref_clk_lo or posedge reset_r_i) begin
        if(reset_r_i)
            reset_iodelay_sync_r <= '1;
        else
            reset_iodelay_sync_r <= {1'b0, reset_iodelay_sync_r[3:1]};
    end
    assign reset_iodelay_li = reset_iodelay_sync_r[0];

    logic reset_iodelay_hold_r;
    logic [3:0] reset_iodelay_hold_cnt_r;
    wire down_li = (reset_iodelay_hold_cnt_r != '0);
    bsg_counter_set_down #(
        .width_p(4)
       ,.init_val_p(4'b1111) // hold high for more than 60ns
        ) reset_iodelay_hold_cnt_reg (
        .clk_i(iodelay_ref_clk_lo)
       ,.reset_i(reset_iodelay_li)
       ,.set_i(1'b0) /* UNUSED */
       ,.val_i('0) /* UNUSED */
       ,.down_i(down_li)
       ,.count_r_o(reset_iodelay_hold_cnt_r)
        );

    wire data_li = (reset_iodelay_hold_cnt_r != '0);
    bsg_dff_reset #(
        .width_p(1)
       ,.reset_val_p(1'b1)
        ) reset_iodelay_hold_reg (
        .clk_i(iodelay_ref_clk_lo)
       ,.reset_i(reset_iodelay_li)
       ,.data_i(data_li)
       ,.data_o(reset_iodelay_hold_r)
        );

`ifdef FPGA
    IDELAYCTRL idelayctrl_inst (
        .RDY(/* UNUSED */)
        ,.REFCLK(iodelay_ref_clk_lo)
        ,.RST(reset_iodelay_hold_r) // active-high reset
    );

`endif
endmodule
