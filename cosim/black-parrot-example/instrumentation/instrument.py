import argparse
parser = argparse.ArgumentParser()
parser.add_argument("-s", "--sigfile",\
                      type=str,\
                        help="Path to file containing control signals",\
                          required=True)
parser.add_argument("-o", "--output",\
                      type=str,\
                        help="output macro file name",\
                          required=True)
parser.add_argument("-n", "--numgroups",\
                      type=int,\
                        help="number of groups")
parser.add_argument("-g", "--groupsize",\
                      type=int,\
                        help="number of signals in a group",\
                          required=True,
                            default=32)
args = parser.parse_args()
#print(args)

def cov_head(i):
  return f"\
  bsg_cover_realign \n\
    #(.num_p              ({args.groupsize}) \n\
     ,.num_chain_p        () \n\
     ,.chain_offset_arr_p () \n\
     ,.chain_depth_arr_p  () \n\
     ,.step_p             () \n\
   realign_{i}\n\
    (.clk_i            (bp_clk) \n\
    ,.data_i           ({{"

def cov_tail(i):
  return f"\
      }}) \n\
    ,.data_o           (cov_{i}_lo) \n\
    );\n\n\
  (* keep_hierarchy = \"false\" *) \n\
  bsg_cover \n\
    #(.id_p            ({i}) \n\
     ,.width_p         ({args.groupsize}) \n\
     ,.els_p           (16) \n\
     ,.out_width_p     () \n\
     ,.id_width_p      (8) \n\
     ,.els_width_p     (8) \n\
     ,.len_width_p     (8) \n\
     ,.lg_afifo_size_p (3) \n\
     ,.debug_p(0)) \n\
   cover_{i}\n\
    (.core_clk_i       (bp_clk) \n\
    ,.core_reset_i     (bp_reset_li) \n\
    ,.ds_clk_i         (ds_clk) \n\
    ,.ds_reset_i       (ds_reset_li) \n\
    ,.axi_clk_i        (aclk) \n\
    ,.axi_reset_i      (bp_async_reset_li) \n\
    ,.v_i              (cov_v_li) \n\
    ,.data_i           (cov_{i}_lo) \n\
    ,.ready_o          () \n\
    ,.drain_i          (cov_drain_li) \n\
    ,.gate_o           (cov_gate_lo[{i}]) \n\
    ,.idx_v_o          () \n\
    ,.idx_o            () \n\
    ,.els_o            () \n\
    ,.len_o            () \n\
    ,.ready_i          (cov_ready_li[{i}]) \n\
    ,.v_o              (cov_v_lo[{i}]) \n\
    ,.data_o           (cov_data_lo[{i}]) \n\
    );\n\n"

file = open(args.sigfile, 'r')
lines = file.readlines()
file.close()

from math import ceil
with open(args.output, 'w') as f:
  for group_id in range(ceil(len(lines)/args.groupsize)):
    # realigner
    

    # bsg_cover
    f.write(cov_head(group_id))
    comma = ' '
    for k in range(group_id * args.groupsize, min(len(lines), (group_id+1) * args.groupsize)):
      f.write(f'\t\t\t\t{comma}' + lines[k])
      comma = ','
    f.write(cov_tail(group_id))

  f.close()

print('Number of covergroups:', int(len(lines)/args.groupsize))
