
`timescale 1 ps / 1 ps

`include "bp_zynq_pl.vh"

module top
  #(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH = 10
    , parameter integer C_M00_AXI_DATA_WIDTH = 64
    , parameter integer C_M00_AXI_ADDR_WIDTH = 32
    )
   (
    // Ports of Axi Slave Bus Interface S00_AXI
`ifdef FPGA
    input wire                                   aclk
    ,input wire                                  aresetn

    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
    ,input wire [2 : 0]                          s00_axi_awprot
    ,input wire                                  s00_axi_awvalid
    ,output wire                                 s00_axi_awready
    ,input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
    ,input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
    ,input wire                                  s00_axi_wvalid
    ,output wire                                 s00_axi_wready
    ,output wire [1 : 0]                         s00_axi_bresp
    ,output wire                                 s00_axi_bvalid
    ,input wire                                  s00_axi_bready
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
    ,input wire [2 : 0]                          s00_axi_arprot
    ,input wire                                  s00_axi_arvalid
    ,output wire                                 s00_axi_arready
    ,output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
    ,output wire [1 : 0]                         s00_axi_rresp
    ,output wire                                 s00_axi_rvalid
    ,input wire                                  s00_axi_rready

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
    ,output wire                                 m00_axi_awvalid
    ,input wire                                  m00_axi_awready
    ,output wire [5:0]                           m00_axi_awid
    ,output wire [1:0]                           m00_axi_awlock  // 1 bit bsg_cache_to_axi (AXI4); 2 bit (AXI3)
    ,output wire [3:0]                           m00_axi_awcache
    ,output wire [2:0]                           m00_axi_awprot
    ,output wire [3:0]                           m00_axi_awlen   // 8 bits bsg_cache_to_axi
    ,output wire [2:0]                           m00_axi_awsize
    ,output wire [1:0]                           m00_axi_awburst
    ,output wire [3:0]                           m00_axi_awqos

    ,output wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata
    ,output wire                                 m00_axi_wvalid
    ,input wire                                  m00_axi_wready
    ,output wire [5:0]                           m00_axi_wid
    ,output wire                                 m00_axi_wlast
    ,output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb

    ,input wire                                  m00_axi_bvalid
    ,output wire                                 m00_axi_bready
    ,input wire [5:0]                            m00_axi_bid
    ,input wire [1:0]                            m00_axi_bresp

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr
    ,output wire                                 m00_axi_arvalid
    ,input wire                                  m00_axi_arready
    ,output wire [5:0]                           m00_axi_arid
    ,output wire [1:0]                           m00_axi_arlock
    ,output wire [3:0]                           m00_axi_arcache
    ,output wire [2:0]                           m00_axi_arprot
    ,output wire [3:0]                           m00_axi_arlen
    ,output wire [2:0]                           m00_axi_arsize
    ,output wire [1:0]                           m00_axi_arburst
    ,output wire [3:0]                           m00_axi_arqos

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
    ,input wire                                  m00_axi_rvalid
    ,output wire                                 m00_axi_rready
    ,input wire [5:0]                            m00_axi_rid
    ,input wire                                  m00_axi_rlast
    ,input wire [1:0]                            m00_axi_rresp
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

   wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr;
   wire                                 m00_axi_awvalid;
   wire                                 m00_axi_awready;
   wire [5:0]                           m00_axi_awid;
   wire [1:0]                           m00_axi_awlock;
   wire [3:0]                           m00_axi_awcache;
   wire [2:0]                           m00_axi_awprot;
   wire [3:0]                           m00_axi_awlen;
   wire [2:0]                           m00_axi_awsize;
   wire [1:0]                           m00_axi_awburst;
   wire [3:0]                           m00_axi_awqos;
   wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata;
   wire                                 m00_axi_wvalid;
   wire                                 m00_axi_wready;
   wire [5:0]                           m00_axi_wid;
   wire                                 m00_axi_wlast;
   wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb;
   wire                                 m00_axi_bvalid;
   wire                                 m00_axi_bready;
   wire [5:0]                           m00_axi_bid;
   wire [1:0]                           m00_axi_bresp;
   wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr;
   wire                                 m00_axi_arvalid;
   wire                                 m00_axi_arready;
   wire [5:0]                           m00_axi_arid;
   wire [1:0]                           m00_axi_arlock;
   wire [3:0]                           m00_axi_arcache;
   wire [2:0]                           m00_axi_arprot;
   wire [3:0]                           m00_axi_arlen;
   wire [2:0]                           m00_axi_arsize;
   wire [1:0]                           m00_axi_arburst;
   wire [3:0]                           m00_axi_arqos;
   wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata;
   wire                                 m00_axi_rvalid;
   wire                                 m00_axi_rready;
   wire [5:0]                           m00_axi_rid;
   wire                                 m00_axi_rlast;
   wire [1:0]                           m00_axi_rresp;


   bsg_nonsynth_axi_mem
     #(.axi_id_width_p(6)
       ,.axi_addr_width_p(C_M00_AXI_ADDR_WIDTH)
       ,.axi_data_width_p(C_M00_AXI_DATA_WIDTH)
       ,.axi_len_width_p(4)
       ,.mem_els_p(2**28) // 256 MB
       ,.init_data_p('0)
     )
   axi_mem
     (.clk_i          (aclk)
      ,.reset_i       (~aresetn)

      ,.axi_awid_i    (m00_axi_awid)
      ,.axi_awaddr_i  (m00_axi_awaddr)
      ,.axi_awlen_i   (m00_axi_awlen)
      ,.axi_awburst_i (m00_axi_awburst)
      ,.axi_awvalid_i (m00_axi_awvalid)
      ,.axi_awready_o (m00_axi_awready)

      ,.axi_wdata_i   (m00_axi_wdata)
      ,.axi_wstrb_i   (m00_axi_wstrb)
      ,.axi_wlast_i   (m00_axi_wlast)
      ,.axi_wvalid_i  (m00_axi_wvalid)
      ,.axi_wready_o  (m00_axi_wready)

      ,.axi_bid_o     (m00_axi_bid)
      ,.axi_bresp_o   (m00_axi_bresp)
      ,.axi_bvalid_o  (m00_axi_bvalid)
      ,.axi_bready_i  (m00_axi_bready)

      ,.axi_arid_i    (m00_axi_arid)
      ,.axi_araddr_i  (m00_axi_araddr)
      ,.axi_arlen_i   (m00_axi_arlen)
      ,.axi_arburst_i (m00_axi_arburst)
      ,.axi_arvalid_i (m00_axi_arvalid)
      ,.axi_arready_o (m00_axi_arready)

      ,.axi_rid_o     (m00_axi_rid)
      ,.axi_rdata_o   (m00_axi_rdata)
      ,.axi_rresp_o   (m00_axi_rresp)
      ,.axi_rlast_o   (m00_axi_rlast)
      ,.axi_rvalid_o  (m00_axi_rvalid)
      ,.axi_rready_i  (m00_axi_rready)
      );
`endif

   top_zynq #
     (.C_S00_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH)
      ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ,.C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
      ,.C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH)
      )
     top_fpga_inst
     ( .aclk           (aclk)
      ,.aresetn        (aresetn)
      ,.s00_axi_awaddr (s00_axi_awaddr)
      ,.s00_axi_awprot (s00_axi_awprot)
      ,.s00_axi_awvalid(s00_axi_awvalid)
      ,.s00_axi_awready(s00_axi_awready)
      ,.s00_axi_wdata  (s00_axi_wdata)
      ,.s00_axi_wstrb  (s00_axi_wstrb)
      ,.s00_axi_wvalid (s00_axi_wvalid)
      ,.s00_axi_wready (s00_axi_wready)
      ,.s00_axi_bresp  (s00_axi_bresp)
      ,.s00_axi_bvalid (s00_axi_bvalid)
      ,.s00_axi_bready (s00_axi_bready)
      ,.s00_axi_araddr (s00_axi_araddr)
      ,.s00_axi_arprot (s00_axi_arprot)
      ,.s00_axi_arvalid(s00_axi_arvalid)
      ,.s00_axi_arready(s00_axi_arready)
      ,.s00_axi_rdata  (s00_axi_rdata)
      ,.s00_axi_rresp  (s00_axi_rresp)
      ,.s00_axi_rvalid (s00_axi_rvalid)
      ,.s00_axi_rready (s00_axi_rready)

      ,.m00_axi_awaddr (m00_axi_awaddr)
      ,.m00_axi_awvalid(m00_axi_awvalid)
      ,.m00_axi_awready(m00_axi_awready)
      ,.m00_axi_awid   (m00_axi_awid)
      ,.m00_axi_awlock (m00_axi_awlock)
      ,.m00_axi_awcache(m00_axi_awcache)
      ,.m00_axi_awprot (m00_axi_awprot)
      ,.m00_axi_awlen  (m00_axi_awlen)
      ,.m00_axi_awsize (m00_axi_awsize)
      ,.m00_axi_awburst(m00_axi_awburst)
      ,.m00_axi_awqos  (m00_axi_awqos)

      ,.m00_axi_wdata  (m00_axi_wdata)
      ,.m00_axi_wvalid (m00_axi_wvalid)
      ,.m00_axi_wready (m00_axi_wready)
      ,.m00_axi_wid    (m00_axi_wid)
      ,.m00_axi_wlast  (m00_axi_wlast)
      ,.m00_axi_wstrb  (m00_axi_wstrb)

      ,.m00_axi_bvalid (m00_axi_bvalid)
      ,.m00_axi_bready (m00_axi_bready)
      ,.m00_axi_bid    (m00_axi_bid)
      ,.m00_axi_bresp  (m00_axi_bresp)

      ,.m00_axi_araddr (m00_axi_araddr)
      ,.m00_axi_arvalid(m00_axi_arvalid)
      ,.m00_axi_arready(m00_axi_arready)
      ,.m00_axi_arid   (m00_axi_arid)
      ,.m00_axi_arlock (m00_axi_arlock)
      ,.m00_axi_arcache(m00_axi_arcache)
      ,.m00_axi_arprot (m00_axi_arprot)
      ,.m00_axi_arlen  (m00_axi_arlen)
      ,.m00_axi_arsize (m00_axi_arsize)
      ,.m00_axi_arburst(m00_axi_arburst)
      ,.m00_axi_arqos  (m00_axi_arqos)

      ,.m00_axi_rdata  (m00_axi_rdata)
      ,.m00_axi_rvalid (m00_axi_rvalid)
      ,.m00_axi_rready (m00_axi_rready)
      ,.m00_axi_rid    (m00_axi_rid)
      ,.m00_axi_rlast  (m00_axi_rlast)
      ,.m00_axi_rresp  (m00_axi_rresp)
      );

`ifndef SYNTHESIS
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

  initial
    begin
       $assertoff();
       @(posedge aclk);
       @(negedge aresetn);
       $asserton();
     end
`endif
`endif

 endmodule

