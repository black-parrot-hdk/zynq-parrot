// See LICENSE for license details.

#include "config.h"
#include "htif.h"
//#include "rfb.h"
//#include "elfloader.h"
//#include "platform.h"
#include "byteorder.h"
//#include "trap.h"
//#include "../riscv/common.h"
#include <algorithm>
#include <assert.h>
#include <vector>
#include <queue>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>

htif_t::htif_t(bsg_zynq_pl* zpl)
  : mem(this), zpl(zpl),
    tohost_addr(0x10010), fromhost_addr(0x10020), exitcode(0), stopped(false),
    syscall_proxy(this)
{
  register_devices();
}

htif_t::~htif_t()
{
}

static void bad_address(const std::string& situation, reg_t addr)
{
  std::cerr << "Access exception occurred while " << situation << ":\n";
  std::cerr << "Memory address 0x" << std::hex << addr << " is invalid\n";
  exit(-1);
}

void htif_t::clear_chunk(addr_t taddr, size_t len)
{
  char zeros[chunk_max_size()];
  memset(zeros, 0, chunk_max_size());

  for (size_t pos = 0; pos < len; pos += chunk_max_size())
    write_chunk(taddr + pos, std::min(len - pos, chunk_max_size()), zeros);
}

void htif_t::read_chunk(addr_t taddr, size_t len, void* dst)
{
  uint64_t addr;
  if (taddr >= DRAM_BASE_ADDR)
    addr = GP1_ADDR_BASE - DRAM_BASE_ADDR + taddr;
  else
    addr = GP1_CSR_BASE_ADDR + taddr;

  uint64_t data = zpl->axil_read(addr) & 0xFFFFFFFF;
  if(len == 8) {
    uint64_t datah = zpl->axil_read(addr + 4) & 0xFFFFFFFF;
    data = data | (datah << 32);
  }

  memcpy(dst, (char*)&data, len);
}

void htif_t::write_chunk(addr_t taddr, size_t len, const void* src)
{
  if(len != 8) {
    printf("Invalid write_chunk len: %d\n", len);
    return;
  }

  uint64_t addr;
  if (taddr >= DRAM_BASE_ADDR)
    addr = GP1_ADDR_BASE - DRAM_BASE_ADDR + taddr;
  else
    addr = GP1_CSR_BASE_ADDR + taddr;

  uint64_t data = *(uint64_t*)(src);
  zpl->axil_write(addr, data, 0xf);
  zpl->axil_write(addr + 4, (data >> 32), 0xf);
}

int htif_t::step()
{
  auto enq_func = [](std::queue<reg_t>* q, uint64_t x) { q->push(x); };
  std::queue<reg_t> fromhost_queue;
  std::function<void(reg_t)> fromhost_callback =
    std::bind(enq_func, &fromhost_queue, std::placeholders::_1);

  uint64_t tohost;

  if ((tohost = from_target(mem.read_uint64(tohost_addr))) != 0)
    mem.write_uint64(tohost_addr, target_endian<uint64_t>::zero);

  if (tohost != 0) {
    //printf("tohost: %lx\n", tohost);
    command_t cmd(mem, tohost, fromhost_callback);
    device_list.handle_command(cmd);
  }
  device_list.tick();

  if (!fromhost_queue.empty() && !mem.read_uint64(fromhost_addr)) {
    mem.write_uint64(fromhost_addr, to_target(fromhost_queue.front()));
    fromhost_queue.pop();
  }
  return exitcode; 
}

bool htif_t::done()
{
  return stopped;
}

int htif_t::exit_code()
{
  return exitcode >> 1;
}

void htif_t::register_devices()
{
  device_list.register_device(&syscall_proxy);
  device_list.register_device(&bcd);
}
