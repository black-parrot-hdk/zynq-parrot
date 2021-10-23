
`timescale 1 ns / 1 ps

`include "bp_zynq_pl.vh"

module top #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_S00_AXI_DATA_WIDTH = 32,
   parameter integer C_S00_AXI_ADDR_WIDTH = 5,

   parameter integer C_S01_AXI_DATA_WIDTH = 32,
   parameter integer C_S01_AXI_ADDR_WIDTH = 5
   )
   (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line


`ifdef FPGA
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire                                  s00_axi_aclk,
    input wire                                  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
    input wire [2 : 0]                          s00_axi_awprot,
    input wire                                  s00_axi_awvalid,
    output wire                                 s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire                                  s00_axi_wvalid,
    output wire                                 s00_axi_wready,
    output wire [1 : 0]                         s00_axi_bresp,
    output wire                                 s00_axi_bvalid,
    input wire                                  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
    input wire [2 : 0]                          s00_axi_arprot,
    input wire                                  s00_axi_arvalid,
    output wire                                 s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata,
    output wire [1 : 0]                         s00_axi_rresp,
    output wire                                 s00_axi_rvalid,
    input wire                                  s00_axi_rready,

    // Ports of Axi Slave Bus Interface S01_AXI
    input wire                                  s01_axi_aclk,
    input wire                                  s01_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s01_axi_awaddr,
    input wire [2 : 0]                          s01_axi_awprot,
    input wire                                  s01_axi_awvalid,
    output wire                                 s01_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s01_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb,
    input wire                                  s01_axi_wvalid,
    output wire                                 s01_axi_wready,
    output wire [1 : 0]                         s01_axi_bresp,
    output wire                                 s01_axi_bvalid,
    input wire                                  s01_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s01_axi_araddr,
    input wire [2 : 0]                          s01_axi_arprot,
    input wire                                  s01_axi_arvalid,
    output wire                                 s01_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s01_axi_rdata,
    output wire [1 : 0]                         s01_axi_rresp,
    output wire                                 s01_axi_rvalid,
    input wire                                  s01_axi_rready
    );
`else
    );
    logic s00_axi_aclk, s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [2:0] s00_axi_awprot;
    logic s00_axi_awvalid, s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic s00_axi_wvalid, s00_axi_wready;
    logic [1:0] s00_axi_bresp;
    logic s00_axi_bvalid, s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [2:0] s00_axi_arprot;
    logic s00_axi_arvalid, s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    logic [1:0] s00_axi_rresp;
    logic s00_axi_rvalid, s00_axi_rready;
    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S00_AXI_ADDR_WIDTH), .data_width_p(C_S00_AXI_DATA_WIDTH))
     axil0
      (.aclk_o(s00_axi_aclk)
       ,.aresetn_o(s00_axi_aresetn)

       ,.awaddr_o(s00_axi_awaddr)
       ,.awprot_o(s00_axi_awprot)
       ,.awvalid_o(s00_axi_awvalid)
       ,.awready_i(s00_axi_awready)
       ,.wdata_o(s00_axi_wdata)
       ,.wstrb_o(s00_axi_wstrb)
       ,.wvalid_o(s00_axi_wvalid)
       ,.wready_i(s00_axi_wready)
       ,.bresp_i(s00_axi_bresp)
       ,.bvalid_i(s00_axi_bvalid)
       ,.bready_o(s00_axi_bready)

       ,.araddr_o(s00_axi_araddr)
       ,.arprot_o(s00_axi_arprot)
       ,.arvalid_o(s00_axi_arvalid)
       ,.arready_i(s00_axi_arready)
       ,.rdata_i(s00_axi_rdata)
       ,.rresp_i(s00_axi_rresp)
       ,.rvalid_i(s00_axi_rvalid)
       ,.rready_o(s00_axi_rready)
       );

    logic s01_axi_aclk, s01_axi_aresetn;
    logic [C_S01_AXI_ADDR_WIDTH-1:0] s01_axi_awaddr;
    logic [2:0] s01_axi_awprot;
    logic s01_axi_awvalid, s01_axi_awready;
    logic [C_S01_AXI_DATA_WIDTH-1:0] s01_axi_wdata;
    logic [(C_S01_AXI_DATA_WIDTH/8)-1:0] s01_axi_wstrb;
    logic s01_axi_wvalid, s01_axi_wready;
    logic [1:0] s01_axi_bresp;
    logic s01_axi_bvalid, s01_axi_bready;
    logic [C_S01_AXI_ADDR_WIDTH-1:0] s01_axi_araddr;
    logic [2:0] s01_axi_arprot;
    logic s01_axi_arvalid, s01_axi_arready;
    logic [C_S01_AXI_DATA_WIDTH-1:0] s01_axi_rdata;
    logic [1:0] s01_axi_rresp;
    logic s01_axi_rvalid, s01_axi_rready;
    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S01_AXI_ADDR_WIDTH), .data_width_p(C_S01_AXI_DATA_WIDTH))
     axil1
      (.aclk_o(s01_axi_aclk)
       ,.aresetn_o(s01_axi_aresetn)

       ,.awaddr_o(s01_axi_awaddr)
       ,.awprot_o(s01_axi_awprot)
       ,.awvalid_o(s01_axi_awvalid)
       ,.awready_i(s01_axi_awready)
       ,.wdata_o(s01_axi_wdata)
       ,.wstrb_o(s01_axi_wstrb)
       ,.wvalid_o(s01_axi_wvalid)
       ,.wready_i(s01_axi_wready)
       ,.bresp_i(s01_axi_bresp)
       ,.bvalid_i(s01_axi_bvalid)
       ,.bready_o(s01_axi_bready)

       ,.araddr_o(s01_axi_araddr)
       ,.arprot_o(s01_axi_arprot)
       ,.arvalid_o(s01_axi_arvalid)
       ,.arready_i(s01_axi_arready)
       ,.rdata_i(s01_axi_rdata)
       ,.rresp_i(s01_axi_rresp)
       ,.rvalid_i(s01_axi_rvalid)
       ,.rready_o(s01_axi_rready)
       );
`endif

   localparam num_regs_ps_to_pl_lp = 2;

   // this module currently only valid if these are equal
   localparam num_fifo_ps_to_pl_lp = 1;
   localparam num_fifo_pl_to_ps_lp = 1;

   wire [1:0][num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [1:0][num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li;
   wire [1:0][num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_ready_lo;

   wire [1:0][num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [1:0][num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo;
   wire [1:0][num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_yumi_li;

   wire [1:0][num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li, csr_data_lo;


   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p(num_regs_ps_to_pl_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
       ) bzps0
       (
        .pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li [0])
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li    [0])
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo[0])

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo [0])
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo    [0])
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li [0])

        ,.csr_data_o(csr_data_lo[0])
        ,.csr_data_i(csr_data_li)

        ,.S_AXI_ACLK   (s00_axi_aclk   )
        ,.S_AXI_ARESETN(s00_axi_aresetn)
        ,.S_AXI_AWADDR (s00_axi_awaddr )
        ,.S_AXI_AWPROT (s00_axi_awprot )
        ,.S_AXI_AWVALID(s00_axi_awvalid)
        ,.S_AXI_AWREADY(s00_axi_awready)
        ,.S_AXI_WDATA  (s00_axi_wdata  )
        ,.S_AXI_WSTRB  (s00_axi_wstrb  )
        ,.S_AXI_WVALID (s00_axi_wvalid )
        ,.S_AXI_WREADY (s00_axi_wready )
        ,.S_AXI_BRESP  (s00_axi_bresp  )
        ,.S_AXI_BVALID (s00_axi_bvalid )
        ,.S_AXI_BREADY (s00_axi_bready )
        ,.S_AXI_ARADDR (s00_axi_araddr )
        ,.S_AXI_ARPROT (s00_axi_arprot )
        ,.S_AXI_ARVALID(s00_axi_arvalid)
        ,.S_AXI_ARREADY(s00_axi_arready)
        ,.S_AXI_RDATA  (s00_axi_rdata  )
        ,.S_AXI_RRESP  (s00_axi_rresp  )
        ,.S_AXI_RVALID (s00_axi_rvalid )
        ,.S_AXI_RREADY (s00_axi_rready )
        );

   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p(num_regs_ps_to_pl_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH)
       ) bzps1
       (
        .pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li [1])
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li    [1])
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo[1])

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo [1])
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo    [1])
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li [1])

        ,.csr_data_o(csr_data_lo[1])
        ,.csr_data_i(csr_data_li)

        ,.S_AXI_ACLK   (s01_axi_aclk   )
        ,.S_AXI_ARESETN(s01_axi_aresetn)
        ,.S_AXI_AWADDR (s01_axi_awaddr )
        ,.S_AXI_AWPROT (s01_axi_awprot )
        ,.S_AXI_AWVALID(s01_axi_awvalid)
        ,.S_AXI_AWREADY(s01_axi_awready)
        ,.S_AXI_WDATA  (s01_axi_wdata  )
        ,.S_AXI_WSTRB  (s01_axi_wstrb  )
        ,.S_AXI_WVALID (s01_axi_wvalid )
        ,.S_AXI_WREADY (s01_axi_wready )
        ,.S_AXI_BRESP  (s01_axi_bresp  )
        ,.S_AXI_BVALID (s01_axi_bvalid )
        ,.S_AXI_BREADY (s01_axi_bready )
        ,.S_AXI_ARADDR (s01_axi_araddr )
        ,.S_AXI_ARPROT (s01_axi_arprot )
        ,.S_AXI_ARVALID(s01_axi_arvalid)
        ,.S_AXI_ARREADY(s01_axi_arready)
        ,.S_AXI_RDATA  (s01_axi_rdata  )
        ,.S_AXI_RRESP  (s01_axi_rresp  )
        ,.S_AXI_RVALID (s01_axi_rvalid )
        ,.S_AXI_RREADY (s01_axi_rready )
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

`ifdef VERILATOR
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to trace.fst...\n", $time);
           $dumpfile("trace.fst");
           $dumpvars();
         end
     end
`elsif VCS
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $vcdplusfile("vcdplus.vpd");
           $vcdpluson();
           $vcdplusautoflushon();
         end
       if ($test$plusargs("c_args") != 0)
         begin
           $value$plusargs("c_args=%s", c_args);
         end
       cosim_main(c_args);
     end

   // Evaluate the simulation, until the next clk_i positive edge.
   //
   // Call bsg_dpi_next in simulators where the C testbench does not
   // control the progression of time (i.e. NOT Verilator).
   //
   // The #1 statement guarantees that the positive edge has been
   // evaluated, which is necessary for ordering in all of the DPI
   // functions.
   export "DPI-C" task bsg_dpi_next;
   task bsg_dpi_next();
     @(posedge s00_axi_aclk);
     #1;
   endtask
`endif

 endmodule
