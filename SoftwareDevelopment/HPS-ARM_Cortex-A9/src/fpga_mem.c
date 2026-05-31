/* src/main.c */
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <unistd.h>
#include "fpga_mem.h"

void *fpga_mmap (uint32_t phys_addr, uint32_t size){
    int fd;
    void *map;
    
    fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0){
        perror("open /dev/mem");
        return NULL;
    }

    map = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, phys_addr);

    close(fd);

    if(map == MAP_FAILED){
        perror("mmap");
        return NULL;
    }

    return map;
}

void fpga_munmap(void *map, uint32_t size)
{
    if (map != NULL) {
        munmap(map, size);
    }
}