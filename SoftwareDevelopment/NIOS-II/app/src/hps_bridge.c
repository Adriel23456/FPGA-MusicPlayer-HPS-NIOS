#include "hps_bridge.h"
#include "debug_uart.h"
#include "system.h"

#include <stddef.h>

#define HPS_SHARED_ADDR ((uintptr_t)RAM_NIOS_II_BASE + \
                         (uintptr_t)SHARED_AUDIO_MEM_OFFSET)

static char g_title[META_TEXT_MAX];
static char g_artist[META_TEXT_MAX];
static char g_album[META_TEXT_MAX];

static hps_song_meta_t g_meta = {
    "No Song",
    "Unknown Artist",
    "Unknown Album",
    0u,
    0u,
    RATE_48K
};

static void reset_cached_metadata(void)
{
    g_title[0] = '\0';
    g_artist[0] = '\0';
    g_album[0] = '\0';

    g_meta.name = "No Song";
    g_meta.artist = "Unknown Artist";
    g_meta.album = "Unknown Album";
    g_meta.duration_sec = 0u;
    g_meta.tone_hz = 0u;
    g_meta.rate = RATE_48K;
}

static void copy_shared_text(char *dst, size_t dst_size, volatile const char *src)
{
    size_t i;

    if (dst == 0 || dst_size == 0u || src == 0) {
        return;
    }

    for (i = 0u; i < dst_size - 1u && src[i] != '\0'; i++) {
        dst[i] = (char)src[i];
    }

    dst[i] = '\0';
}

static audio_rate_t sample_rate_to_enum(uint32_t sample_rate)
{
    if (sample_rate == 44100u) {
        return RATE_44K1;
    }

    if (sample_rate == 16000u) {
        return RATE_16K;
    }

    if (sample_rate == 8000u) {
        return RATE_8K;
    }

    return RATE_48K;
}

static int hps_protocol_ready(volatile shared_audio_mem_t *m)
{
    return m != 0 &&
           m->protocol_magic == SHARED_PROTOCOL_MAGIC &&
           m->protocol_version == SHARED_PROTOCOL_VERSION;
}

shared_audio_mem_t *hps_bridge_shared(void)
{
    return (shared_audio_mem_t *)HPS_SHARED_ADDR;
}

unsigned hps_bridge_song_count(void)
{
    volatile shared_audio_mem_t *m = hps_bridge_shared();

    if (!hps_protocol_ready(m)) {
        return 0u;
    }

    return (unsigned)m->song_count;
}

const hps_song_meta_t *hps_bridge_song_meta(unsigned index)
{
    volatile shared_audio_mem_t *m = hps_bridge_shared();

    (void)index;

    if (!hps_protocol_ready(m) || m->current_metadata.valid == 0u) {
        g_meta.name = "No Song";
        g_meta.artist = "Unknown Artist";
        g_meta.album = "Unknown Album";
        g_meta.duration_sec = 0u;
        g_meta.rate = RATE_48K;
        return &g_meta;
    }

    copy_shared_text(g_title, sizeof(g_title), m->current_metadata.title);
    copy_shared_text(g_artist, sizeof(g_artist), m->current_metadata.artist);
    copy_shared_text(g_album, sizeof(g_album), m->current_metadata.album);

    g_meta.name = g_title;
    g_meta.artist = g_artist;
    g_meta.album = g_album;
    g_meta.duration_sec = (unsigned)m->current_metadata.duration_seconds;
    g_meta.rate = sample_rate_to_enum(m->current_metadata.sample_rate_hz);

    return &g_meta;
}

void hps_bridge_init(void)
{
    volatile shared_audio_mem_t *m = hps_bridge_shared();

    reset_cached_metadata();

    if (hps_protocol_ready(m)) {
        m->nios_event_flags = NIOS_EVENT_NONE;
    }

    dbg_puts("[HPS] shared-memory bridge selected\r\n");
}
