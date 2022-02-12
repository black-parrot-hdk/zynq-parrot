
module rv_plic_wrapper
    import rv_plic_reg_pkg::*; #(
      parameter axil_data_width_p = 32
    , parameter axil_addr_width_p = 32
    // {Ethernet INT, Reserved}
    , localparam int SRCW    = $clog2(NumSrc)
  )
  (
      input                                      clk_i
    , input                                      reset_i
    // Interrupt Sources
    , input       [NumSrc-1:0]                   intr_src_i
    //====================== AXI-4 LITE (Master) =========================
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

    //====================== AXI-4 LITE (Slave) =========================
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

  parameter reg_width_p      = top_pkg::TL_DW;
  parameter reg_addr_width_p = top_pkg::TL_AW;
  localparam plic_addr_width_lp = 22;
  localparam s_mode_plic_addr_lp = 'h30_b004;

  // Interrupt notification to targets
  logic [NumTarget-1:0]                   irq_lo; // eip

  // Bus Interface (device)
  tlul_pkg::tl_h2d_t tl_li;
  tlul_pkg::tl_d2h_t tl_lo;

  logic [axil_addr_width_p-1:0] cmd_addr_li, cmd_addr_lo;
  logic                         cmd_wr_en_li, cmd_wr_en_lo;
  logic [1:0]                   cmd_data_size_li, cmd_data_size_lo;
  logic [axil_data_width_p-1:0] cmd_wdata_li, cmd_wdata_lo;
                                            
  logic [axil_data_width_p-1:0] resp_rdata_li;

  logic                         tlul_req_li;
  logic                         tlul_gnt_lo;
  logic [top_pkg::TL_AW-1:0]    tlul_addr_li;
  logic                         tlul_we_li;
  logic [top_pkg::TL_DW-1:0]    tlul_wdata_li;
  logic [top_pkg::TL_DBW-1:0]   tlul_be_li;
                                
  logic                         tlul_valid_lo;
  logic [top_pkg::TL_DW-1:0]    tlul_rdata_lo;
  logic [top_pkg::TL_DW-1:0]    tlul_rdata_packed_lo;

  axil_client_adaptor #(
    .axil_data_width_p(reg_width_p)
   ,.axil_addr_width_p(reg_addr_width_p)
  ) adaptor (
    .clk_i(clk_i)
   ,.reset_i(reset_i)

   ,.cmd_v_o(input_fifo_v_li)
   ,.cmd_ready_and_i(input_fifo_ready_lo)
   ,.cmd_addr_o(cmd_addr_li)
   ,.cmd_wr_en_o(cmd_wr_en_li)
   ,.cmd_data_size_o(cmd_data_size_li)
   ,.cmd_wdata_o(cmd_wdata_li)
                    
   ,.resp_v_i(output_fifo_v_lo)
   ,.resp_ready_and_o(output_fifo_ready_and_li)
   ,.resp_rdata_i(resp_rdata_li)
                    
   ,.s_axil_awaddr_i
   ,.s_axil_awprot_i
   ,.s_axil_awvalid_i
   ,.s_axil_awready_o
                    
   ,.s_axil_wdata_i
   ,.s_axil_wstrb_i
   ,.s_axil_wvalid_i
   ,.s_axil_wready_o
                    
   ,.s_axil_bresp_o
   ,.s_axil_bvalid_o
   ,.s_axil_bready_i
                    
   ,.s_axil_araddr_i
   ,.s_axil_arprot_i
   ,.s_axil_arvalid_i
   ,.s_axil_arready_o
                    
   ,.s_axil_rdata_o
   ,.s_axil_rresp_o
   ,.s_axil_rvalid_o
   ,.s_axil_rready_i
  );

  wire output_fifo_yumi = output_fifo_v_lo & output_fifo_ready_and_li;
  wire tlul_ack = tlul_req_li & tlul_gnt_lo;
  // allow only 1 outstanding req at a time
  logic next_req_disable_r;
  bsg_dff_reset_set_clear #(
    .width_p(1)
    ,.clear_over_set_p(0)
  ) next_req_disable_reg (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(tlul_ack)
    ,.clear_i(output_fifo_yumi)
    ,.data_o(next_req_disable_r)
    );

  bsg_one_fifo #(
    .width_p(reg_width_p + reg_addr_width_p + 2 + 1))
   input_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i({cmd_wdata_li, cmd_addr_li, cmd_data_size_li, cmd_wr_en_li})
    ,.v_i(input_fifo_v_li)
    ,.ready_o(input_fifo_ready_lo)
    ,.data_o({cmd_wdata_lo, cmd_addr_lo, cmd_data_size_lo, cmd_wr_en_lo})
    ,.v_o(input_fifo_v_o)
    ,.yumi_i(output_fifo_yumi)
    );
  bsg_bus_pack
   #(.in_width_p(reg_width_p))
    bus_pack
     (.data_i(tlul_rdata_lo)
      ,.sel_i('b0)
      ,.size_i(cmd_data_size_lo)
      ,.data_o(tlul_rdata_packed_lo)
      );
  bsg_one_fifo #(
    .width_p(reg_width_p))
   output_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(tlul_rdata_packed_lo)
    ,.v_i(tlul_valid_lo)
    ,.ready_o(/* UNUSED */)
    ,.data_o(resp_rdata_li)
    ,.v_o(output_fifo_v_lo)
    ,.yumi_i(output_fifo_yumi)
   );
  assign tlul_req_li = input_fifo_v_o & ~next_req_disable_r;
  assign tlul_addr_li = (top_pkg::TL_AW)'(cmd_addr_lo[plic_addr_width_lp-1:0]);
  assign tlul_we_li  = cmd_wr_en_lo;
  assign tlul_wdata_li = cmd_wdata_lo;
  assign tlul_be_li = '1; // write strobe == '1

  assign rst_ni = ~reset_i;
  rv_plic rv_plic (
    .clk_i(clk_i)
   ,.rst_ni(rst_ni)

    // Bus Interface (device)
   ,.tl_i(tl_li)
   ,.tl_o(tl_lo)

    // Interrupt Sources
   ,.intr_src_i(intr_src_i)

   ,.alert_rx_i(/* UNUSED */)
   ,.alert_tx_o(/* UNUSED */)

    // Interrupt notification to targets
   ,.irq_o(irq_lo) // per target
   ,.irq_id_o(/* UNUSED */) // per target
   ,.msip_o(/* UNUSED */)
  );


  tlul_adapter_host #(
    .MAX_REQS(1)
   ,.EnableDataIntgGen(1)
  ) tlul_adapter_host (
    .clk_i(clk_i)
   ,.rst_ni(rst_ni)

   ,.req_i(tlul_req_li)
   ,.gnt_o(tlul_gnt_lo)
   ,.addr_i(tlul_addr_li)
   ,.we_i(tlul_we_li)
   ,.wdata_i(tlul_wdata_li)
   ,.wdata_intg_i(/* UNUSED */)
   ,.be_i(tlul_be_li)
   ,.instr_type_i(prim_mubi_pkg::MuBi4False) /* UNUSED */
              
   ,.valid_o(tlul_valid_lo)
   ,.rdata_o(tlul_rdata_lo)
   ,.rdata_intg_o(/* UNUSED */)
   ,.err_o(/* UNUSED */)
   ,.intg_err_o(/* UNUSED */)

   ,.tl_o(tl_li)
   ,.tl_i(tl_lo)
  );

  irq_to_axil_adaptor #(
    .axil_data_width_p(axil_data_width_p)
    ,.axil_addr_width_p(axil_addr_width_p)
    ,.s_mode_plic_addr_p(s_mode_plic_addr_lp)
  ) irq_to_axil_adaptor (
      .clk_i(clk_i)                         
     ,.reset_i(reset_i)
     ,.irq_r_i(irq_lo)
                                 
     ,.m_axil_awaddr_o(m_axil_awaddr_o)
     ,.m_axil_awprot_o(m_axil_awprot_o)
     ,.m_axil_awvalid_o(m_axil_awvalid_o)
     ,.m_axil_awready_i(m_axil_awready_i)
                                 
     ,.m_axil_wdata_o(m_axil_wdata_o)
     ,.m_axil_wstrb_o(m_axil_wstrb_o)
     ,.m_axil_wvalid_o(m_axil_wvalid_o)
     ,.m_axil_wready_i(m_axil_wready_i)
                                 
     ,.m_axil_bresp_i(m_axil_bresp_i)
     ,.m_axil_bvalid_i(m_axil_bvalid_i)
     ,.m_axil_bready_o(m_axil_bready_o)
                                 
     ,.m_axil_araddr_o(m_axil_araddr_o)
     ,.m_axil_arprot_o(m_axil_arprot_o)
     ,.m_axil_arvalid_o(m_axil_arvalid_o)
     ,.m_axil_arready_i(m_axil_arready_i)
                                 
     ,.m_axil_rdata_i(m_axil_rdata_i)
     ,.m_axil_rresp_i(m_axil_rresp_i)
     ,.m_axil_rvalid_i(m_axil_rvalid_i)
     ,.m_axil_rready_o(m_axil_rready_o)
    );


  // synopsys translate_off
  always_ff @(posedge clk_i) begin
    if(~reset_i) begin
      if(axil_data_width_p > top_pkg::TL_DW
            || axil_addr_width_p > top_pkg::TL_AW) begin
        $display("rv_plic_top: tlul bus width too small");
      end
    end
  end              
  // synopsys translate_on

endmodule
