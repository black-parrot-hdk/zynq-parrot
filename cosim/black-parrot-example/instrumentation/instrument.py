import argparse
parser = argparse.ArgumentParser()
parser.add_argument("-s", "--sigfile", type=str, help = "Path to file containing control signals", required=True)
parser.add_argument("-n", "--numgroups", type=int, help = "number of groups")
parser.add_argument("-g", "--groupsize", type=int, help = "number of signals in a group")
parser.add_argument("-t", "--toggleonly", type=int, help = "toggle-coverage only (1 or 0)", default=0)
parser.add_argument("-o", "--output", type=str, help = "output macro file name", required=True, default='/dev/null')
args = parser.parse_args()
print(args)
group_size=int(args.groupsize)
cov_map_w =32
num_groups=int(args.numgroups)/group_size
toggle_only=int(args.toggleonly)

boilerplate_pre = "\
  localparam num_cov_group_lp = %d;                                                   \n\
  localparam cov_mux_sel_width_lp = `BSG_SAFE_CLOG2(num_cov_group_lp);                \n\
  localparam n_sigs_per_grp_lp = %d;                                                  \n\
  localparam cov_map_width_lp  = %d;                                                  \n\
  localparam cov_mask_width_lp = $clog2(cov_map_width_lp);                            \n\
  localparam toggle_cov_only_p = %d;                                                  \n\
  localparam cov_addr_width_lp = toggle_cov_only_p                                    \n\
                                  ? 1 : n_sigs_per_grp_lp - cov_mask_width_lp;        \n\
                                                                                      \n\
  logic [num_cov_group_lp-1:0][cov_map_width_lp-1:0] cov_lo;                          \n\
  logic [num_cov_group_lp-1:0] cov_v_lo;                                              \n\
                                                                                      \n\
  logic [cov_map_width_lp-1:0] cov_muxed_lo;                                          \n\
  reg   cov_v_r;                                                                      \n\
  logic cov_full_li;                                                                  \n\
                                                                                      \n\
  logic [cov_mux_sel_width_lp-1:0] cov_sel_crossed_li;                                \n\
  reg [cov_mux_sel_width_lp-1:0] gid_r;                                               \n\
  reg [cov_addr_width_lp-1:0] sid_r;                                                  \n\
  wire [cov_addr_width_lp-1:0] sid_max_r = toggle_cov_only_p ? '0 : '1;               \n\
  assign sdone = ~cov_full_li;                                                        \n\
  assign gdone = (sid_r == sid_max_r) & sdone;                                        \n\
                                                                                      \n\
  always @(posedge gated_aclk)                                                        \n\
    if(gated_bp_reset_li)                                                             \n\
      begin                                                                           \n\
      gid_r <= '0;                                                                    \n\
      sid_r <= '0;                                                                    \n\
      cov_v_r <= '0;                                                                  \n\
      end                                                                             \n\
    else if(cov_sel_crossed_li != '0)                                                 \n\
      begin                                                                           \n\
      gid_r <= gdone ? gid_r + 1'b1 : gid_r;                                          \n\
      sid_r <= sdone                                                                  \n\
                ? (~gdone ? (sid_r + 1'b1) : '0)                                      \n\
                : sid_r;                                                              \n\
      cov_v_r <= 1'b1;                                                                \n\
      end                                                                             \n\
                                                                                      \n\
  " %(num_groups, group_size, cov_map_w, toggle_only)

macro_head = "\
  (* keep_hierarchy = \"false\" *) coverage #(.width_p(n_sigs_per_grp_lp)             \n\
             ,.toggle_cov_only_p(%d))                                                 \n\
    c%d                                                                               \n\
    (.clk_i(gated_aclk)                                                               \n\
     ,.reset_i(gated_bp_reset_li)                                                     \n\
     ,.master_reset_i(~gated_aresetn)                                                 \n\
     ,.i({"

macro_tail = "\
      })                                                                              \n\
     ,.req_i((gid_r == cov_mux_sel_width_lp'('d%d)) & (cov_sel_crossed_li != '0))     \n\
     ,.cov_o(cov_lo[%d])                                                              \n\
     ,.id_i(sid_r)                                                                    \n\
     );\n"

boilerplate_post = "\
  bsg_mux                                                                             \n\
    #(.width_p(cov_map_width_lp)                                                      \n\
     ,.els_p(num_cov_group_lp)                                                        \n\
     )                                                                                \n\
    cov_mux                                                                           \n\
    (.data_i(cov_lo)                                                                  \n\
    ,.sel_i(gid_r-1'b1)                                                               \n\
    ,.data_o(cov_muxed_lo)                                                            \n\
    );                                                                                \n\
                                                                                      \n\
  bsg_sync_sync #(.width_p(cov_mux_sel_width_lp))                                     \n\
    cov_cross                                                                         \n\
    (.oclk_i(gated_aclk)                                                              \n\
    ,.iclk_data_i(cov_sel_li)                                                         \n\
    ,.oclk_data_o(cov_sel_crossed_li)                                                 \n\
    );                                                                                \n\
                                                                                      \n\
  bsg_async_fifo                                                                      \n\
  #(.width_p(cov_map_width_lp), .lg_size_p(2))                                        \n\
   cov_async                                                                          \n\
    ( .w_clk_i(gated_aclk)                                                            \n\
     ,.w_reset_i(~gated_aresetn)                                                      \n\
     ,.w_enq_i(cov_v_r & ~cov_full_li)                                                \n\
     ,.w_data_i(cov_muxed_lo)                                                         \n\
     ,.w_full_o(cov_full_li)                                                          \n\
                                                                                      \n\
     ,.r_clk_i(aclk)                                                                  \n\
     ,.r_reset_i(~aresetn)                                                            \n\
     ,.r_deq_i(cov_map_ready_li & cov_map_v_lo & ~(cov_sel_li == '0))                 \n\
     ,.r_data_o(cov_map_lo)                                                           \n\
     ,.r_valid_o(cov_map_v_lo)                                                        \n\
     );"

file = open(args.sigfile, 'r')
lines = file.readlines()
file.close()

with open(args.output, 'w') as f:
  f.write(boilerplate_pre)
  for group_id in range(len(lines)/group_size):
    sig_id = group_id * group_size
    f.write(macro_head % (toggle_only, group_id+1))
    f.write('         ' + lines[sig_id])
    for k in range(sig_id+1,sig_id+group_size):
      f.write('        ,' + lines[k])
    f.write(macro_tail %(group_id+1, group_id))
  f.write(boilerplate_post)
  f.close()
