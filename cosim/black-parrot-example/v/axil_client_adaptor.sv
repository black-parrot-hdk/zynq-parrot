
module axil_client_adaptor
 #(
  // AXI CHANNEL PARAMS
    parameter axil_data_width_p = 32
  , parameter axil_addr_width_p = 32
  )

  (//==================== GLOBAL SIGNALS =======================
   input                                        clk_i
   , input                                      reset_i

   //==================== HOST SIGNALS ======================
   , output logic                               v_o
   , input                                      ready_and_i
   , output logic [axil_addr_width_p-1:0]       addr_o
   , output logic                               wr_en_o
   , output logic [1:0]                         data_size_o
   , output logic [axil_data_width_p-1:0]       wdata_o

   , input                                      v_i
   , output logic                               ready_and_o
   , input [axil_data_width_p-1:0]              rdata_i

   //====================== AXI-4 LITE =========================
   // WRITE ADDRESS CHANNEL SIGNALS
   , input [axil_addr_width_p-1:0]              s_axil_awaddr_i
   , input [2:0]                                s_axil_awprot_i
   , input                                      s_axil_awvalid_i
   , output logic                               s_axil_awready_o

   // WRITE DATA CHANNEL SIGNALS
   , input [axil_data_width_p-1:0]              s_axil_wdata_i
   , input [(axil_data_width_p>>3)-1:0]         s_axil_wstrb_i
   , input                                      s_axil_wvalid_i
   , output logic                               s_axil_wready_o

   // WRITE RESPONSE CHANNEL SIGNALS
   , output logic [1:0]                         s_axil_bresp_o
   , output logic                               s_axil_bvalid_o
   , input                                      s_axil_bready_i

   // READ ADDRESS CHANNEL SIGNALS
   , input [axil_addr_width_p-1:0]              s_axil_araddr_i
   , input [2:0]                                s_axil_arprot_i
   , input                                      s_axil_arvalid_i
   , output logic                               s_axil_arready_o

   // READ DATA CHANNEL SIGNALS
   , output logic [axil_data_width_p-1:0]       s_axil_rdata_o
   , output logic [1:0]                         s_axil_rresp_o
   , output logic                               s_axil_rvalid_o
   , input                                      s_axil_rready_i
  );

  localparam e_axi_prot_default = 3'b000;
  localparam e_axi_resp_okay    = 2'b00;

  wire unused = &{s_axil_awprot_i, s_axil_arprot_i};

  // Declaring all possible states
  enum {e_wait, e_read_resp, e_write_resp} state_n, state_r;

  always_comb
    begin
      state_n = state_r;

      // HOST side
      addr_o         = '0;
      wdata_o        = '0;
      wr_en_o        = '0;
      v_o            = '0;
      ready_and_o    = '0;


      // set default size
      data_size_o = (axil_data_width_p == 32) ? 2'b10 : 2'b11;


      // WRITE ADDRESS CHANNEL SIGNALS
      s_axil_awready_o = '0;

      // WRITE DATA CHANNEL SIGNALS
      s_axil_wready_o  = '0;

      // READ ADDRESS CHANNEL SIGNALS
      s_axil_arready_o = '0;

      // READ DATA CHANNEL SIGNALS
      s_axil_rdata_o   = '0;
      s_axil_rresp_o   = e_axi_resp_okay;
      s_axil_rvalid_o  = '0;

      // WRITE RESPONSE CHANNEL SIGNALS
      s_axil_bresp_o   = e_axi_resp_okay;
      s_axil_bvalid_o  = '0;

      if (s_axil_wvalid_i) begin
        case (s_axil_wstrb_i)
          (axil_data_width_p>>3)'('h1)  : data_size_o = 2'b00;
          (axil_data_width_p>>3)'('h3)  : data_size_o = 2'b01;
          (axil_data_width_p>>3)'('hF)  : data_size_o = 2'b10;
          (axil_data_width_p>>3)'('hFF) : data_size_o = 2'b11;
          default:
            $warning("%m: received unhandled strobe pattern %b\n",s_axil_wstrb_i);
        endcase
      end

      unique casez (state_r)
        e_wait:
          begin
            // TODO: This assumes that we can either get a read/write, but not both.
            //   Generally this is a good assumption, but is non-compliant with AXI
            // Wait until Host is ready to receive the data

            if (s_axil_arvalid_i)
              begin
                addr_o           = s_axil_araddr_i;
                wr_en_o          = 1'b0;
                v_o              = 1'b1;
                s_axil_arready_o = ready_and_i;

                state_n = (s_axil_arready_o & s_axil_arvalid_i) ? e_read_resp : e_wait;
              end
            else if (s_axil_awvalid_i & s_axil_wvalid_i)
              begin
                addr_o                = s_axil_awaddr_i;
                wr_en_o               = 1'b1;
                wdata_o               = s_axil_wdata_i;
                v_o                   = 1'b1;

                s_axil_awready_o = ready_and_i;
                s_axil_wready_o  = ready_and_i;

                state_n = (s_axil_awready_o & s_axil_awvalid_i
                        & s_axil_wready_o & s_axil_wvalid_i) ? 
                            e_write_resp : e_wait;
              end
          end

        e_write_resp:
          begin
            s_axil_bvalid_o  = v_i;
            ready_and_o = s_axil_bready_i;
            state_n = (s_axil_bvalid_o & s_axil_bready_i) ? e_wait : state_r;
          end

        e_read_resp:
          begin
            s_axil_rdata_o  = rdata_i;
            s_axil_rvalid_o = v_i;
            ready_and_o     = s_axil_rready_i;

            state_n = (ready_and_o & v_i) ? e_wait : state_r;
          end

        default: state_n = state_r;
      endcase
    end

  // synopsys sync_set_reset "reset_i"
  always_ff @(posedge clk_i)
    if (reset_i)
      state_r <= e_wait;
    else
      state_r <= state_n;

  if (axil_data_width_p != 64 && axil_data_width_p != 32)
    $fatal("AXI4-LITE only supports a data width of 32 or 64 bits.");

  //synopsys translate_off
  initial
    begin
       $display("## axil_to_bp_lite_client: instantiating with axil_data_width_p=%d, axil_addr_width_p=%d (%m)\n",axil_data_width_p,axil_addr_width_p);
    end

/*  always_ff @(negedge clk_i)
    begin
      if (s_axil_awprot_i != 3'b000)
        $error("AXI4-LITE access permission mode is not supported.");
    end*/
  assert property (@(posedge clk_i)(s_axil_awprot_i == 3'b000))
    else $error("AXI4-LITE access permission mode is not supported.");
  // synopsys translate_on

endmodule

