//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.


#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <time.h>
#include <unistd.h>

#include "bp_zynq_pl.h"

#define FREE_DRAM 0
#define DRAM_ALLOCATE_SIZE 120*1024*1024

void nbf_load(bp_zynq_pl *zpl, char *);
bool decode_bp_output(bp_zynq_pl *zpl, int data);


inline unsigned long long get_counter_64(bp_zynq_pl *zpl, unsigned int addr)
{
  unsigned long long val;
  do {
    unsigned int val_hi = zpl->axil_read(addr+4);
    unsigned int val_lo = zpl->axil_read(addr+0);
    unsigned int val_hi2 = zpl->axil_read(addr+4);
    if (val_hi == val_hi2)
    {
      val = ((unsigned long long) val_hi) << 32;
      val += val_lo;
      return val;
    }
    else
      printf("ps.cpp: timer wrapover!");
  }
  while (1);
}

int main(int argc, char **argv) {
  // this ensures that even with tee, the output is line buffered
  // so that we can see what is happening in real time

  setvbuf(stdout, NULL, _IOLBF, 0);

  bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

   // the read memory map is essentially
   //
   // 0,4,8: reset, dram allocated, dram base address
   // C: pl to ps fifo
   // 10: pl to ps fifo count
   // 14: ps to pl fifo count

   // the write memory map is essentially
   //
   // 0,4,8: registers
   // 10: ps to pl fifo 
    
   int data;
   int val1 = 0x1;
   int val2 = 0x0;
   int mask1 = 0xf;
   int mask2 = 0xf;
   bool done = false;

   int allocated_dram = DRAM_ALLOCATE_SIZE;
#ifdef FPGA
    unsigned long phys_ptr;
    volatile int *buf;
#endif

    int val;
    printf("ps.cpp: reading three base registers\n");
    printf("ps.cpp: reset(lo)=%d dram_init=%d, dram_base=%x\n"
	   ,zpl->axil_read(0x0 + GP0_ADDR_BASE)
	   ,zpl->axil_read(0x4 + GP0_ADDR_BASE)
	   ,val = zpl->axil_read(0x8 + GP0_ADDR_BASE)
	   );

    printf("ps.cpp: putting BP into reset\n");
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1); // BP reset
    
    printf("ps.cpp: attempting to write and read register 0x8\n");

    zpl->axil_write(0x8 + GP0_ADDR_BASE, 0xDEADBEEF, mask1); // BP reset
    assert( (zpl->axil_read(0x8 + GP0_ADDR_BASE) == (0xDEADBEEF)));
    zpl->axil_write(0x8 + GP0_ADDR_BASE, val, mask1); // BP reset
    assert( (zpl->axil_read(0x8 + GP0_ADDR_BASE) == (val)));

    printf("ps.cpp: successfully wrote and read registers in bsg_zynq_shell (verified ARM GP0 connection)\n");
#ifdef FPGA
    data = zpl->axil_read(0x4 + GP0_ADDR_BASE);
    if (data == 0) {
      printf("ps.cpp: CSRs do not contain a DRAM base pointer; calling allocate dram with size %d\n",allocated_dram);
      buf = (volatile int*) zpl->allocate_dram(allocated_dram, &phys_ptr);
      printf("ps.cpp: received %p (phys = %lx)\n",buf, phys_ptr);
      zpl->axil_write(0x8 + GP0_ADDR_BASE, phys_ptr, mask1);
      assert( (zpl->axil_read(0x8 + GP0_ADDR_BASE) == (phys_ptr)));
      printf("ps.cpp: wrote and verified base register\n");
      zpl->axil_write(0x4 + GP0_ADDR_BASE, 0x1, mask2);
      assert(zpl->axil_read(0x4 + GP0_ADDR_BASE) == 1);
    }
    else
      printf("ps.cpp: reusing dram base pointer %x\n",zpl->axil_read(0x8 + GP0_ADDR_BASE));

    int outer = 1024/4;
#else
    zpl->axil_write(0x8+GP0_ADDR_BASE, val1, mask1);
    assert( (zpl->axil_read(0x8 + GP0_ADDR_BASE) == (val1)));
    printf("ps.cpp: wrote and verified base register\n");

    int outer = 8/4;
#endif

    if (argc == 1)
      {
	printf("No nbf file specified, sleeping for 2^31 seconds (this will hold onto allocated DRAM)\n");
	sleep(1 << 31);
	exit(0);
      }
    
    printf("ps.cpp: asserting reset to BP\n");

    // Assert reset, we do it repeatedly just to make sure that enough cycles pass
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
    assert( (zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
    assert( (zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
    assert( (zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
    assert( (zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
    
    // Deassert reset
    printf("ps.cpp: deasserting reset to BP\n");
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);
    zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);
    
    printf("Reset asserted and deasserted\n");

    printf("ps.cpp: attempting to read mtime reg in BP CFG space, should increase monotonically  (testing ARM GP1 connections)\n");

    for (int q = 0; q < 10; q++)
    {
      int z = zpl->axil_read(0xA0000000U+0x30bff8);
      // read second 32-bits
      int z2 = zpl->axil_read(0xA0000000U+0x30bff8+4);
      //        printf("ps.cpp: %d%c",z,(q % 8) == 7 ? '\n' : ' ');
    }

    printf("ps.cpp: attempting to read and write mtime reg in BP CFG space (testing ARM GP1 connections)\n");

    printf("ps.cpp: reading mtimecmp\n");
    int y = zpl->axil_read(0xA0000000U+0x304000);

    printf("ps.cpp: writing mtimecmp\n");
    zpl->axil_write(0xA0000000U+0x304000,y+1,mask1);

    printf("ps.cpp: reading mtimecmp\n");
    assert(zpl->axil_read(0xA0000000U+0x304000)==y+1);

    /*
    printf("ps.cpp: mis-aligned read of mtime reg in BP CFG space\n");
    for (int q = 0; q < 10; q++)
      {
        int z = zpl->axil_read(0xA0000000+0x30bff9);
      }
    */

    int tmp = zpl->BP_ZYNQ_PL_DEBUG;
    
#ifndef SKIP_DRAM_TESTING
    
    int num_times = allocated_dram/32768;
    printf("ps.cpp: attempting to write L2 %d times over %d MB (testing ARM GP1 and HP0 connections)\n",num_times*outer,(allocated_dram)>>20);
    zpl->axil_write(0x80000000,0x12345678,mask1);


    zpl->BP_ZYNQ_PL_DEBUG=0;
    for (int s = 0 ; s < outer; s++)
      for (int t = 0 ; t < num_times; t++)
      {
        zpl->axil_write(0x80000000+32768*t+s*4,0x1ADACACA+t+s
                        ,mask1);
      }
    zpl->BP_ZYNQ_PL_DEBUG=tmp;
    printf("ps.cpp: finished write L2 %d times over %d MB\n",num_times*outer,(allocated_dram)>>20);

    int mismatches = 0;
    int matches = 0;

#ifdef FPGA
    for (int s = 0 ; s < outer; s++)
      for (int t = 0 ; t < num_times; t++)
        if  (buf[(32768*t+s*4)/4] == 0x1ADACACA+t+s)
          matches++;
        else
          mismatches++;

    printf("ps.cpp: DIRECT access from ARM to DDR (some L1/L2 coherence mismatches expected) %d matches, %d mismatches, %f\n",matches,mismatches,((float) matches)/(float) (mismatches+matches));
#endif

    printf("ps.cpp: attempting to read L2 %d times over %d MB (testing ARM GP1 and HP0 connections)\n",num_times*outer,(allocated_dram)>>20);
    zpl->BP_ZYNQ_PL_DEBUG=0;
    for (int s = 0 ; s < outer; s++)
      for (int t = 0 ; t < num_times; t++)
        if (zpl->axil_read(0x80000000+32768*t+s*4) == 0x1ADACACA+t+s)
          matches++;
        else
          mismatches++;

    zpl->BP_ZYNQ_PL_DEBUG=tmp;

    printf("ps.cpp: READ access through BP (some L1 coherence mismatch expected): %d matches, %d mismatches, %f\n",matches,mismatches,((float) matches)/(float) (mismatches+matches));

#endif     // SKIP_DRAM_TESTING

    zpl->BP_ZYNQ_PL_DEBUG=0;
    
    printf("ps.cpp: beginning nbf load\n");
    nbf_load(zpl, argv[1]);
    struct timespec start,end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    unsigned long long minstrret_start = get_counter_64(zpl,0x18 + GP0_ADDR_BASE);
    unsigned long long  mtime_start    = get_counter_64(zpl,0xA0000000+0x30bff8);
    zpl->BP_ZYNQ_PL_DEBUG=0;

    //    zpl->BP_ZYNQ_PL_DEBUG=tmp;

    if (zpl->BP_ZYNQ_PL_DEBUG) {
      printf("ps.cpp: finished nbf load\n");
      printf("ps.cpp: polling i/o\n");
    }

    while(1) {
      // keep reading as long as there is data
      data = zpl->axil_read(0x10 + GP0_ADDR_BASE);
      if (data != 0) {
        data = zpl->axil_read(0xC + GP0_ADDR_BASE);
        done |= decode_bp_output(zpl, data);
      } else if (done)
	break;
    }

    //zpl->BP_ZYNQ_PL_DEBUG=tmp;
    unsigned long long mtime_stop = get_counter_64(zpl,0xA0000000+0x30bff8);

    unsigned long long minstrret_stop = get_counter_64(zpl,0x18 + GP0_ADDR_BASE);
    // test delay for reading counter
    unsigned long long counter_data = get_counter_64(zpl,0x18 + GP0_ADDR_BASE);
    clock_gettime(CLOCK_MONOTONIC, &end);
    setlocale(LC_NUMERIC,"");
    printf("ps.cpp: end polling i/o\n");
    printf("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n", minstrret_start,minstrret_start);
    printf("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n", minstrret_stop,minstrret_stop);
    unsigned long long minstrret_delta = minstrret_stop-minstrret_start;
    printf("ps.cpp: minstret delta:                  %'16llu (%16llx)\n",minstrret_delta,minstrret_delta);
    printf("ps.cpp: MTIME start:                     %'16llu (%16llx)\n",mtime_start,mtime_start);
    printf("ps.cpp: MTIME stop:                      %'16llu (%16llx)\n",mtime_stop,mtime_stop);
    unsigned long long mtime_delta = mtime_stop-mtime_start;
    printf("ps.cpp: MTIME delta (=1/8 BP cycles):    %'16llu (%16llx)\n",mtime_delta,mtime_delta);
    printf("ps.cpp: IPC        :                     %'16f\n", ((double) minstrret_delta) / ((double) (mtime_delta))/8.0);
    printf("ps.cpp: minstret (instructions retired): %'16llu (%16llx)\n", counter_data,counter_data);
    unsigned long long diff_ns = 1000LL*1000LL*1000LL * ((unsigned long long) (end.tv_sec - start.tv_sec)) + (end.tv_nsec - start.tv_nsec);
    printf("ps.cpp: wall clock time                : %'16llu (%16llx) ns\n",diff_ns,diff_ns);
    printf("ps.cpp: sim/emul speed                 : %'16.2f BP cycles per minute\n", mtime_delta*8/((double) (diff_ns) / (60.0*1000.0*1000.0*1000.0)));

    printf("ps.cpp: BP DRAM USAGE MASK (each bit is 8 MB): %-8.8x%-8.8x%-8.8x%-8.8x\n"
           , zpl->axil_read(0x2C + GP0_ADDR_BASE)
           , zpl->axil_read(0x28 + GP0_ADDR_BASE)
           , zpl->axil_read(0x24 + GP0_ADDR_BASE)
           , zpl->axil_read(0x20 + GP0_ADDR_BASE)
      );
#ifdef FPGA
    // in general we do not want to free the dram; the Xilinx allocator has a tendency to
    // fail after many allocate/fail cycle. instead we keep a pointer to the dram in a CSR
    // in the accelerator, and if we reload the bitstream, we copy the pointer back in.s
    
    if (FREE_DRAM) {
      printf("ps.cpp: freeing DRAM buffer\n");
      zpl->free_dram((void *)buf);
      zpl->axil_write(0x4 + GP0_ADDR_BASE, 0x0, mask2);
    }
#endif
    
    zpl->done();

    delete zpl;
    exit(EXIT_SUCCESS);
}

void nbf_load(bp_zynq_pl *zpl, char *nbf_filename) {
    string nbf_command;
    string tmp;
    string delimiter = "_";

    long long int nbf[3];
    int pos = 0;
    long unsigned int address;
    int data;
    ifstream nbf_file(nbf_filename);

    if (!nbf_file.is_open())
      {
        printf("ps.cpp: error opening nbf file.\n");
        exit(-1);
      }

    int line_count=0;
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
      if (nbf[0] == 0x3) {
        // we map BP physical addresses for DRAM (0x8000_0000 - 0x9FFF_FFFF) (256MB)
        // to the same ARM physical addresses
        // see top_fpga.v for more details

        if (nbf[1] >= 0x80000000) {
          address = nbf[1];
          address = address;
          data = nbf[2];
          nbf[2] = nbf[2] >> 32;
          zpl->axil_write(address, data, 0xf);
          address = address + 4;
          data = nbf[2];
          zpl->axil_write(address, data, 0xf);
        }
        // we map BP physical address for CSRs etc (0x0000_0000 - 0x0FFF_FFFF)
        // to ARM address to 0xA0000_0000 - 0xAFFF_FFFF  (256MB)
        else {
          address = nbf[1];
          address = address + 0xA0000000;
          data = nbf[2];
          zpl->axil_write(address, data, 0xf);
        }
      }
      else if (nbf[0] == 0xfe) {
        continue;
      }
      else {
	if (zpl->BP_ZYNQ_PL_DEBUG)
	  printf("ps.cpp: unrecognized nbf command, line %d : %x\n", line_count,  nbf[0]);
        return;
      }
    }
    if (zpl->BP_ZYNQ_PL_DEBUG)
      printf("ps.cpp: finished loading %d lines of nbf.\n",line_count);
  }

bool decode_bp_output(bp_zynq_pl *zpl, int data) {
    int rd_wr = data >> 31;
    int address = (data >> 8) & 0x7FFFFF;
    int print_data = data & 0xFF;
    if (rd_wr) {
      if (address == 0x101000) {
        printf("%c", print_data);
        return false;
      }
      else if (address == 0x102000) {
        if (print_data == 0)
          printf("\nPASS\n");
        else
          printf("\nFAIL\n");
        return true;
      }

      printf("ps.cpp: Errant write to %x", address);
      return false;
    }
    // TODO: Need to implement logic for bp io_read
    else return false;
  }


