/* include/fpga_mem.h */
#ifndef FPGA_MEM_H
#define FPGA_MEM_H

#include <stddef.h>
#include <stdint.h>
#include "../../common/include/shared_protocol.h"

/* Full HPS-to-FPGA AXI bridge base: FPGA slaves region */
#define H2F_AXI_BASE     0xC0000000UL

/* RAM_NIOS_II.s1 offset from address map:
   0x0004_0000 - 0x0007_FFFF on h2f_axi_master */
#define RAM_S1_OFFSET    0x00040000UL
#define RAM_S1_SIZE      0x00040000UL  /* 256 KB */

#define RAM_S1_PHYS      (H2F_AXI_BASE + RAM_S1_OFFSET)
#define SHARED_AUDIO_MEM_PHYS (RAM_S1_PHYS + SHARED_AUDIO_MEM_OFFSET)

void *fpga_mmap(uintptr_t phys_addr, size_t size);
void  fpga_munmap(void *map, size_t size);

#endif /* FPGA_MEM_H */
