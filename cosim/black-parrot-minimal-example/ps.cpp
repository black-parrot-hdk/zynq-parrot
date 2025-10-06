//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <bitset>
#include <locale.h>
#include <pthread.h>
#include <queue>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>

#include "ps.hpp"

#include "bp_bedrock_packet.h"
#include "bsg_argparse.h"
#include "bsg_printing.h"
#include "bsg_zynq_pl.h"

#ifndef FREE_DRAM
#define FREE_DRAM 0
#endif

#ifndef ZERO_DRAM
#define ZERO_DRAM 0
#endif

#ifndef DRAM_ALLOCATE_SIZE_MB
#define DRAM_ALLOCATE_SIZE_MB 128
#endif
#define DRAM_ALLOCATE_SIZE (DRAM_ALLOCATE_SIZE_MB * 1024 * 1024)

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef BP_NCPUS
#define BP_NCPUS 1
#endif

// Helper functions
void nbf_load(bsg_zynq_pl *zpl, char *filename);
bool decode_bp_output(bsg_zynq_pl *zpl);

// Globals
std::queue<int> getchar_queue;
std::bitset<BP_NCPUS> done_vec;

inline void send_bp_fwd_packet(bsg_zynq_pl *zpl, bp_bedrock_packet *packet) {
    int axil_len = sizeof(bp_bedrock_packet) / 4;

    uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
    for (int i = 0; i < axil_len; i++) {
        while (!zpl->shell_read(GP0_RD_PS2PL_FIFO_CTRS))
            ;
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA, pkt_data[i], 0xf);
    }
}

inline void recv_bp_rev_packet(bsg_zynq_pl *zpl, bp_bedrock_packet *packet) {
    int axil_len = sizeof(bp_bedrock_packet) / 4;

    uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
    for (int i = 0; i < axil_len; i++) {
        while (!zpl->shell_read(GP0_RD_PL2PS_FIFO_CTRS))
            ;
        pkt_data[i] = zpl->shell_read(GP0_RD_PL2PS_FIFO_DATA);
    }
}

inline void recv_bp_fwd_packet(bsg_zynq_pl *zpl, bp_bedrock_packet *packet) {
    int axil_len = sizeof(bp_bedrock_packet) / 4;

    uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
    for (int i = 0; i < axil_len; i++) {
        while (!zpl->shell_read(GP0_RD_PL2PS_FIFO_CTRS + 4))
            ;
        pkt_data[i] = zpl->shell_read(GP0_RD_PL2PS_FIFO_DATA + 4);
    }
}

inline void send_bp_rev_packet(bsg_zynq_pl *zpl, bp_bedrock_packet *packet) {
    int axil_len = sizeof(bp_bedrock_packet) / 4;

    uint32_t *pkt_data = reinterpret_cast<uint32_t *>(packet);
    for (int i = 0; i < axil_len; i++) {
        while (!zpl->shell_read(GP0_RD_PS2PL_FIFO_CTRS + 4))
            ;
        zpl->shell_write(GP0_WR_PS2PL_FIFO_DATA + 4, pkt_data[i], 0xf);
    }
}
int j = 0;
inline void send_bp_write(bsg_zynq_pl *zpl, uint64_t addr, int64_t data,
                          uint8_t wmask) {
    bp_bedrock_packet fwd_packet;
    bp_bedrock_mem_payload payload;

    payload.did = 0xfff;

    fwd_packet.msg_type = BEDROCK_MEM_WR;
    fwd_packet.subop = BEDROCK_STORE;
    fwd_packet.addr0 = (addr >> 0) & 0xffffffff;
    fwd_packet.addr1 = (addr >> 32) & 0xffffffff;
    fwd_packet.size = (wmask == 0xff) ? 3 : 2; // Only support 32/64 currently
    fwd_packet.payload = payload;
    fwd_packet.data0 = (data >> 0) & 0xffffffff;
    fwd_packet.data1 = (data >> 32) & 0xffffffff;

    send_bp_fwd_packet(zpl, &fwd_packet);
}

inline int64_t send_bp_read(bsg_zynq_pl *zpl, uint64_t addr) {
    bp_bedrock_packet fwd_packet;
    bp_bedrock_mem_payload payload;

    payload.did = 0xfff;

    fwd_packet.msg_type = BEDROCK_MEM_RD;
    fwd_packet.subop = BEDROCK_STORE;
    fwd_packet.addr0 = (addr >> 0) & 0xffffffff;
    fwd_packet.addr1 = (addr >> 32) & 0xffffffff;
    fwd_packet.size = 3; // Only support 64b currently
    fwd_packet.payload = payload;

    send_bp_fwd_packet(zpl, &fwd_packet);

    bp_bedrock_packet rev_packet;
    recv_bp_rev_packet(zpl, &rev_packet);

    int64_t return_data = 0;
    return_data |= (rev_packet.data0 << 0);
    return_data |= (rev_packet.data0 << 32);

    return return_data;
}

void *monitor(void *vargp) {
    char c;
    while (1) {
        c = getchar();
        if (c != -1)
            getchar_queue.push(c);
    }
    bsg_pr_info("Exiting from pthread\n");

    return NULL;
}

inline uint64_t get_counter_64(bsg_zynq_pl *zpl, uint64_t addr,
                               bool bp_not_shell) {
    uint64_t val, val_hi, val_lo, val_hi2;
    if (bp_not_shell) {
        return (uint64_t)send_bp_read(zpl, addr + 4);
    }

    do {
        val_hi = zpl->shell_read(addr + 4);
        val_lo = zpl->shell_read(addr + 0);
        val_hi2 = zpl->shell_read(addr + 4);
        if (val_hi == val_hi2) {
            val = val_hi << 32;
            val += val_lo;
            return val;
        } else {
            bsg_pr_err("ps.cpp: timer wrapover!\n");
        }
    } while (1);
}

int ps_main(int argc, char **argv) {

    bsg_zynq_pl *zpl = new bsg_zynq_pl(argc, argv);

    long data;
    long val1 = 0x1;
    long val2 = 0x0;
    long mask1 = 0xf;
    long mask2 = 0xf;

    pthread_t thread_id;
    long allocated_dram = DRAM_ALLOCATE_SIZE;

    int32_t val;
    bsg_pr_info("ps.cpp: reading three base registers\n");
    bsg_pr_info("ps.cpp: reset(lo)=%d, dram_init=%d, dram_base=%d\n",
                zpl->shell_read(GP0_RD_CSR_SYS_RESETN),
                zpl->shell_read(GP0_RD_CSR_DRAM_INITED),
                val = zpl->shell_read(GP0_RD_CSR_DRAM_BASE));

    bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

    zpl->shell_write(GP0_WR_CSR_DRAM_BASE, 0xDEADBEEF, mask1);
    assert((zpl->shell_read(GP0_RD_CSR_DRAM_BASE) == (0xDEADBEEF)));
    zpl->shell_write(GP0_WR_CSR_DRAM_BASE, val, mask1);
    assert((zpl->shell_read(GP0_RD_CSR_DRAM_BASE) == (val)));

    bsg_pr_info(
        "ps.cpp: successfully wrote and read registers in bsg_zynq_shell "
        "(verified ARM GP0 connection)\n");

    // Freeze processor
    zpl->shell_write(GP0_WR_CSR_FREEZEN, 0x1, 0xF);

    // Deassert the active-low system reset as we finish initializing the whole
    // system
    zpl->shell_write(GP0_RD_CSR_SYS_RESETN, 0x1, 0xF);

    // Put processor into debug mode
    zpl->shell_write(GP0_WR_CSR_DEBUG_IRQ, 0x1, 0xF);
    for (int i = 0; i < 10; i++)
        zpl->tick();
    zpl->shell_write(GP0_WR_CSR_DEBUG_IRQ, 0x0, 0xF);

    unsigned long phys_ptr;
    volatile int32_t *buf;
    data = zpl->shell_read(GP0_RD_CSR_DRAM_INITED);
    if (data == 0) {
        bsg_pr_info(
            "ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate "
            "dram with size %ld\n",
            allocated_dram);
        buf = (volatile int32_t *)zpl->allocate_dram(allocated_dram, &phys_ptr);
        bsg_pr_info("ps.cpp: received %p (phys = %lx)\n", buf, phys_ptr);
        zpl->shell_write(GP0_WR_CSR_DRAM_BASE, phys_ptr, mask1);
        assert((zpl->shell_read(GP0_RD_CSR_DRAM_BASE) == (int32_t)(phys_ptr)));
        bsg_pr_info("ps.cpp: wrote and verified base register\n");
        zpl->shell_write(GP0_RD_CSR_DRAM_INITED, 1, mask1);
        assert(zpl->shell_read(GP0_RD_CSR_DRAM_INITED) == 1);
    } else
        bsg_pr_info("ps.cpp: reusing dram base pointer %x\n",
                    zpl->shell_read(GP0_RD_CSR_DRAM_BASE));

    int outer = 1024 / 4;

    if (argc == 1) {
        bsg_pr_warn(
            "No nbf file specified, sleeping for 2^31 seconds (this will hold "
            "onto allocated DRAM)\n");
        sleep(1U << 31);
        delete zpl;
        return -1;
    }

#ifdef ZYNQ
    // Must zero DRAM for FPGA Linux boot, because opensbi payload mode
    //   obliterates the section names of the payload (Linux)
    if (ZERO_DRAM) {
        bsg_pr_info("ps.cpp: Zero-ing DRAM (%d bytes)\n", DRAM_ALLOCATE_SIZE);
        for (int i = 0; i < DRAM_ALLOCATE_SIZE; i += 4) {
            if (i % (1024 * 1024) == 0)
                bsg_pr_info("ps.cpp: zero-d %d MB\n", i / (1024 * 1024));
            send_bp_write(zpl, gp1_addr_base + i, 0x0, mask1);
        }
    }
#endif

#ifdef DRAM_TEST

    long num_times = allocated_dram / 32768;
    bsg_pr_info(
        "ps.cpp: attempting to write L2 %ld times over %ld MB (testing ARM GP1 "
        "and HP0 connections)\n",
        num_times * outer, (allocated_dram) >> 20);
    send_bp_write(zpl, DRAM_BASE_ADDR, 0x12345678, mask1);

    for (int s = 0; s < outer; s++)
        for (int t = 0; t < num_times; t++) {
            send_bp_write(zpl, DRAM_BASE_ADDR + 32768 * t + s * 4,
                          0x1ADACACA + t + s, mask1);
        }
    bsg_pr_info("ps.cpp: finished write L2 %ld times over %ld MB\n",
                num_times * outer, (allocated_dram) >> 20);

    int mismatches = 0;
    int matches = 0;

#ifdef ZYNQ
    for (int s = 0; s < outer; s++)
        for (int t = 0; t < num_times; t++)
            if (buf[(32768 * t + s * 4) / 4] == 0x1ADACACA + t + s)
                matches++;
            else
                mismatches++;

    bsg_pr_info("ps.cpp: DIRECT access from ARM to DDR (some L1/L2 coherence "
                "mismatches expected) %d matches, %d mismatches, %f\n",
                matches, mismatches,
                ((float)matches) / (float)(mismatches + matches));
#endif

    bsg_pr_info(
        "ps.cpp: attempting to read L2 %ld times over %ld MB (testing ARM GP1 "
        "and HP0 connections)\n",
        num_times * outer, (allocated_dram) >> 20);
    for (int s = 0; s < outer; s++)
        for (int t = 0; t < num_times; t++)
            if (zpl->shell_read(DRAM_BASE_ADDR + 32768 * t + s * 4) ==
                0x1ADACACA + t + s)
                matches++;
            else
                mismatches++;

    bsg_pr_info("ps.cpp: READ access through BP (some L1 coherence mismatch "
                "expected): %d matches, %d mismatches, %f\n",
                matches, mismatches,
                ((float)matches) / (float)(mismatches + matches));

#endif // DRAM_TEST

    bsg_pr_info("ps.cpp: beginning nbf load\n");
    nbf_load(zpl, argv[1]);
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    unsigned long long minstret_start = get_counter_64(zpl, GP0_RD_MINSTRET, 0);
    bsg_pr_dbg_ps("ps.cpp: finished nbf load\n");

    bsg_pr_info("ps.cpp: Starting scan thread\n");
    pthread_create(&thread_id, NULL, monitor, NULL);

    // Freeze processor
    zpl->shell_write(GP0_WR_CSR_FREEZEN, 0x0, 0xF);

    bsg_pr_info("ps.cpp: Starting i/o polling thread\n");
    int axil_len = sizeof(bp_bedrock_packet) / 4;
    while (1) {
        decode_bp_output(zpl);
        // break loop when all cores done
        if (done_vec.all()) {
            break;
        }
    }

    unsigned long long minstret_stop = get_counter_64(zpl, GP0_RD_MINSTRET, 0);
    // test delay for reading counter
    unsigned long long counter_data = get_counter_64(zpl, GP0_RD_MINSTRET, 0);
    clock_gettime(CLOCK_MONOTONIC, &end);
    setlocale(LC_NUMERIC, "");
    bsg_pr_info("ps.cpp: end polling i/o\n");
    bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
                minstret_start, minstret_start);
    bsg_pr_info("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n",
                minstret_stop, minstret_stop);
    unsigned long long minstret_delta = minstret_stop - minstret_start;
    bsg_pr_info("ps.cpp: minstret delta:                  %'16llu (%16llx)\n",
                minstret_delta, minstret_delta);
    unsigned long long diff_ns =
        1000LL * 1000LL * 1000LL *
            ((unsigned long long)(end.tv_sec - start.tv_sec)) +
        (end.tv_nsec - start.tv_nsec);
    bsg_pr_info(
        "ps.cpp: wall clock time                : %'16llu (%16llx) ns\n",
        diff_ns, diff_ns);

#ifdef ZYNQ
    // in general we do not want to free the dram; the Xilinx allocator has a
    // tendency to
    // fail after many allocate/fail cycle. instead we keep a pointer to the
    // dram in a CSR in the accelerator, and if we reload the bitstream, we copy
    // the pointer back in.s

    if (FREE_DRAM) {
        bsg_pr_info("ps.cpp: freeing DRAM buffer\n");
        zpl->free_dram((void *)buf);
        zpl->shell_write(GP0_WR_CSR_DRAM_INITED, 0x0, mask2);
    }
#endif

    zpl->done();
    delete zpl;
    return -1;
}

std::uint32_t rotl(std::uint32_t v, std::int32_t shift) {
    std::int32_t s = shift >= 0 ? shift % 32 : -((-shift) % 32);
    return (v << s) | (v >> (32 - s));
}

void nbf_load(bsg_zynq_pl *zpl, char *nbf_filename) {
    string nbf_command;
    string tmp;
    string delimiter = "_";

    long long int nbf[3];
    int pos = 0;
    long unsigned int base_addr;
    int data;
    std::ifstream nbf_file(nbf_filename);

    if (!nbf_file.is_open()) {
        bsg_pr_err("ps.cpp: error opening nbf file.\n");
        return;
    }

    int line_count = 0;
    int credit_count = 0;
    while (getline(nbf_file, nbf_command)) {
        line_count++;
        int i = 0;
        while ((pos = nbf_command.find(delimiter)) != std::string::npos) {
            tmp = nbf_command.substr(0, pos);
            nbf[i] = std::stoull(tmp, nullptr, 16);
            nbf_command.erase(0, pos + 1);
            i++;
        }
        nbf[i] = std::stoull(nbf_command, nullptr, 16);

        if (nbf[0] == 0x3 || nbf[0] == 0x2 || nbf[0] == 0x1 || nbf[0] == 0x0) {
            if (nbf[0] == 0x3) {
                send_bp_write(zpl, nbf[1], nbf[2], 0xff);
            } else if (nbf[0] == 0x2) {
                send_bp_write(zpl, nbf[1], nbf[2], 0xf);
            }
        } else if (nbf[0] == 0xfe) {
            continue;
        } else if (nbf[0] == 0xff) {
            bsg_pr_dbg_ps("ps.cpp: nbf finish command, line %d\n", line_count);
            continue;
        } else {
            bsg_pr_dbg_ps("ps.cpp: unrecognized nbf command, line %d : %llx\n",
                          line_count, nbf[0]);
            return;
        }
    }
    bsg_pr_dbg_ps("ps.cpp: waiting for credit returns.\n", credit_count);
    while (zpl->shell_read(GP0_RD_CREDITS))
        ;

    bsg_pr_dbg_ps("ps.cpp: finished loading %d lines of nbf.\n", line_count);
}

bool decode_bp_output(bsg_zynq_pl *zpl) {
    bp_bedrock_packet fwd_packet;
    recv_bp_fwd_packet(zpl, &fwd_packet);

    uint32_t address = fwd_packet.addr0 & 0xFFFFFFFC;
    uint64_t data = 0;
    data |= fwd_packet.data0 << 0;
    data |= fwd_packet.data1 << 32;
    char print_data = data & 0xFF;
    char core = (address - 0x102000) >> 3;
    // write from BP
    if (address == 0x101000) {
        printf("%c", print_data);
        fflush(stdout);
    } else if (address >= 0x102000 && address < 0x103000) {
        done_vec[core] = true;
        if (print_data == 0) {
            bsg_pr_info("CORE[%d] PASS\n", core);
        } else {
            bsg_pr_info("CORE[%d] FAIL\n", core);
        }
    } else if (address == 0x103000) {
        bsg_pr_dbg_ps("ps.cpp: Watchdog tick\n");
    } else if (address >= 0x110000 && address < 0x111000) {
        int bootrom_addr0 = (address >> 2) & 0x1ff;
        zpl->shell_write(GP0_WR_CSR_BOOTROM_ADDR, bootrom_addr0, 0xf);
        int bootrom_data0 = zpl->shell_read(GP0_RD_BOOTROM_DATA);
        int bootrom_addr1 = bootrom_addr0 + 1;
        zpl->shell_write(GP0_WR_CSR_BOOTROM_ADDR, bootrom_addr1, 0xf);
        int bootrom_data1 = zpl->shell_read(GP0_RD_BOOTROM_DATA);

        bp_bedrock_packet rev_packet = fwd_packet;
        rev_packet.data0 = bootrom_data0;
        rev_packet.data1 = bootrom_data1;
        send_bp_rev_packet(zpl, &rev_packet);
    } else {
        bsg_pr_err("ps.cpp: Errant write to %lx\n", address);
        return false;
    }

    return true;
}
