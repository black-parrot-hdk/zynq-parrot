//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

// This host code uses Linux to allocate some uncached DRAM that can be shared
// with
// DRAM.  We send the physical address to the PL so that it knows where to host
// its DRAM region.
//

#include "bsg_zynq_pl.h"
#include <stdio.h>
#include <stdlib.h>

#include "ps.hpp"

int ps_main(bsg_zynq_pl *zpl, int argc, char **argv) {

    int mask1 = 0xf;
    unsigned long phys_ptr;
    int pl_dram_req_rw = 0; //0 = read, 1 = write
    int pl_dram_req_data = 0xCAFE;
    int pl_dram_resp_data = 0;

    volatile int *buf;

    buf = (volatile int *)zpl->allocate_dram(DRAM_ALLOC_SIZE_BYTES, &phys_ptr);
    zpl->shell_write(GP0_WR_CSR_DRAM_BASE_ADDR, phys_ptr, mask1);

    bsg_pr_info("Allocated DRAM with virt_ptr: 0x%llx, phys_ptr: 0x%llx\n", buf, phys_ptr);

    // write all of the dram
    for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES / 4; i++)
        buf[i] = i;

    // read all of the dram
    for (int i = 0; i < DRAM_ALLOC_SIZE_BYTES / 4; i++)
        assert(buf[i] == i);

    //read from memory from pl
    bsg_pr_info("Reading DRAM from PL\n");

    zpl->shell_write(GP0_WR_PS2PL_FIFO_REQ_ADDR, 0x8, mask1);
    zpl->shell_write(GP0_WR_PS2PL_FIFO_REQ_DATA, 0x0, mask1);
    zpl->shell_write(GP0_WR_PS2PL_FIFO_REQ_TYPE, pl_dram_req_rw, mask1);

    while(zpl->shell_read(GP0_RD_PL2PS_FIFO_RESP_CNTR) == 0x0);

    pl_dram_resp_data = zpl->shell_read(GP0_RD_PL2PS_FIFO_RESP_DATA);
    bsg_pr_info("Reading from buf[2] from PL: %llx\n", pl_dram_resp_data);

    assert(pl_dram_resp_data == buf[2]);

    //write to memory from pl
    bsg_pr_info("Writing to DRAM from PL\n");

    pl_dram_req_rw = 1;
    zpl->shell_write(GP0_WR_PS2PL_FIFO_REQ_ADDR, 0x8, mask1);
    zpl->shell_write(GP0_WR_PS2PL_FIFO_REQ_DATA, pl_dram_req_data, mask1);
    zpl->shell_write(GP0_WR_PS2PL_FIFO_REQ_TYPE, pl_dram_req_rw, mask1);

    //check write_progress CSR status
    int write_progress;
    do {
        write_progress = zpl->shell_read(GP0_RD_CSR_WRITE_PROGRESS);
        bsg_pr_dbg_pl("write_progress: %llx, buf[2]: 0x%llx\n", write_progress, buf[2]);
    } while (write_progress != 0);

    //check the write is coherent on PS
    assert(buf[2] == pl_dram_req_data);
    bsg_pr_info("PL wrote 0x%llx to buf[2]\n", buf[2]);

    if (argc == 1)
        zpl->free_dram((void *)buf);

    return zpl->done();
}
