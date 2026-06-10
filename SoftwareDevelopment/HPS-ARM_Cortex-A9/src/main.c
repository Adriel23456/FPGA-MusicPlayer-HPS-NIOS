#define _DEFAULT_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <setjmp.h>
#include "shared_protocol.h"
#include "fpga_mem.h"
#include "hps_fpga_comm.h"
#include "hps_audio_streamer.h"

#define DEFAULT_MUSIC_DIR "/mnt/music"
#define POLL_SLEEP_US     1000u

/* defined in hps_fpga_comm.c */
extern volatile sig_atomic_t g_bus_fault;
extern sigjmp_buf            g_bus_jmp;

int main(int argc, char *argv[])
{
    const char *music_dir = (argc > 1) ? argv[1] : DEFAULT_MUSIC_DIR;

    if (hps_fpga_init(SHARED_AUDIO_MEM_PHYS, sizeof(shared_audio_mem_t)) != 0)
        return 1;

    volatile shared_audio_mem_t *shared = hps_fpga_get_shared();
    if (!shared) { hps_fpga_close(); return 1; }

    hps_stream_init_shared(shared);
    hps_stream_load_playlist(shared, music_dir);

    for (;;) {
        /* recover from a bus fault by remapping the shared region */
        if (sigsetjmp(g_bus_jmp, 1) != 0) {
            hps_fpga_close();
            if (hps_fpga_init(SHARED_AUDIO_MEM_PHYS, sizeof(shared_audio_mem_t)) != 0)
                return 1;
            shared = hps_fpga_get_shared();
            hps_stream_init_shared(shared);
            continue;
        }

        hps_stream_handle_nios_events(shared);
        hps_stream_try_fill_next_buffer(shared);
        usleep(POLL_SLEEP_US);
    }

    hps_fpga_close();
    return 0;
}