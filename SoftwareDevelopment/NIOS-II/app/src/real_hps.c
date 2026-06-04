#include "real_hps.h"
#include "debug_uart.h"
#include <string.h>

/* The Nios data master sees the shared RAM at this address. It is the SAME
 * physical memory the HPS maps at SHARED_AUDIO_MEM_PHYS (0xC0040000). */
#define NIOS_SHARED_BASE  0x00078000u

shared_audio_mem_t *hps_shared(void)
{
    return (shared_audio_mem_t *)NIOS_SHARED_BASE;
}

unsigned hps_song_count(void)
{
    return (unsigned)hps_shared()->song_count;
}

audio_rate_t hps_rate_from_hz(uint32_t hz)
{
    switch (hz) {
        case SR_8000:  return RATE_8K;
        case SR_16000: return RATE_16K;
        case SR_44100: return RATE_44K1;
        case SR_48000: return RATE_48K;
        default:       return RATE_48K;   /* safe default */
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

    dbg_puts("[HPS] meta: ");
    dbg_puts(out->name);
    dbg_puts(" / ");
    dbg_puts(out->artist);
    dbg_puts("\r\n");
}