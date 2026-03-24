module trace_capture
  #(parameter width_p = 64)
  (
    input  logic                         clk_i
  , input  logic                         reset_i

  // Simplified commit interface (to be refined)
  , input  logic                         commit_v_i
  , input  logic [31:0]                  pc_i
  , input  logic [31:0]                  instr_i
  , input  logic [31:0]                  npc_i
  , input  logic                         exception_i

  // Trace output
  , output logic                         trace_v_o
  , output logic [31:0]                  trace_pc_o
  );

  // Only capture architecturally committed instructions
  assign trace_v_o  = commit_v_i;
  assign trace_pc_o = pc_i;

  // Intended to connect to bp_be_commit_pkt_s in bp_be_top.sv
  // This is a minimal stub for future trace encoding

endmodule