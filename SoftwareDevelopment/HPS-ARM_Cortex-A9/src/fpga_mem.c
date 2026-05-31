#define _FILE_OFFSET_BITS 64

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <unistd.h>
#include <inttypes.h>
#include "fpga_mem.h"

void *fpga_mmap(uintptr_t phys_addr, size_t size){
    int fd;
    void *map;
    long page_size;

    if (size == 0u) {
        fprintf(stderr, "fpga_mmap: size must be nonzero\n");
        return NULL;
    }

    page_size = sysconf(_SC_PAGESIZE);

    if (page_size <= 0) {
        perror("sysconf(_SC_PAGESIZE)");
        return NULL;
    }

    if ((phys_addr % (uintptr_t)page_size) != 0u) {
        fprintf(stderr,
                "fpga_mmap: physical address 0x%08" PRIXPTR
                " is not page-aligned to %ld bytes\n",
                phys_addr,
                page_size);
        return NULL;
    }
    
    fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0){
        perror("open /dev/mem");
        return NULL;
    }

    map = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, (off_t)phys_addr);

    close(fd);

    if(map == MAP_FAILED){
        perror("mmap");
        return NULL;
    }

    return map;
}

void fpga_munmap(void *map, size_t size)
{
    if (map != NULL && size != 0u) {
        munmap(map, size);
    }
}
