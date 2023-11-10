#ifndef __HTIF_H
#define __HTIF_H

#include "memif.h"
#include "syscall.h"
#include "device.h"
#include "byteorder.h"
#include "bsg_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"
#include "bsg_mem_dma.hpp"
#include "ps.hpp"
#include <string.h>
#include <map>
#include <vector>
#include <assert.h>

class htif_t : public chunked_memif_t
{
 public:
  htif_t(bsg_zynq_pl* zpl, bsg_mem_dma::Memory* dram);
  virtual ~htif_t();

  int step();
  bool done();
  int exit_code();
  virtual memif_t& memif() { return mem; }

  template<typename T> inline T from_target(target_endian<T> n) const
  {
    endianness_t endianness = get_target_endianness();
    assert(endianness == endianness_little || endianness == endianness_big);

    return endianness == endianness_big? n.from_be() : n.from_le();
  }

  template<typename T> inline target_endian<T> to_target(T n) const
  {
    endianness_t endianness = get_target_endianness();
    assert(endianness == endianness_little || endianness == endianness_big);

    return endianness == endianness_big? target_endian<T>::to_be(n) : target_endian<T>::to_le(n);
  }

  addr_t get_tohost_addr() { return tohost_addr; }
  addr_t get_fromhost_addr() { return fromhost_addr; }

 protected:
  virtual void read_chunk(addr_t taddr, size_t len, void* dst) override;
  virtual void write_chunk(addr_t taddr, size_t len, const void* src) override;
  virtual void clear_chunk(addr_t taddr, size_t len) override;

  virtual size_t chunk_align() override {return 8;}
  virtual size_t chunk_max_size() override {return 8;}

 private:
  void register_devices();
  memif_t mem;
  addr_t tohost_addr;
  addr_t fromhost_addr;
  bsg_zynq_pl* zpl;
  bsg_mem_dma::Memory* dram;
  int exitcode;
  bool stopped;

  device_list_t device_list;
  syscall_t syscall_proxy;
  bcd_t bcd;

  friend class memif_t;
  friend class syscall_t;
};

#endif // __HTIF_H
