#include "hps_fpga_comm.h"
#include "fpga_mem.h"
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <setjmp.h>

static volatile shared_audio_mem_t *g_shared = 0;
static void    *g_map  = 0;
static uint32_t g_size = 0;

#define RETRY_SLEEP_US   500000u
#define MAX_RETRIES      20u

/* Shared with main.c so the poll loop can recover from a bus fault. */
volatile sig_atomic_t g_bus_fault = 0;
sigjmp_buf            g_bus_jmp;

static void bus_handler(int sig)
{
    (void)sig;
    g_bus_fault = 1;
    siglongjmp(g_bus_jmp, 1);
}

/* Touch the mapping once under a temporary SIGBUS handler: a valid pointer
 * can still fault if the H2F bridge is not up yet. */
static int probe_shared(volatile shared_audio_mem_t *m)
{
    struct sigaction sa = {0}, old;
    sa.sa_handler = bus_handler;
    sigaction(SIGBUS, &sa, &old);

    g_bus_fault = 0;
    uint32_t dummy = 0;
    if (sigsetjmp(g_bus_jmp, 1) == 0)
        dummy = m->nios_event_flags;
    (void)dummy;

    sigaction(SIGBUS, &old, NULL);
    return g_bus_fault ? -1 : 0;
}

int hps_fpga_init(uint32_t phys_addr, uint32_t size)
{
    g_size = size;

    for (unsigned attempt = 0; attempt < MAX_RETRIES; attempt++) {
        void *map = fpga_mmap(phys_addr, size);
        if (map) {
            g_map    = map;
            g_shared = (volatile shared_audio_mem_t *)map;
            if (probe_shared(g_shared) == 0)
                return 0;

            /* pointer valid but bus faults on access -> bridge not ready */
            fpga_munmap(map, size);
            g_map    = 0;
            g_shared = 0;
        }
        usleep(RETRY_SLEEP_US);
    }

    fprintf(stderr, "[HPS] bridge never came up after %u attempts\n", MAX_RETRIES);
    return -1;
}

volatile shared_audio_mem_t *hps_fpga_get_shared(void)
{
    return g_shared;
}

void hps_fpga_close(void)
{
    if (g_map) {
        fpga_munmap(g_map, g_size);
        g_map    = 0;
        g_shared = 0;
    }
}