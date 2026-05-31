#include "hps_fpga_comm.h"
#include "fpga_mem.h"

#ifdef USE_FAKE_SHARED_MEM

static shared_audio_mem_t fake_shared;

int hps_fpga_init(uintptr_t phys_base, size_t map_size)
{
    (void)phys_base;
    (void)map_size;

    return 0;
}

void hps_fpga_close(void)
{
}

volatile shared_audio_mem_t *hps_fpga_get_shared(void)
{
    return &fake_shared;
}

#else

static size_t mapped_size = 0;
static volatile shared_audio_mem_t *shared_ptr = 0;

int hps_fpga_init(uintptr_t phys_base, size_t map_size)
{
    void *mapped_addr;

    if (map_size == 0){
        return -1;
    }

    mapped_addr = fpga_mmap(phys_base, map_size);

    if(mapped_addr == NULL){
        return -1;
    }

    shared_ptr = (volatile shared_audio_mem_t*) mapped_addr;
    mapped_size = map_size;

    return 0;
}

void hps_fpga_close(void)
{
    if(shared_ptr != 0){
        fpga_munmap((void *)shared_ptr, mapped_size);
        shared_ptr = 0;
        mapped_size = 0;
    }
}

volatile shared_audio_mem_t *hps_fpga_get_shared(void)
{
    return shared_ptr;
}

#endif
