
#ifndef BSG_ZYNQ_PL_BASE_H
#define BSG_ZYNQ_PL_BASE_H

#include "bsg_printing.h"
#include "zynq_headers.h"

#include <vector>

// Copy this to C++14 so we don't have to upgrade
// https://stackoverflow.com/questions/3424962/where-is-erase-if
// for std::vector
namespace std {
template <class T, class A, class Predicate>
void erase_if(vector<T, A> &c, Predicate pred) {
    c.erase(remove_if(c.begin(), c.end(), pred), c.end());
}
} // namespace std

class bsg_zynq_pl_base {
  protected:
    int status = 0;

  public:
    int done(void) {
        bsg_pr_info("  bsg_zynq_pl: done() called, exiting\n");
        return status;
    }

  public:
    virtual int32_t shell_read(uintptr_t addr) = 0;
    virtual void shell_write(uintptr_t addr, int32_t data, uint8_t wstrb) = 0;
    virtual void tick(void) = 0;

    virtual uint64_t shell_read64b(uintptr_t addr) {
        uint64_t val;
        do {
            uint64_t val_hi = shell_read(addr + 4);
            uint64_t val_lo = shell_read(addr + 0);
            uint64_t val_hi2 = shell_read(addr + 4);
            if (val_hi == val_hi2) {
                val = val_hi << 32;
                val += val_lo;
                return val;
            } else {
                bsg_pr_err("ps.cpp: timer wrapover!\n");
			}
        } while (1);
    }
  
    virtual void shell_read4(uintptr_t addr, int32_t *data0, int32_t *data1,
                     int32_t *data2, int32_t *data3) {
        *data0 = shell_read(addr + 0);
        *data1 = shell_read(addr + 4);
        *data2 = shell_read(addr + 8);
        *data3 = shell_read(addr + 12);
    }
  
    virtual void shell_write4(uintptr_t addr, int32_t data0, int32_t data1,
                      int32_t data2, int32_t data3) {
        shell_write(addr + 0, data0, 0xf);
        shell_write(addr + 4, data1, 0xf);
        shell_write(addr + 8, data2, 0xf);
        shell_write(addr + 12, data3, 0xf);
    }
};

#endif

