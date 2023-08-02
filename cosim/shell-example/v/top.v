
`timescale 1 ps / 1 ps

`include "bp_zynq_pl.vh"

module top #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_S00_AXI_DATA_WIDTH = 32,
   parameter integer C_S00_AXI_ADDR_WIDTH = 6
   )
   (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

`ifdef FGPA
    input wire                                  aclk,
    input wire                                  aresetn,
    // Ports of Axi Slave Bus Interface S00_AXI
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
    input wire                                  s00_axi_rready
    );
`else
    );

    localparam aclk_period_lp = 50000;
    logic aclk;
    bsg_nonsynth_clock_gen
     #(.cycle_time_p(aclk_period_lp))
     aclk_gen
      (.o(aclk));

    logic areset;
    bsg_nonsynth_reset_gen
     #(.reset_cycles_lo_p(0), .reset_cycles_hi_p(10))
     reset_gen
      (.clk_i(aclk), .async_reset_o(areset));
    wire aresetn = ~areset;

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
      (.aclk_i(aclk)
       ,.aresetn_i(aresetn)

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
`endif

   localparam num_regs_ps_to_pl_lp = 4;
   localparam num_fifo_ps_to_pl_lp = 4;
   localparam num_fifo_pl_to_ps_lp = 2;
   localparam num_regs_pl_to_ps_lp = 1;

   wire [num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_ready_lo;

   wire [num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_yumi_li;

   wire [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
   wire [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH (C_S00_AXI_ADDR_WIDTH)
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
        logic [C_S00_AXI_ADDR_WIDTH-1:0] last_write_addr_r;

        always @(posedge aclk)
          if (~aresetn)
            last_write_addr_r <= '0;
          else
            if (s00_axi_awvalid & s00_axi_awready)
              last_write_addr_r <= s00_axi_awaddr;
        assign csr_data_li = last_write_addr_r;

        // User logic ends

`ifndef VIVADO
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
`else
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
`ifdef VCS
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $vcdplusfile("vcdplus.vpd");
           $vcdpluson();
           $vcdplusautoflushon();
         end
`endif
`ifdef XCELIUM
         begin
           $shm_open("dump.shm");
           $shm_probe("ASM");
         end 
`endif
       if ($test$plusargs("c_args") != 0)
         begin
           $value$plusargs("c_args=%s", c_args);
         end
       cosim_main(c_args);
       $finish;
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
     @(posedge aclk);
     #1;
   endtask
`endif
`endif

 endmodule
