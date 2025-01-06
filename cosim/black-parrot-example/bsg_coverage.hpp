//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <cstdint>
#include <iostream>
#include <iomanip>
#include <unordered_set>

#ifdef COV_EN
#define COV_BUF_LEN 1024
typedef uint64_t dma_t;

struct covBits {
  int N;
  dma_t* arr;

  covBits(int N): N(N) {
    arr = new dma_t[N];
  }

  void set(int i, dma_t x) {
    this->arr[i] = x;
  }

  bool operator==(const covBits& c) const {
    if(this->N != c.N)
      return false;

    for(int i = 0; i < this->N; i++)
      if(this->arr[i] != c.arr[i])
        return false;
    return true;
  }

  struct Hash
  {
    size_t operator()(const covBits& c) const {
      size_t NHash = std::hash<int>()(c.N);
      size_t arrHash = std::hash<dma_t*>()(c.arr) << 1;
      return NHash ^ arrHash;
    }
  };
};

ostream& operator<<(ostream& os, const covBits& c) {
    for(int i = 0; i < c.N; i++)
      os << std::hex << c.arr[i] << std::dec;
    return os;
}


struct covProcState {
  bool is_header;
  int id;
  int len;
  int els;
  int els_cnt;
  int len_cnt;
  covBits* curr_cov;

  covProcState() {
    is_header = true;
  }
};

covProcState covState;
std::unordered_set<covBits, covBits::Hash> covs[COV_NUM];

inline void cov_proc(dma_t* buffer, int size) {
  dma_t* p = buffer;
  int cnt = size;
  while(true) {
    if(covState.is_header) {
      if(cnt == 0)
        return;

      //bsg_pr_info("ps.cpp: header = %x\n", *p);
      covState.id = *p & 0xFF;
      covState.els = (*p >> 8) & 0xFF;
      covState.len = (*p >> 16) & 0xFF;
      covState.is_header = false;
      covState.els_cnt = 0;
      covState.len_cnt = 0;
      p++;
      cnt--;
    }
    else {
      while(covState.els_cnt < covState.els) {
        while(covState.len_cnt < covState.len) {
          //bsg_pr_info("ps.cpp: data = %x\n", *p);
          if(cnt == 0)
            return;

          if(covState.len_cnt == 0)
            covState.curr_cov = new covBits(covState.len);

          covState.curr_cov->set(covState.len_cnt, *p);
          covState.len_cnt++;
          p++;
          cnt--;
        }
        //cout << "ps.cpp: cov = " << *covState.curr_cov << endl;
        covs[covState.id].insert(*covState.curr_cov);
        covState.len_cnt = 0;
        covState.els_cnt++;
      }
      covState.is_header = true;
    }
  }
}

#ifdef ZYNQ
PYNQ_SHARED_MEMORY cov_buff;
PYNQ_AXI_DMA dma;

pthread_t cov_pid;
bool cov_run = true;

void* cov_poll(void *vargp) {
  bsg_zynq_pl* zpl = (bsg_zynq_pl*) vargp;
  int len;
  while(cov_run) {

    // initiate read transfer and wait for completion
    PYNQ_readDMA(&dma, &cov_buff, 0, sizeof(dma_t) * COV_BUF_LEN);
    PYNQ_waitForDMAComplete(&dma, AXI_DMA_READ, &len);

    // process the packet
    cov_proc((dma_t*)cov_buff.pointer, (len / sizeof(dma_t)));
  }
  return NULL;
}

void cov_start(bsg_zynq_pl *zpl) {
  // allocate CMA buffer and open read DMA
  bsg_pr_info("ps.cpp: allocating coverage CMA memory\n");
  PYNQ_allocatedSharedMemory(&cov_buff, sizeof(dma_t) * COV_BUF_LEN, 0);

  bsg_pr_info("ps.cpp: openning DMA device\n");
  PYNQ_openDMA(&dma, GP0_DMA_ADDR+1, true, false, sizeof(dma_t) * COV_BUF_LEN);

  // assert coverage collection
  bsg_pr_info("ps.cpp: Asserting coverage collection enable\n");
  zpl->shell_write(GP0_WR_CSR_COV_EN, 0x1, 0xf);

  // start coverage polling thread
  pthread_create(&cov_pid, NULL, cov_poll, (void*)zpl);
}

void cov_done(bsg_zynq_pl *zpl) {
  // stop coverage polling thread
  cov_run = false;
  pthread_join(cov_pid, NULL);

  // deassert coverage collection
  bsg_pr_info("ps.cpp: Deasserting coverage collection enable\n");
  zpl->shell_write(GP0_WR_CSR_COV_EN, 0x0, 0xf);

  // close DMA and free CMA buffer
  PYNQ_closeDMA(&dma);
  PYNQ_freeSharedMemory(&cov_buff);

  // report covergroup utilization
  for(int i = 0; i < COV_NUM; i++) {
    printf("cover-group[%d] size: %d\n", i, covs[i].size());
  }
}
#else
dma_t cov_buff[COV_BUF_LEN];

void cov_poll(bsg_zynq_pl *zpl) {
  // check if a complete DMA packet is available
  int len = 0;
  if(zpl->buffer_has_read()) // buffer was previously DMA
    len = zpl->buffer_read((int32_t *)cov_buff);
  else
    return;

  // process the packet
  //bsg_pr_info("ps.cpp: dma read done with len: %d\n", len);
  cov_proc(cov_buff, len);
}

void cov_start(bsg_zynq_pl *zpl) {
  // assert coverage collection
  bsg_pr_info("ps.cpp: Asserting coverage collection enable\n");
  zpl->shell_write(GP0_WR_CSR_COV_EN, 0x1, 0xf);
}

void cov_done(bsg_zynq_pl *zpl) {
  // deassert coverage collection
  bsg_pr_info("ps.cpp: Desserting coverage collection enable\n");
  zpl->shell_write(GP0_WR_CSR_COV_EN, 0x0, 0xf);

  // report covergroup utilization
  for(int i = 0; i < COV_NUM; i++) {
    printf("cover-group[%d] size: %d\n", i, covs[i].size());
  }
}
#endif
#endif
