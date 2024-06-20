
`include "bsg_defines.sv"

module bsg_axil_store_packer
 import bsg_axi_pkg::*;
 #(parameter `BSG_INV_PARAM(axil_data_width_p)

   , localparam axis_mask_width_lp = axis_data_width_p>>3
   )
   (input clk_i
    , input reset_i

    , output logic                               ready_o
    , input                                      v_i
    , input [axil_data_width_p-1:0]              data_i

    //====================== AXI-4 STREAM =========================
    , input                                 m_axis_tready_i
    , output logic                          m_axis_tvalid_o
    , output logic [axis_data_width_p-1:0]  m_axis_tdata_o
    , output logic [axis_mask_width_lp-1:0] m_axis_tkeep_o
    , output logic                          m_axis_tlast_o
    );

  assign m_axis_tdata_o = data_i;
  assign m_axis_tvalid_o = v_i;
  assign ready_o = m_axis_tready_i;
  

  enum logic [2:0] {e_ready, e_write_req, e_read_req, e_read_resp, e_write_resp} state_n, state_r;
  wire is_ready      = (state_r == e_ready);
  wire is_write_req  = (state_r == e_write_req);
  wire is_read_req   = (state_r == e_read_req);
  wire is_read_resp  = (state_r == e_read_resp);
  wire is_write_resp = (state_r == e_write_resp);

  // Don't support errors
  assign s_axil_bresp_o = e_axi_resp_okay;
  assign s_axil_rresp_o = e_axi_resp_okay;

  assign s_axil_rdata_o = data_i;
  assign ready_o = s_axil_rready_i;

  wire [axil_data_width_p-1:0] read_cmd_lo =
    {1'b0, s_axil_araddr_i[0+:payload_addr_width_p], {payload_data_width_p{1'b0}}};
  wire [axil_data_width_p-1:0] write_cmd_lo =
    {1'b1, s_axil_awaddr_i[0+:payload_addr_width_p], s_axil_wdata_i[0+:payload_data_width_p]};

  always_comb
    begin
      s_axil_awready_o = '0;
      s_axil_wready_o  = '0;
      s_axil_arready_o = '0;

      s_axil_bvalid_o  = '0;
      s_axil_rvalid_o  = '0;

      data_o = '0;
      v_o    = '0;
      state_n = state_r;

      case (state_r)
        e_ready:
          begin
            state_n = (s_axil_awvalid_i & s_axil_wvalid_i)
                      ? e_write_req
                      : s_axil_arvalid_i
                        ? e_read_req
                        : e_ready;
          end

        e_write_req:
          begin
            v_o = 1'b1;
            s_axil_awready_o = ready_i;
            s_axil_wready_o = ready_i;
            data_o = write_cmd_lo;

            state_n = (ready_i & v_o) ? e_write_resp : e_write_req;
          end

        e_read_req:
          begin
            v_o = 1'b1;
            s_axil_arready_o = ready_i;
            data_o = read_cmd_lo;

            state_n = (ready_i & v_o) ? e_read_resp : e_read_req;
          end

        e_read_resp:
          begin
            s_axil_rvalid_o = v_i;

            state_n = (s_axil_rready_i & s_axil_rvalid_o) ? e_ready : e_read_resp;
          end

        e_write_resp:
          begin
            s_axil_bvalid_o = 1'b1;

            state_n = (s_axil_bready_i & s_axil_bvalid_o) ? e_ready : e_write_resp;
          end
      endcase
    end

  // synopsys sync_set_reset reset_i
  always_ff @(posedge clk_i)
    if (reset_i)
      state_r <= e_ready;
    else
      state_r <= state_n;

endmodule

`BSG_ABSTRACT_MODULE(bsg_axil_store_packer)

