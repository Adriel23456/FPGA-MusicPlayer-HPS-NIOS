#include "real_hps.h"

/* The Nios data master sees the shared RAM at this address. It is the SAME
 * physical memory the HPS maps at SHARED_AUDIO_MEM_PHYS.
 *
 * RAM is 0x8000-0xFFFF (32 KB). The shared region occupies the top 8 KB,
 * so its base is 0x8000 + 0x6000 = 0xE000. */
#define NIOS_SHARED_BASE  0x0000E000u

shared_audio_mem_t *hps_shared(void)
{
    return (shared_audio_mem_t *)NIOS_SHARED_BASE;
}

unsigned hps_song_count(void)
{
    return (unsigned)hps_shared()->song_count;
}

/* Map a source sample rate in Hz to the engine rate enum. Only 44.1k, 16k and
 * 8k are supported; anything else falls back to 44.1k. */
audio_rate_t hps_rate_from_hz(uint32_t hz)
{
    switch (hz) {
        case SR_8000:  return RATE_8K;
        case SR_16000: return RATE_16K;
        case SR_44100: return RATE_44K1;
        default:       return RATE_44K1;   /* safe default */
    }
}

/* copy a volatile char[] field out of shared memory into a plain buffer */
static void copy_meta_field(char *dst, const volatile char *src)
{
    unsigned i;
    for (i = 0; i < META_TEXT_MAX - 1u; i++) {
        char c = src[i];
        dst[i] = c;
        if (c == '\0') break;
    }
    dst[i] = '\0';
}

void hps_current_meta(song_meta_t *out)
{
    shared_audio_mem_t *m = hps_shared();

    copy_meta_field(out->name,   m->current_meta.title);
    copy_meta_field(out->artist, m->current_meta.artist);
    copy_meta_field(out->album,  m->current_meta.album);
    out->duration_sec = (unsigned)m->current_meta.duration_seconds;
}