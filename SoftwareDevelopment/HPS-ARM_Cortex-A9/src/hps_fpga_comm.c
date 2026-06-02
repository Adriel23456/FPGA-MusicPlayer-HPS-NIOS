#include "hps_fpga_comm.h"
#include "fpga_mem.h"
#include <stdio.h>
#include <unistd.h>

static volatile shared_audio_mem_t *g_shared = 0;
static void    *g_map  = 0;
static uint32_t g_size = 0;

#define RETRY_SLEEP_US   500000u   /* 0.5 s between attempts */

int hps_fpga_init(uint32_t phys_addr, uint32_t size)
{
    g_size = size;
    unsigned attempt = 0;

    /* Retry forever: as a boot daemon we may start before the FPGA is
       programmed / the bridge is up. Never crash -- just keep trying. */
    for (;;) {
        void *map = fpga_mmap(phys_addr, size);
        if (map) {
            g_map = map;
            g_shared = (volatile shared_audio_mem_t *)map;
            printf("[HPS] shared mem mapped at 0x%08X (attempt %u)\n",
                   phys_addr, attempt + 1);
            return 0;
        }
        attempt++;
        printf("[HPS] mmap failed (attempt %u), retrying in 0.5s...\n", attempt);
        usleep(RETRY_SLEEP_US);
    }
}

volatile shared_audio_mem_t *hps_fpga_get_shared(void) { return g_shared; }

void hps_fpga_close(void)
{
    if (g_map) { fpga_munmap(g_map, g_size); g_map = 0; g_shared = 0; }
}