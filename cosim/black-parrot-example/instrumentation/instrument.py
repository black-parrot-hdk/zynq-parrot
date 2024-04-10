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
print(args)

def macro_head(i):
  return f"\
  (* keep_hierarchy = \"false\" *) \n\
  bsg_cover \n\
    #(.idx_p           ({i}) \n\
     ,.width_p         ({args.groupsize}) \n\
     ,.els_p           (1) \n\
     ,.lg_afifo_size_p (3)) \n\
   cover_{i} \n\
    (.core_clk_i       (bp_clk) \n\
    ,.core_reset_i     (bp_reset_li) \n\
    ,.ds_clk_i         (ds_clk) \n\
    ,.ds_reset_i       (ds_reset_li) \n\
    ,.axi_clk_i        (aclk) \n\
    ,.axi_reset_i      (bp_async_reset_li) \n\
    ,.v_i              (cov_v_li) \n\
    ,.data_i           ("

def macro_tail(i):
  return f") \n\
    ,.ready_o          () \n\
    ,.drain_i          (cov_drain_li) \n\
    ,.gate_o           (cov_gate_lo[{i}]) \n\
    ,.ready_i          (cov_ready_li[{i}]) \n\
    ,.v_o              (cov_v_lo[{i}]) \n\
    ,.idx_v_o          (cov_idx_v_lo[{i}]) \n\
    ,.data_o           (cov_data_lo[{i}]) \n\
    );\n\n"

file = open(args.sigfile, 'r')
lines = file.readlines()
file.close()
from math import ceil
with open(args.output, 'w') as f:
  for group_id in range(int(len(lines)/args.groupsize)):
    f.write(macro_head(group_id))
    f.write('{\n')
    ch = ' '
    for k in range(group_id * args.groupsize, min(len(lines), (group_id+1) * args.groupsize)):
      f.write(f'\t\t\t\t{ch}' + lines[k])
      ch = ','
    f.write('\t\t\t\t}')
    f.write(macro_tail(group_id))
  f.close()
