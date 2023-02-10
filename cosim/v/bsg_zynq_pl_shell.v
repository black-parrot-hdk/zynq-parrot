
`include "bsg_defines.v"

`timescale 1 ns / 1 ps

module bsg_zynq_pl_shell #
  (
   //--------------------------------------------------------------------------------
   // USER MODIFY -- Configure your accelerator interface by setting these parameters
   //--------------------------------------------------------------------------------
   //
   // Change these parameters to change the number of CSRs, input FIFOs and output FIFOs.
   //
   // note: we automatically create a "elements avail" CSR for the input FIFO
   //       and a "free space avail" csr for each output FIFO
   //
   // if the PS reads from the FIFO and it is empty, it will return bogus data.
   // if the PS writes to a FIFO and it is full, it will be dropped.
   //
   // reading the FIFO csrs tells you how many consecutive words you can read/write before
   // checking the csr again

   parameter  num_regs_ps_to_pl_p = 1      // number of user CSRs read-only by PL, r/w by PS
   ,parameter num_regs_pl_to_ps_p = 1      // number of user CSRs read-only by PS, r/w by PL
   ,parameter num_fifo_ps_to_pl_p = 1      // number of input FIFOs (from PS to PL)
   ,parameter num_fifo_pl_to_ps_p = 1      // number of output FIFOs (from PL to PS)

   // this correspond to the number of word addresses that can be read by PS
   ,parameter read_locs_lp = num_regs_ps_to_pl_p+num_fifo_pl_to_ps_p+num_fifo_ps_to_pl_p+num_fifo_pl_to_ps_p+num_regs_pl_to_ps_p

   // this corresponds to the number of addresses that can be written by PS
   ,parameter write_locs_lp = num_regs_ps_to_pl_p+num_fifo_ps_to_pl_p

   // Width of S_AXI data bus

   ,parameter integer C_S_AXI_DATA_WIDTH   = 32

   // Width of S_AXI address bus

   // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
   // ADDR_LSB is used for addressing 32/64 bit registers/memories
   // ADDR_LSB = 2 for 32 bits (n downto 2)
   // ADDR_LSB = 3 for 64 bits (n downto 3)

   ,localparam integer ADDR_LSB_lp = (C_S_AXI_DATA_WIDTH/32) + 1
   ,parameter integer C_S_AXI_ADDR_WIDTH   = `BSG_SAFE_CLOG2(read_locs_lp)+ADDR_LSB_lp
   )
   (
    input wire [num_fifo_pl_to_ps_p-1:0][C_S_AXI_DATA_WIDTH-1:0]  pl_to_ps_fifo_data_i,
    input wire [num_fifo_pl_to_ps_p-1:0]                          pl_to_ps_fifo_v_i,
    output wire [num_fifo_pl_to_ps_p-1:0]                         pl_to_ps_fifo_ready_o,

    output wire [num_fifo_ps_to_pl_p-1:0][C_S_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_o,
    output wire [num_fifo_ps_to_pl_p-1:0]                         ps_to_pl_fifo_v_o,
    input wire [num_fifo_ps_to_pl_p-1:0]                          ps_to_pl_fifo_yumi_i,

    output wire [num_regs_ps_to_pl_p-1:0]                         csr_data_v_o,
    output wire [num_regs_ps_to_pl_p-1:0]                         csr_data_w_o,
    output wire [num_regs_ps_to_pl_p-1:0][C_S_AXI_DATA_WIDTH-1:0] csr_data_o,

    // note: this does not create registers, they are implemented in client PL
    input wire [num_regs_pl_to_ps_p-1:0][C_S_AXI_DATA_WIDTH-1:0]  csr_data_i,

                // Global Clock Signal
    input wire                                                    S_AXI_ACLK,
                // Global Reset Signal. This Signal is Active LOW
    input wire                                                    S_AXI_ARESETN,
                // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0]                         S_AXI_AWADDR,
                // Write channel Protection type. This signal indicates the
                // privilege and security level of the transaction, and whether
                // the transaction is a data access or an instruction access.
    input wire [2 : 0]                                            S_AXI_AWPROT,
                // Write address valid. This signal indicates that the master signaling
                // valid write address and control information.
    input wire                                                    S_AXI_AWVALID,
                // Write address ready. This signal indicates that the slave is ready
                // to accept an address and associated control signals.
    output wire                                                   S_AXI_AWREADY,
                // Write data (issued by master, acceped by Slave)
    input wire [C_S_AXI_DATA_WIDTH-1 : 0]                         S_AXI_WDATA,
                // Write strobes. This signal indicates which byte lanes hold
                // valid data. There is one write strobe bit for each eight
                // bits of the write data bus.
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]                     S_AXI_WSTRB,
                // Write valid. This signal indicates that valid write
                // data and strobes are available.
    input wire                                                    S_AXI_WVALID,
                // Write ready. This signal indicates that the slave
                // can accept the write data.
    output wire                                                   S_AXI_WREADY,
                // Write response. This signal indicates the status
                // of the write transaction.
    output wire [1 : 0]                                           S_AXI_BRESP,
                // Write response valid. This signal indicates that the channel
                // is signaling a valid write response.
    output wire                                                   S_AXI_BVALID,
                // Response ready. This signal indicates that the master
                // can accept a write response.
    input wire                                                    S_AXI_BREADY,
                // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0]                         S_AXI_ARADDR,
                // Protection type. This signal indicates the privilege
                // and security level of the transaction, and whether the
                // transaction is a data access or an instruction access.
    input wire [2 : 0]                                            S_AXI_ARPROT,
                // Read address valid. This signal indicates that the channel
                // is signaling valid read address and control information.
    input wire                                                    S_AXI_ARVALID,
                // Read address ready. This signal indicates that the slave is
                // ready to accept an address and associated control signals.
    output wire                                                   S_AXI_ARREADY,
                // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]                        S_AXI_RDATA,
                // Read response. This signal indicates the status of the
                // read transfer.
    output wire [1 : 0]                                           S_AXI_RRESP,
                // Read valid. This signal indicates that the channel is
                // signaling the required read data.
    output wire                                                   S_AXI_RVALID,
                // Read ready. This signal indicates that the master can
                // accept the read data and response information.
    input wire                                                    S_AXI_RREADY
    );

   // AXI4LITE signals
   reg [C_S_AXI_ADDR_WIDTH-1 : 0]                                 axi_awaddr;
   reg                                                            axi_awready;
   reg                                                            axi_wready;
   reg [1 : 0]                                                    axi_bresp;
   reg                                                            axi_bvalid;
   reg [C_S_AXI_ADDR_WIDTH-1 : 0]                                 axi_araddr;
   reg                                                            axi_arready;
   reg [C_S_AXI_DATA_WIDTH-1 : 0]                                 axi_rdata;
   reg [1 : 0]                                                    axi_rresp;
   reg                  axi_rvalid;
   reg [num_regs_ps_to_pl_p-1:0] csr_data_v_r;
   reg [num_regs_ps_to_pl_p-1:0] csr_data_w_r;

   initial
     begin
        assert(`BSG_SAFE_CLOG2(read_locs_lp)+ADDR_LSB_lp <= C_S_AXI_ADDR_WIDTH)
          else
            $error("read_locs_lp (%d) + ADDR_LSB_lp (%d) ! <= C_S_AXI_ADDR_WIDTH (%d)\n",`BSG_SAFE_CLOG2(read_locs_lp),ADDR_LSB_lp, C_S_AXI_ADDR_WIDTH);
     end

   wire     slv_reg_rden;
   wire     slv_reg_wren;
   reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
   integer                      byte_index;
   reg                          aw_en;

   // I/O Connections assignments

   assign S_AXI_AWREADY    = axi_awready;
   assign S_AXI_WREADY     = axi_wready;
   assign S_AXI_BRESP      = axi_bresp;
   assign S_AXI_BVALID     = axi_bvalid;
   assign S_AXI_ARREADY    = axi_arready;
   assign S_AXI_RDATA      = axi_rdata;
   assign S_AXI_RRESP      = axi_rresp;
   assign S_AXI_RVALID     = axi_rvalid;
   // Implement axi_awready generation
   // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
   // de-asserted when reset is low.

   always @( posedge S_AXI_ACLK )
     begin
        if ( S_AXI_ARESETN == 1'b0 )
          begin
             axi_awready <= 1'b0;
             aw_en <= 1'b1;
          end
        else
          begin
             if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
               begin
                  // slave is ready to accept write address when
                  // there is a valid write address and write data
                  // on the write address and data bus. This design
                  // expects no outstanding transactions.
                  axi_awready <= 1'b1;
                  aw_en <= 1'b0;
               end
             else if (S_AXI_BREADY && axi_bvalid)
               begin
                  aw_en <= 1'b1;
                  axi_awready <= 1'b0;
               end
             else
               begin
                  axi_awready <= 1'b0;
               end
          end
     end

   // Implement axi_awaddr latching
   // This process is used to latch the address when both
   // S_AXI_AWVALID and S_AXI_WVALID are valid.

   always @( posedge S_AXI_ACLK )
     begin
        if ( S_AXI_ARESETN == 1'b0 )
            begin
               axi_awaddr <= 0;
            end
        else
          begin
             if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
               begin
                  // Write Address latching
                  axi_awaddr <= S_AXI_AWADDR;
               end
          end
        end

   // Implement axi_wready generation
   // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
   // de-asserted when reset is low.

   always @( posedge S_AXI_ACLK )
     begin
        if ( S_AXI_ARESETN == 1'b0 )
          begin
             axi_wready <= 1'b0;
          end
          else
            begin
               if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
                 begin
                    // slave is ready to accept write data when
                    // there is a valid write address and write data
                    // on the write address and data bus. This design
                    // expects no outstanding transactions.
                    axi_wready <= 1'b1;
                 end
               else
                 begin
                    axi_wready <= 1'b0;
                 end
            end
     end

   // Implement memory mapped register select and write logic generation
   // The write data is accepted and written to memory mapped registers when
   // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
   // select byte enables of slave registers while writing.
   // These registers are cleared when reset (active low) is applied.
   // Slave register write enable is asserted when valid address and data are available
   // and the slave is ready to accept the write address and write data.
   assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

   wire [read_locs_lp-1:0] slv_rd_sel_one_hot;
   wire [write_locs_lp-1:0] slv_wr_sel_one_hot;

   bsg_decode_with_v #(.num_out_p(read_locs_lp)) decode_rd
     (.i(axi_araddr[`BSG_SAFE_CLOG2(read_locs_lp)+ADDR_LSB_lp-1:ADDR_LSB_lp])
      ,.v_i(slv_reg_rden)
      ,.o(slv_rd_sel_one_hot)
      );

   // for num_regs_ps_to_pl_p=4 and num_fifo_ps_to_pl_p=4, the write memory map is essentially:
   //
   // 0,4,8,C: registers
   // 10,14,18,1C: input fifo

   bsg_decode_with_v #(.num_out_p(write_locs_lp)) decode_wr
     (.i(axi_awaddr[`BSG_SAFE_CLOG2(write_locs_lp)+ADDR_LSB_lp-1:ADDR_LSB_lp])
      ,.v_i(slv_reg_wren)
      ,.o(slv_wr_sel_one_hot)
      );

   logic [num_regs_ps_to_pl_p-1:0][C_S_AXI_DATA_WIDTH-1:0] slv_r;

   // instantiate user read/write CSRs
   for (genvar k=0; k < num_regs_ps_to_pl_p; k++)
     begin: rof
        bsg_dff_reset_en #(.width_p(C_S_AXI_DATA_WIDTH)) slv_reg
          (.clk_i(S_AXI_ACLK)
           ,.reset_i(~S_AXI_ARESETN)
           ,.en_i(slv_wr_sel_one_hot[k])
           ,.data_i(S_AXI_WDATA)
           ,.data_o(slv_r[k])
           );
     end

   wire [num_fifo_ps_to_pl_p-1:0] ps_to_pl_fifo_ready_lo, ps_to_pl_fifo_valid_lo, ps_to_pl_fifo_yumi_li, ps_to_pl_fifo_valid_li;
   wire [num_fifo_ps_to_pl_p-1:0][C_S_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [num_fifo_ps_to_pl_p-1:0][`BSG_WIDTH(4)-1:0]      ps_to_pl_fifo_ctrs;
   wire [num_fifo_ps_to_pl_p-1:0][C_S_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_ctrs_full;

   // instantiate in (PS to PL) FIFOs
   for (genvar k=0; k < num_fifo_ps_to_pl_p; k++)
     begin: rof2
        assign ps_to_pl_fifo_ctrs_full[k] = (C_S_AXI_DATA_WIDTH) ' (ps_to_pl_fifo_ctrs[k]);

        assign ps_to_pl_fifo_valid_li[k] = ps_to_pl_fifo_ready_lo[k] & slv_wr_sel_one_hot[num_regs_ps_to_pl_p+k];

        bsg_fifo_1r1w_small #(.width_p(C_S_AXI_DATA_WIDTH), .els_p(4)) fifo
          (.clk_i(S_AXI_ACLK)
           ,.reset_i(~S_AXI_ARESETN)
           ,.v_i(ps_to_pl_fifo_valid_li[k])
           ,.ready_o(ps_to_pl_fifo_ready_lo[k])
           ,.data_i(S_AXI_WDATA)

           ,.v_o(ps_to_pl_fifo_valid_lo[k])
           ,.data_o(ps_to_pl_fifo_data_lo[k])
           ,.yumi_i(ps_to_pl_fifo_yumi_li[k])
           );

        always @(negedge S_AXI_ACLK)
          begin
             assert(~S_AXI_ARESETN | ~slv_wr_sel_one_hot[num_regs_ps_to_pl_p+k] | ps_to_pl_fifo_ready_lo[k])
               else $error("write to full fifo");
          end

        bsg_flow_counter #(.els_p(4)
                           ,.count_free_p(1)
                           ) bfc
          (.clk_i(S_AXI_ACLK)
           ,.reset_i(~S_AXI_ARESETN)
           ,.v_i    (ps_to_pl_fifo_valid_li[k])
           ,.ready_i(ps_to_pl_fifo_ready_lo[k])
           ,.yumi_i (ps_to_pl_fifo_yumi_li [k])
           ,.count_o(ps_to_pl_fifo_ctrs    [k])
           );

     end // block: rof2


   logic [num_fifo_pl_to_ps_p-1:0][C_S_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_r, pl_to_ps_fifo_data_li;
   logic [num_fifo_pl_to_ps_p-1:0]                         pl_to_ps_fifo_valid_lo,
                                                           pl_to_ps_fifo_ready_lo,
                                                           pl_to_ps_fifo_valid_li,
                                                           pl_to_ps_fifo_yumi_li;

   logic [num_fifo_pl_to_ps_p-1:0][`BSG_WIDTH(4)-1:0]      pl_to_ps_fifo_ctrs;
   logic [num_fifo_pl_to_ps_p-1:0][C_S_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_ctrs_full;

   for (genvar k=0; k < num_fifo_pl_to_ps_p; k++)
     begin: rof4
        assign pl_to_ps_fifo_data_li[k]  = pl_to_ps_fifo_data_i  [k];
        assign pl_to_ps_fifo_valid_li[k] = pl_to_ps_fifo_v_i     [k];
        assign pl_to_ps_fifo_ready_o[k]  = pl_to_ps_fifo_ready_lo[k];
     end

   for (genvar k=0; k < num_fifo_ps_to_pl_p; k++)
     begin: rof1
        assign ps_to_pl_fifo_yumi_li[k] = ps_to_pl_fifo_yumi_i  [k];
        assign ps_to_pl_fifo_data_o[k]  = ps_to_pl_fifo_data_lo [k];
        assign ps_to_pl_fifo_v_o[k]     = ps_to_pl_fifo_valid_lo[k];
     end

   always @(posedge S_AXI_ACLK) begin
     if (S_AXI_ARESETN == 1'b0) begin
       csr_data_w_r <= '0;
       csr_data_v_r <= '0;
     end
     else begin
       csr_data_w_r <= slv_wr_sel_one_hot[num_regs_ps_to_pl_p-1:0];
       csr_data_v_r <= slv_wr_sel_one_hot[num_regs_ps_to_pl_p-1:0] | slv_rd_sel_one_hot[num_regs_ps_to_pl_p-1:0];
     end
   end

   for (genvar k=0; k < num_regs_ps_to_pl_p; k++)
     begin: rof5
        assign csr_data_o[k] = slv_r[k];
        assign csr_data_v_o[k] = csr_data_v_r[k];
        assign csr_data_w_o[k] = csr_data_w_r[k];
     end

   // END

   // instantiate out (pl_to_ps) FIFOs

   for (genvar k=0; k < num_fifo_pl_to_ps_p; k++)
     begin: pl_to_ps

        assign pl_to_ps_fifo_ctrs_full[k] = (C_S_AXI_DATA_WIDTH) ' (pl_to_ps_fifo_ctrs[k]);

        assign pl_to_ps_fifo_yumi_li[k] = pl_to_ps_fifo_valid_lo[k] & slv_rd_sel_one_hot[num_regs_ps_to_pl_p+k];

        bsg_fifo_1r1w_small #(.width_p(C_S_AXI_DATA_WIDTH), .els_p(4)) fifo
          (.clk_i(S_AXI_ACLK)
           ,.reset_i(~S_AXI_ARESETN)
           ,.v_i(    pl_to_ps_fifo_valid_li[k])
           ,.ready_o(pl_to_ps_fifo_ready_lo[k])

           ,.data_i( pl_to_ps_fifo_data_li [k])

           ,.v_o(   pl_to_ps_fifo_valid_lo[k])
           ,.data_o(pl_to_ps_fifo_data_r  [k])
           // only deque if it is not empty =)
           ,.yumi_i(pl_to_ps_fifo_valid_lo[k] & slv_rd_sel_one_hot[num_regs_ps_to_pl_p+k])
           );

       bsg_flow_counter #(.els_p(4)
                          ,.count_free_p(0)
                          ) bfc
         (.clk_i   (S_AXI_ACLK)
          ,.reset_i(~S_AXI_ARESETN)
          ,.v_i    (pl_to_ps_fifo_valid_li[k])
          ,.ready_i(pl_to_ps_fifo_ready_lo[k])
          ,.yumi_i (pl_to_ps_fifo_yumi_li [k])
          ,.count_o(pl_to_ps_fifo_ctrs    [k])
          );

        always @(negedge S_AXI_ACLK)
          begin
             assert(~S_AXI_ARESETN | ~slv_rd_sel_one_hot[num_regs_ps_to_pl_p+k] | pl_to_ps_fifo_valid_lo[k])
               else $error("read from empty fifo");
          end
     end

   // Implement write response logic generation
   // The write response and response valid signals are asserted by the slave
   // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
   // This marks the acceptance of address and indicates the status of
   // write transaction.

   always @( posedge S_AXI_ACLK )
     begin
        if ( S_AXI_ARESETN == 1'b0 )
          begin
             axi_bvalid  <= 0;
             axi_bresp   <= 2'b0;
          end
        else
          begin
             if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
               begin
                  // indicates a valid write response is available
                  axi_bvalid <= 1'b1;
                  axi_bresp  <= 2'b0; // 'OKAY' response
               end                   // work error responses in future
             else
               begin
                  if (S_AXI_BREADY && axi_bvalid)
                    //check if bready is asserted while bvalid is high)
                    //(there is a possibility that bready is always asserted high)
                    begin
                       axi_bvalid <= 1'b0;
                    end
               end
          end
     end

   // Implement axi_arready generation
   // axi_arready is asserted for one S_AXI_ACLK clock cycle when
   // S_AXI_ARVALID is asserted. axi_awready is
   // de-asserted when reset (active low) is asserted.
   // The read address is also latched when S_AXI_ARVALID is
   // asserted. axi_araddr is reset to zero on reset assertion.

   always @( posedge S_AXI_ACLK )
     begin
        if ( S_AXI_ARESETN == 1'b0 )
          begin
             axi_arready <= 1'b0;
             axi_araddr  <= 0;
          end
        else
          begin
             if (~axi_arready && S_AXI_ARVALID)
               begin
                  // indicates that the slave has acceped the valid read address
                  axi_arready <= 1'b1;
                  // Read address latching
                  axi_araddr  <= S_AXI_ARADDR;
               end
             else
               begin
                  axi_arready <= 1'b0;
               end
            end
     end


   // Implement axi_arvalid generation
   // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_ARVALID and axi_arready are asserted. The slave registers
   // data are available on the axi_rdata bus at this instance. The
   // assertion of axi_rvalid marks the validity of read data on the
   // bus and axi_rresp indicates the status of read transaction.axi_rvalid
   // is deasserted on reset (active low). axi_rresp and axi_rdata are
   // cleared to zero on reset (active low).
   always @( posedge S_AXI_ACLK )
     begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
               axi_rvalid <= 0;
               axi_rresp  <= 0;
            end
          else
            begin
               if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                 begin
                    // Valid read data is available at the read data bus
                    axi_rvalid <= 1'b1;
                    axi_rresp  <= 2'b0; // 'OKAY' response
                 end
               else if (axi_rvalid && S_AXI_RREADY)
                 begin
                    // Read data is accepted by the master
                    axi_rvalid <= 1'b0;
                 end
            end
     end

   // Implement memory mapped register select and read logic generation
   // Slave register read enable is asserted when valid address is available
   // and the slave is ready to accept the read address.
   assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

   // the order of items in the input to this one-hot mux determines the order of the
   // address map for PS reads. the default is user csrs, pl_to_ps fifos, pl_to_ps fifo counters, ps_to_pl fifo counters
   // e.g., for 4 regs, 4 ps_to_pl fifos, and 2 pl_to_ps fifos, the read memory map is essentially
   //
   // 0,4,8,C: registers
   // 10, 14: pl_to_ps fifo heads
   // 18, 1C: pl_to_ps fifo counts
   // 20,24,28,2C: ps_to_pl fifo counts

   initial
     begin: info
        $display("-------------------------------");
        $display("BSG: Zynq Shell PL Read Offsets (%m)");

        for (integer k = 0; k < num_regs_ps_to_pl_p; k++)
          $display("%3h: ps_to_pl register %2d",k << 2, k);

        for (integer k = 0; k < num_fifo_pl_to_ps_p; k++)
          $display("%3h: pl_to_ps fifo #%2d data",(num_regs_ps_to_pl_p << 2)+(k<<2),k);

        for (integer k = 0; k < num_fifo_pl_to_ps_p; k++)
          $display("%3h: pl_to_ps fifo #%2d count",((num_fifo_pl_to_ps_p+num_regs_ps_to_pl_p) << 2)+(k<<2),k);

        for (integer k = 0; k < num_fifo_ps_to_pl_p; k++)
          $display("%3h: ps_to_pl fifo #%2d count",((num_fifo_pl_to_ps_p*2+num_regs_ps_to_pl_p) << 2)+(k<<2),k);

        for (integer k = 0; k < num_regs_pl_to_ps_p; k++)
          $display("%3h: pl_to_ps register %2d"
                   ,((num_fifo_pl_to_ps_p*2+num_regs_ps_to_pl_p+num_fifo_ps_to_pl_p) << 2)+(k<<2),k);

        $display("-------------------------------");
        $display("BSG: Zynq Shell PL Write Offsets (%m)");

        for (integer k = 0; k < num_regs_ps_to_pl_p; k++)
          $display("%3h: ps_to_pl register %2d",k << 2, k);

        for (integer k = 0; k < num_fifo_ps_to_pl_p; k++)
          $display("%3h: ps_to_pl fifo #%2d data",((num_regs_ps_to_pl_p) << 2)+(k<<2),k);
     end


   bsg_mux_one_hot #(.width_p(C_S_AXI_DATA_WIDTH),.els_p(read_locs_lp)) muxoh
     (.data_i({csr_data_i, ps_to_pl_fifo_ctrs_full, pl_to_ps_fifo_ctrs_full, pl_to_ps_fifo_data_r, slv_r})
      ,.sel_one_hot_i(slv_rd_sel_one_hot)
      ,.data_o(reg_data_out)
      );

   // Output register or memory read data
   always @( posedge S_AXI_ACLK )
     begin
        if ( S_AXI_ARESETN == 1'b0 )
          begin
             axi_rdata  <= 0;
          end
          else
            begin
               // When there is a valid read address (S_AXI_ARVALID) with
               // acceptance of read address by the slave (axi_arready),
               // output the read dada
               if (slv_reg_rden)
                 begin
                    axi_rdata <= reg_data_out;     // register read data
                 end
            end
     end

endmodule
