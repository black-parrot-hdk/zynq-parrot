
// synopsys translate_off

module iddr_nonsynth #
(
    parameter WIDTH = 1
)
(
    input  wire             clk,

    input  wire [WIDTH-1:0] d,

    output wire [WIDTH-1:0] q1,
    output wire [WIDTH-1:0] q2
);
  reg [WIDTH-1:0] d_reg_1;
  reg [WIDTH-1:0] d_reg_2;

  reg [WIDTH-1:0] q_reg_1;
  reg [WIDTH-1:0] q_reg_2;

  always @(posedge clk) begin
      d_reg_1 <= d;
  end

  always @(negedge clk) begin
      d_reg_2 <= d;
  end

  always @(posedge clk) begin
      q_reg_1 <= d_reg_1;
      q_reg_2 <= d_reg_2;
  end

  assign q1 = q_reg_1;
  assign q2 = q_reg_2;
endmodule


// synopsys translate_on
