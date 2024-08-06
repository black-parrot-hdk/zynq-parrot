
`timescale 1 ps / 1 ps

module top_zynq
 #(
   // NOTE these parameters are usually overridden by the parent module (top.v)
   // but we set them to make expectations consistent

   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_GP0_AXI_DATA_WIDTH   = 32
   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_GP0_AXI_ADDR_WIDTH   = 10
   , parameter integer C_HP0_AXI_DATA_WIDTH   = 32
   , parameter integer C_HP0_AXI_ADDR_WIDTH   = 32
   )
  (input wire                                    aclk
   , input wire                                  aresetn

   // Ports of Axi Slave Bus Interface S00_AXI
   , input wire [C_GP0_AXI_ADDR_WIDTH-1:0]       s00_axi_awaddr
   , input wire [2:0]                            s00_axi_awprot
   , input wire                                  s00_axi_awvalid
   , output wire                                 s00_axi_awready
   , input wire [C_GP0_AXI_DATA_WIDTH-1:0]       s00_axi_wdata
   , input wire [(C_GP0_AXI_DATA_WIDTH/8)-1:0]   s00_axi_wstrb
   , input wire                                  s00_axi_wvalid
   , output wire                                 s00_axi_wready
   , output wire [1:0]                           s00_axi_bresp
   , output wire                                 s00_axi_bvalid
   , input wire                                  s00_axi_bready
   , input wire [C_GP0_AXI_ADDR_WIDTH-1:0]       s00_axi_araddr
   , input wire [2:0]                            s00_axi_arprot
   , input wire                                  s00_axi_arvalid
   , output wire                                 s00_axi_arready
   , output wire [C_GP0_AXI_DATA_WIDTH-1:0]      s00_axi_rdata
   , output wire [1 : 0]                         s00_axi_rresp
   , output wire                                 s00_axi_rvalid
   , input wire                                  s00_axi_rready

   , output wire [C_HP0_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
   , output wire                                 m00_axi_awvalid
   , input wire                                  m00_axi_awready
   , output wire [5:0]                           m00_axi_awid
   , output wire                                 m00_axi_awlock
   , output wire [3:0]                           m00_axi_awcache
   , output wire [2:0]                           m00_axi_awprot
   , output wire [7:0]                           m00_axi_awlen
   , output wire [2:0]                           m00_axi_awsize
   , output wire [1:0]                           m00_axi_awburst
   , output wire [3:0]                           m00_axi_awqos

   , output wire [C_HP0_AXI_DATA_WIDTH-1:0]      m00_axi_wdata
   , output wire                                 m00_axi_wvalid
   , input wire                                  m00_axi_wready
   , output wire [5:0]                           m00_axi_wid
   , output wire                                 m00_axi_wlast
   , output wire [(C_HP0_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb

   , input wire                                  m00_axi_bvalid
   , output wire                                 m00_axi_bready
   , input wire [5:0]                            m00_axi_bid
   , input wire [1:0]                            m00_axi_bresp

   , output wire [C_HP0_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr
   , output wire                                 m00_axi_arvalid
   , input wire                                  m00_axi_arready
   , output wire [5:0]                           m00_axi_arid
   , output wire                                 m00_axi_arlock
   , output wire [3:0]                           m00_axi_arcache
   , output wire [2:0]                           m00_axi_arprot
   , output wire [7:0]                           m00_axi_arlen
   , output wire [2:0]                           m00_axi_arsize
   , output wire [1:0]                           m00_axi_arburst
   , output wire [3:0]                           m00_axi_arqos

   , input wire [C_HP0_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
   , input wire                                  m00_axi_rvalid
   , output wire                                 m00_axi_rready
   , input wire [5:0]                            m00_axi_rid
   , input wire                                  m00_axi_rlast
   , input wire [1:0]                            m00_axi_rresp
   );

   localparam num_regs_ps_to_pl_lp  = 1;
   localparam num_regs_pl_to_ps_lp  = 1;
   localparam num_fifos_ps_to_pl_lp = 3;
   localparam num_fifos_pl_to_ps_lp = 1;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_lo:
   //
   // 0: dram_base_addr
   //    
   // c: bootrom addr
   //
   logic [num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_lo;
   logic [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;

   ///////////////////////////////////////////////////////////////////////////////////////
   // csr_data_li:
   //
   // 0 : NULL
   //
   logic [num_regs_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_li;

   ///////////////////////////////////////////////////////////////////////////////////////
   // pl_to_ps_fifo_data_li:
   //
   // 0: DRAM response
   logic [num_fifos_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   logic [num_fifos_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;


   ///////////////////////////////////////////////////////////////////////////////////////
   // ps_to_pl_fifo_data_lo:
   //
   // 0: DRAM request TYPE (0 = write, 1 = read)
   // 4: DRAM request ADDR
   // 8: DRAM request DATA
   logic [num_fifos_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   logic [num_fifos_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo, ps_to_pl_fifo_yumi_li;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      // need to update C_GP0_AXI_ADDR_WIDTH accordingly
      .num_fifo_ps_to_pl_p(num_fifos_ps_to_pl_lp)
      ,.num_fifo_pl_to_ps_p(num_fifos_pl_to_ps_lp)
      ,.num_regs_ps_to_pl_p(num_regs_ps_to_pl_lp)
      ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
      ,.C_S_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_new_o(csr_data_new_lo)
        ,.csr_data_o(csr_data_lo)
        ,.csr_data_i(csr_data_li)

        ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

        ,.S_AXI_ACLK   (aclk)
        ,.S_AXI_ARESETN(aresetn)
        ,.S_AXI_AWADDR (s00_axi_awaddr)
        ,.S_AXI_AWPROT (s00_axi_awprot)
        ,.S_AXI_AWVALID(s00_axi_awvalid)
        ,.S_AXI_AWREADY(s00_axi_awready)
        ,.S_AXI_WDATA  (s00_axi_wdata)
        ,.S_AXI_WSTRB  (s00_axi_wstrb)
        ,.S_AXI_WVALID (s00_axi_wvalid)
        ,.S_AXI_WREADY (s00_axi_wready)
        ,.S_AXI_BRESP  (s00_axi_bresp)
        ,.S_AXI_BVALID (s00_axi_bvalid)
        ,.S_AXI_BREADY (s00_axi_bready)
        ,.S_AXI_ARADDR (s00_axi_araddr)
        ,.S_AXI_ARPROT (s00_axi_arprot)
        ,.S_AXI_ARVALID(s00_axi_arvalid)
        ,.S_AXI_ARREADY(s00_axi_arready)
        ,.S_AXI_RDATA  (s00_axi_rdata)
        ,.S_AXI_RRESP  (s00_axi_rresp)
        ,.S_AXI_RVALID (s00_axi_rvalid)
        ,.S_AXI_RREADY (s00_axi_rready)
        );

   ///////////////////////////////////////////////////////////////////////////////////////
   // TODO: User code goes here
   ///////////////////////////////////////////////////////////////////////////////////////
   logic [C_HP0_AXI_ADDR_WIDTH-1:0] dram_base_li;

   logic [C_HP0_AXI_DATA_WIDTH-1:0] data_li;
   logic [C_HP0_AXI_ADDR_WIDTH-1:0] addr_li;
   logic [C_HP0_AXI_DATA_WIDTH/8-1:0] wmask_li;
   logic v_li, w_li, ready_and_lo;
   logic [C_HP0_AXI_DATA_WIDTH-1:0] data_lo;
   logic v_lo, ready_and_li;  

   assign dram_base_li = csr_data_lo[0];
   assign csr_data_li[0] = '0;

   assign data_li = ps_to_pl_fifo_data_lo[2];
   assign addr_li = ps_to_pl_fifo_data_lo[1];
   assign wmask_li = '1;
   assign v_li = ps_to_pl_fifo_v_lo[0] & ps_to_pl_fifo_v_lo[1] & ps_to_pl_fifo_v_lo[2];
   assign w_li = ps_to_pl_fifo_data_lo[0];
   assign ps_to_pl_fifo_yumi_li[0] = ready_and_lo & v_li;
   assign ps_to_pl_fifo_yumi_li[1] = ready_and_lo & v_li;
   assign ps_to_pl_fifo_yumi_li[2] = ready_and_lo & v_li;
   assign pl_to_ps_fifo_data_li[0] = data_lo;
   assign pl_to_ps_fifo_v_li[0] = v_lo;
   assign ready_and_li = pl_to_ps_fifo_ready_lo[0];

   logic [C_HP0_AXI_ADDR_WIDTH-1:0] m_axil_awaddr;
   logic [2:0] m_axil_awprot;
   logic m_axil_awvalid, m_axil_awready;
   logic [C_HP0_AXI_DATA_WIDTH-1:0] m_axil_wdata;
   logic [C_HP0_AXI_DATA_WIDTH/8-1:0] m_axil_wstrb;
   logic m_axil_wvalid, m_axil_wready;
   logic [1:0] m_axil_bresp;
   logic m_axil_bvalid, m_axil_bready;
   logic [C_HP0_AXI_ADDR_WIDTH-1:0] m_axil_araddr;
   logic [2:0] m_axil_arprot;
   logic m_axil_arvalid, m_axil_arready;
   logic [C_HP0_AXI_DATA_WIDTH-1:0] m_axil_rdata;
   logic [1:0] m_axil_rresp;
   logic m_axil_rvalid, m_axil_rready;
   bsg_axil_fifo_master
    #(.axil_data_width_p(C_HP0_AXI_DATA_WIDTH)
      ,.axil_addr_width_p(C_HP0_AXI_ADDR_WIDTH)
      )
    shell2fifo
     (.clk_i(aclk)
      ,.reset_i(~aresetn)

      ,.data_i(data_li)
      ,.addr_i(addr_li)
      ,.v_i(v_li)
      ,.w_i(w_li)
      ,.wmask_i(wmask_li)
      ,.ready_and_o(ready_and_lo)

      ,.data_o(data_lo)
      ,.v_o(v_lo)
      ,.ready_and_i(ready_and_li)

      ,.m_axil_awaddr_o(m_axil_awaddr)
      ,.m_axil_awprot_o(m_axil_awprot)
      ,.m_axil_awvalid_o(m_axil_awvalid)
      ,.m_axil_awready_i(m_axil_awready)

      ,.m_axil_wdata_o(m_axil_wdata)
      ,.m_axil_wstrb_o(m_axil_wstrb)
      ,.m_axil_wvalid_o(m_axil_wvalid)
      ,.m_axil_wready_i(m_axil_wready)

      ,.m_axil_bresp_i(m_axil_bresp)
      ,.m_axil_bvalid_i(m_axil_bvalid)
      ,.m_axil_bready_o(m_axil_bready)

      ,.m_axil_araddr_o(m_axil_araddr)
      ,.m_axil_arprot_o(m_axil_arprot)
      ,.m_axil_arvalid_o(m_axil_arvalid)
      ,.m_axil_arready_i(m_axil_arready)

      ,.m_axil_rdata_i(m_axil_rdata)
      ,.m_axil_rresp_i(m_axil_rresp)
      ,.m_axil_rvalid_i(m_axil_rvalid)
      ,.m_axil_rready_o(m_axil_rready)
	  );

   assign m00_axi_awaddr = m_axil_awaddr + dram_base_li;
   assign m00_axi_awvalid = m_axil_awvalid;
   assign m_axil_awready = m00_axi_awready;
   assign m00_axi_awid = '0;
   assign m00_axi_awlock = '0;
   assign m00_axi_awcache = '0;
   assign m00_axi_awprot = '0;
   assign m00_axi_awlen = '0;
   assign m00_axi_awsize = 3'b010; // 32b
   assign m00_axi_awburst = 2'b01; // incr
   assign m00_axi_awqos = '0;

   assign m00_axi_wdata = m_axil_wdata;
   assign m00_axi_wvalid = m_axil_wvalid;
   assign m_axil_wready = m00_axi_wready;
   assign m00_axi_wid = '0;
   assign m00_axi_wlast = 1'b1;
   assign m00_axi_wstrb = m_axil_wstrb;

   assign m_axil_bresp = m00_axi_bresp;
   assign m_axil_bvalid = m00_axi_bvalid;
   assign m00_axi_bready = m_axil_bready;

   assign m00_axi_araddr = m_axil_araddr + dram_base_li;
   assign m00_axi_arvalid = m_axil_arvalid;
   assign m_axil_arready = m00_axi_arready;
   assign m00_axi_arid = '0;
   assign m00_axi_arlock = '0;
   assign m00_axi_arcache = '0;
   assign m00_axi_arprot = '0;
   assign m00_axi_arlen = '0;
   assign m00_axi_arsize = 3'b010; // 32b
   assign m00_axi_arburst = 2'b01; // incr
   assign m00_axi_arqos = '0;

   assign m_axil_rdata = m00_axi_rdata;
   assign m_axil_rresp = m00_axi_rresp;
   assign m_axil_rvalid = m00_axi_rvalid;
   assign m00_axi_rready = m_axil_rvalid;

endmodule

