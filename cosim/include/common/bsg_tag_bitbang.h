
#ifndef BSG_TAG_BITBANG_H
#define BSG_TAG_BITBANG_H

#include "bsg_zynq_pl.h"

struct bsg_tag_client {
    int nodeID;
    int width;

    bsg_tag_client(int nodeID, int width) : nodeID(nodeID), width(width) { }
};

class bsg_tag_bitbang {
    static int safe_clog2(int x) {
        int ret = 1;
        int val = x*2-1;
        while ((val >>= 1) > 1) ret++;
        return ret;
    }

    bsg_zynq_pl *zpl;
    int id_len;
    int max_len;
    uintptr_t shell_addr;

    // low-level bit manipulation function
    void write_bit(int bit) {
        zpl->shell_write(shell_addr, (bit&1), 0xf);
    }

    // low-level tag interaction
    void write_client(int nodeID, int data_not_reset, int width, int payload) {
        // start bit
        write_bit(1);
        // payload len
        for(int i = 0; i < max_len; i++) {
            write_bit((width >> i) & 0x1);
        }
        // data_not_reset
        write_bit(data_not_reset);
        // nodeID
        for(int i = 0; i < id_len; i++) {
            write_bit((nodeID >> i) & 0x1);
        }
        // payload
        for(int i = 0; i < width; i++) {
            write_bit((payload >> i) & 0x1);
        }
        // end bit
        write_bit(0x0);
    }

    public:
    // Construct a bitbang tag client
    bsg_tag_bitbang(bsg_zynq_pl *zpl, uintptr_t shell_addr, int num_clients, int max_len)
        : zpl(zpl), shell_addr(shell_addr), id_len(safe_clog2(num_clients)), max_len(max_len) {
            bsg_pr_info("Creating Bitbang Driver: %p %" PRIxPTR " %d %d\n", zpl, shell_addr, num_clients, max_len);
        }

    // Set a specific bsg tag client
    void set_client(bsg_tag_client *client, int payload) {
        bsg_pr_info("Setting Tag Client %d<-%d\n", client->nodeID, payload);
        write_client(client->nodeID, 1, client->width, payload);
    }

    // Reset a specific bsg tag client
    void reset_client(bsg_tag_client *client) {
        bsg_pr_info("Resetting Tag Client %d\n", client->nodeID);
        write_client(client->nodeID, 0, client->width, 1);
    }

    // Reset the bsg tag master
    void reset_master() {
        bsg_pr_info("Reset Tag Master\n");
        write_bit(1);
        // Make sure we get enough cycles for tag master to initialize itself
        for(int i = 0; i < 100; i++) {
            write_bit(0);
        }
    }

    // Idle
    void idle(int cycles) {
        bsg_pr_info("Idling for %d\n", cycles);
        for (int i = 0; i < cycles; i++) {
            write_bit(0);
        }
    }
};

#endif
