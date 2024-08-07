
#ifndef BSG_PIN_H
#define BSG_PIN_H

#include "bsg_nonsynth_dpi_gpio.hpp"
#include "bsg_printing.h"
#include "bsg_pin.h"

#ifndef ZYNQ_AXI_TIMEOUT
#define ZYNQ_AXI_TIMEOUT 1000
#endif

extern "C" { int bsg_dpi_time(); }
using namespace std;
using namespace bsg_nonsynth_dpi;
using namespace boost::coroutines2;
using namespace std::placeholders;

// W = width of pin
template <unsigned int W>
class pin {
    std::unique_ptr<dpi_gpio<W>> gpio;

public:
    pin(const string &hierarchy) {
        gpio = std::make_unique<dpi_gpio<W>>(hierarchy);
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

