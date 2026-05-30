#ifndef DUMMY_HPS_H
#define DUMMY_HPS_H

#include <stdint.h>
#include "shared_protocol.h"
#include "audio_driver.h"

/* Song metadata the "HPS" exposes alongside the audio buffers. The real HPS
 * will provide this through shared memory too; here it's baked in. */
typedef struct {
    const char *name;
    const char *artist;
    const char *album;
    unsigned    duration_sec;
    unsigned    tone_hz;       /* dummy: each song is a distinct tone */
    audio_rate_t rate;         /* dummy: source rate for the tone     */
} song_meta_t;

/* Pointer to the shared region. Dummy: points at a local struct.
 * Real HPS: repoint this at the H2F-bridge-mapped address. */
shared_audio_mem_t *hps_shared(void);

/* Total songs the HPS reports available. */
unsigned hps_song_count(void);

/* Metadata for song index (0-based). */
const song_meta_t *hps_song_meta(unsigned index);

/* --- Dummy HPS "service": call once per main-loop pass. It watches
 * nios_event_flags, "loads" the requested song into the buffers, and writes
 * hps_event_ack -- emulating the real HPS reacting over the bridge. ---- */
void hps_init(void);
void hps_service(void);

#endif /* DUMMY_HPS_H */