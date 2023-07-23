#include "device.h"
#include "term.h"
#include "memif.h"
#include <cassert>
#include <algorithm>
#include <climits>
#include <iostream>
#include <thread>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
using namespace std::placeholders;

device_t::device_t()
  : command_handlers(command_t::MAX_COMMANDS),
    command_names(command_t::MAX_COMMANDS)
{
  for (size_t cmd = 0; cmd < command_t::MAX_COMMANDS; cmd++)
    register_command(cmd, std::bind(&device_t::handle_null_command, this, _1), "");
  register_command(command_t::MAX_COMMANDS-1, std::bind(&device_t::handle_identify, this, _1), "identity");
}

void device_t::register_command(size_t cmd, command_func_t handler, const char* name)
{
  assert(cmd < command_t::MAX_COMMANDS);
  assert(strlen(name) < IDENTITY_SIZE);
  command_handlers[cmd] = handler;
  command_names[cmd] = name;
}

void device_t::handle_command(command_t cmd)
{
  command_handlers[cmd.cmd()](cmd);
}

void device_t::handle_null_command(command_t)
{
}

void device_t::handle_identify(command_t cmd)
{
  size_t what = cmd.payload() % command_t::MAX_COMMANDS;
  uint64_t addr = cmd.payload() / command_t::MAX_COMMANDS;

  char id[IDENTITY_SIZE] = {0};
  if (what == command_t::MAX_COMMANDS-1)
  {
    assert(strlen(identity()) < IDENTITY_SIZE);
    strcpy(id, identity());
  }
  else
    strcpy(id, command_names[what].c_str());

  cmd.memif().write(addr, IDENTITY_SIZE, id);
  cmd.respond(1);
}

bcd_t::bcd_t()
{
  register_command(0, std::bind(&bcd_t::handle_read, this, _1), "read");
  register_command(1, std::bind(&bcd_t::handle_write, this, _1), "write");
}

void bcd_t::handle_read(command_t cmd)
{
  pending_reads.push(cmd);
}

void bcd_t::handle_write(command_t cmd)
{
  putchar(cmd.payload());
  fflush(stdout);
}

void bcd_t::tick()
{
  int ch;
  if (!pending_reads.empty() && (ch = getchar()) != EOF)
  {
    pending_reads.front().respond(0x100 | ch);
    pending_reads.pop();
  }
}

device_list_t::device_list_t()
  : devices(command_t::MAX_COMMANDS, &null_device), num_devices(0)
{
}

void device_list_t::register_device(device_t* dev)
{
  num_devices++;
  assert(num_devices < command_t::MAX_DEVICES);
  devices[num_devices-1] = dev;
}

void device_list_t::handle_command(command_t cmd)
{
  devices[cmd.device()]->handle_command(cmd);
}

void device_list_t::tick()
{
  for (size_t i = 0; i < num_devices; i++)
    devices[i]->tick();
}
