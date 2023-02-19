
#ifndef BSG_TAG_BITBANG_H
#define BSG_TAG_BITBANG_H

#include "bp_zynq_pl.h"

class bsg_tag_bitbang {
  unsigned clog2(unsigned val) {
    unsigned i;
    for(i = 0;i < 32;i++) {
      if((1U << i) >= val)
        break;
    }
    return i;
  }
  unsigned safe_clog2(unsigned x) {
    return (x == 1U) ? 1U : clog2(x);
  }
public:
  bsg_tag_bitbang() {}
  // low-level bit manipulation function
  void bsg_tag_bit_write(bp_zynq_pl *zpl, unsigned csr_addr, bool bit) {
    zpl->axil_write(csr_addr, bit, 0xf);
  }
  void bsg_tag_packet_write(bp_zynq_pl *zpl, unsigned csr_addr, unsigned els, unsigned width,
        bool data_not_reset, unsigned nodeID, unsigned payload) {
    // start
    bsg_tag_bit_write(zpl, csr_addr, 1);
    // payload len
    for(unsigned i = 0;i < clog2(width + 1);i++)
      bsg_tag_bit_write(zpl, csr_addr, (width >> i) & 1U);
    // data_not_reset
    bsg_tag_bit_write(zpl, csr_addr, data_not_reset);
    // nodeID
    for(unsigned i = 0;i < safe_clog2(els);i++)
      bsg_tag_bit_write(zpl, csr_addr, (nodeID >> i) & 1U);
    // payload
    for(unsigned i = 0;i < width;i++)
      bsg_tag_bit_write(zpl, csr_addr, (payload >> i) & 1U);
    // end
    bsg_tag_bit_write(zpl, csr_addr, 0U);
    // Need some additional toggles for data to propagate through
    for(int i = 0;i < 3;i++)
      bsg_tag_bit_write(zpl, csr_addr, 0U);
  }
  // Reset the bsg tag master
  // In simulation we need this to initialize zeros_ctr_r in tag master.
  void bsg_tag_reset(bp_zynq_pl *zpl, unsigned csr_addr) {
    bsg_tag_bit_write(zpl, csr_addr, 1);
    // Make sure we get enough cycles for tag master to initialize itself
    for(unsigned i = 0;i < 100;i++)
      bsg_tag_bit_write(zpl, csr_addr, 0);
  }
};

#endif
