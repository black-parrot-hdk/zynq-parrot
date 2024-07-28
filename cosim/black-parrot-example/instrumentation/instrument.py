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

def get_depths(lines):
  return [int(line.rstrip('\n').split(',')[-1]) for line in lines]

def sort_lines(lines):
  line_tuples = [(line.rstrip('\n'), int(line.rstrip('\n').split(',')[-1])) for line in lines]
  sorted_lines = sorted(line_tuples, key=lambda x: x[1])
  sorted_lines = [line[0] for line in sorted_lines]
  return sorted_lines

def create_arrays(sorted_numbers):
  index_dict = {}
  for index, number in enumerate(sorted_numbers):
    if number not in index_dict:
      index_dict[number] = index
  # convert the dictionary to a list of lists
  result = [[number, index_dict[number]] for number in index_dict]
  return result

def cov_head(i, l, depths, offsets):
  return f"\
  wire [{l}-1:0] cov_{i}_lo; \n\
  bsg_cover_realign \n\
    #(.num_p              ({args.groupsize}) \n\
     ,.num_chain_p        ({l}) \n\
     ,.chain_offset_arr_p ({ostr}) \n\
     ,.chain_depth_arr_p  ({dstr}) \n\
     ,.step_p             (8) \n\
   realign_{i}\n\
    (.clk_i            (bp_clk) \n\
    ,.data_i           ({{\n"

def cov_tail(i, l):
  return f"\
      }}) \n\
    ,.data_o           (cov_{i}_lo) \n\
    );\n\n\
  (* keep_hierarchy = \"false\" *) \n\
  bsg_cover \n\
    #(.id_p            ({i}) \n\
     ,.width_p         ({l}) \n\
     ,.els_p           (16) \n\
     ,.out_width_p     (C_M02_AXI_DATA_WIDTH) \n\
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
files = file.readlines()
file.close()

import os 
dir_path = os.path.dirname(os.path.realpath(__file__))

lines=[]
for f in files:
  fname = dir_path + '/../' + f
  file = open(fname[:-1], 'r')
  lines.append(file.readlines())
  file.close()

# sort lines according to depth
#sorted_lines = sort_lines(lines)
#lines = sorted_lines

#print(lines)

from math import ceil
with open(args.output, 'w') as f:
  for gid in range(len(lines)):
    gsize = len(lines[gid])
    print('group size = ', gsize, gid)
    # collect the lines
    unsorted_group_lines = lines[gid]
    group_lines = sort_lines(unsorted_group_lines)
    indices = create_arrays(get_depths(group_lines))
    #print(indices)
    offsets = [col[1] for col in indices]
    depths = [col[0] for col in indices]

    l = len(offsets)
    ostr = "'{"
    for i in offsets:
      ostr += str(i) + ", "
    ostr = ostr[:-2] + "}"
    print('offset str', ostr)

    dstr = "'{"
    for i in depths:
      dstr += str(i) + ", "
    dstr = dstr[:-2] + "}"
    print('depth str', dstr)

    # bsg_cover
    f.write(cov_head(gid, l, ostr, dstr))
    comma = ' '
    for k in range(gsize):
      cpos = group_lines[k].rfind(',')
      f.write(f'\t\t\t\t{comma}' + group_lines[k][0:cpos] + "\n")
      comma = ','
    f.write(cov_tail(gid, l))

  f.close()
