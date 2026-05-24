// File: bp_trace_bind.sv
// Description: Binds the custom RISC-V Trace Encoder to the FOSSi BlackParrot core

bind bp_core bp_trace_encoder my_trace_encoder_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),

    // Reaching into the core to tap the commit signals
    .commit_v_i(commit_v_o),
    .commit_pc_i(commit_pc_o),
    .commit_instr_i(commit_instr_o),

    // Routing the outputs (leaving unconnected for the initial compile test)
    .trace_valid_o(),  
    .trace_packet_o()  
);
