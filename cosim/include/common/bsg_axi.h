
#ifndef BSG_AXI_H
#define BSG_AXI_H

template <unsigned int A, unsigned int D> class axi_defaults {
  protected:
    // abstract class
    axi_defaults() = default;

    static_assert(A == 0 || A < 64, "< 64b address width supported");
    static_assert(D == 0 || D == 32 || D == 64, "32/64b data width supported");

    using addr_t = uintptr_t;
    using data_t = typename std::conditional<(D == 64), int64_t, int32_t>::type;
};

#endif

