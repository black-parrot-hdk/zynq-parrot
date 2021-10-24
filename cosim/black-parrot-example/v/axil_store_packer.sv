
// This module converts an AXI load/store into a store in the following format
//   {write_not_read, addr[22:0], data[7:0]}
//  Loads will then ready for data to come back as a blocking operation
// This module relies on the read/write channels being mutex, as is the
//   case for BP axi. This makes it incompatible with general axi-lite
// To avoid dealing with ordering transactions, only 1 req is outstanding
// We could very easily increase throughput here, but wait until it's a bottleneck

`include "bp_me_defines.svh"

module axil_store_packer
 import bp_me_pkg::*;
 #(parameter `BSG_INV_PARAM(axi_addr_width_p)
   , parameter `BSG_INV_PARAM(axi_data_width_p)
   )
   (input clk_i
    , input reset_i

    //====================== AXI-4 LITE =========================
    // WRITE ADDRESS CHANNEL SIGNALS
    , input [axi_addr_width_p-1:0]               s_axi_awaddr_i
    , input axi_prot_type_e                      s_axi_awprot_i
    , input                                      s_axi_awvalid_i
    , output logic                               s_axi_awready_o

    // WRITE DATA CHANNEL SIGNALS
    , input [axi_data_width_p-1:0]               s_axi_wdata_i
    , input [axi_data_width_p>>3-1:0]            s_axi_wstrb_i // unused
    , input                                      s_axi_wvalid_i
    , output logic                               s_axi_wready_o

    // WRITE RESPONSE CHANNEL SIGNALS
    , output axi_resp_type_e                     s_axi_bresp_o
    , output logic                               s_axi_bvalid_o
    , input                                      s_axi_bready_i

    // READ ADDRESS CHANNEL SIGNALS
    , input [axi_addr_width_p-1:0]               s_axi_araddr_i
    , input axi_prot_type_e                      s_axi_arprot_i
    , input                                      s_axi_arvalid_i
    , output logic                               s_axi_arready_o

    // READ DATA CHANNEL SIGNALS
    , output logic [axi_data_width_p-1:0]        s_axi_rdata_o
    , output axi_resp_type_e                     s_axi_rresp_o
    , output logic                               s_axi_rvalid_o
    , input                                      s_axi_rready_i

    , output logic [31:0]                        data_o
    , output logic                               v_o
    , input                                      ready_i

    , input [31:0]                               data_i
    , input                                      v_i
    , output logic                               ready_o
    );

  enum {e_ready, e_read_resp, e_write_resp} state_n, state_r;
  wire is_ready      = (state_r == e_ready);
  wire is_read_resp  = (state_r == e_read_resp);
  wire is_write_resp = (state_r == e_write_resp);

  // Ready for a request if we can send it out to the fifo
  assign s_axi_awready_o = is_ready & ready_i;
  assign s_axi_wready_o  = is_ready & ready_i;
  assign s_axi_arready_o = is_ready & ready_i;

  // Don't support errors
  assign s_axi_bresp_o = e_axi_resp_okay;
  assign s_axi_rresp_o = e_axi_resp_okay;

  assign s_axi_rdata_o = data_i;
  assign ready_o = s_axi_rready_i;

  wire [31:0] read_cmd_lo  = {1'b0, s_axi_araddr_i[22:0], 8'b0};
  wire [31:0] write_cmd_lo = {1'b1, s_axi_awaddr_i[22:0], s_axi_wdata_i[7:0]};

  always_comb
    begin
      s_axi_bvalid_o  = '0;
      s_axi_rvalid_o  = '0;

      data_o = '0;
      v_o    = '0;

      case (state_r)
        e_ready:
          begin
            v_o = (s_axi_awready_o & s_axi_awvalid_i & s_axi_wready_o & s_axi_wvalid_i)
              || (s_axi_arready_o & s_axi_arvalid_i);

            data_o = s_axi_arvalid_i ? read_cmd_lo : write_cmd_lo;

            state_n = v_o
              ? s_axi_arvalid_i
                ? e_read_resp
                : e_write_resp
              : e_ready;
          end

        e_read_resp:
          begin
            s_axi_rvalid_o = v_i;

            state_n = (s_axi_rready_i & s_axi_rvalid_o) ? e_ready : e_read_resp;
          end

        e_write_resp:
          begin
            s_axi_bvalid_o = 1'b1;

            state_n = (s_axi_bready_i & s_axi_bvalid_o) ? e_ready : e_write_resp;
          end
      endcase
    end

  // synopsys sync_set_reset reset_i
  always_ff @(posedge clk_i)
    if (reset_i)
      state_r <= e_ready;
    else
      state_r <= state_n;

  // synopsys translate_off
  always_ff @(negedge clk_i)
    begin
      assert(~(s_axi_awvalid_i & s_axi_arvalid_i))
        else $error("AXI lite requests must be mutex in this module.");
    end
  // synopsys translate_on

endmodule

