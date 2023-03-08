
`include "bsg_defines.v"

module bsg_axil_watchdog
 import zynq_pkg::*;
 import bsg_tag_pkg::*;
 #(// The period of the watchdog (default to 1s @25MHz)
   parameter watchdog_period_p = 25000000
   // AXI WRITE DATA CHANNEL PARAMS
   , parameter axil_data_width_p = 32
   , parameter axil_addr_width_p = 32
   )
  (input                                        clk_i
   , input                                      reset_i

   , input                                      tag_clk_i
   , input                                      tag_data_i

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

   zynq_wd_tag_lines_s tag_lines_lo;
   bsg_tag_master_decentralized
    #(.els_p(tag_els_gp)
      ,.local_els_p(tag_wd_local_els_gp)
      ,.lg_width_p(tag_lg_width_gp)
      )
    btm
     (.clk_i(tag_clk_i)
      ,.data_i(tag_data_i)
      ,.node_id_offset_i(tag_wd_offset_gp)
      ,.clients_o(tag_lines_lo)
      );

   wire tag_reset_li;
   bsg_tag_client
    #(.width_p(1))
    btc
     (.bsg_tag_i(tag_lines_lo.core_reset)
      ,.recv_clk_i(clk_i)
      ,.recv_new_r_o() // UNUSED
      ,.recv_data_r_o(tag_reset_li)
      );
  wire core_reset_li = reset_i | tag_reset_li;

  logic [`BSG_SAFE_CLOG2(watchdog_period_p)-1:0] watchdog_cnt;
  logic watchdog_tick;
  bsg_counter_clear_up
   #(.max_val_p(watchdog_period_p-1)
     ,.init_val_p(0)
     ,.disable_overflow_warning_p(1)
     )
   watchdog_counter
    (.clk_i(clk_i)
     ,.reset_i(core_reset_li)

     ,.clear_i(1'b0)
     ,.up_i(watchdog_tick)
     ,.count_o(watchdog_cnt)
     );
  wire watchdog_send = (watchdog_cnt == '0);

  logic [axil_data_width_p-1:0] wdata_li;
  logic [axil_addr_width_p-1:0] addr_li;
  logic v_li, w_li, ready_and_lo;
  logic [(axil_data_width_p>>3)-1:0] wmask_li; 
  bsg_axil_fifo_master
   #(.axil_data_width_p(axil_data_width_p)
     ,.axil_addr_width_p(axil_addr_width_p)
     )
   fifo_master
    (.clk_i(clk_i)
     ,.reset_i(core_reset_li)

     ,.data_i(wdata_li)
     ,.addr_i(addr_li)
     ,.v_i(v_li)
     ,.w_i(w_li)
     ,.wmask_i(wmask_li)
     ,.ready_and_o(ready_and_lo)

     // We auto-ack and do not check result
     ,.data_o()
     ,.v_o()
     ,.ready_and_i(1'b1)

     ,.*
     );

  always_comb
    begin
      wdata_li = 1'b1;
      // Hardcoded for now
      addr_li = 32'h103000;
      v_li = watchdog_send;
      w_li = 1'b1;
      wmask_li = '1;

      watchdog_tick = ~watchdog_send || (ready_and_lo & v_li);
    end

endmodule

