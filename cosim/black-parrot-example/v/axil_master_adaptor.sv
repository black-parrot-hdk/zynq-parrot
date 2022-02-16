
module axil_master_adaptor #(
  // AXI WRITE DATA CHANNEL PARAMS
    parameter axil_data_width_p = 32
  , parameter axil_addr_width_p = 32
  )
 (//==================== GLOBAL SIGNALS =======================
  input                                        clk_i
  , input                                      reset_i

  //====================== AXI-4 LITE =========================
  // WRITE ADDRESS CHANNEL SIGNALS
  , output logic [axil_addr_width_p-1:0]       m_axil_awaddr_o
  , output logic [2:0]                         m_axil_awprot_o
  , output logic                               m_axil_awvalid_o
  , input                                      m_axil_awready_i

  // WRITE DATA CHANNEL SIGNALS
  , output logic [axil_data_width_p-1:0]       m_axil_wdata_o
  , output logic [(axil_data_width_p>>3)-1:0]  m_axil_wstrb_o
  , output logic                               m_axil_wvalid_o
  , input                                      m_axil_wready_i

  // WRITE RESPONSE CHANNEL SIGNALS
  , input [1:0]                                m_axil_bresp_i
  , input                                      m_axil_bvalid_i
  , output logic                               m_axil_bready_o

  // READ ADDRESS CHANNEL SIGNALS
  , output logic [axil_addr_width_p-1:0]       m_axil_araddr_o
  , output logic [2:0]                         m_axil_arprot_o
  , output logic                               m_axil_arvalid_o
  , input                                      m_axil_arready_i

  // READ DATA CHANNEL SIGNALS
  , input [axil_data_width_p-1:0]              m_axil_rdata_i
  , input [1:0]                                m_axil_rresp_i
  , input                                      m_axil_rvalid_i
  , output logic                               m_axil_rready_o

  //====================== HOST SIGNALS =========================
  , input  [axil_addr_width_p-1:0]             cmd_addr_i
  , input                                      cmd_v_i
  , output logic                               cmd_yumi_o
  , input                                      cmd_wr_en_i
  , input [1:0]                                cmd_data_size_i
  , input [axil_data_width_p-1:0]              cmd_wdata_i

  , output logic                               resp_v_o
  , input                                      resp_ready_and_i
  , output logic [axil_data_width_p-1:0]       resp_rdata_o
  );

  localparam e_axi_prot_default = 3'b000;
  // declaring all possible states
  enum {e_ready, e_read_data_tx, e_write_data_tx, e_write_resp_rx} state_r, state_n;

  // combinational Logic
  always_comb
    begin
      state_n = state_r;

      cmd_yumi_o = 1'b0;
      resp_rdata_o = m_axil_rdata_i;
      resp_v_o = 1'b0;

      // WRITE ADDRESS CHANNEL SIGNALS
      m_axil_awaddr_o  = cmd_addr_i;
      m_axil_awprot_o  = e_axi_prot_default;
      m_axil_awvalid_o = 1'b0;

      // WRITE DATA CHANNEL SIGNALS
      m_axil_wdata_o   = cmd_wdata_i;
      m_axil_wvalid_o  = 1'b0;

      // READ ADDRESS CHANNEL SIGNALS
      m_axil_araddr_o  = cmd_addr_i;
      m_axil_arprot_o  = e_axi_prot_default;
      m_axil_arvalid_o = 1'b0;

      // READ DATA CHANNEL SIGNALS
      m_axil_rready_o  = 1'b0;

      // WRITE RESPONSE CHANNEL SIGNALS
      m_axil_bready_o  = 1'b0;

      case (cmd_data_size_i)
        2'b00 : m_axil_wstrb_o = (axil_data_width_p>>3)'('h1);
        2'b01 : m_axil_wstrb_o = (axil_data_width_p>>3)'('h3);
        2'b10 : m_axil_wstrb_o = (axil_data_width_p>>3)'('hF);
        2'b11 : m_axil_wstrb_o = (axil_data_width_p>>3)'('hFF);
        default              : m_axil_wstrb_o = (axil_data_width_p>>3)'('h0);
      endcase

      case (state_r)
        e_ready:
          begin
            // if the client device is ready to receive, send the data along with the address
            if (cmd_v_i & cmd_wr_en_i)
              begin
                m_axil_awvalid_o   = 1'b1;
                m_axil_wvalid_o    = 1'b1;
                cmd_yumi_o = m_axil_awready_i;

                state_n = (m_axil_wready_i & m_axil_wvalid_o)
                  ? e_write_resp_rx
                  : (m_axil_awready_i & m_axil_awvalid_o)
                    ? e_write_data_tx
                    : e_ready;
              end

            else if (cmd_v_i & ~cmd_wr_en_i)
              begin
                m_axil_arvalid_o   = 1'b1;
                resp_v_o           = m_axil_rvalid_i;
                m_axil_rready_o    = resp_ready_and_i;
                cmd_yumi_o        = m_axil_arready_i;

                state_n = (m_axil_rready_o & m_axil_rvalid_i)
                          ? e_ready
                          : (m_axil_arready_i & m_axil_arvalid_o)
                            ? e_read_data_tx
                            : e_ready;
              end
          end

        e_write_data_tx:
          begin
            m_axil_wvalid_o    = 1'b1;
            cmd_yumi_o = m_axil_wready_i;

            state_n = (m_axil_wready_i & m_axil_wvalid_o) ? e_ready : e_write_data_tx;
          end

        e_write_resp_rx:
          begin
            m_axil_bready_o = resp_ready_and_i;
            resp_v_o     = m_axil_bvalid_i;
            state_n = (m_axil_bvalid_i & m_axil_bready_o) ? e_ready : state_r;
          end

       e_read_data_tx:
         begin
           m_axil_rready_o = resp_ready_and_i;
           resp_v_o        = m_axil_rvalid_i;

           state_n = (resp_ready_and_i & resp_v_o) ? e_ready : state_r;
         end

        default: state_n = state_r;
      endcase
    end

  // synopsys sync_set_reset "reset_i"
  always_ff @(posedge clk_i)
    begin
      if (reset_i)
        state_r <= e_ready;
      else
        state_r <= state_n;
    end

  if (axil_data_width_p != 32 && axil_data_width_p != 64)
    $error("AXI4-LITE only supports a data width of 32 or 64bits");

  //synopsys translate_off
/*  initial
    begin
      // give a warning if the client device has an error response
      assert(reset_i !== '0 || ~m_axil_rvalid_i || m_axil_rresp_i == '0) else $warning("Client device has an error response to reads");
      assert(reset_i !== '0 || ~m_axil_bvalid_i || m_axil_bresp_i == '0) else $warning("Client device has an error response to writes");
    end*/
  assert property (@(posedge clk_i) (reset_i !== '0 || ~m_axil_rvalid_i || m_axil_rresp_i == '0))
    else $warning("Client device has an error response to reads");
  assert property (@(posedge clk_i) (reset_i !== '0 || ~m_axil_bvalid_i || m_axil_bresp_i == '0))
    else $warning("Client device has an error response to writes");
  //synopsys translate_on

endmodule
