
module ariane_top
  #(
    parameter AXI_ADDR_WIDTH = 64
   ,parameter AXI_DATA_WIDTH = 64
   ,parameter AXI_USER_WIDTH = 1

   ,localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8
   )
  (
   input clk_i
   ,input resetn_i
   ,input core_resetn_i

   // Slave AXI4 Bus
   // Missing atop and region fields
   ,input s_awvalid_i
   ,input [1:0] s_awburst_i
   ,input [AXI_ADDR_WIDTH-1:0] s_awaddr_i
   ,input [7:0] s_awlen_i
   ,input [2:0] s_awsize_i
   ,input [3:0] s_awid_i
   ,input [3:0] s_awcache_i
   ,input [2:0] s_awprot_i
   ,input [3:0] s_awqos_i
   ,input s_awuser_i
   ,input  s_awlock_i
   ,output s_awready_o

   ,input s_wvalid_i
   ,input [AXI_STRB_WIDTH-1:0] s_wstrb_i
   ,input [AXI_DATA_WIDTH-1:0] s_wdata_i
   ,input s_wlast_i
   ,input s_wuser_i
   ,output s_wready_o

   ,input s_bready_i
   ,output s_bvalid_o
   ,output [1:0] s_bresp_o
   ,output [3:0] s_bid_o
   ,output s_buser_o

   // Missing region field
   ,input s_arvalid_i
   ,input [1:0] s_arburst_i
   ,input [AXI_ADDR_WIDTH-1:0] s_araddr_i
   ,input [7:0] s_arlen_i
   ,input [2:0] s_arsize_i
   ,input [3:0] s_arid_i
   ,input [3:0] s_arcache_i
   ,input [2:0] s_arprot_i
   ,input [3:0] s_arqos_i
   ,input s_aruser_i
   ,input s_arlock_i
   ,output s_arready_o

   ,input s_rready_i
   ,output s_rvalid_o
   ,output [AXI_DATA_WIDTH-1:0] s_rdata_o
   ,output [1:0] s_rresp_o
   ,output [3:0] s_rid_o
   ,output s_rlast_o
   ,output s_ruser_o

   // Master AXI4 Bus
   // Missing atop and region fields
   ,input m_awready_i
   ,output m_awvalid_o
   ,output [1:0] m_awburst_o
   ,output [AXI_ADDR_WIDTH-1:0] m_awaddr_o
   ,output [7:0] m_awlen_o
   ,output [2:0] m_awsize_o
   ,output [4:0] m_awid_o
   ,output [3:0] m_awcache_o
   ,output [2:0] m_awprot_o
   ,output [3:0] m_awqos_o
   ,output m_awuser_o
   ,output m_awlock_o

   ,input m_wready_i
   ,output m_wvalid_o
   ,output [AXI_STRB_WIDTH-1:0] m_wstrb_o
   ,output [AXI_DATA_WIDTH-1:0] m_wdata_o
   ,output m_wlast_o
   ,output m_wuser_o

   ,input m_bvalid_i
   ,input [1:0] m_bresp_i
   ,input [4:0] m_bid_i
   ,input m_buser_i
   ,output m_bready_o

   // Missing region field
   ,input m_arready_i
   ,output m_arvalid_o
   ,output [1:0] m_arburst_o
   ,output [AXI_ADDR_WIDTH-1:0] m_araddr_o
   ,output [7:0] m_arlen_o
   ,output [2:0] m_arsize_o
   ,output [4:0] m_arid_o
   ,output [3:0] m_arcache_o
   ,output [2:0] m_arprot_o
   ,output [3:0] m_arqos_o
   ,output m_aruser_o
   ,output m_arlock_o

   ,input m_rvalid_i
   ,input [AXI_DATA_WIDTH-1:0] m_rdata_i
   ,input [1:0] m_rresp_i
   ,input [4:0] m_rid_i
   ,input m_rlast_i
   ,input m_ruser_i
   ,output m_rready_o

   // GPIO Master AXI4-Lite port
   ,input io_awready_i
   ,output io_awvalid_o
   ,output [AXI_ADDR_WIDTH-1:0] io_awaddr_o

   ,input io_wready_i
   ,output io_wvalid_o
   ,output [AXI_STRB_WIDTH-1:0] io_wstrb_o
   ,output [AXI_DATA_WIDTH-1:0] io_wdata_o

   ,input io_bvalid_i
   ,input [1:0] io_bresp_i
   ,output io_bready_o

   ,input io_arready_i
   ,output io_arvalid_o
   ,output [AXI_ADDR_WIDTH-1:0] io_araddr_o

   ,input io_rvalid_i
   ,input [AXI_DATA_WIDTH-1:0] io_rdata_i
   ,input [1:0] io_rresp_i
   ,output io_rready_o
  );

localparam NBSlave = ariane_soc::NrSlaves; // 0: ariane, 1: host
localparam AxiIdWidthMaster = ariane_soc::IdWidth;
localparam AxiIdWidthSlaves = ariane_soc::IdWidthSlave; // 5

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( AxiIdWidthMaster   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH     )
) slave[NBSlave-1:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH     )
) master[ariane_soc::NB_PERIPHERALS-1:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH     )
) dram();

AXI_LITE #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     )
) gpio();

// Slave connections
assign slave[1].aw_valid  = s_awvalid_i;
assign slave[1].aw_burst  = s_awburst_i;
assign slave[1].aw_addr   = s_awaddr_i;
assign slave[1].aw_len    = s_awlen_i;
assign slave[1].aw_size   = s_awsize_i;
assign slave[1].aw_id     = s_awid_i;
assign slave[1].aw_cache  = s_awcache_i;
assign slave[1].aw_prot   = s_awprot_i;
assign slave[1].aw_qos    = s_awqos_i;
assign slave[1].aw_user   = s_awuser_i;
assign slave[1].aw_lock   = s_awlock_i;
assign slave[1].aw_atop   = '0;
assign slave[1].aw_region = '0;
assign s_awready_o        = slave[1].aw_ready;

assign slave[1].w_valid   = s_wvalid_i;
assign slave[1].w_strb    = s_wstrb_i;
assign slave[1].w_data    = s_wdata_i;
assign slave[1].w_last    = s_wlast_i;
assign slave[1].w_user    = s_wuser_i;
assign s_wready_o         = slave[1].w_ready;

assign slave[1].b_ready   = s_bready_i;
assign s_bvalid_o         = slave[1].b_valid;
assign s_bresp_o          = slave[1].b_resp;
assign s_bid_o            = slave[1].b_id;
assign s_buser_o          = slave[1].b_user;

assign slave[1].ar_valid  = s_arvalid_i;
assign slave[1].ar_burst  = s_arburst_i;
assign slave[1].ar_addr   = s_araddr_i;
assign slave[1].ar_len    = s_arlen_i;
assign slave[1].ar_size   = s_arsize_i;
assign slave[1].ar_id     = s_arid_i;
assign slave[1].ar_cache  = s_arcache_i;
assign slave[1].ar_prot   = s_arprot_i;
assign slave[1].ar_qos    = s_arqos_i;
assign slave[1].ar_user   = s_aruser_i;
assign slave[1].ar_lock   = s_arlock_i;
assign slave[1].ar_region = '0;
assign s_arready_o        = slave[1].ar_ready;

assign slave[1].r_ready   = s_rready_i;
assign s_rvalid_o         = slave[1].r_valid;
assign s_rdata_o          = slave[1].r_data;
assign s_rresp_o          = slave[1].r_resp;
assign s_rid_o            = slave[1].r_id;
assign s_rlast_o          = slave[1].r_last;
assign s_ruser_o          = slave[1].r_user;

// Master connections
assign dram.aw_ready      = m_awready_i;
assign m_awvalid_o        = dram.aw_valid;
assign m_awburst_o        = dram.aw_burst;
assign m_awaddr_o         = dram.aw_addr;
assign m_awlen_o          = dram.aw_len;
assign m_awsize_o         = dram.aw_size;
assign m_awid_o           = dram.aw_id;
assign m_awcache_o        = dram.aw_cache;
assign m_awprot_o         = dram.aw_prot;
assign m_awqos_o          = dram.aw_qos;
assign m_awuser_o         = dram.aw_user;
assign m_awlock_o         = dram.aw_lock;

assign dram.w_ready       = m_wready_i;
assign m_wvalid_o         = dram.w_valid;
assign m_wstrb_o          = dram.w_strb;
assign m_wdata_o          = dram.w_data;
assign m_wlast_o          = dram.w_last;
assign m_wuser_o          = dram.w_user;

assign dram.b_valid       = m_bvalid_i;
assign dram.b_resp        = m_bresp_i;
assign dram.b_id          = m_bid_i;
assign dram.b_user        = m_buser_i;
assign m_bready_o         = dram.b_ready;

assign dram.ar_ready      = m_arready_i;
assign m_arvalid_o        = dram.ar_valid;
assign m_arburst_o        = dram.ar_burst;
assign m_araddr_o         = dram.ar_addr;
assign m_arlen_o          = dram.ar_len;
assign m_arsize_o         = dram.ar_size;
assign m_arid_o           = dram.ar_id;
assign m_arcache_o        = dram.ar_cache;
assign m_arprot_o         = dram.ar_prot;
assign m_arqos_o          = dram.ar_qos;
assign m_aruser_o         = dram.ar_user;
assign m_arlock_o         = dram.ar_lock;

assign dram.r_valid       = m_rvalid_i;
assign dram.r_data        = m_rdata_i;
assign dram.r_resp        = m_rresp_i;
assign dram.r_id          = m_rid_i;
assign dram.r_last        = m_rlast_i;
assign dram.r_user        = m_ruser_i;
assign m_rready_o         = dram.r_ready;

// GPIO connections
assign gpio.aw_ready      = io_awready_i;
assign io_awvalid_o       = gpio.aw_valid;
assign io_awaddr_o        = gpio.aw_addr;

assign gpio.w_ready       = io_wready_i;
assign io_wvalid_o        = gpio.w_valid;
assign io_wstrb_o         = gpio.w_strb;
assign io_wdata_o         = gpio.w_data;

assign gpio.b_valid       = io_bvalid_i;
assign gpio.b_resp        = io_bresp_i;
assign io_bready_o        = gpio.b_ready;

assign gpio.ar_ready      = io_arready_i;
assign io_arvalid_o       = gpio.ar_valid;
assign io_araddr_o        = gpio.ar_addr;

assign gpio.r_valid       = io_rvalid_i;
assign gpio.r_data        = io_rdata_i;
assign gpio.r_resp        = io_rresp_i;
assign io_rready_o        = gpio.r_ready;

// ---------------
// AXI Xbar
// ---------------
axi_node_wrap_with_slices #(
    // three ports from Ariane (instruction, data and bypass)
    .NB_SLAVE           ( NBSlave                    ),
    .NB_MASTER          ( ariane_soc::NB_PERIPHERALS ),
    .NB_REGION          ( ariane_soc::NrRegion       ),
    .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH             ),
    .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH             ),
    .AXI_USER_WIDTH     ( AXI_USER_WIDTH             ),
    .AXI_ID_WIDTH       ( AxiIdWidthMaster           ),
    .MASTER_SLICE_DEPTH ( 2                          ),
    .SLAVE_SLICE_DEPTH  ( 2                          )
) i_axi_xbar (
    .clk          ( clk_i        ),
    .rst_n        ( resetn_i     ),
    .test_en_i    ( '0           ),
    .slave        ( slave        ),
    .master       ( master       ),
    .start_addr_i ({
        ariane_soc::CLINTBase,
        ariane_soc::GPIOBase,
        ariane_soc::DRAMBase
    }),
    .end_addr_i   ({
        ariane_soc::CLINTBase    + ariane_soc::CLINTLength - 1,
        ariane_soc::GPIOBase     + ariane_soc::GPIOLength - 1,
        ariane_soc::DRAMBase     + ariane_soc::DRAMLength - 1
    }),
    .valid_rule_i (ariane_soc::ValidRule)
);

// ---------------
// Core
// ---------------
logic ipi, timer_irq;
ariane_axi::req_t    axi_ariane_req;
ariane_axi::resp_t   axi_ariane_resp;

ariane #(
    .ArianeCfg ( ariane_soc::ArianeSocCfg )
) i_ariane (
    .clk_i        ( clk_i               ),
    .rst_ni       ( core_resetn_i       ),
    .boot_addr_i  ( ariane_soc::DRAMBase), // start fetching from DRAM
    .hart_id_i    ( '0                  ),
    .irq_i        ( '0                  ),
    .ipi_i        ( ipi                 ),
    .time_irq_i   ( timer_irq           ),
    .debug_req_i  ( '0                  ),
    .axi_req_o    ( axi_ariane_req      ),
    .axi_resp_i   ( axi_ariane_resp     )
);

axi_master_connect i_axi_master_connect_ariane (.axi_req_i(axi_ariane_req), .axi_resp_o(axi_ariane_resp), .master(slave[0]));

// ---------------
// CLINT
// ---------------
// divide clock by two
logic rtc;
always_ff @(posedge clk_i) begin
  if (~resetn_i) begin
    rtc <= 0;
  end else begin
    rtc <= rtc ^ 1'b1;
  end
end

ariane_axi::req_t    axi_clint_req;
ariane_axi::resp_t   axi_clint_resp;

clint #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH   ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH   ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves ),
    .NR_CORES       ( 1                )
) i_clint (
    .clk_i       ( clk_i          ),
    .rst_ni      ( resetn_i       ),
    .testmode_i  ( '0             ),
    .axi_req_i   ( axi_clint_req  ),
    .axi_resp_o  ( axi_clint_resp ),
    .rtc_i       ( rtc            ),
    .timer_irq_o ( timer_irq      ),
    .ipi_o       ( ipi            )
);

axi_slave_connect i_axi_slave_connect_clint (.axi_req_o(axi_clint_req), .axi_resp_i(axi_clint_resp), .slave(master[ariane_soc::CLINT]));

// ---------------
// DRAM
// ---------------
axi_riscv_atomics_wrap #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( AxiIdWidthSlaves   ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH     ),
    .AXI_MAX_WRITE_TXNS ( 1  ),
    .RISCV_WORD_WIDTH   ( 64 )
) i_axi_riscv_atomics (
    .clk_i  ( clk_i                    ),
    .rst_ni ( resetn_i                 ),
    .slv    ( master[ariane_soc::DRAM] ),
    .mst    ( dram                     )
);

// ---------------
// GPIO
// ---------------

axi_to_axi_lite #(
  .NUM_PENDING_RD(),
  .NUM_PENDING_WR()
) i_axi2axilite (
  .clk_i      ( clk_i                   ),
  .rst_ni     ( resetn_i                ),
  .testmode_i ( '0                      ),
  .in         ( master[ariane_soc::GPIO]),
  .out        ( gpio                    )
);

localparam debug_lp = 0;

always @(negedge clk_i) begin
  if (debug_lp) begin

  if (slave[1].ar_valid & slave[1].ar_ready)
    $display("ariane_top: Slave 1 READ Addr %x, Len %x", slave[1].ar_addr, slave[1].ar_len);
  if (slave[1].aw_valid & slave[1].aw_ready)
    $display("ariane_top: Slave 1 WRITE Addr %x, Size %x", slave[1].aw_addr, slave[1].aw_size);
  if (slave[1].w_valid & slave[1].w_ready)
    $display("ariane_top: Slave 1 WRITE Data %x, Strb %x", slave[1].w_data, slave[1].w_strb);
  if (slave[1].r_valid & slave[1].r_ready)
    $display("ariane_top: Slave 1 READ Data %x, Resp %x", slave[1].r_data, slave[1].r_resp);
  if (slave[1].b_valid & slave[1].b_ready)
    $display("ariane_top: Slave 1 WRITE Resp %x", slave[1].b_resp);

  if (slave[0].ar_valid & slave[0].ar_ready)
    $display("ariane_top: Slave 0 READ Addr %x, Len %x", slave[0].ar_addr, slave[0].ar_len);
  if (slave[0].aw_valid & slave[0].aw_ready)
    $display("ariane_top: Slave 0 WRITE Addr %x, Size %x", slave[0].aw_addr, slave[0].aw_size);
  if (slave[0].w_valid & slave[0].w_ready)
    $display("ariane_top: Slave 0 WRITE Data %x, Strb %x", slave[0].w_data, slave[0].w_strb);
  if (slave[0].r_valid & slave[0].r_ready)
    $display("ariane_top: Slave 0 READ Data %x, Resp", slave[0].r_data, slave[0].r_resp);
  if (slave[0].b_valid & slave[0].b_ready)
    $display("ariane_top: Slave 0 WRITE Resp %x", slave[0].b_resp);

  if (master[ariane_soc::CLINT].ar_valid & master[ariane_soc::CLINT].ar_ready)
    $display("ariane_top: CLINT READ Addr %x, ID %x", master[ariane_soc::CLINT].ar_addr, master[ariane_soc::CLINT].ar_id);
  if (master[ariane_soc::CLINT].aw_valid & master[ariane_soc::CLINT].aw_ready)
    $display("ariane_top: CLINT WRITE Addr %x, ID %x", master[ariane_soc::CLINT].aw_addr, master[ariane_soc::CLINT].aw_id);
  if (master[ariane_soc::CLINT].r_valid & master[ariane_soc::CLINT].r_ready)
    $display("ariane_top: CLINT READ Data %x, ID %x", master[ariane_soc::CLINT].r_data, master[ariane_soc::CLINT].r_id);

  if (dram.ar_valid & dram.ar_ready)
    $display("ariane_top: dram READ Addr %x, ID %x", dram.ar_addr, dram.ar_id);
  if (dram.aw_valid & dram.aw_ready)
    $display("ariane_top: dram WRITE Addr %x, Size %x, ID %x", dram.aw_addr, dram.aw_size, dram.aw_id);
  if (dram.w_valid & dram.w_ready)
    $display("ariane_top: dram WRITE Data %x, Strb %x", dram.w_data, dram.w_strb);
  if (dram.r_valid & dram.r_ready)
    $display("ariane_top: dram READ Data %x, ID %x", dram.r_data, dram.r_id);
  if (dram.b_valid & dram.b_ready)
    $display("ariane_top: dram WRITE Resp %x, ID %x", dram.b_resp, dram.b_id);

  if (master[ariane_soc::GPIO].aw_valid & master[ariane_soc::GPIO].aw_ready)
    $display("ariane_top: GPIO WRITE Addr %x", master[ariane_soc::GPIO].aw_addr);
  if (master[ariane_soc::GPIO].w_valid & master[ariane_soc::GPIO].w_ready)
    $display("ariane_top: GPIO WRITE Data %x, Strb %x", master[ariane_soc::GPIO].w_data, master[ariane_soc::GPIO].w_strb);
  if (master[ariane_soc::GPIO].b_valid & master[ariane_soc::GPIO].b_ready)
    $display("ariane_top: GPIO WRITE Resp %x, ID %x", master[ariane_soc::GPIO].b_resp, master[ariane_soc::GPIO].b_id);
 end
end

endmodule
