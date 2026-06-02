#ifndef HPS_AUDIO_STREAMER_H
#define HPS_AUDIO_STREAMER_H
#include "shared_protocol.h"

void hps_stream_init_shared(volatile shared_audio_mem_t *shared);
int  hps_stream_load_playlist(volatile shared_audio_mem_t *shared, const char *dir);

/* one poll-loop pass: handle a pending Nios event, then top up buffers */
void hps_stream_handle_nios_events(volatile shared_audio_mem_t *shared);
void hps_stream_try_fill_next_buffer(volatile shared_audio_mem_t *shared);
#endif