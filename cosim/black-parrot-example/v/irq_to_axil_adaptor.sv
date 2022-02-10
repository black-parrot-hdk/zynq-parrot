
`include "bsg_defines.v"

module irq_to_axil_adaptor #(
      parameter axil_data_width_p = 32
    , parameter axil_addr_width_p = 32
    , parameter `BSG_INV_PARAM(s_mode_plic_addr_p)
    , localparam NumTarget = 1 // We only support 1 target for now
    )
    (
      input  logic                               clk_i
    , input  logic                               reset_i
    // Interrupt notification
    , input  logic [NumTarget-1:0]               irq_r_i // help meet timing

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
    );

    logic                 cmd_v_li;
    logic                 cmd_yumi_lo;
    logic [NumTarget-1:0] irq_prev_r;
    wire level_change_detected = irq_r_i[0] ^ irq_prev_r[0];

    bsg_dff_reset #(.width_p(NumTarget))
      irq_prev_regs (
        .clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.data_i(irq_r_i[0])
       ,.data_o(irq_prev_r[0])
      );
    bsg_dff_reset_set_clear #(
        .width_p(NumTarget)
       ,.clear_over_set_p(0)
      ) pending_reg (
        .clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.set_i(level_change_detected)
       ,.clear_i(cmd_yumi_lo)
       ,.data_o(cmd_v_li)
      );
    axil_master_adaptor #(
        .axil_data_width_p(axil_data_width_p)
       ,.axil_addr_width_p(axil_addr_width_p)
    ) axil_master_adaptor (
        .clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.m_axil_awaddr_o
       ,.m_axil_awprot_o
       ,.m_axil_awvalid_o
       ,.m_axil_awready_i
       ,.m_axil_wdata_o
       ,.m_axil_wstrb_o
       ,.m_axil_wvalid_o
       ,.m_axil_wready_i
       ,.m_axil_bresp_i
       ,.m_axil_bvalid_i
       ,.m_axil_bready_o
       ,.m_axil_araddr_o
       ,.m_axil_arprot_o
       ,.m_axil_arvalid_o
       ,.m_axil_arready_i
       ,.m_axil_rdata_i
       ,.m_axil_rresp_i
       ,.m_axil_rvalid_i
       ,.m_axil_rready_o

       ,.cmd_addr_i(s_mode_plic_addr_p)
       ,.cmd_v_i(cmd_v_li)
       ,.cmd_yumi_o(cmd_yumi_lo)
       ,.cmd_wr_en_i(1'b1)
       ,.cmd_data_size_i('b10)
       ,.cmd_wdata_i(irq_r_i)

       ,.resp_v_o(/* UNUSED */)
       ,.resp_ready_and_i(1'b1)
       ,.resp_rdata_o(/* UNUSED */)
    );
    

endmodule
