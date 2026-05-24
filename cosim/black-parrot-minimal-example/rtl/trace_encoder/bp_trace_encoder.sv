module bp_trace_encoder
(
  input  logic         clk_i,
  input  logic         reset_i,

  // Commit stage signals intercepting core signals
  input  logic         commit_v_i,
  input  logic [63:0]  commit_pc_i,
  input  logic [31:0]  commit_instr_i,

  // Trace output for validation
  output logic         trace_valid_o,
  output logic [79:0]  trace_packet_o
);

  // --- Internal Registers for Tracking ---
  logic [63:0] prev_pc_r;
  logic        branch_active;

  // Track the PC on positive clock edge when reset is inactive
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      prev_pc_r <= '0;
    end else if (commit_v_i) begin
      prev_pc_r <= commit_pc_i;
    end
  end

  // Basic Non-Linear Filter 
  // Matching the RISC-V B-Type opcode directly from instruction bits
  assign branch_active = commit_v_i & (commit_instr_i[6:0] == 7'b1100011); 

  // Output formatting stub
  always_comb begin
    trace_valid_o = branch_active;
    trace_packet_o = '0; 
    
    // Simple packet implementation indicating branch delta
    if (branch_active) begin
       trace_packet_o = {16'hBEEF, commit_pc_i - prev_pc_r}; // Header + PC Delta
    end
  end

endmodule
