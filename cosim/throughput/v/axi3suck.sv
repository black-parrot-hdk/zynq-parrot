////////////////////////////////////////////////////////////////////////////////
`default_nettype none
module	axi3suck  #(
		parameter	C_AXI_ID_WIDTH = 1,
		parameter	C_AXI_ADDR_WIDTH = 32,
		parameter	C_AXI_DATA_WIDTH = 32,
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,

		//
		// AXI3 SLAVE
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	S_AXI_AWID,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]	S_AXI_AWADDR,
		input	wire	[3:0]			S_AXI_AWLEN,
		input	wire	[2:0]			S_AXI_AWSIZE,
		input	wire	[1:0]			S_AXI_AWBURST,
		input	wire	[1:0]			S_AXI_AWLOCK,
		input	wire	[3:0]			S_AXI_AWCACHE,
		input	wire	[2:0]			S_AXI_AWPROT,
		input	wire	[3:0]			S_AXI_AWQOS,

		//
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	S_AXI_WID,
		input	wire	[C_AXI_DATA_WIDTH-1:0]	S_AXI_WDATA,
		input	wire [C_AXI_DATA_WIDTH/8-1:0]	S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,

		//
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		output	wire	[C_AXI_ID_WIDTH-1:0]	S_AXI_BID,
		output	wire	[1:0]			S_AXI_BRESP,

		//
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	S_AXI_ARID,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]	S_AXI_ARADDR,
		input	wire	[3:0]			S_AXI_ARLEN,
		input	wire	[2:0]			S_AXI_ARSIZE,
		input	wire	[1:0]			S_AXI_ARBURST,
		input	wire	[1:0]			S_AXI_ARLOCK,
		input	wire	[3:0]			S_AXI_ARCACHE,
		input	wire	[2:0]			S_AXI_ARPROT,
		input	wire	[3:0]			S_AXI_ARQOS,

		//
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		output	wire	[C_AXI_ID_WIDTH-1:0]	S_AXI_RID,
		output	wire	[C_AXI_DATA_WIDTH-1:0]	S_AXI_RDATA,
		output	wire				S_AXI_RLAST,
		output	wire	[1:0]			S_AXI_RRESP,

	);

   // note that AXI is valid->ready; valid must stay asserted
   
   wire [3:0] 						count_r;
   logic [C_AXI_ID_WIDTH-1:0] 				axi_id_r;
   
   // we have write acknowledgements left to give
   assign S_AXI_BVALID = (count_r != 0);

   // we accept a write only if there is a valid address and we are not almost full
   wire write_valid = S_AXI_WVALID & S_AXI_AWVALID & (count_r != 4'hF);

   // we are on the last write when there is data and we accept it;
   wire write_last  = S_AXI_WLAST  & write_valid;

   // grap the last AWID id; note this is technically a bug and assumes there is only one writer ever
   // should be implemented with a FIFO 

   always @(posedge S_AXI_ACLK)
     begin
	if (write_last)
	  axi_id_r <= S_AXI_AWID;
     end

   assign S_AXI_BID = axi_id_r;
   	
   // we deqeue the address when we are done with the write
   assign S_AXI_AWREADY = write_last;
   assign S_AXI_WREADY  = write_valid;

   assign S_AXI_BRESP = 2'b00; // OKAY
   
   // hang on reads =)
   assign S_AXI_ARREADY = 1'b0;
   assign S_AXI_RVALID  = 1'b0;
   assign S_AXI_RLAST   = 1'b0;
   assign S_AXI_RRESP   = 2'b11; // decode error; saying we don't live here

    bsg_counter_up_down #(.max_val_p(15),.init_val_p(0),.max_step_p(1)) bcud
     (.clk_i(S_AXI_ACLK)
      ,.reset_i(~S_AXI_ARESETN)
      ,.up_i(write_last)
      ,.down_i(S_AXI_BVALID & S_AXI_BREADY)
      ,.count_o(count_r)
      );
   
endmodule
