#ifndef REAL_HPS_H
#define REAL_HPS_H

#include <stdint.h>
#include "shared_protocol.h"
#include "audio_driver.h"

/* Metadata view returned to the player. Filled from shared->current_meta,
 * which the real HPS publishes over the H2F bridge. */
typedef struct {
    char     name[META_TEXT_MAX];
    char     artist[META_TEXT_MAX];
    char     album[META_TEXT_MAX];
    unsigned duration_sec;
} song_meta_t;

/* Pointer to the shared region (same physical RAM the HPS maps at
 * SHARED_AUDIO_MEM_PHYS). */
shared_audio_mem_t *hps_shared(void);

/* Total songs the HPS reports (read from shared memory). */
unsigned hps_song_count(void);

/* Snapshot the current song's metadata from shared memory into `out`. */
void hps_current_meta(song_meta_t *out);

/* Map Hz -> engine rate enum. */
audio_rate_t hps_rate_from_hz(uint32_t hz);

#endif /* REAL_HPS_H */