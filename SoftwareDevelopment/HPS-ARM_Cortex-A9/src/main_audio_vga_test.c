#define _FILE_OFFSET_BITS 64

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <unistd.h>
#include <inttypes.h>
#include "fpga_mem.h"


void *fpga_mmap(uintptr_t phys_addr, size_t size) {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open /dev/mem"); return NULL; }
    void *map = mmap(NULL, size, PROT_READ | PROT_WRITE,
                     MAP_SHARED, fd, (off_t)phys_addr);
    close(fd);
    if (map == MAP_FAILED) { perror("mmap"); return NULL; }
    return map;
}

void fpga_munmap(void *map, size_t size) {
    munmap(map, size);
}

int main(void) {
    printf("=== HPS-to-FPGA RAM Test ===\n");
    printf("Physical address: 0x%08" PRIXPTR "\n", (uintptr_t)RAM_S1_PHYS);
    printf("Size:             0x%08zX (%zu KB)\n\n",
           (size_t)RAM_S1_SIZE,
           (size_t)RAM_S1_SIZE / 1024u);

    volatile uint32_t *mem = fpga_mmap(RAM_S1_PHYS, RAM_S1_SIZE);
    if (!mem) return 1;

    /* Read initial value */
    printf("Read  [0x00]: 0x%08X\n", mem[0]);

    /* Write test pattern */
    mem[0] = 0xDEADBEEF;
    mem[1] = 0xCAFEBABE;
    mem[2] = 0x12345678;

    /* Read back */
    printf("Write [0x00]: 0xDEADBEEF  ->  Read: 0x%08X  %s\n",
           mem[0], mem[0] == 0xDEADBEEF ? "OK" : "FAIL");
    printf("Write [0x04]: 0xCAFEBABE  ->  Read: 0x%08X  %s\n",
           mem[1], mem[1] == 0xCAFEBABE ? "OK" : "FAIL");
    printf("Write [0x08]: 0x12345678  ->  Read: 0x%08X  %s\n",
           mem[2], mem[2] == 0x12345678 ? "OK" : "FAIL");

    /* Clear */
    mem[0] = 0x00000000;
    mem[1] = 0x00000000;
    mem[2] = 0x00000000;
    printf("\nCleared. Read back [0x00]: 0x%08X\n", mem[0]);

    fpga_munmap((void *)mem, RAM_S1_SIZE);
    printf("\nDone.\n");
    return 0;
}
