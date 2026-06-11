#ifndef FPGA_MEM_H
#define FPGA_MEM_H

#include <stdint.h>

#define H2F_AXI_BASE   0xC0000000UL
#define RAM_S1_OFFSET  0x00008000UL
#define RAM_S1_SIZE    0x00008000UL   /* 32 KB */
#define RAM_S1_PHYS    (H2F_AXI_BASE + RAM_S1_OFFSET)

/* Map / unmap a physical region into this process via /dev/mem. */
void *fpga_mmap(uint32_t phys_addr, uint32_t size);
void  fpga_munmap(void *map, uint32_t size);

#endif /* FPGA_MEM_H */