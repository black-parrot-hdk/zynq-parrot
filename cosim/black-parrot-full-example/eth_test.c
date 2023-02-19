
/*
* This test targets at the combination of BP + Ethernet + PLIC. It
* assumes TX and RX side of the RGMII have been connected together
* to form a loopback structure.
*
* This test corresponds to eth_test.nbf
*/

#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include "bp_utils.h"
#include "bp_trap.h"

#define PACKET_SIZE 1024

// Enable external interrupt
static void s_external_interrupt_enable()
{
	unsigned long tmp;
	asm volatile ("li %0, (1 << 9)\n" : "=r"(tmp));
	asm volatile ("csrs mie, %0\n" : : "r"(tmp) : "memory");
}
// Enable global machine interrupt
static void global_interrupt_enable()
{
	unsigned long tmp;
	asm volatile ("li %0, (1 << 3)\n" : "=r"(tmp));
	asm volatile ("csrs mstatus, %0\n" : : "r"(tmp) : "memory");
}

#define eth_base           0x10000000UL
#define eth_tx_packet_addr (eth_base + 0x0800UL)
#define eth_tx_size_addr   (eth_base + 0x1028UL)
#define eth_tx_send_addr   (eth_base + 0x1018UL)
#define eth_rx_enable_addr (eth_base + 0x1014UL)
#define eth_tx_enable_addr (eth_base + 0x1034UL)
#define eth_tx_pending_addr     (eth_base + 0x1030UL)
#define eth_rx_packet_addr      (eth_base + 0x0UL)
#define eth_rx_packet_size_addr (eth_base + 0x1004UL)
#define eth_rx_pending_addr     (eth_base + 0x1010UL)

#define plic_base       0x20000000UL
#define priority_addr  (plic_base + 0x4UL)
#define pending_addr   (plic_base + 0x1000UL)
#define enable_addr    (plic_base + 0x2000UL)
#define threshold_addr (plic_base + 0x200000UL)
#define cc_addr        (plic_base + 0x200004UL)

char buf[2048] __attribute__ ((aligned (4)));
int total_send_count;
volatile int done;

// valid op_size: 1, 2, 4
void send_packet(const char buf[], int size, int op_size)
{
    assert(op_size == 1 || op_size == 2 || op_size == 4);
    // write packet
    int base;
    int word = size / op_size;
    int offset = size % op_size;
    assert(offset == 0);
    for(base = 0;base < word * op_size;base += op_size) {
        if(op_size == 1) {
            *(volatile uint8_t *)(eth_tx_packet_addr + base) =
                *(volatile uint8_t *)(buf + base);
        } else if(op_size == 2) {
            *(volatile uint16_t *)(eth_tx_packet_addr + base) =
                *(volatile uint16_t *)(buf + base);
        } else { // op_size == 4
            *(volatile uint32_t *)(eth_tx_packet_addr + base) =
                *(volatile uint32_t *)(buf + base);
        }
    }

    // write size
    *(volatile int *)(eth_tx_size_addr) = size;
    // send
    *(volatile int *)(eth_tx_send_addr) = 1;  
}


void plic_handler(uint64_t *regs, uint64_t mcause, uint64_t instr)
{
    (void)regs;
    (void)mcause;
    (void)instr;
    unsigned byte;
    bp_print_string("Entering S-mode interrupt\n");
    // S-mode external interrupt handling
    // PLIC claim
    int claim_id = *(volatile char *)cc_addr;
    // interrupt is coming from source 1, i.e. Ethernet
    if(claim_id == 1) {
        static int received_count = 0;
        // Check RX pending
        if(*(volatile int *)eth_rx_pending_addr) {
            int size;
            // Read out packet
            size = *(volatile unsigned *)(eth_rx_packet_size_addr);
            assert(size == PACKET_SIZE);

            // Check packet ID
            byte = *(volatile unsigned char *)(eth_rx_packet_addr + 0);
            assert(byte == (unsigned)received_count);
            for(int i = 1;i < size;i++) {
                byte = *(volatile unsigned char *)(eth_rx_packet_addr + i);
                assert(byte == (unsigned)(i % 64));
            }
            bp_print_string("Receive #");
            bp_hprint_uint64(received_count + 1);
            bp_print_string(" packet successfully with byte granularity\n");
            received_count++;
            if(received_count == total_send_count) {
                done = 1;
            }

            // Write 1 to clear RX pending bit
            *(volatile int *)eth_rx_pending_addr = 1;
        }
        // Check TX pending
        if(*(volatile int *)eth_tx_pending_addr) {
            //   TX pending bit of the Ethernet core is set when 
            // the state of the Ethernet TX buffer swicthes
            // from full to non-full. Depending on the Ethernet
            // speed(10M, 100M or 1G) and the number of packets,
            // this bit can be set sometimes.
            bp_print_string("TX buffer becomes available\n");
            // Write 1 to clear TX pending bit
            *(volatile int *)eth_tx_pending_addr = 1;
        }
        // PLIC complete
        *(volatile int *)cc_addr = claim_id;
    }
    else {
        bp_print_string("Unknown claim id: ");
        bp_hprint_uint64(claim_id);
        bp_finish(1);
    }
}

int main()
{
    printf("Test starts\n");
    // Register S-mode external interrupt handler
    if(register_trap_handler(&plic_handler, (9UL | (1UL << 63)))) {
      printf("Fail to register trap_handler\n");
      bp_finish(-1);
    }
    // Set priority to 1
    *(volatile unsigned *)(priority_addr) = 1;
    // Set threshold to 0
    *(volatile unsigned *)(threshold_addr) = 0;
    // Set PLIC interrupt enable bit
    *(volatile unsigned *)(enable_addr) = 2;
    // Set Ethernet RX interrupt enable bit
    *(volatile int *)(eth_rx_enable_addr) = 1;
    // Set Ethernet TX interrupt enable bit
    *(volatile int *)(eth_tx_enable_addr) = 1;
    // Set BP S-mode interrupt enable bit
    s_external_interrupt_enable();
    // Set BP global interrupt enable bit for M-mode
    global_interrupt_enable();

    // Init Packet content
    //   It is possible to have packet drops if the packet size
    // and the total send count exceed the capacity of the
    // internal buffers inside the Ethernet device.
    total_send_count = 6;
    for(int i = 0;i < PACKET_SIZE;i++)
        buf[i] = i % 64;
    // Send packets 
    for(int i = 0;i < total_send_count;i++) {
        buf[0] = i; // We use first byte as the packet ID
        printf("Sending #%d packet with byte granularity\n", i + 1);
        send_packet(buf, PACKET_SIZE, 1);
    }
    printf("Test ends. Wait until all packets are received...\n");
    while(done == 0);
    
    bp_finish(0);
}
