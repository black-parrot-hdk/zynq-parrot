
module top
  #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S00_AXI_ADDR_WIDTH = 10
    , parameter integer C_S01_AXI_DATA_WIDTH = 32
    , parameter integer C_S01_AXI_ADDR_WIDTH = 30
    , parameter integer C_S02_AXI_DATA_WIDTH = 32
    , parameter integer C_S02_AXI_ADDR_WIDTH = 28
    , parameter integer C_M00_AXI_DATA_WIDTH = 64
    , parameter integer C_M00_AXI_ADDR_WIDTH = 32
    , parameter integer C_M01_AXI_DATA_WIDTH = 32
    , parameter integer C_M01_AXI_ADDR_WIDTH = 32
    , parameter integer C_MP0_AXI_DATA_WIDTH = 64
    , parameter integer __DUMMY = 0
    )
   (
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire                                   aclk
    ,input wire                                  aresetn
    ,input wire                                  ds_clk
    ,input wire                                  rt_clk
    // In order to prevent X from propagating to any of the initialized AXI buses,
    //   we use sys_resetn to put modules that have resets generated from bsg tags
    //   into reset while the tags are still reseting. Unused in this example.
    ,output wire                                 sys_resetn

    ,output wire                                 tag_ck
    ,output wire                                 tag_data

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

    ,input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_awaddr
    ,input wire [2 : 0]                          s01_axi_awprot
    ,input wire                                  s01_axi_awvalid
    ,output wire                                 s01_axi_awready
    ,input wire [C_S01_AXI_DATA_WIDTH-1 : 0]     s01_axi_wdata
    ,input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb
    ,input wire                                  s01_axi_wvalid
    ,output wire                                 s01_axi_wready
    ,output wire [1 : 0]                         s01_axi_bresp
    ,output wire                                 s01_axi_bvalid
    ,input wire                                  s01_axi_bready
    ,input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_araddr
    ,input wire [2 : 0]                          s01_axi_arprot
    ,input wire                                  s01_axi_arvalid
    ,output wire                                 s01_axi_arready
    ,output wire [C_S01_AXI_DATA_WIDTH-1 : 0]    s01_axi_rdata
    ,output wire [1 : 0]                         s01_axi_rresp
    ,output wire                                 s01_axi_rvalid
    ,input wire                                  s01_axi_rready

    ,input wire [C_S02_AXI_ADDR_WIDTH-1 : 0]     s02_axi_awaddr
    ,input wire [2 : 0]                          s02_axi_awprot
    ,input wire                                  s02_axi_awvalid
    ,output wire                                 s02_axi_awready
    ,input wire [C_S02_AXI_DATA_WIDTH-1 : 0]     s02_axi_wdata
    ,input wire [(C_S02_AXI_DATA_WIDTH/8)-1 : 0] s02_axi_wstrb
    ,input wire                                  s02_axi_wvalid
    ,output wire                                 s02_axi_wready
    ,output wire [1 : 0]                         s02_axi_bresp
    ,output wire                                 s02_axi_bvalid
    ,input wire                                  s02_axi_bready
    ,input wire [C_S02_AXI_ADDR_WIDTH-1 : 0]     s02_axi_araddr
    ,input wire [2 : 0]                          s02_axi_arprot
    ,input wire                                  s02_axi_arvalid
    ,output wire                                 s02_axi_arready
    ,output wire [C_S02_AXI_DATA_WIDTH-1 : 0]    s02_axi_rdata
    ,output wire [1 : 0]                         s02_axi_rresp
    ,output wire                                 s02_axi_rvalid
    ,input wire                                  s02_axi_rready

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
    ,output wire                                 m00_axi_awvalid
    ,input wire                                  m00_axi_awready
    ,output wire [5:0]                           m00_axi_awid
    ,output wire                                 m00_axi_awlock
    ,output wire [3:0]                           m00_axi_awcache
    ,output wire [2:0]                           m00_axi_awprot
    ,output wire [7:0]                           m00_axi_awlen
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
    ,output wire                                 m00_axi_arlock
    ,output wire [3:0]                           m00_axi_arcache
    ,output wire [2:0]                           m00_axi_arprot
    ,output wire [7:0]                           m00_axi_arlen
    ,output wire [2:0]                           m00_axi_arsize
    ,output wire [1:0]                           m00_axi_arburst
    ,output wire [3:0]                           m00_axi_arqos

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
    ,input wire                                  m00_axi_rvalid
    ,output wire                                 m00_axi_rready
    ,input wire [5:0]                            m00_axi_rid
    ,input wire                                  m00_axi_rlast
    ,input wire [1:0]                            m00_axi_rresp

    ,output wire [C_M01_AXI_ADDR_WIDTH-1 : 0]    m01_axi_awaddr
    ,output wire [2 : 0]                         m01_axi_awprot
    ,output wire                                 m01_axi_awvalid
    ,input wire                                  m01_axi_awready
    ,output wire [C_M01_AXI_DATA_WIDTH-1 : 0]    m01_axi_wdata
    ,output wire [(C_M01_AXI_DATA_WIDTH/8)-1:0]  m01_axi_wstrb
    ,output wire                                 m01_axi_wvalid
    ,input wire                                  m01_axi_wready
    ,input wire [1 : 0]                          m01_axi_bresp
    ,input wire                                  m01_axi_bvalid
    ,output wire                                 m01_axi_bready
    ,output wire [C_M01_AXI_ADDR_WIDTH-1 : 0]    m01_axi_araddr
    ,output wire [2 : 0]                         m01_axi_arprot
    ,output wire                                 m01_axi_arvalid
    ,input wire                                  m01_axi_arready
    ,input wire [C_M01_AXI_DATA_WIDTH-1 : 0]     m01_axi_rdata
    ,input wire [1 : 0]                          m01_axi_rresp
    ,input wire                                  m01_axi_rvalid
    ,output wire                                 m01_axi_rready

    ,input wire                                  mp0_axi_tready
    ,output wire                                 mp0_axi_tvalid
    ,output wire [C_MP0_AXI_DATA_WIDTH-1 : 0]    mp0_axi_tdata
    ,output wire [(C_MP0_AXI_DATA_WIDTH/8)-1:0]  mp0_axi_tkeep
    ,output wire                                 mp0_axi_tlast
    );

   top_zynq #
     (.C_S00_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH)
      ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ,.C_S01_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH)
      ,.C_S01_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH)
      ,.C_S02_AXI_DATA_WIDTH(C_S02_AXI_DATA_WIDTH)
      ,.C_S02_AXI_ADDR_WIDTH(C_S02_AXI_ADDR_WIDTH)
      ,.C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
      ,.C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH)
      ,.C_M01_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH)
      ,.C_M01_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH)
      ,.C_DMA_AXIS_DATA_WIDTH(C_MP0_AXI_DATA_WIDTH)
      )
     top_fpga_inst
     (.aclk            (aclk)
      ,.aresetn        (aresetn)
      ,.ds_clk         (ds_clk)
      ,.rt_clk         (rt_clk)
      ,.sys_resetn     (sys_resetn)

      ,.tag_ck         (tag_ck)
      ,.tag_data       (tag_data)

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

      ,.s01_axi_awaddr (s01_axi_awaddr)
      ,.s01_axi_awprot (s01_axi_awprot)
      ,.s01_axi_awvalid(s01_axi_awvalid)
      ,.s01_axi_awready(s01_axi_awready)
      ,.s01_axi_wdata  (s01_axi_wdata)
      ,.s01_axi_wstrb  (s01_axi_wstrb)
      ,.s01_axi_wvalid (s01_axi_wvalid)
      ,.s01_axi_wready (s01_axi_wready)
      ,.s01_axi_bresp  (s01_axi_bresp)
      ,.s01_axi_bvalid (s01_axi_bvalid)
      ,.s01_axi_bready (s01_axi_bready)
      ,.s01_axi_araddr (s01_axi_araddr)
      ,.s01_axi_arprot (s01_axi_arprot)
      ,.s01_axi_arvalid(s01_axi_arvalid)
      ,.s01_axi_arready(s01_axi_arready)
      ,.s01_axi_rdata  (s01_axi_rdata)
      ,.s01_axi_rresp  (s01_axi_rresp)
      ,.s01_axi_rvalid (s01_axi_rvalid)
      ,.s01_axi_rready (s01_axi_rready)

      ,.s02_axi_awaddr (s02_axi_awaddr)
      ,.s02_axi_awprot (s02_axi_awprot)
      ,.s02_axi_awvalid(s02_axi_awvalid)
      ,.s02_axi_awready(s02_axi_awready)
      ,.s02_axi_wdata  (s02_axi_wdata)
      ,.s02_axi_wstrb  (s02_axi_wstrb)
      ,.s02_axi_wvalid (s02_axi_wvalid)
      ,.s02_axi_wready (s02_axi_wready)
      ,.s02_axi_bresp  (s02_axi_bresp)
      ,.s02_axi_bvalid (s02_axi_bvalid)
      ,.s02_axi_bready (s02_axi_bready)
      ,.s02_axi_araddr (s02_axi_araddr)
      ,.s02_axi_arprot (s02_axi_arprot)
      ,.s02_axi_arvalid(s02_axi_arvalid)
      ,.s02_axi_arready(s02_axi_arready)
      ,.s02_axi_rdata  (s02_axi_rdata)
      ,.s02_axi_rresp  (s02_axi_rresp)
      ,.s02_axi_rvalid (s02_axi_rvalid)
      ,.s02_axi_rready (s02_axi_rready)

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

      ,.m01_axi_awaddr (m01_axi_awaddr)
      ,.m01_axi_awprot (m01_axi_awprot)
      ,.m01_axi_awvalid(m01_axi_awvalid)
      ,.m01_axi_awready(m01_axi_awready)
      ,.m01_axi_wdata  (m01_axi_wdata)
      ,.m01_axi_wstrb  (m01_axi_wstrb)
      ,.m01_axi_wvalid (m01_axi_wvalid)
      ,.m01_axi_wready (m01_axi_wready)
      ,.m01_axi_bresp  (m01_axi_bresp)
      ,.m01_axi_bvalid (m01_axi_bvalid)
      ,.m01_axi_bready (m01_axi_bready)
      ,.m01_axi_araddr (m01_axi_araddr)
      ,.m01_axi_arprot (m01_axi_arprot)
      ,.m01_axi_arvalid(m01_axi_arvalid)
      ,.m01_axi_arready(m01_axi_arready)
      ,.m01_axi_rdata  (m01_axi_rdata)
      ,.m01_axi_rresp  (m01_axi_rresp)
      ,.m01_axi_rvalid (m01_axi_rvalid)
      ,.m01_axi_rready (m01_axi_rready)

      ,.dma_axis_tready(mp0_axi_tready)
      ,.dma_axis_tvalid(mp0_axi_tvalid)
      ,.dma_axis_tdata (mp0_axi_tdata)
      ,.dma_axis_tkeep (mp0_axi_tkeep)
      ,.dma_axis_tlast (mp0_axi_tlast)
      );

`ifdef DROMAJO_COSIM
  logic cosim_clk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(1000))
   cosim_clk_gen
    (.o(cosim_clk));

  logic cosim_reset;
  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(0)
     ,.reset_cycles_hi_p(10)
     )
   cosim_reset_gen
    (.clk_i(cosim_clk)
     ,.async_reset_o(cosim_reset)
     );

   bind bp_be_top
     bp_nonsynth_cosim
      #(.bp_params_p(bp_params_p))
      cosim
       (.clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.freeze_i(calculator.pipe_sys.csr.cfg_bus_cast_i.freeze)

        // We hardcode these for now, integrate more cosim features later
        ,.num_core_i(num_core_p)
        ,.cosim_en_i(1'b1)
        ,.amo_en_i(1'b1)
        ,.trace_en_i('0)
        ,.checkpoint_i('0)
        ,.mhartid_i(calculator.pipe_sys.csr.cfg_bus_cast_i.core_id)
        ,.config_file_i('0)
        ,.instr_cap_i(0)
        ,.memsize_i(256)
        ,.finish_i('0)

        ,.decode_i(calculator.dispatch_pkt_cast_i.decode)

        ,.is_debug_mode_i(calculator.pipe_sys.csr.is_debug_mode)
        ,.commit_pkt_i(calculator.commit_pkt_cast_o)

        ,.priv_mode_i(calculator.pipe_sys.csr.priv_mode_r)
        ,.mstatus_i(calculator.pipe_sys.csr.mstatus_lo)
        ,.mcause_i(calculator.pipe_sys.csr.mcause_lo)
        ,.scause_i(calculator.pipe_sys.csr.scause_lo)

        ,.ird_w_v_i(scheduler.iwb_pkt_cast_i.ird_w_v)
        ,.ird_addr_i(scheduler.iwb_pkt_cast_i.rd_addr)
        ,.ird_data_i(scheduler.iwb_pkt_cast_i.rd_data)

        ,.frd_w_v_i(scheduler.fwb_pkt_cast_i.frd_w_v)
        ,.frd_addr_i(scheduler.fwb_pkt_cast_i.rd_addr)
        ,.frd_data_i(scheduler.fwb_pkt_cast_i.rd_data)

        ,.cache_req_yumi_i(calculator.pipe_mem.dcache.cache_req_yumi_i)
        ,.cache_req_complete_i(calculator.pipe_mem.dcache.complete_recv)
        ,.cache_req_nonblocking_i(calculator.pipe_mem.dcache.nonblocking_req)

        ,.cosim_clk_i(top.cosim_clk)
        ,.cosim_reset_i(top.cosim_reset)
        );
`endif

endmodule

