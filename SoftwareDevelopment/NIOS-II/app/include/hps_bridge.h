#ifndef HPS_BRIDGE_H
#define HPS_BRIDGE_H

#include <stdint.h>
#include "shared_protocol.h"
#include "audio_driver.h"

/* Song metadata cached from the HPS-owned shared memory. */
typedef struct {
    const char *name;
    const char *artist;
    const char *album;
    unsigned    duration_sec;
    unsigned    tone_hz;       /* unused by the real HPS bridge */
    audio_rate_t rate;         /* source PCM rate reported by HPS */
} hps_song_meta_t;

/*
 * Nios-side bridge to the HPS-owned shared-memory protocol.
 * The Linux HPS process initializes metadata, fills audio buffers, and ACKs
 * events. Nios II reads/updates the same memory through these helpers.
 */
shared_audio_mem_t *hps_bridge_shared(void);

/* Total songs the HPS reports available. */
unsigned hps_bridge_song_count(void);

/* Metadata for song index (0-based). */
const hps_song_meta_t *hps_bridge_song_meta(unsigned index);

void hps_bridge_init(void);

#endif /* HPS_BRIDGE_H */
