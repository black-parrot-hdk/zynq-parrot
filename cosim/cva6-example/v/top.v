
`timescale 1 ns / 1 ps

`include "bp_zynq_pl.vh"

module top
  #(
    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_ADDR_WIDTH = 9
    , parameter integer C_S00_AXI_DATA_WIDTH = 32
    , parameter integer C_S01_AXI_ADDR_WIDTH = 32
    , parameter integer C_S01_AXI_DATA_WIDTH = 64
    , parameter integer C_M00_AXI_ADDR_WIDTH = 32
    , parameter integer C_M00_AXI_DATA_WIDTH = 64
    )
   (
`ifdef FPGA
    input wire                                   aclk
    ,input wire                                  aresetn

    // AXI4-Lite Slave bus
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

    // AXI4 Slave bus
    ,input wire [C_S01_AXI_ADDR_WIDTH-1:0]       s01_axi_awaddr
    ,input wire                                  s01_axi_awvalid
    ,output wire                                 s01_axi_awready
    ,input wire [4:0]                            s01_axi_awid
    ,input wire                                  s01_axi_awlock
    ,input wire [3:0]                            s01_axi_awcache
    ,input wire [2:0]                            s01_axi_awprot
    ,input wire [7:0]                            s01_axi_awlen
    ,input wire [2:0]                            s01_axi_awsize
    ,input wire [1:0]                            s01_axi_awburst
    ,input wire [3:0]                            s01_axi_awqos
    ,input wire                                  s01_axi_awuser

    ,input wire [C_S01_AXI_DATA_WIDTH-1:0]       s01_axi_wdata
    ,input wire                                  s01_axi_wvalid
    ,output wire                                 s01_axi_wready
    ,input wire                                  s01_axi_wlast
    ,input wire [(C_S01_AXI_DATA_WIDTH/8)-1:0]   s01_axi_wstrb
    ,input wire                                  s01_axi_wuser

    ,output wire                                 s01_axi_bvalid
    ,input wire                                  s01_axi_bready
    ,output wire [4:0]                           s01_axi_bid
    ,output wire [1:0]                           s01_axi_bresp
    ,output wire                                 s01_axi_buser

    ,input wire [C_S01_AXI_ADDR_WIDTH-1:0]       s01_axi_araddr
    ,input wire                                  s01_axi_arvalid
    ,output wire                                 s01_axi_arready
    ,input wire [4:0]                            s01_axi_arid
    ,input wire                                  s01_axi_arlock
    ,input wire [3:0]                            s01_axi_arcache
    ,input wire [2:0]                            s01_axi_arprot
    ,input wire [7:0]                            s01_axi_arlen
    ,input wire [2:0]                            s01_axi_arsize
    ,input wire [1:0]                            s01_axi_arburst
    ,input wire [3:0]                            s01_axi_arqos
    ,input wire                                  s01_axi_aruser

    ,output wire [C_S01_AXI_DATA_WIDTH-1:0]      s01_axi_rdata
    ,output wire                                 s01_axi_rvalid
    ,input wire                                  s01_axi_rready
    ,output wire [4:0]                           s01_axi_rid
    ,output wire                                 s01_axi_rlast
    ,output wire [1:0]                           s01_axi_rresp
    ,output wire                                 s01_axi_ruser

    // AXI4 Master bus
    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr
    ,output wire                                 m00_axi_awvalid
    ,input wire                                  m00_axi_awready
    ,output wire [4:0]                           m00_axi_awid
    ,output wire                                 m00_axi_awlock
    ,output wire [3:0]                           m00_axi_awcache
    ,output wire [2:0]                           m00_axi_awprot
    ,output wire [7:0]                           m00_axi_awlen
    ,output wire [2:0]                           m00_axi_awsize
    ,output wire [1:0]                           m00_axi_awburst
    ,output wire [3:0]                           m00_axi_awqos
    ,output wire                                 m00_axi_awuser

    ,output wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata
    ,output wire                                 m00_axi_wvalid
    ,input wire                                  m00_axi_wready
    ,output wire                                 m00_axi_wlast
    ,output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb
    ,output wire                                 m00_axi_wuser

    ,input wire                                  m00_axi_bvalid
    ,output wire                                 m00_axi_bready
    ,input wire [4:0]                            m00_axi_bid
    ,input wire [1:0]                            m00_axi_bresp
    ,input wire                                  m00_axi_buser

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr
    ,output wire                                 m00_axi_arvalid
    ,input wire                                  m00_axi_arready
    ,output wire [4:0]                           m00_axi_arid
    ,output wire                                 m00_axi_arlock
    ,output wire [3:0]                           m00_axi_arcache
    ,output wire [2:0]                           m00_axi_arprot
    ,output wire [7:0]                           m00_axi_arlen
    ,output wire [2:0]                           m00_axi_arsize
    ,output wire [1:0]                           m00_axi_arburst
    ,output wire [3:0]                           m00_axi_arqos
    ,output wire                                 m00_axi_aruser

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]       m00_axi_rdata
    ,input wire                                  m00_axi_rvalid
    ,output wire                                 m00_axi_rready
    ,input wire [4:0]                            m00_axi_rid
    ,input wire                                  m00_axi_rlast
    ,input wire [1:0]                            m00_axi_rresp
    ,input wire                                  m00_axi_ruser
    );

    assign {s00_axi_aclk, s01_axi_aclk, m00_axi_aclk} = {3{aclk}};
    assign {s00_axi_aresetn, s01_axi_aresetn, m00_axi_aresetn} = {3{aresetn}};
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
    logic [C_S01_AXI_DATA_WIDTH-1:0] s01_axi_wdata, axi_wdata;
    logic [(C_S01_AXI_DATA_WIDTH/8)-1:0] s01_axi_wstrb, axi_wstrb;
    logic s01_axi_wvalid, s01_axi_wready;
    logic [1:0] s01_axi_bresp;
    logic s01_axi_bvalid, s01_axi_bready;
    logic [C_S01_AXI_ADDR_WIDTH-1:0] s01_axi_araddr;
    logic [2:0] s01_axi_arprot;
    logic s01_axi_arvalid, s01_axi_arready;
    logic [C_S01_AXI_DATA_WIDTH-1:0] s01_axi_rdata;
    logic [1:0] s01_axi_rresp;
    logic s01_axi_rvalid, s01_axi_rready;
    assign s01_axi_wstrb = axi_wstrb << s01_axi_awaddr[2:0];
    assign s01_axi_wdata = axi_wdata << {s01_axi_awaddr[2:0], 3'b0};

    logic [4:0] s01_axi_awid;
    logic [3:0] s01_axi_awcache, s01_axi_awqos;
    logic [7:0] s01_axi_awlen;
    logic [2:0] s01_axi_awsize;
    logic [1:0] s01_axi_awburst;
    logic s01_axi_awlock, s01_axi_awuser;
    assign s01_axi_awid = '0;
    assign s01_axi_awcache = '0;
    assign s01_axi_awqos = '0;
    assign s01_axi_awlen = '0; //BL=1
    assign s01_axi_awsize = 3'b010; //32-bits
    assign s01_axi_awburst = 2'b01; //inc
    assign s01_axi_awlock = '0;
    assign s01_axi_awuser = '0;

    logic s01_axi_wlast, s01_axi_wuser;
    assign s01_axi_wlast = 1'b1;
    assign s01_axi_wuser = '0;

    logic [4:0] s01_axi_bid;
    logic s01_axi_buser;

    logic [4:0] s01_axi_arid;
    logic [3:0] s01_axi_arcache, s01_axi_arqos;
    logic [7:0] s01_axi_arlen;
    logic [2:0] s01_axi_arsize;
    logic [1:0] s01_axi_arburst;
    logic s01_axi_arlock, s01_axi_aruser;
    assign s01_axi_arid = '0;
    assign s01_axi_arcache = '0;
    assign s01_axi_arqos = '0;
    assign s01_axi_arlen = '0; //BL=1
    assign s01_axi_arsize = 3'b010; //32-bits
    assign s01_axi_arburst = 2'b01; //inc
    assign s01_axi_arlock = '0;
    assign s01_axi_aruser = '0;

    logic s01_axi_rlast, s01_axi_ruser;
    logic [4:0] s01_axi_rid;

    logic [C_S01_AXI_ADDR_WIDTH-1:0] axi_araddr_r;
    logic [C_S01_AXI_DATA_WIDTH-1:0] axi_rdata;
    assign axi_rdata = s01_axi_rdata >> {axi_araddr_r[2:0], 3'b0};
    always_ff @(negedge s01_axi_aclk) begin
      if(s01_axi_arvalid & s01_axi_arready) begin
        axi_araddr_r <= s01_axi_araddr;
      end
    end

    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S01_AXI_ADDR_WIDTH), .data_width_p(C_S01_AXI_DATA_WIDTH))
     axil1
      (.aclk_o(s01_axi_aclk)
       ,.aresetn_o(s01_axi_aresetn)

       ,.awaddr_o(s01_axi_awaddr)
       ,.awprot_o(s01_axi_awprot)
       ,.awvalid_o(s01_axi_awvalid)
       ,.awready_i(s01_axi_awready)
       ,.wdata_o(axi_wdata)
       ,.wstrb_o(axi_wstrb)
       ,.wvalid_o(s01_axi_wvalid)
       ,.wready_i(s01_axi_wready)
       ,.bresp_i(s01_axi_bresp)
       ,.bvalid_i(s01_axi_bvalid)
       ,.bready_o(s01_axi_bready)

       ,.araddr_o(s01_axi_araddr)
       ,.arprot_o(s01_axi_arprot)
       ,.arvalid_o(s01_axi_arvalid)
       ,.arready_i(s01_axi_arready)
       ,.rdata_i(axi_rdata)
       ,.rresp_i(s01_axi_rresp)
       ,.rvalid_i(s01_axi_rvalid)
       ,.rready_o(s01_axi_rready)
       );

   localparam axi_id_width_p = 6;
   localparam axi_addr_width_p = 32;
   localparam axi_data_width_p = 64;
   localparam axi_strb_width_p = axi_data_width_p >> 3;
   localparam axi_burst_len_p = (ariane_pkg::ICACHE_LINE_WIDTH)/axi_data_width_p;

   wire                                 m00_axi_aclk = s00_axi_aclk;
   wire                                 m00_axi_aresetn = s00_axi_aresetn;
   wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_awaddr;
   wire                                 m00_axi_awvalid;
   wire                                 m00_axi_awready;
   wire [4:0]                           m00_axi_awid;
   wire                                 m00_axi_awlock;
   wire [3:0]                           m00_axi_awcache;
   wire [2:0]                           m00_axi_awprot;
   wire [7:0]                           m00_axi_awlen;
   wire [2:0]                           m00_axi_awsize;
   wire [1:0]                           m00_axi_awburst;
   wire [3:0]                           m00_axi_awqos;
   wire                                 m00_axi_awuser;
   wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_wdata;
   wire                                 m00_axi_wvalid;
   wire                                 m00_axi_wready;
   wire                                 m00_axi_wlast;
   wire [(C_M00_AXI_DATA_WIDTH/8)-1:0]  m00_axi_wstrb;
   wire                                 m00_axi_wuser;
   wire                                 m00_axi_bvalid;
   wire                                 m00_axi_bready;
   wire [4:0]                           m00_axi_bid;
   wire [1:0]                           m00_axi_bresp;
   wire                                 m00_axi_buser;
   wire [C_M00_AXI_ADDR_WIDTH-1:0]      m00_axi_araddr;
   wire                                 m00_axi_arvalid;
   wire                                 m00_axi_arready;
   wire [4:0]                           m00_axi_arid;
   wire                                 m00_axi_arlock;
   wire [3:0]                           m00_axi_arcache;
   wire [2:0]                           m00_axi_arprot;
   wire [7:0]                           m00_axi_arlen;
   wire [2:0]                           m00_axi_arsize;
   wire [1:0]                           m00_axi_arburst;
   wire [3:0]                           m00_axi_arqos;
   wire                                 m00_axi_aruser;
   wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata;
   wire                                 m00_axi_rvalid;
   wire                                 m00_axi_rready;
   wire [4:0]                           m00_axi_rid;
   wire                                 m00_axi_rlast;
   wire [1:0]                           m00_axi_rresp;
   wire                                 m00_axi_ruser;

   assign m00_axi_buser = '0;
   assign m00_axi_ruser = '0;

   bsg_nonsynth_axi_mem
     #(.axi_id_width_p(axi_id_width_p)
       ,.axi_addr_width_p(axi_addr_width_p)
       ,.axi_data_width_p(axi_data_width_p)
       ,.axi_burst_len_p (axi_burst_len_p)
       ,.mem_els_p(2**28) // 256 MB
       ,.init_data_p('0)
     )
   axi_mem
     (.clk_i          (m00_axi_aclk)
      ,.reset_i       (~m00_axi_aresetn)

      ,.axi_awid_i    (m00_axi_awid)
      ,.axi_awaddr_i  (m00_axi_awaddr)
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
      ,.C_S01_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH)
      ,.C_S01_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH)
      ,.C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
      ,.C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH)
      )
     top_fpga_inst
     (.s00_axi_aclk    (s00_axi_aclk)
      ,.s00_axi_aresetn(s00_axi_aresetn)
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

      ,.s01_axi_aclk   (s01_axi_aclk)
      ,.s01_axi_aresetn(s01_axi_aresetn)
      ,.s01_axi_awaddr (s01_axi_awaddr)
      ,.s01_axi_awvalid(s01_axi_awvalid)
      ,.s01_axi_awready(s01_axi_awready)
      ,.s01_axi_awid   (s01_axi_awid)
      ,.s01_axi_awlock (s01_axi_awlock)
      ,.s01_axi_awcache(s01_axi_awcache)
      ,.s01_axi_awprot (s01_axi_awprot)
      ,.s01_axi_awlen  (s01_axi_awlen)
      ,.s01_axi_awsize (s01_axi_awsize)
      ,.s01_axi_awburst(s01_axi_awburst)
      ,.s01_axi_awqos  (s01_axi_awqos)
      ,.s01_axi_awuser (s01_axi_awuser)

      ,.s01_axi_wdata  (s01_axi_wdata)
      ,.s01_axi_wvalid (s01_axi_wvalid)
      ,.s01_axi_wready (s01_axi_wready)
      ,.s01_axi_wlast  (s01_axi_wlast)
      ,.s01_axi_wstrb  (s01_axi_wstrb)
      ,.s01_axi_wuser  (s01_axi_wuser)

      ,.s01_axi_bvalid (s01_axi_bvalid)
      ,.s01_axi_bready (s01_axi_bready)
      ,.s01_axi_bid    (s01_axi_bid)
      ,.s01_axi_bresp  (s01_axi_bresp)
      ,.s01_axi_buser  (s01_axi_buser)

      ,.s01_axi_araddr (s01_axi_araddr)
      ,.s01_axi_arvalid(s01_axi_arvalid)
      ,.s01_axi_arready(s01_axi_arready)
      ,.s01_axi_arid   (s01_axi_arid)
      ,.s01_axi_arlock (s01_axi_arlock)
      ,.s01_axi_arcache(s01_axi_arcache)
      ,.s01_axi_arprot (s01_axi_arprot)
      ,.s01_axi_arlen  (s01_axi_arlen)
      ,.s01_axi_arsize (s01_axi_arsize)
      ,.s01_axi_arburst(s01_axi_arburst)
      ,.s01_axi_arqos  (s01_axi_arqos)
      ,.s01_axi_aruser (s01_axi_aruser)

      ,.s01_axi_rdata  (s01_axi_rdata)
      ,.s01_axi_rvalid (s01_axi_rvalid)
      ,.s01_axi_rready (s01_axi_rready)
      ,.s01_axi_rid    (s01_axi_rid)
      ,.s01_axi_rlast  (s01_axi_rlast)
      ,.s01_axi_rresp  (s01_axi_rresp)
      ,.s01_axi_ruser  (s01_axi_ruser)

      ,.m00_axi_aclk   (m00_axi_aclk)
      ,.m00_axi_aresetn(m00_axi_aresetn)
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
      ,.m00_axi_awuser (m00_axi_awuser)

      ,.m00_axi_wdata  (m00_axi_wdata)
      ,.m00_axi_wvalid (m00_axi_wvalid)
      ,.m00_axi_wready (m00_axi_wready)
      ,.m00_axi_wlast  (m00_axi_wlast)
      ,.m00_axi_wstrb  (m00_axi_wstrb)
      ,.m00_axi_wuser  (m00_axi_wuser)

      ,.m00_axi_bvalid (m00_axi_bvalid)
      ,.m00_axi_bready (m00_axi_bready)
      ,.m00_axi_bid    (m00_axi_bid)
      ,.m00_axi_bresp  (m00_axi_bresp)
      ,.m00_axi_buser  (m00_axi_buser)

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
      ,.m00_axi_aruser (m00_axi_aruser)

      ,.m00_axi_rdata  (m00_axi_rdata)
      ,.m00_axi_rvalid (m00_axi_rvalid)
      ,.m00_axi_rready (m00_axi_rready)
      ,.m00_axi_rid    (m00_axi_rid)
      ,.m00_axi_rlast  (m00_axi_rlast)
      ,.m00_axi_rresp  (m00_axi_rresp)
      ,.m00_axi_ruser  (m00_axi_ruser)
      );

`ifdef VCS
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $dumpfile("vcdplus.vpd");
           $dumpvars();
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
`elsif VERILATOR
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to trace.fst...\n", $time);
           $dumpfile("trace.fst");
           $dumpvars();
         end
     end
`endif

endmodule

