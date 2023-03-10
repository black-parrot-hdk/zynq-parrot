
#ifndef BP_BEDROCK_PACKET_H
#define BP_BEDROCK_PACKET_H

  // 3b size
  #define BEDROCK_MSG_SIZE_1   0x0
  #define BEDROCK_MSG_SIZE_2   0x1
  #define BEDROCK_MSG_SIZE_4   0x2
  #define BEDROCK_MSG_SIZE_8   0x3
  #define BEDROCK_MSG_SIZE_16  0x4
  #define BEDROCK_MSG_SIZE_32  0x5
  #define BEDROCK_MSG_SIZE_64  0x6
  #define BEDROCK_MSG_SIZE_128 0x7

  // 4b message type
  #define BEDROCK_MEM_RD       0x0
  #define BEDROCK_MEM_WR       0x1
  #define BEDROCK_MEM_UC_RD    0x2
  #define BEDROCK_MEM_UC_WR    0x3
  #define BEDROCK_MEM_PRE      0x4
  #define BEDROCK_MEM_AMO      0x5

  // 4b write type
  #define BEDROCK_STORE        0x0
  #define BEDROCK_AMOLR        0x1
  #define BEDROCK_AMOSC        0x2
  #define BEDROCK_AMOSWAP      0x3
  #define BEDROCK_AMOADD       0x4
  #define BEDROCK_AMOXOR       0x5
  #define BEDROCK_AMOAND       0x6
  #define BEDROCK_AMOOR        0x7
  #define BEDROCK_AMOMIN       0x8
  #define BEDROCK_AMOMAX       0x9
  #define BEDROCK_AMOMINU      0xa
  #define BEDROCK_AMOMAXU      0xb

  // 3b coherence state
  #define BEDROCK_COH_I        0x0
  #define BEDROCK_COH_S        0x1
  #define BEDROCK_COH_E        0x2
  #define BEDROCK_COH_F        0x3
  #define BEDROCK_COH_UNUSED0  0x4
  #define BEDROCK_COH_UNUSED1  0x5
  #define BEDROCK_COH_M        0x6
  #define BEDROCK_COH_O        0x7

  // 64b payload
  typedef struct mem_payload {
    uint8_t  speculative;
    uint8_t  uncached;
    uint8_t  prefetch;
    uint8_t  did;
    uint8_t  lce_id;
    uint8_t  way_id;
    uint8_t  state;
    uint8_t  padding[1];
  } __attribute__((packed, aligned(4))) bp_bedrock_mem_payload;

  // This is a BedRock packet aligned to 196b packet size
  typedef struct {
    uint8_t  msg_type;
    uint8_t  subop;
    uint32_t addr0;
    uint32_t addr1;
    uint8_t  size;
    bp_bedrock_mem_payload payload;
    uint32_t data;
    uint8_t  padding[1];
  } __attribute__((packed, aligned(4))) bp_bedrock_packet;

#endif

