
#ifndef BSG_TAG_BITBANG_H
#define BSG_TAG_BITBANG_H

#include "bsg_axil.h"

class bsg_tag_bitbang {
  // the axi bus where bit banging happens
  axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> *axi;
  // tick function
  void (*tick)(void);
  // Address of the bitbang CSR
  unsigned csr_addr;

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
  bsg_tag_bitbang(axilm<GP0_ADDR_WIDTH, GP0_DATA_WIDTH> *axi, void (*tick)(void),
          unsigned csr_addr) {
    this->axi = axi;
    this->tick = tick;
    this->csr_addr = csr_addr;
  }
  // low-level bit manipulation function
  void bsg_tag_bit_write(bool bit) {
    axi->axil_write_helper(csr_addr, bit, 0xf, tick);
  }
  void bsg_tag_packet_write(unsigned els, unsigned width, bool data_not_reset,
          unsigned nodeID, unsigned payload) {
    // start
    bsg_tag_bit_write(1);
    // payload len
    for(unsigned i = 0;i < clog2(width + 1);i++)
      bsg_tag_bit_write((width >> i) & 1U);
    // data_not_reset
    bsg_tag_bit_write(data_not_reset);
    // nodeID
    for(unsigned i = 0;i < safe_clog2(els);i++)
      bsg_tag_bit_write((nodeID >> i) & 1U);
    // payload
    for(unsigned i = 0;i < width;i++)
      bsg_tag_bit_write((payload >> i) & 1U);
  }
  // Reset the bsg tag master
  // In simulation we need this to initialize zeros_ctr_r in tag master.
  void bsg_tag_reset_master() {
    bsg_tag_bit_write(1);
    // Make sure we get enough cycles for tag master to initialize itself
    for(unsigned i = 0;i < 100;i++)
      bsg_tag_bit_write(0);
  }
};

#endif
