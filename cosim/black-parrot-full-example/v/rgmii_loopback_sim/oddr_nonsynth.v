
// synopsys translate_off

module oddr_nonsynth #
(
    parameter WIDTH = 1
)
(
    input  wire             clk,

    input  wire [WIDTH-1:0] d1,
    input  wire [WIDTH-1:0] d2,

    output wire [WIDTH-1:0] q
);

  reg [WIDTH-1:0] d_reg_1;
  reg [WIDTH-1:0] d_reg_2;

  reg [WIDTH-1:0] q_reg;

  always @(posedge clk) begin
      d_reg_1 <= d1;
      d_reg_2 <= d2;
  end

  always @(posedge clk) begin
      q_reg <= d1;
  end

  always @(negedge clk) begin
      q_reg <= d_reg_2;
  end

  assign q = q_reg;

endmodule

// synopsys translate_on
