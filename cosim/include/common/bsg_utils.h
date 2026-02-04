#ifndef BSG_UTILS_H
#define BSG_UTILS_H

uint64_t get_counter_64(bsg_zynq_pl *zpl, uint64_t addr) {
    uint64_t val;
    do {
        uint64_t val_hi = zpl->shell_read(addr + 4);
        uint64_t val_lo = zpl->shell_read(addr + 0);
        uint64_t val_hi2 = zpl->shell_read(addr + 4);
        if (val_hi == val_hi2) {
            val = val_hi << 32;
            val += val_lo;
            return val;
        } else
            bsg_pr_err("ps.cpp: timer wrapover!\n");
    } while (1);
}

uint32_t rotl(uint32_t v, int32_t shift) {
    int32_t s = shift >= 0 ? shift % 32 : -((-shift) % 32);
    return (v << s) | (v >> (32 - s));
}

#endif
