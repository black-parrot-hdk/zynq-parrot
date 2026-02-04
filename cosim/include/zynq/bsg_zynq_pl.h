
#ifndef BSG_ZYNQ_PL_H
#define BSG_ZYNQ_PL_H

#if !defined(__arm__) && !defined(__aarch64__)
#error this file intended only to be compiled on an ARM (Zynq) platform
#endif

// This is an implementation of the standardized host bsg_zynq_pl API
// that runs on the real Zynq chip.
//

#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "zynq_headers.h"
#include <assert.h>
#include <cstdint>
#include <errno.h>
#include <fcntl.h>
#include <fstream>
#include <inttypes.h>
#include <iostream>
#include <map>
#include <memory>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <pybind11/embed.h>
#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>
namespace py = pybind11;

#include "bsg_zynq_pl_hardware.h"

#define BITSTREAM_STRING STRINGIFY(BITSTREAM_FILE)

class bsg_zynq_pl : public bsg_zynq_pl_hardware {
  private:
    void *_dram_map_storage;
    using DramMap = std::map<void *, py::object>;
    DramMap *get_dram_map() {
        return static_cast<DramMap *>(_dram_map_storage);
    }

    bool load_bitstream(const char *bitstream) {
        py::module_ pynq = py::module_::import("pynq");
        py::object overlay = pynq.attr("Overlay")(bitstream);

        return true;
    }

  public:
    bsg_zynq_pl(int argc, char *argv[]) {
        static py::scoped_interpreter guard{};
        printf("// bsg_zynq_pl: be sure to run as root\n");

        load_bitstream(BITSTREAM_STRING);
        _dram_map_storage = new DramMap();

        init();
    }

    ~bsg_zynq_pl(void) {
        py::gil_scoped_acquire acquire;
        deinit();
        // can I delete _dram_map_storage directly?
        DramMap *dram_map = get_dram_map();
        delete dram_map;
    }

    void tick(void) override { /* Does nothing on PS */ }

    void start(void) override { printf("bsg_zynq_pl: start() called\n"); }

    void stop(void) override { printf("bsg_zynq_pl: stop() called\n"); }

    int done(void) override {
        printf("bsg_zynq_pl: done() called, exiting\n");
        return (status > 0);
    }

    // returns virtual pointer, writes physical parameter into arguments
    void *allocate_dram(unsigned long len_in_bytes,
                        unsigned long *physical_ptr) override {
        py::gil_scoped_acquire acquire;

        // for now, we do uncacheable to keep things simple, memory accesses go
        // straight to DRAM and
        // thus would be coherent with the PL
        py::module_ pynq = py::module_::import("pynq");
        py::object buffer = pynq.attr("allocate")(
            py::arg("shape") = py::make_tuple(len_in_bytes),
            py::arg("dtype") = "u1");

        *physical_ptr = buffer.attr("physical_address").cast<unsigned long>();

        auto array = buffer.cast<py::array_t<uint8_t>>();
        py::buffer_info info = array.request();
        void *virtual_ptr = info.ptr;

        DramMap *dram_map = get_dram_map();
        (*dram_map)[virtual_ptr] = buffer;

        return virtual_ptr;
    }

    void free_dram(void *virtual_ptr) override {
        py::gil_scoped_acquire acquire;

        DramMap *dram_map = get_dram_map();
        auto it = dram_map->find(virtual_ptr);
        if (it != dram_map->end()) {
            printf("bsg_zynq_pl: free_dram() called on virtual ptr=%p\n",
                   virtual_ptr);
            dram_map->erase(it);
        } else {
            printf("bsg_zynq_pl: free_dram() called on unknown ptr=%p\n",
                   virtual_ptr);
        }
    }

    int32_t shell_read(uintptr_t addr) override { return axil_read(addr); }

    void shell_write(uintptr_t addr, int32_t data, uint8_t wmask) override {
        axil_write(addr, data, wmask);
    }

#ifdef NEON
    // typedef uint32_t uint32x4_t[4];
    void shell_write4(uintptr_t addr, int32_t data0, int32_t data1,
                      int32_t data2, int32_t data3) override {
        volatile uint32x4_t *ptr = (volatile uint32x4_t *)addr;
        int32_t sarray[4] = {data0, data1, data2, data3};
        uint32_t *array{reinterpret_cast<uint32_t *>(sarray)};
        uint32x4_t val = vld1q_u32(array);

        *ptr = val;
    }

    void shell_read4(uintptr_t addr, int32_t *data0, int32_t *data1,
                     int32_t *data2, int32_t *data3) override {
        volatile uint32x4_t *ptr = (volatile uint32x4_t *)addr;
        uint32x4_t val = *ptr;

        *data0 = val[0];
        *data1 = val[1];
        *data2 = val[2];
        *data3 = val[3];
    }
#endif
};

#endif
