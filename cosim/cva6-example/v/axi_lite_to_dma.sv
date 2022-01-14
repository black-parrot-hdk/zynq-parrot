
module axi_lite_to_dma
 #(
   parameter addr_width_p = 64
  ,parameter data_width_p = 64

  ,localparam strb_width_lp = data_width_p / 8
  )
  (
   input clk_i
  ,input reset_i

  // Master AXI4-Lite port
  ,output awready_o
  ,input awvalid_i
  ,input [addr_width_p-1:0] awaddr_i

  ,output wready_o
  ,input wvalid_i
  ,input [strb_width_lp-1:0] wstrb_i
  ,input [data_width_p-1:0] wdata_i

  ,output bvalid_o
  ,output [1:0] bresp_o
  ,input bready_i

  ,output arready_o
  ,input arvalid_i
  ,input [addr_width_p-1:0] araddr_i

  ,output rvalid_o
  ,output [data_width_p-1:0] rdata_o
  ,output [1:0] rresp_o
  ,input rready_i

  // DMA ports
  ,input ready_i
  ,output v_o
  ,output we_o
  ,output [addr_width_p-1:0] addr_o
  ,output [strb_width_lp-1:0] be_o
  ,output [data_width_p-1:0] data_o

  ,output ready_o
  ,input v_i
  ,input [data_width_p-1:0] data_i
  );

  logic fence, bvalid_lo;
  assign awready_o = ~reset_i & ready_i & ~fence & awvalid_i & wvalid_i;
  assign arready_o = ~reset_i & ready_i & ~fence & arvalid_i & ~awready_o;
  assign wready_o  = awready_o;

  assign v_o     = awready_o | arready_o;
  assign we_o    = awready_o;
  assign addr_o  = we_o ? awaddr_i : araddr_i;
  assign be_o    = wstrb_i;
  assign data_o  = wdata_i;

  assign ready_o = rready_i;
  assign rvalid_o = v_i;
  assign rdata_o = data_i;
  assign rresp_o = 2'b0;

  assign bvalid_o = bvalid_lo;
  assign bresp_o = 2'b0;

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      fence <= 1'b0;
    end
    else if(awready_o | arready_o) begin
      fence <= 1'b1;
    end
    else if((bvalid_o & bready_i) | (rvalid_o & rready_i)) begin
      fence <= 1'b0;
    end
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      bvalid_lo <= 1'b0;
    end
    else if(awready_o) begin
      bvalid_lo <= 1'b1;
    end
    else if(bvalid_o & bready_i) begin
      bvalid_lo <= 1'b0;
    end
  end

endmodule
