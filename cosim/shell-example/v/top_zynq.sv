

module top_zynq
 #(// Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_GP0_AXI_DATA_WIDTH     = 32

   // needs to be updated to fit all addresses used
   // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
   , parameter integer C_GP0_AXI_ADDR_WIDTH   = 6
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
   );

   localparam num_regs_ps_to_pl_lp = 4;
   localparam num_fifo_ps_to_pl_lp = 4;
   localparam num_fifo_pl_to_ps_lp = 2;
   localparam num_regs_pl_to_ps_lp = 1;

   wire [num_fifo_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_ready_lo;

   wire [num_fifo_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_yumi_li;

   wire [num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_lo;
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
        ,.csr_data_new_o()
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

   for (genvar k = 0; k < num_fifo_pl_to_ps_lp; k++)
     begin: rof4
        assign pl_to_ps_fifo_data_li [k] = ps_to_pl_fifo_data_lo[k*2] + ps_to_pl_fifo_data_lo [k*2+1];
        assign pl_to_ps_fifo_v_li    [k] = ps_to_pl_fifo_v_lo   [k*2] & ps_to_pl_fifo_v_lo    [k*2+1];

        assign ps_to_pl_fifo_yumi_li[k*2]   = pl_to_ps_fifo_v_li[k] & pl_to_ps_fifo_ready_lo[k];
        assign ps_to_pl_fifo_yumi_li[k*2+1] = pl_to_ps_fifo_v_li[k] & pl_to_ps_fifo_ready_lo[k];
     end

        // Add user logic here
        //
        logic [C_GP0_AXI_ADDR_WIDTH-1:0] last_write_addr_r;

        always @(posedge aclk)
          if (~aresetn)
            last_write_addr_r <= '0;
          else
            if (gp0_axi_awvalid & gp0_axi_awready)
              last_write_addr_r <= gp0_axi_awaddr;
        assign csr_data_li = last_write_addr_r;

        // User logic ends

 endmodule

