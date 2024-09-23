

module top_zynq
 #(
   parameter integer C_GP0_AXI_DATA_WIDTH     = 32
   , parameter integer C_GP0_AXI_ADDR_WIDTH   = 6
   , parameter integer C_SP0_AXI_DATA_WIDTH   = 32
   , parameter integer C_MP0_AXI_DATA_WIDTH   = 32
   )
  (input                                         aclk
   , input                                       aresetn

   , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_awaddr
   , input wire [2 : 0]                          gp0_axi_awprot
   , input wire                                  gp0_axi_awvalid
   , output wire                                 gp0_axi_awready

   , input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     gp0_axi_wdata
   , input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp0_axi_wstrb
   , input wire                                  gp0_axi_wvalid
   , output wire                                 gp0_axi_wready

   , output wire [1 : 0]                         gp0_axi_bresp
   , output wire                                 gp0_axi_bvalid
   , input wire                                  gp0_axi_bready

   , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp0_axi_araddr
   , input wire [2 : 0]                          gp0_axi_arprot
   , input wire                                  gp0_axi_arvalid
   , output wire                                 gp0_axi_arready

   , output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    gp0_axi_rdata
   , output wire [1 : 0]                         gp0_axi_rresp
   , output wire                                 gp0_axi_rvalid
   , input wire                                  gp0_axi_rready

   , input wire [C_SP0_AXI_DATA_WIDTH-1:0]       sp0_axi_tdata
   , input wire                                  sp0_axi_tvalid
   , input wire [(C_SP0_AXI_DATA_WIDTH/8)-1:0]   sp0_axi_tkeep
   , input wire                                  sp0_axi_tlast
   , output wire                                 sp0_axi_tready

   , output wire [C_MP0_AXI_DATA_WIDTH-1:0]      mp0_axi_tdata
   , output wire                                 mp0_axi_tvalid
   , output wire [(C_MP0_AXI_DATA_WIDTH/8)-1:0]  mp0_axi_tkeep
   , output wire                                 mp0_axi_tlast
   , input wire                                  mp0_axi_tready
   );

   localparam num_regs_ps_to_pl_lp = 1;
   localparam num_fifo_ps_to_pl_lp = 1;
   localparam num_fifo_pl_to_ps_lp = 1;
   localparam num_regs_pl_to_ps_lp = 1;

   wire [num_fifo_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_ready_lo;

   wire [num_fifo_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_yumi_li;

   wire [num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_lo;
   wire [num_regs_ps_to_pl_lp-1:0]                           csr_data_new_lo;
   wire [num_regs_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_li;

   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH (C_GP0_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH (C_GP0_AXI_ADDR_WIDTH)
       ) bzps
       (
        .pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

        ,.csr_data_o(csr_data_lo)
        ,.csr_data_new_o(csr_data_new_lo)
        ,.csr_data_i(csr_data_li)
        ,.S_AXI_ACLK   (aclk           )
        ,.S_AXI_ARESETN(aresetn        )
        ,.S_AXI_AWADDR (gp0_axi_awaddr )
        ,.S_AXI_AWPROT (gp0_axi_awprot )
        ,.S_AXI_AWVALID(gp0_axi_awvalid)
        ,.S_AXI_AWREADY(gp0_axi_awready)
        ,.S_AXI_WDATA  (gp0_axi_wdata  )
        ,.S_AXI_WSTRB  (gp0_axi_wstrb  )
        ,.S_AXI_WVALID (gp0_axi_wvalid )
        ,.S_AXI_WREADY (gp0_axi_wready )
        ,.S_AXI_BRESP  (gp0_axi_bresp  )
        ,.S_AXI_BVALID (gp0_axi_bvalid )
        ,.S_AXI_BREADY (gp0_axi_bready )
        ,.S_AXI_ARADDR (gp0_axi_araddr )
        ,.S_AXI_ARPROT (gp0_axi_arprot )
        ,.S_AXI_ARVALID(gp0_axi_arvalid)
        ,.S_AXI_ARREADY(gp0_axi_arready)
        ,.S_AXI_RDATA  (gp0_axi_rdata  )
        ,.S_AXI_RRESP  (gp0_axi_rresp  )
        ,.S_AXI_RVALID (gp0_axi_rvalid )
        ,.S_AXI_RREADY (gp0_axi_rready )
        );

   //--------------------------------------------------------------------------------
   // USER MODIFY -- Configure your accelerator interface by wiring these signals to
   //                your accelerator.
   //--------------------------------------------------------------------------------
   //
   // BEGIN logic is replaced with connections to the accelerator core
   // as a stand-in, we loopback the ps to pl fifos to the pl to ps fifos,
   // adding the outputs of a pair of ps to pl fifos to generate the value
   // inserted into a pl to ps fifo.
   localparam txn_size_lp = 16;

   logic [C_SP0_AXI_DATA_WIDTH-1:0] tdata_lo;
   logic tready_li, tvalid_lo, tlast_lo;
   logic [(C_SP0_AXI_DATA_WIDTH/8)-1:0] tkeep_lo;
   logic [`BSG_WIDTH(txn_size_lp)-1:0] tx_tcount_lo, rx_tcount_lo;
   logic rx_success_lo;

   logic [C_SP0_AXI_DATA_WIDTH-1:0] tdata_li;
   logic tready_lo, tvalid_li, tlast_li;
   logic [(C_SP0_AXI_DATA_WIDTH/8)-1:0] tkeep_li;

   logic tinit_lo, tstatus_r;

   assign tdata_lo = ps_to_pl_fifo_data_lo[0];
   assign tvalid_lo = ps_to_pl_fifo_v_lo[0];
   assign tkeep_lo = '1;
   assign ps_to_pl_fifo_yumi_li[0] = tready_li & tvalid_lo;
   assign tinit_lo = csr_data_new_lo[0];

   assign tready_lo = pl_to_ps_fifo_ready_lo[0];
   assign pl_to_ps_fifo_v_li[0] = tvalid_li;
   assign pl_to_ps_fifo_data_li[0] = tdata_li;

   assign csr_data_li[0] = tstatus_r;

   assign mp0_axi_tdata = tdata_lo;
   assign mp0_axi_tvalid = tvalid_lo;
   assign mp0_axi_tkeep = tkeep_lo;
   assign mp0_axi_tlast = tlast_lo;
   assign tready_li = mp0_axi_tready;

   assign tdata_li = sp0_axi_tdata;
   assign tvalid_li = sp0_axi_tvalid;
   assign tkeep_li = sp0_axi_tkeep;
   assign tlast_li = sp0_axi_tlast;
   assign sp0_axi_tready = tready_lo;

   bsg_counter_clear_up
    #(.max_val_p(txn_size_lp), .init_val_p(0))
    tx_counter
     (.clk_i(aclk)
      ,.reset_i(!aresetn)
      ,.clear_i(tinit_lo)
      ,.up_i(tready_li & tvalid_lo)
      ,.count_o(tx_tcount_lo)
      );
   assign tlast_lo = (tx_tcount_lo == txn_size_lp-1);

   bsg_counter_clear_up
    #(.max_val_p(txn_size_lp), .init_val_p(0))
    rx_counter
     (.clk_i(aclk)
      ,.reset_i(!aresetn)
      ,.clear_i(tinit_lo)
      ,.up_i(tready_lo & tvalid_li)
      ,.count_o(rx_tcount_lo)
      );
   assign rx_success_lo = (tready_lo & tvalid_li & tlast_li) & (rx_tcount_lo == txn_size_lp-1);

   bsg_dff_reset_set_clear
    #(.width_p(1))
    tstatus_reg
     (.clk_i(aclk)
      ,.reset_i(!aresetn)

      ,.set_i(rx_success_lo)
      ,.clear_i(tinit_lo)
      ,.data_o(tstatus_r)
      );

endmodule

