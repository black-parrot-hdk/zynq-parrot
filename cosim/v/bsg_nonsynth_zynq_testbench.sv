
`timescale 1 ps / 1 ps
`include "bsg_defines.sv"

module bsg_nonsynth_zynq_testbench;

`ifdef GP0_ENABLE
  localparam C_S00_AXI_DATA_WIDTH = `GP0_DATA_WIDTH;
  localparam C_S00_AXI_ADDR_WIDTH = `GP0_ADDR_WIDTH;
`endif
`ifdef GP1_ENABLE
  localparam C_S01_AXI_DATA_WIDTH = `GP1_DATA_WIDTH;
  localparam C_S01_AXI_ADDR_WIDTH = `GP1_ADDR_WIDTH;
`endif
`ifdef GP2_ENABLE
  localparam C_S02_AXI_DATA_WIDTH = `GP2_DATA_WIDTH;
  localparam C_S02_AXI_ADDR_WIDTH = `GP2_ADDR_WIDTH;
`endif
`ifdef HP0_ENABLE
  localparam C_M00_AXI_DATA_WIDTH = `HP0_DATA_WIDTH;
  localparam C_M00_AXI_ADDR_WIDTH = `HP0_ADDR_WIDTH;
`endif
`ifdef HP1_ENABLE
  localparam C_M01_AXI_DATA_WIDTH = `HP1_DATA_WIDTH;
  localparam C_M01_AXI_ADDR_WIDTH = `HP1_ADDR_WIDTH;
`endif
`ifdef HP2_ENABLE
  localparam C_M02_AXI_DATA_WIDTH = `HP2_DATA_WIDTH;
  localparam C_M02_AXI_ADDR_WIDTH = `HP2_ADDR_WIDTH;
`endif

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

  localparam ds_clk_period_lp = 200000;
  logic ds_clk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(ds_clk_period_lp))
   ds_clk_gen
    (.o(ds_clk));

  localparam rt_clk_period_lp = 2500000;
  logic rt_clk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(rt_clk_period_lp))
   rt_clk_gen
    (.o(rt_clk));

  logic tag_ck, tag_data, sys_resetn;

`ifdef GP0_ENABLE
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

`ifdef GP1_ENABLE
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
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

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

`ifdef GP2_ENABLE
  logic [C_S02_AXI_ADDR_WIDTH-1:0] s02_axi_awaddr;
  logic [2:0] s02_axi_awprot;
  logic s02_axi_awvalid, s02_axi_awready;
  logic [C_S02_AXI_DATA_WIDTH-1:0] s02_axi_wdata;
  logic [(C_S02_AXI_DATA_WIDTH/8)-1:0] s02_axi_wstrb;
  logic s02_axi_wvalid, s02_axi_wready;
  logic [1:0] s02_axi_bresp;
  logic s02_axi_bvalid, s02_axi_bready;
  logic [C_S02_AXI_ADDR_WIDTH-1:0] s02_axi_araddr;
  logic [2:0] s02_axi_arprot;
  logic s02_axi_arvalid, s02_axi_arready;
  logic [C_S02_AXI_DATA_WIDTH-1:0] s02_axi_rdata;
  logic [1:0] s02_axi_rresp;
  logic s02_axi_rvalid, s02_axi_rready;
  bsg_nonsynth_dpi_to_axil
   #(.addr_width_p(C_S02_AXI_ADDR_WIDTH), .data_width_p(C_S02_AXI_DATA_WIDTH))
   axil2
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_o(s02_axi_awaddr)
     ,.awprot_o(s02_axi_awprot)
     ,.awvalid_o(s02_axi_awvalid)
     ,.awready_i(s02_axi_awready)
     ,.wdata_o(s02_axi_wdata)
     ,.wstrb_o(s02_axi_wstrb)
     ,.wvalid_o(s02_axi_wvalid)
     ,.wready_i(s02_axi_wready)
     ,.bresp_i(s02_axi_bresp)
     ,.bvalid_i(s02_axi_bvalid)
     ,.bready_o(s02_axi_bready)

     ,.araddr_o(s02_axi_araddr)
     ,.arprot_o(s02_axi_arprot)
     ,.arvalid_o(s02_axi_arvalid)
     ,.arready_i(s02_axi_arready)
     ,.rdata_i(s02_axi_rdata)
     ,.rresp_i(s02_axi_rresp)
     ,.rvalid_i(s02_axi_rvalid)
     ,.rready_o(s02_axi_rready)
     );
`endif

`ifdef HP0_ENABLE
  logic [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr;
  logic                                 m00_axi_awvalid;
  logic                                 m00_axi_awready;
  logic [5:0]                           m00_axi_awid;
  logic                                 m00_axi_awlock;
  logic [3:0]                           m00_axi_awcache;
  logic [2:0]                           m00_axi_awprot;
  logic [7:0]                           m00_axi_awlen;
  logic [2:0]                           m00_axi_awsize;
  logic [1:0]                           m00_axi_awburst;
  logic [3:0]                           m00_axi_awqos;

  logic [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata;
  logic                                 m00_axi_wvalid;
  logic                                 m00_axi_wready;
  logic [5:0]                           m00_axi_wid;
  logic                                 m00_axi_wlast;
  logic [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb;

  logic                                 m00_axi_bvalid;
  logic                                 m00_axi_bready;
  logic [5:0]                           m00_axi_bid;
  logic [1:0]                           m00_axi_bresp;

  logic [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr;
  logic                                 m00_axi_arvalid;
  logic                                 m00_axi_arready;
  logic [5:0]                           m00_axi_arid;
  logic                                 m00_axi_arlock;
  logic [3:0]                           m00_axi_arcache;
  logic [2:0]                           m00_axi_arprot;
  logic [7:0]                           m00_axi_arlen;
  logic [2:0]                           m00_axi_arsize;
  logic [1:0]                           m00_axi_arburst;
  logic [3:0]                           m00_axi_arqos;

  logic [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata;
  logic                                 m00_axi_rvalid;
  logic                                 m00_axi_rready;
  logic [5:0]                           m00_axi_rid;
  logic                                 m00_axi_rlast;
  logic [1:0]                           m00_axi_rresp;

`ifdef AXI_MEM_ENABLE
  bsg_nonsynth_axi_mem
    #(.axi_id_width_p(6)
      ,.axi_addr_width_p(C_M00_AXI_ADDR_WIDTH)
      ,.axi_data_width_p(C_M00_AXI_DATA_WIDTH)
      ,.axi_len_width_p(8)
      ,.mem_els_p(2**28) // 256 MB
      ,.init_data_p('0)
    )
  axi_mem
    (.clk_i(aclk)
     ,.reset_i(~aresetn)

     ,.axi_awid_i(m00_axi_awid)
     ,.axi_awaddr_i(m00_axi_awaddr)
     ,.axi_awlen_i(m00_axi_awlen)
     ,.axi_awburst_i(m00_axi_awburst)
     ,.axi_awvalid_i(m00_axi_awvalid)
     ,.axi_awready_o(m00_axi_awready)

     ,.axi_wdata_i(m00_axi_wdata)
     ,.axi_wstrb_i(m00_axi_wstrb)
     ,.axi_wlast_i(m00_axi_wlast)
     ,.axi_wvalid_i(m00_axi_wvalid)
     ,.axi_wready_o(m00_axi_wready)

     ,.axi_bid_o(m00_axi_bid)
     ,.axi_bresp_o(m00_axi_bresp)
     ,.axi_bvalid_o(m00_axi_bvalid)
     ,.axi_bready_i(m00_axi_bready)

     ,.axi_arid_i(m00_axi_arid)
     ,.axi_araddr_i(m00_axi_araddr)
     ,.axi_arlen_i(m00_axi_arlen)
     ,.axi_arburst_i(m00_axi_arburst)
     ,.axi_arvalid_i(m00_axi_arvalid)
     ,.axi_arready_o(m00_axi_arready)

     ,.axi_rid_o(m00_axi_rid)
     ,.axi_rdata_o(m00_axi_rdata)
     ,.axi_rresp_o(m00_axi_rresp)
     ,.axi_rlast_o(m00_axi_rlast)
     ,.axi_rvalid_o(m00_axi_rvalid)
     ,.axi_rready_i(m00_axi_rready)
     );
`else
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_M00_AXI_ADDR_WIDTH), .data_width_p(C_M00_AXI_DATA_WIDTH))
   axil3
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(m00_axi_awaddr)
     ,.awprot_i(m00_axi_awprot)
     ,.awvalid_i(m00_axi_awvalid)
     ,.awready_o(m00_axi_awready)
     ,.wdata_i(m00_axi_wdata)
     ,.wstrb_i(m00_axi_wstrb)
     ,.wvalid_i(m00_axi_wvalid)
     ,.wready_o(m00_axi_wready)
     ,.bresp_o(m00_axi_bresp)
     ,.bvalid_o(m00_axi_bvalid)
     ,.bready_i(m00_axi_bready)

     ,.araddr_i(m00_axi_araddr)
     ,.arprot_i(m00_axi_arprot)
     ,.arvalid_i(m00_axi_arvalid)
     ,.arready_o(m00_axi_arready)
     ,.rdata_o(m00_axi_rdata)
     ,.rresp_o(m00_axi_rresp)
     ,.rvalid_o(m00_axi_rvalid)
     ,.rready_i(m00_axi_rready)
     );
`endif
`endif

`ifdef HP1_ENABLE
  logic [C_M01_AXI_ADDR_WIDTH-1:0] m01_axi_awaddr;
  logic [2:0] m01_axi_awprot;
  logic m01_axi_awvalid, m01_axi_awready;
  logic [C_M01_AXI_DATA_WIDTH-1:0] m01_axi_wdata;
  logic [(C_M01_AXI_DATA_WIDTH/8)-1:0] m01_axi_wstrb;
  logic m01_axi_wvalid, m01_axi_wready;
  logic [1:0] m01_axi_bresp;
  logic m01_axi_bvalid, m01_axi_bready;
  logic [C_M01_AXI_ADDR_WIDTH-1:0] m01_axi_araddr;
  logic [2:0] m01_axi_arprot;
  logic m01_axi_arvalid, m01_axi_arready;
  logic [C_M01_AXI_DATA_WIDTH-1:0] m01_axi_rdata;
  logic [1:0] m01_axi_rresp;
  logic m01_axi_rvalid, m01_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_M01_AXI_ADDR_WIDTH), .data_width_p(C_M01_AXI_DATA_WIDTH))
   axil4
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(m01_axi_awaddr)
     ,.awprot_i(m01_axi_awprot)
     ,.awvalid_i(m01_axi_awvalid)
     ,.awready_o(m01_axi_awready)
     ,.wdata_i(m01_axi_wdata)
     ,.wstrb_i(m01_axi_wstrb)
     ,.wvalid_i(m01_axi_wvalid)
     ,.wready_o(m01_axi_wready)
     ,.bresp_o(m01_axi_bresp)
     ,.bvalid_o(m01_axi_bvalid)
     ,.bready_i(m01_axi_bready)

     ,.araddr_i(m01_axi_araddr)
     ,.arprot_i(m01_axi_arprot)
     ,.arvalid_i(m01_axi_arvalid)
     ,.arready_o(m01_axi_arready)
     ,.rdata_o(m01_axi_rdata)
     ,.rresp_o(m01_axi_rresp)
     ,.rvalid_o(m01_axi_rvalid)
     ,.rready_i(m01_axi_rready)
     );
`endif

`ifdef HP2_ENABLE
  logic [C_M02_AXI_ADDR_WIDTH-1:0] m02_axi_awaddr;
  logic [2:0] m02_axi_awprot;
  logic m02_axi_awvalid, m02_axi_awready;
  logic [C_M02_AXI_DATA_WIDTH-1:0] m02_axi_wdata;
  logic [(C_M02_AXI_DATA_WIDTH/8)-1:0] m02_axi_wstrb;
  logic m02_axi_wvalid, m02_axi_wready;
  logic [1:0] m02_axi_bresp;
  logic m02_axi_bvalid, m02_axi_bready;
  logic [C_M02_AXI_ADDR_WIDTH-1:0] m02_axi_araddr;
  logic [2:0] m02_axi_arprot;
  logic m02_axi_arvalid, m02_axi_arready;
  logic [C_M02_AXI_DATA_WIDTH-1:0] m02_axi_rdata;
  logic [1:0] m02_axi_rresp;
  logic m02_axi_rvalid, m02_axi_rready;
  bsg_nonsynth_axil_to_dpi
   #(.addr_width_p(C_M02_AXI_ADDR_WIDTH), .data_width_p(C_M02_AXI_DATA_WIDTH))
   axil5
    (.aclk_i(aclk)
     ,.aresetn_i(aresetn)

     ,.awaddr_i(m02_axi_awaddr)
     ,.awprot_i(m02_axi_awprot)
     ,.awvalid_i(m02_axi_awvalid)
     ,.awready_o(m02_axi_awready)
     ,.wdata_i(m02_axi_wdata)
     ,.wstrb_i(m02_axi_wstrb)
     ,.wvalid_i(m02_axi_wvalid)
     ,.wready_o(m02_axi_wready)
     ,.bresp_o(m02_axi_bresp)
     ,.bvalid_o(m02_axi_bvalid)
     ,.bready_i(m02_axi_bready)

     ,.araddr_i(m02_axi_araddr)
     ,.arprot_i(m02_axi_arprot)
     ,.arvalid_i(m02_axi_arvalid)
     ,.arready_o(m02_axi_arready)
     ,.rdata_o(m02_axi_rdata)
     ,.rresp_o(m02_axi_rresp)
     ,.rvalid_o(m02_axi_rvalid)
     ,.rready_i(m02_axi_rready)
     );
`endif

  top #(
`ifdef GP0_ENABLE
     .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
     .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
`endif
`ifdef GP1_ENABLE
     .C_S01_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH),
     .C_S01_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH),
`endif
`ifdef GP2_ENABLE
     .C_S02_AXI_DATA_WIDTH(C_S02_AXI_DATA_WIDTH),
     .C_S02_AXI_ADDR_WIDTH(C_S02_AXI_ADDR_WIDTH),
`endif
`ifdef HP0_ENABLE
     .C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
     .C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
`endif
`ifdef HP1_ENABLE
     .C_M01_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH),
     .C_M01_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH),
`endif
`ifdef HP2_ENABLE
     .C_M02_AXI_DATA_WIDTH(C_M02_AXI_DATA_WIDTH),
     .C_M02_AXI_ADDR_WIDTH(C_M02_AXI_ADDR_WIDTH),
`endif
     .__DUMMY(0)
     )
   dut
    (.*);

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

   export "DPI-C" function bsg_dpi_time;
   function int bsg_dpi_time();
     return $time;
   endfunction

endmodule

