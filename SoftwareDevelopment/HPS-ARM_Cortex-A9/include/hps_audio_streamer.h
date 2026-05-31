#ifndef HPS_AUDIO_STREAMER_H
#define HPS_AUDIO_STREAMER_H

#include "shared_protocol.h"

void hps_stream_init_shared(volatile shared_audio_mem_t *shared);

uint32_t hps_count_valid_songs(const char *music_dir);

int hps_stream_try_fill_next_buffer(volatile shared_audio_mem_t *shared);

void hps_stream_handle_nios_events(volatile shared_audio_mem_t *shared);

int hps_stream_start_wav_file(volatile shared_audio_mem_t *shared, const char *path);

int hps_stream_load_playlist(volatile shared_audio_mem_t *shared,
                             const char *music_dir);

#endif