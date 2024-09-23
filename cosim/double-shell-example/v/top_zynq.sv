
module top_zynq
 #(
   parameter integer C_GP0_AXI_DATA_WIDTH   = 32
   , parameter integer C_GP0_AXI_ADDR_WIDTH = 5

   , parameter integer C_GP1_AXI_DATA_WIDTH = 32
   , parameter integer C_GP1_AXI_ADDR_WIDTH = 5
   )
   (
    input wire                                    aclk
    , input wire                                  aresetn

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

    , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_awaddr
    , input wire [2 : 0]                          gp1_axi_awprot
    , input wire                                  gp1_axi_awvalid
    , output wire                                 gp1_axi_awready
    , input wire [C_GP0_AXI_DATA_WIDTH-1 : 0]     gp1_axi_wdata
    , input wire [(C_GP0_AXI_DATA_WIDTH/8)-1 : 0] gp1_axi_wstrb
    , input wire                                  gp1_axi_wvalid
    , output wire                                 gp1_axi_wready
    , output wire [1 : 0]                         gp1_axi_bresp
    , output wire                                 gp1_axi_bvalid
    , input wire                                  gp1_axi_bready
    , input wire [C_GP0_AXI_ADDR_WIDTH-1 : 0]     gp1_axi_araddr
    , input wire [2 : 0]                          gp1_axi_arprot
    , input wire                                  gp1_axi_arvalid
    , output wire                                 gp1_axi_arready
    , output wire [C_GP0_AXI_DATA_WIDTH-1 : 0]    gp1_axi_rdata
    , output wire [1 : 0]                         gp1_axi_rresp
    , output wire                                 gp1_axi_rvalid
    , input wire                                  gp1_axi_rready
    );

   localparam num_regs_ps_to_pl_lp = 2;
   localparam num_regs_pl_to_ps_lp = 2;

   // this module currently only valid if these are equal
   localparam num_fifo_ps_to_pl_lp = 1;
   localparam num_fifo_pl_to_ps_lp = 1;

   wire [1:0][num_fifo_pl_to_ps_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [1:0][num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li;
   wire [1:0][num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_ready_lo;

   wire [1:0][num_fifo_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [1:0][num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo;
   wire [1:0][num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_yumi_li;

   wire [1:0][num_regs_ps_to_pl_lp-1:0][C_GP0_AXI_DATA_WIDTH-1:0] csr_data_lo;


   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p(num_regs_ps_to_pl_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_GP0_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_GP0_AXI_ADDR_WIDTH)
       ) bzps0
       (
        .pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li [0])
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li    [0])
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo[0])

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo [0])
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo    [0])
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li [0])

        ,.csr_data_o(csr_data_lo[0])
        ,.csr_data_new_o()
        ,.csr_data_i(csr_data_lo[1])

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

   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p(num_regs_ps_to_pl_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_GP1_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_GP1_AXI_ADDR_WIDTH)
       ) bzps1
       (
        .pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li [1])
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li    [1])
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo[1])

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo [1])
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo    [1])
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li [1])

        ,.csr_data_o(csr_data_lo[1])
        ,.csr_data_new_o()
        ,.csr_data_i(csr_data_lo[0])

        ,.S_AXI_ACLK   (aclk           )
        ,.S_AXI_ARESETN(aresetn        )
        ,.S_AXI_AWADDR (gp1_axi_awaddr )
        ,.S_AXI_AWPROT (gp1_axi_awprot )
        ,.S_AXI_AWVALID(gp1_axi_awvalid)
        ,.S_AXI_AWREADY(gp1_axi_awready)
        ,.S_AXI_WDATA  (gp1_axi_wdata  )
        ,.S_AXI_WSTRB  (gp1_axi_wstrb  )
        ,.S_AXI_WVALID (gp1_axi_wvalid )
        ,.S_AXI_WREADY (gp1_axi_wready )
        ,.S_AXI_BRESP  (gp1_axi_bresp  )
        ,.S_AXI_BVALID (gp1_axi_bvalid )
        ,.S_AXI_BREADY (gp1_axi_bready )
        ,.S_AXI_ARADDR (gp1_axi_araddr )
        ,.S_AXI_ARPROT (gp1_axi_arprot )
        ,.S_AXI_ARVALID(gp1_axi_arvalid)
        ,.S_AXI_ARREADY(gp1_axi_arready)
        ,.S_AXI_RDATA  (gp1_axi_rdata  )
        ,.S_AXI_RRESP  (gp1_axi_rresp  )
        ,.S_AXI_RVALID (gp1_axi_rvalid )
        ,.S_AXI_RREADY (gp1_axi_rready )
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


   for (genvar k=0; k < num_fifo_pl_to_ps_lp; k++)
     begin: rof4

        // criss-cross between two AXI slave ports the data and valid signals
        assign pl_to_ps_fifo_data_li[0][k] = ps_to_pl_fifo_data_lo[1][k];
        assign pl_to_ps_fifo_v_li   [0][k] = ps_to_pl_fifo_v_lo   [1][k];
        assign pl_to_ps_fifo_data_li[1][k] = ps_to_pl_fifo_data_lo[0][k];
        assign pl_to_ps_fifo_v_li   [1][k] = ps_to_pl_fifo_v_lo   [0][k];

        assign ps_to_pl_fifo_yumi_li[0][k] = pl_to_ps_fifo_v_li[1][k] & pl_to_ps_fifo_ready_lo[1][k];
        assign ps_to_pl_fifo_yumi_li[1][k] = pl_to_ps_fifo_v_li[0][k] & pl_to_ps_fifo_ready_lo[0][k];

     end

        // Add user logic here

        // User logic ends

 endmodule

