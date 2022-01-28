
// TODO: This module will only work if the incoming axil stream
//   is not multiplexed between reads and writes. This is the case in BP.
//   More specifically, arvalid and awvalid should be mutex


`include "bsg_defines.v"

module bsg_axil_demux
 #(parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , localparam master_count = 4
   )
  (input                                 clk_i
   , input                               reset_i

   , input [addr_width_p-1:0]            s00_axil_awaddr
   , input [2:0]                         s00_axil_awprot
   , input                               s00_axil_awvalid
   , output logic                        s00_axil_awready

   , input [data_width_p-1:0]            s00_axil_wdata
   , input [(data_width_p/8)-1:0]        s00_axil_wstrb
   , input                               s00_axil_wvalid
   , output logic                        s00_axil_wready

   , output logic [1:0]                  s00_axil_bresp
   , output logic                        s00_axil_bvalid
   , input                               s00_axil_bready

   , input [addr_width_p-1:0]            s00_axil_araddr
   , input [2:0]                         s00_axil_arprot
   , input                               s00_axil_arvalid
   , output logic                        s00_axil_arready

   , output logic [data_width_p-1:0]     s00_axil_rdata
   , output logic [1:0]                  s00_axil_rresp
   , output logic                        s00_axil_rvalid
   , input                               s00_axil_rready

   , output logic [addr_width_p-1:0]     m00_axil_awaddr
   , output logic [2:0]                  m00_axil_awprot
   , output logic                        m00_axil_awvalid
   , input                               m00_axil_awready

   , output logic [data_width_p-1:0]     m00_axil_wdata
   , output logic [(data_width_p/8)-1:0] m00_axil_wstrb
   , output logic                        m00_axil_wvalid
   , input                               m00_axil_wready

   , input [1:0]                         m00_axil_bresp
   , input                               m00_axil_bvalid
   , output logic                        m00_axil_bready

   , output logic [addr_width_p-1:0]     m00_axil_araddr
   , output logic [2:0]                  m00_axil_arprot
   , output logic                        m00_axil_arvalid
   , input                               m00_axil_arready

   , input [data_width_p-1:0]            m00_axil_rdata
   , input [1:0]                         m00_axil_rresp
   , input                               m00_axil_rvalid
   , output logic                        m00_axil_rready

   , output logic [addr_width_p-1:0]     m01_axil_awaddr
   , output logic [2:0]                  m01_axil_awprot
   , output logic                        m01_axil_awvalid
   , input                               m01_axil_awready

   , output logic [data_width_p-1:0]     m01_axil_wdata
   , output logic [(data_width_p/8)-1:0] m01_axil_wstrb
   , output logic                        m01_axil_wvalid
   , input                               m01_axil_wready

   , input [1:0]                         m01_axil_bresp
   , input                               m01_axil_bvalid
   , output logic                        m01_axil_bready

   , output logic [addr_width_p-1:0]     m01_axil_araddr
   , output logic [2:0]                  m01_axil_arprot
   , output logic                        m01_axil_arvalid
   , input                               m01_axil_arready

   , input [data_width_p-1:0]            m01_axil_rdata
   , input [1:0]                         m01_axil_rresp
   , input                               m01_axil_rvalid
   , output logic                        m01_axil_rready

   , output logic [addr_width_p-1:0]     m02_axil_awaddr
   , output logic [2:0]                  m02_axil_awprot
   , output logic                        m02_axil_awvalid
   , input                               m02_axil_awready

   , output logic [data_width_p-1:0]     m02_axil_wdata
   , output logic [(data_width_p/8)-1:0] m02_axil_wstrb
   , output logic                        m02_axil_wvalid
   , input                               m02_axil_wready

   , input [1:0]                         m02_axil_bresp
   , input                               m02_axil_bvalid
   , output logic                        m02_axil_bready

   , output logic [addr_width_p-1:0]     m02_axil_araddr
   , output logic [2:0]                  m02_axil_arprot
   , output logic                        m02_axil_arvalid
   , input                               m02_axil_arready

   , input [data_width_p-1:0]            m02_axil_rdata
   , input [1:0]                         m02_axil_rresp
   , input                               m02_axil_rvalid
   , output logic                        m02_axil_rready

   , output logic [addr_width_p-1:0]     m03_axil_awaddr
   , output logic [2:0]                  m03_axil_awprot
   , output logic                        m03_axil_awvalid
   , input                               m03_axil_awready

   , output logic [data_width_p-1:0]     m03_axil_wdata
   , output logic [(data_width_p/8)-1:0] m03_axil_wstrb
   , output logic                        m03_axil_wvalid
   , input                               m03_axil_wready

   , input [1:0]                         m03_axil_bresp
   , input                               m03_axil_bvalid
   , output logic                        m03_axil_bready

   , output logic [addr_width_p-1:0]     m03_axil_araddr
   , output logic [2:0]                  m03_axil_arprot
   , output logic                        m03_axil_arvalid
   , input                               m03_axil_arready

   , input [data_width_p-1:0]            m03_axil_rdata
   , input [1:0]                         m03_axil_rresp
   , input                               m03_axil_rvalid
   , output logic                        m03_axil_rready

   );

  logic [master_count-1:0] select_m0x_one_hot_r, select_m0x_one_hot_n;
  logic [master_count-1:0] select_m0x_one_hot;
  logic [master_count-1:0] m0x_enable;
  logic                    select_m0x_one_hot_v_r;
  logic                    encoder_v_lo;

  wire [master_count-1:0] raddr_hit = {
        ((s00_axil_araddr >= 32'h50_0000) && (s00_axil_araddr < 32'h60_0000))  // eth
       ,((s00_axil_araddr >= 32'h60_0000) && (s00_axil_araddr < 32'h460_0000)) // plic
       ,((s00_axil_araddr >= 32'h460_0000) || ((s00_axil_araddr >= 32'h20_0000) && (s00_axil_araddr < 32'h50_0000))) // acc
       ,(s00_axil_araddr < 32'h20_0000)  // host
       };

  wire [master_count-1:0] waddr_hit = {
        ((s00_axil_araddr >= 32'h50_0000) && (s00_axil_araddr < 32'h60_0000))  // eth
       ,((s00_axil_araddr >= 32'h60_0000) && (s00_axil_araddr < 32'h460_0000)) // plic
       ,((s00_axil_araddr >= 32'h460_0000) || ((s00_axil_araddr >= 32'h20_0000) && (s00_axil_araddr < 32'h50_0000))) // acc
       ,(s00_axil_araddr < 32'h20_0000)  // host
       };

  for(genvar i = 0;i < master_count;i++) begin: enable
    assign m0x_enable[i] = ((s00_axil_arvalid && raddr_hit[i])
                     || (s00_axil_awvalid && waddr_hit[i]));
  end


  wire clear_selection = (s00_axil_rvalid & s00_axil_rready)
            | (s00_axil_bvalid & s00_axil_bready);

  bsg_priority_encode_one_hot_out #(
      .width_p(master_count)
     ,.lo_to_hi_p(1)
    ) encoder (
      .i(m0x_enable)
     ,.o(select_m0x_one_hot)
     ,.v_o(encoder_v_lo)
     );


  bsg_dff_reset_set_clear
   #(.width_p(1)
     ,.clear_over_set_p(0))
   select_m0x_one_hot_v_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.set_i(encoder_v_lo)
     ,.clear_i(clear_selection)
     ,.data_o(select_m0x_one_hot_v_r)
     );

  always_comb begin
    select_m0x_one_hot_n = select_m0x_one_hot_r;
    if(encoder_v_lo) begin
      if(~select_m0x_one_hot_v_r | clear_selection)
        select_m0x_one_hot_n = select_m0x_one_hot;
    end
    else if(clear_selection)
      select_m0x_one_hot_n = '0;
  end

  bsg_dff_reset
   #(.width_p(master_count))
   select_m0x_one_hot_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(select_m0x_one_hot_n)
     ,.data_o(select_m0x_one_hot_r)
    );



  assign {m03_axil_awaddr, m02_axil_awaddr, m01_axil_awaddr, m00_axil_awaddr}
        = {(master_count){s00_axil_awaddr}};
  assign {m03_axil_awprot, m02_axil_awprot, m01_axil_awprot, m00_axil_awprot}
        = {(master_count){s00_axil_awprot}};

  assign m00_axil_awvalid = select_m0x_one_hot_r[0] & s00_axil_awvalid;
  assign m01_axil_awvalid = select_m0x_one_hot_r[1] & s00_axil_awvalid;
  assign m02_axil_awvalid = select_m0x_one_hot_r[2] & s00_axil_awvalid;
  assign m03_axil_awvalid = select_m0x_one_hot_r[3] & s00_axil_awvalid;

  assign s00_axil_awready = (select_m0x_one_hot_r[0] & m00_axil_awready)
                          | (select_m0x_one_hot_r[1] & m01_axil_awready)
                          | (select_m0x_one_hot_r[2] & m02_axil_awready)
                          | (select_m0x_one_hot_r[3] & m03_axil_awready);

  assign {m03_axil_wdata, m02_axil_wdata, m01_axil_wdata, m00_axil_wdata}
        = {(master_count){s00_axil_wdata}};
  assign {m03_axil_wstrb, m02_axil_wstrb, m01_axil_wstrb, m00_axil_wstrb}
        = {(master_count){s00_axil_wstrb}};
  assign m00_axil_wvalid = select_m0x_one_hot_r[0] & s00_axil_wvalid;
  assign m01_axil_wvalid = select_m0x_one_hot_r[1] & s00_axil_wvalid;
  assign m02_axil_wvalid = select_m0x_one_hot_r[2] & s00_axil_wvalid;
  assign m03_axil_wvalid = select_m0x_one_hot_r[3] & s00_axil_wvalid;

  assign s00_axil_wready = (select_m0x_one_hot_r[0] & m00_axil_wready)
                         | (select_m0x_one_hot_r[1] & m01_axil_wready)
                         | (select_m0x_one_hot_r[2] & m02_axil_wready)
                         | (select_m0x_one_hot_r[3] & m03_axil_wready);

  always_comb begin
    s00_axil_bresp = '0;
    case(select_m0x_one_hot_r)
      4'b0001:
        s00_axil_bresp = m00_axil_bresp;
      4'b0010:
        s00_axil_bresp = m01_axil_bresp;
      4'b0100:
        s00_axil_bresp = m02_axil_bresp;
      4'b1000:
        s00_axil_bresp = m03_axil_bresp;
    endcase
  end
  assign s00_axil_bvalid = (select_m0x_one_hot_r[0] & m00_axil_bvalid)
                         | (select_m0x_one_hot_r[1] & m01_axil_bvalid)
                         | (select_m0x_one_hot_r[2] & m02_axil_bvalid)
                         | (select_m0x_one_hot_r[3] & m03_axil_bvalid);

  assign m00_axil_bready = select_m0x_one_hot_r[0] & s00_axil_bready;
  assign m01_axil_bready = select_m0x_one_hot_r[1] & s00_axil_bready;
  assign m02_axil_bready = select_m0x_one_hot_r[2] & s00_axil_bready;
  assign m03_axil_bready = select_m0x_one_hot_r[3] & s00_axil_bready;


  assign {m03_axil_araddr, m02_axil_araddr, m01_axil_araddr, m00_axil_araddr}
        = {(master_count){s00_axil_araddr}};
  assign {m03_axil_arprot, m02_axil_arprot, m01_axil_arprot, m00_axil_arprot}
        = {(master_count){s00_axil_arprot}};
  assign m00_axil_arvalid = select_m0x_one_hot_r[0] & s00_axil_arvalid;
  assign m01_axil_arvalid = select_m0x_one_hot_r[1] & s00_axil_arvalid;
  assign m02_axil_arvalid = select_m0x_one_hot_r[2] & s00_axil_arvalid;
  assign m03_axil_arvalid = select_m0x_one_hot_r[3] & s00_axil_arvalid;

  assign s00_axil_arready = (select_m0x_one_hot_r[0] & m00_axil_arready)
                          | (select_m0x_one_hot_r[1] & m01_axil_arready)
                          | (select_m0x_one_hot_r[2] & m02_axil_arready)
                          | (select_m0x_one_hot_r[3] & m03_axil_arready);

  always_comb begin
    s00_axil_rdata = '0;
    s00_axil_rresp = '0;
    case(select_m0x_one_hot_r)
        4'b0001: begin
          s00_axil_rdata = m00_axil_rdata;
          s00_axil_rresp = m00_axil_rresp;
        end
        4'b0010: begin
          s00_axil_rdata = m01_axil_rdata;
          s00_axil_rresp = m01_axil_rresp;
        end
        4'b0100: begin
          s00_axil_rdata = m02_axil_rdata;
          s00_axil_rresp = m02_axil_rresp;
        end
        4'b1000: begin
          s00_axil_rdata = m03_axil_rdata;
          s00_axil_rresp = m03_axil_rresp;
        end
    endcase
  end

  assign s00_axil_rvalid = (select_m0x_one_hot_r[0] & m00_axil_rvalid)
                         | (select_m0x_one_hot_r[1] & m01_axil_rvalid)
                         | (select_m0x_one_hot_r[2] & m02_axil_rvalid)
                         | (select_m0x_one_hot_r[3] & m03_axil_rvalid);
  assign m00_axil_rready = select_m0x_one_hot_r[0] & s00_axil_rready;
  assign m01_axil_rready = select_m0x_one_hot_r[1] & s00_axil_rready;
  assign m02_axil_rready = select_m0x_one_hot_r[2] & s00_axil_rready;
  assign m03_axil_rready = select_m0x_one_hot_r[3] & s00_axil_rready;

endmodule

`BSG_ABSTRACT_MODULE(bsg_axil_demux)

