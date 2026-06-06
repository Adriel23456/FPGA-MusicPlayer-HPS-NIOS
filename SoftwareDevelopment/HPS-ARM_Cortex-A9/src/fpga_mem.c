#include "fpga_mem.h"
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

void *fpga_mmap(uint32_t phys_addr, uint32_t size)
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) return NULL;

    void *map = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, phys_addr);
    close(fd);

    return (map == MAP_FAILED) ? NULL : map;
}

void fpga_munmap(void *map, uint32_t size)
{
    munmap(map, size);
}