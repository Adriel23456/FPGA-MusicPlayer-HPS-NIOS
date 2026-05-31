#define _DEFAULT_SOURCE

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>

#include "shared_protocol.h"
#include "fpga_mem.h"
#include "hps_fpga_comm.h"
#include "hps_audio_streamer.h"

#define DEFAULT_MUSIC_DIR "/mnt/music"
#define POLL_SLEEP_US 1000u

int main(int argc, char *argv[])
{
    volatile shared_audio_mem_t *shared;
    const char *music_dir = DEFAULT_MUSIC_DIR;

    if (argc > 1) {
        music_dir = argv[1];
    }

    if (hps_fpga_init(RAM_S1_PHYS, sizeof(shared_audio_mem_t)) != 0) {
        printf("ERROR: hps_fpga_init failed.\n");
        return 1;
    }

    shared = hps_fpga_get_shared();

    if (shared == 0) {
        printf("ERROR: shared memory pointer is NULL.\n");
        hps_fpga_close();
        return 1;
    }

    hps_stream_init_shared(shared);

    if (hps_stream_load_playlist(shared, music_dir) != 0) {
        printf("ERROR: Failed to load playlist from %s\n", music_dir);
        hps_fpga_close();
        return 1;
    }

    printf("HPS music streamer started.\n");
    printf("Music directory: %s\n", music_dir);
    printf("Detected songs: %u\n", shared->song_count);

    while (1) {
        hps_stream_handle_nios_events(shared);
        hps_stream_try_fill_next_buffer(shared);

        usleep(POLL_SLEEP_US);
    }

    hps_fpga_close();
    return 0;
}
