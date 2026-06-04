#define _DEFAULT_SOURCE
#include <stdio.h>
#include <unistd.h>
#include "shared_protocol.h"
#include "fpga_mem.h"
#include "hps_fpga_comm.h"
#include "hps_audio_streamer.h"

#define DEFAULT_MUSIC_DIR "/mnt/music"
#define POLL_SLEEP_US     100u

int main(int argc, char *argv[])
{
    const char *music_dir = (argc > 1) ? argv[1] : DEFAULT_MUSIC_DIR;

    /* retries internally until the bridge is up -> daemon-safe */
    if (hps_fpga_init(SHARED_AUDIO_MEM_PHYS, sizeof(shared_audio_mem_t)) != 0)
        return 1;

    volatile shared_audio_mem_t *shared = hps_fpga_get_shared();
    if (!shared) { hps_fpga_close(); return 1; }

    hps_stream_init_shared(shared);

    if (hps_stream_load_playlist(shared, music_dir) != 0) {
        printf("[HPS] no songs in %s (will still serve events)\n", music_dir);
    }
    printf("[HPS] streamer up. songs=%u dir=%s\n", shared->song_count, music_dir);

    for (;;) {
        hps_stream_handle_nios_events(shared);   /* react to Nios requests */
        hps_stream_try_fill_next_buffer(shared); /* top up one empty buffer */
        usleep(POLL_SLEEP_US);
    }

    hps_fpga_close();   /* unreached */
    return 0;
}