`ifndef BSG_MANYCORE_ENDPOINT_TO_FIFOS_VH
`define BSG_MANYCORE_ENDPOINT_TO_FIFOS_VH

// To ease the programming, we slices the fields in the bsg_manycore_packet_s
// struct, and cast the fields into fields that are multiples of bytes.
//
// Assumptions:
//   bsg_manycore_reg_id_width_gp <= 8
//   $bits(bsg_manycore_packet_op_e) <= 8
//   $bits(bsg_manycore_packet_op_ex_u) <= 8
//   $bits(bsg_manycore_return_packet_type_e) <= 8
//   data_width_mp % 8 == 0
//   x_cord_width_mp % 8 == 0
//   y_cord_width_mp % 8 == 0
`define declare_bsg_manycore_packet_aligned_s(fifo_width_mp,addr_width_mp,data_width_mp,x_cord_width_mp,y_cord_width_mp) \
\
  typedef struct packed { \
    logic [fifo_width_mp-8-data_width_mp-8-y_cord_width_mp-x_cord_width_mp-1:0] padding ; \
    logic [                8-1:0] pkt_type; \
    logic [    data_width_mp-1:0] data    ; \
    logic [                8-1:0] reg_id  ; \
    logic [  y_cord_width_mp-1:0] y_cord  ; \
    logic [  x_cord_width_mp-1:0] x_cord  ; \
  } bsg_manycore_return_packet_aligned_s; \
\
  typedef union packed { \
    logic [data_width_mp-1:0] data     ; \
      struct packed {                                                                    \
        logic [data_width_mp-$bits(bsg_manycore_load_info_s)-1:0] reserved;              \
        bsg_manycore_load_info_s load_info;                                              \
      } load_info_s;                                                                     \
  } bsg_manycore_packet_payload_aligned_u; \
\
  typedef struct packed { \
    logic [fifo_width_mp-addr_width_mp-2*8-data_width_mp-2*y_cord_width_mp-2*x_cord_width_mp-1:0] padding   ; \
    logic [  addr_width_mp-1:0] addr      ; \
    logic [              8-1:0] op_v2     ; \
    logic [              8-1:0] reg_id    ; \
    bsg_manycore_packet_payload_aligned_u    payload   ; \
    logic [y_cord_width_mp-1:0] src_y_cord; \
    logic [x_cord_width_mp-1:0] src_x_cord; \
    logic [y_cord_width_mp-1:0] y_cord    ; \
    logic [x_cord_width_mp-1:0] x_cord    ; \
  } bsg_manycore_packet_aligned_s

  // This is the width of the byte-aligned host fifo interface
  localparam bsg_manycore_packet_aligned_width_gp = 128;

`endif // BSG_MANYCORE_ENDPOINT_TO_FIFOS_VH

