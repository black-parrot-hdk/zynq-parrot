
`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_unicore_axi_sim
 import bp_common_pkg::*;
 import bp_me_pkg::*;
 // see bp_common/src/include/bp_common_aviary_pkgdef.svh for a list of configurations that you can try!
 // this design requires a unicore and an L2 (of any size)
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)

   // AXI4-LITE PARAMS
   , parameter axi_lite_addr_width_p   = 32
   , parameter axi_lite_data_width_p   = 32

   , parameter axi_addr_width_p = 32
   , parameter axi_data_width_p = 64
   
   , localparam uce_mem_data_width_lp = `BSG_MAX(icache_fill_width_p, dcache_fill_width_p)
   `declare_bp_bedrock_mem_if_widths(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce)
	 , localparam dma_pkt_width_lp = `bsg_cache_dma_pkt_width(caddr_width_p)
   )
  (input clk_i
  , input reset_i
 
	//========================Outgoing I/O========================
    , output logic [axi_lite_addr_width_p-1:0]      m_axi_lite_awaddr_o
    , output axi_prot_type_e                        m_axi_lite_awprot_o
    , output logic                                  m_axi_lite_awvalid_o
    , input                                         m_axi_lite_awready_i

    , output logic [axi_lite_data_width_p-1:0]      m_axi_lite_wdata_o
    , output logic [(axi_lite_data_width_p>>3)-1:0] m_axi_lite_wstrb_o
    , output logic                                  m_axi_lite_wvalid_o
    , input                                         m_axi_lite_wready_i

    , input axi_resp_type_e                         m_axi_lite_bresp_i
    , input                                         m_axi_lite_bvalid_i
    , output logic                                  m_axi_lite_bready_o

    , output logic [axi_lite_addr_width_p-1:0]      m_axi_lite_araddr_o
    , output axi_prot_type_e                        m_axi_lite_arprot_o
    , output logic                                  m_axi_lite_arvalid_o
    , input                                         m_axi_lite_arready_i

    , input [axi_lite_data_width_p-1:0]             m_axi_lite_rdata_i
    , input axi_resp_type_e                         m_axi_lite_rresp_i
    , input                                         m_axi_lite_rvalid_i
    , output logic                                  m_axi_lite_rready_o

    //========================Incoming I/O========================
    , input [axi_lite_addr_width_p-1:0]             s_axi_lite_awaddr_i
    , input axi_prot_type_e                         s_axi_lite_awprot_i
    , input                                         s_axi_lite_awvalid_i
    , output logic                                  s_axi_lite_awready_o

    , input [axi_lite_data_width_p-1:0]             s_axi_lite_wdata_i
    , input [(axi_lite_data_width_p>>3)-1:0]        s_axi_lite_wstrb_i
    , input                                         s_axi_lite_wvalid_i
    , output logic                                  s_axi_lite_wready_o

    , output axi_resp_type_e                        s_axi_lite_bresp_o 
    , output logic                                  s_axi_lite_bvalid_o
    , input                                         s_axi_lite_bready_i

    , input [axi_lite_addr_width_p-1:0]             s_axi_lite_araddr_i
    , input axi_prot_type_e                         s_axi_lite_arprot_i
    , input                                         s_axi_lite_arvalid_i
    , output logic                                  s_axi_lite_arready_o

    , output logic [axi_lite_data_width_p-1:0]      s_axi_lite_rdata_o
    , output axi_resp_type_e                        s_axi_lite_rresp_o
    , output logic                                  s_axi_lite_rvalid_o
    , input                                         s_axi_lite_rready_i

    , output logic [axi_addr_width_p-1:0]           m_axi_awaddr_o
    , output logic                                  m_axi_awvalid_o
    , input                                         m_axi_awready_i
    , output logic [5:0]                            m_axi_awid_o
    , output logic [1:0]                            m_axi_awlock_o
    , output logic [3:0]                            m_axi_awcache_o
    , output logic [2:0]                            m_axi_awprot_o
    , output logic [3:0]                            m_axi_awlen_o
    , output logic [2:0]                            m_axi_awsize_o
    , output logic [1:0]                            m_axi_awburst_o
    , output logic [3:0]                            m_axi_awqos_o

    , output logic [axi_data_width_p-1:0]           m_axi_wdata_o
    , output logic                                  m_axi_wvalid_o
    , input                                         m_axi_wready_i
    , output logic [5:0]                            m_axi_wid_o
    , output logic                                  m_axi_wlast_o
    , output logic [(axi_data_width_p>>3)-1:0]      m_axi_wstrb_o

    , input                                         m_axi_bvalid_i
    , output logic                                  m_axi_bready_o
    , input [5:0]                                   m_axi_bid_i
    , input [1:0]                                   m_axi_bresp_i

    , output logic [axi_addr_width_p-1:0]           m_axi_araddr_o
    , output logic                                  m_axi_arvalid_o
    , input                                         m_axi_arready_i
    , output logic [5:0]                            m_axi_arid_o
    , output logic [1:0]                            m_axi_arlock_o
    , output logic [3:0]                            m_axi_arcache_o
    , output logic [2:0]                            m_axi_arprot_o
    , output logic [3:0]                            m_axi_arlen_o
    , output logic [2:0]                            m_axi_arsize_o
    , output logic [1:0]                            m_axi_arburst_o
    , output logic [3:0]                            m_axi_arqos_o

    , input [axi_data_width_p-1:0]                  m_axi_rdata_i
    , input                                         m_axi_rvalid_i
    , output logic                                  m_axi_rready_o
    , input [5:0]                                   m_axi_rid_i
    , input                                         m_axi_rlast_i
    , input [1:0]                                   m_axi_rresp_i
	);

  // unicore declaration
  `declare_bp_bedrock_mem_if(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce);
  bp_bedrock_uce_mem_msg_s io_cmd_li, io_resp_lo;
  logic io_cmd_v_li, io_cmd_ready_and_lo, io_resp_v_lo, io_resp_ready_li;
  bp_bedrock_uce_mem_msg_s io_cmd_lo, io_resp_li;
  logic io_cmd_v_lo, io_cmd_ready_and_li, io_resp_v_li, io_resp_ready_and_lo;
  
  // note: bp_unicore has L2 cache; (bp_unicore_lite does not, but does not have dma_* interface
  // and would need mem_cmd/mem_resp-to-axi converter to be written.)
  `declare_bsg_cache_dma_pkt_s(daddr_width_p);
  bsg_cache_dma_pkt_s dma_pkt_lo;
  logic dma_pkt_v_lo, dma_pkt_yumi_li;
  logic [l2_fill_width_p-1:0] dma_data_lo, dma_data_li;
  logic dma_data_v_li, dma_data_ready_and_lo, dma_data_v_lo, dma_data_yumi_li;
  bp_unicore
   #(.bp_params_p(bp_params_p))
   unicore
   (.clk_i(clk_i)
    ,.reset_i(reset_i)

    // Irrelevant for zynq-parrot
    ,.my_did_i('0)
    ,.host_did_i('0)
    ,.my_cord_i('0)

    // Outgoing I/O
    ,.io_cmd_header_o(io_cmd_lo.header)
    ,.io_cmd_data_o(io_cmd_lo.data)
    ,.io_cmd_v_o(io_cmd_v_lo)
    ,.io_cmd_ready_and_i(io_cmd_ready_and_li)
    ,.io_cmd_last_o()

    ,.io_resp_header_i(io_resp_li.header)
    ,.io_resp_data_i(io_resp_li.data)
    ,.io_resp_v_i(io_resp_v_li)
    ,.io_resp_ready_and_o(io_resp_ready_and_lo)
    ,.io_resp_last_i(io_resp_v_li) // stub

    // Incoming I/O
    ,.io_cmd_header_i(io_cmd_li.header)
    ,.io_cmd_data_i(io_cmd_li.data)
    ,.io_cmd_v_i(io_cmd_v_li)
    ,.io_cmd_ready_and_o(io_cmd_ready_and_lo)
    ,.io_cmd_last_i(io_cmd_v_li) // stub

    ,.io_resp_header_o(io_resp_lo.header)
    ,.io_resp_data_o(io_resp_lo.data)
    ,.io_resp_v_o(io_resp_v_lo)
    ,.io_resp_ready_and_i(io_resp_ready_li)
    ,.io_resp_last_o()

    ,.dma_pkt_o(dma_pkt_lo)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_and_o(dma_data_ready_and_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
    );
  
  // incoming io wrapper
  axi_lite_to_bp_lite_client
   #(.bp_params_p(bp_params_p)
     ,.axi_data_width_p(axi_lite_data_width_p)
     ,.axi_addr_width_p(axi_lite_addr_width_p)
     )
   axil2io
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.io_cmd_o(io_cmd_li)
     ,.io_cmd_v_o(io_cmd_v_li)
     ,.io_cmd_yumi_i(io_cmd_ready_and_lo & io_cmd_v_li)

     ,.io_resp_i(io_resp_lo)
     ,.io_resp_v_i(io_resp_v_lo)
     ,.io_resp_ready_o(io_resp_ready_li)

     ,.lce_id_i(lce_id_width_p'('b10))
     ,.*
     );

  // incoming io wrapper
  bp_lite_to_axi_lite_master
   #(.bp_params_p(bp_params_p)
     ,.axi_data_width_p(axi_lite_data_width_p)
     ,.axi_addr_width_p(axi_lite_addr_width_p)
     )
   io2axil
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.io_cmd_i(io_cmd_lo)
     ,.io_cmd_v_i(io_cmd_v_lo)
     ,.io_cmd_ready_o(io_cmd_ready_and_li)

     ,.io_resp_o(io_resp_li)
     ,.io_resp_v_o(io_resp_v_li)
     ,.io_resp_yumi_i(io_resp_ready_and_lo & io_resp_v_li)

     ,.*
     );

   localparam axi_id_width_p = 6;
   localparam axi_burst_len_p = 8;
   bsg_cache_to_axi #
     (.addr_width_p(daddr_width_p)
      ,.data_width_p(l2_fill_width_p)
      ,.block_size_in_words_p(l2_block_size_in_fill_p)
      ,.num_cache_p(1)
      ,.axi_id_width_p  (axi_id_width_p)
      ,.axi_data_width_p(axi_data_width_p)
      ,.axi_burst_len_p (axi_burst_len_p)
      )
   cache2axi
     (.clk_i   (clk_i)
      ,.reset_i(reset_i)

      ,.dma_pkt_i        (dma_pkt_lo)
      ,.dma_pkt_v_i      (dma_pkt_v_lo)
      ,.dma_pkt_yumi_o   (dma_pkt_yumi_li)

      ,.dma_data_o       (dma_data_li)
      ,.dma_data_v_o     (dma_data_v_li)
      ,.dma_data_ready_i (dma_data_ready_and_lo)

      ,.dma_data_i       (dma_data_lo)
      ,.dma_data_v_i     (dma_data_v_lo)
      ,.dma_data_yumi_o  (dma_data_yumi_li)

      ,.axi_awid_o       (m_axi_awid_o)
      ,.axi_awaddr_addr_o(m_axi_awaddr_o)
      ,.axi_awlen_o      (m_axi_awlen_o) // this is an 8-bit output, connected to 4-bit output??
                                         // as long as the max burst length bits in 4-bits, we are okay
      ,.axi_awsize_o     (m_axi_awsize_o)
      ,.axi_awburst_o    (m_axi_awburst_o)
      ,.axi_awcache_o    (m_axi_awcache_o)
      ,.axi_awprot_o     (m_axi_awprot_o)
      ,.axi_awlock_o     (m_axi_awlock_o)
      ,.axi_awvalid_o    (m_axi_awvalid_o)
      ,.axi_awready_i    (m_axi_awready_i)

      ,.axi_wdata_o      (m_axi_wdata_o)
      ,.axi_wstrb_o      (m_axi_wstrb_o)
      ,.axi_wlast_o      (m_axi_wlast_o)
      ,.axi_wvalid_o     (m_axi_wvalid_o)
      ,.axi_wready_i     (m_axi_wready_i)

      ,.axi_bid_i        (m_axi_bid_i)
      ,.axi_bresp_i      (m_axi_bresp_i)
      ,.axi_bvalid_i     (m_axi_bvalid_i)
      ,.axi_bready_o     (m_axi_bready_o)

      ,.axi_arid_o       (m_axi_arid_o)
      ,.axi_araddr_addr_o(m_axi_araddr_o)
      ,.axi_arlen_o      (m_axi_arlen_o) // 8-bit output connect to 4-bit output?
      ,.axi_arsize_o     (m_axi_arsize_o)
      ,.axi_arburst_o    (m_axi_arburst_o)
      ,.axi_arcache_o    (m_axi_arcache_o)
      ,.axi_arprot_o     (m_axi_arprot_o)
      ,.axi_arlock_o     (m_axi_arlock_o)
      ,.axi_arvalid_o    (m_axi_arvalid_o)
      ,.axi_arready_i    (m_axi_arready_i)

      ,.axi_rid_i        (m_axi_rid_i)
      ,.axi_rdata_i      (m_axi_rdata_i)
      ,.axi_rresp_i      (m_axi_rresp_i)
      ,.axi_rlast_i      (m_axi_rlast_i)
      ,.axi_rvalid_i     (m_axi_rvalid_i)
      ,.axi_rready_o     (m_axi_rready_o)

      // Unused
      ,.axi_awaddr_cache_id_o()
      ,.axi_araddr_cache_id_o()
      );

endmodule

