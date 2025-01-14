
#ifndef BSG_PIN_H
#define BSG_PIN_H

#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_pin.h"
#include "bsg_printing.h"

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 1000
#endif

// W = width of pin
template <unsigned int W> class pin {
    std::unique_ptr<bsg_nonsynth_dpi::dpi_gpio<W>> gpio;

  public:
    pin(const std::string &hierarchy) {
        gpio = std::make_unique<bsg_nonsynth_dpi::dpi_gpio<W>>(hierarchy);
    }

    void set(const unsigned int val) {
        unsigned int bval = 0;
        for (int i = 0; i < W; i++) {
            bval = (val & (1 << i)) >> i;
            gpio->set(i, bval);
        }
    }

    void operator=(const unsigned int val) { set(val); }

    int get() const {
        unsigned int N = 0;
        for (int i = 0; i < W; i++) {
            N |= gpio->get(i) << i;
        }

        return N;
    }

    operator int() const { return get(); }
};

#endif
