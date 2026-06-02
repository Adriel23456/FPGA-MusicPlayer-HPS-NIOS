#define _DEFAULT_SOURCE
#include "hps_audio_streamer.h"
#include "wav_reader.h"
#include <stdio.h>
#include <string.h>
#include <dirent.h>

static char     g_paths[MAX_SONGS][512];
static unsigned g_song_count = 0;
static unsigned g_cur_song   = 0;

static wav_info_t g_wav;          /* currently open song */
static int        g_wav_open = 0;
static unsigned   g_next_fill = 0; /* next buffer index HPS will fill (RR) */

static int has_wav_ext(const char *name)
{
    size_t n = strlen(name);
    return (n > 4 && (strcmp(name + n - 4, ".wav") == 0 ||
                      strcmp(name + n - 4, ".WAV") == 0));
}

void hps_stream_init_shared(volatile shared_audio_mem_t *m)
{
    m->nios_event_flags = NIOS_EVENT_NONE;
    m->nios_arg         = 0;
    m->hps_event_ack    = HPS_ACK_NONE;
    m->song_count       = 0;
    for (unsigned i = 0; i < NUM_BUFFERS; i++) {
        m->buffers[i].state = BUF_EMPTY;
        m->buffers[i].flags = BUF_FLAG_NONE;
        m->buffers[i].size_bytes = 0;
    }
}

int hps_stream_load_playlist(volatile shared_audio_mem_t *m, const char *dir)
{
    DIR *d = opendir(dir);
    if (!d) { perror("opendir"); return -1; }

    g_song_count = 0;
    struct dirent *e;
    while ((e = readdir(d)) && g_song_count < MAX_SONGS) {
        if (has_wav_ext(e->d_name)) {
            snprintf(g_paths[g_song_count], sizeof(g_paths[0]),
                     "%s/%s", dir, e->d_name);
            g_song_count++;
        }
    }
    closedir(d);

    m->song_count = g_song_count;
    return (g_song_count > 0) ? 0 : -1;
}

/* push current song's metadata into shared memory */
static void publish_meta(volatile shared_audio_mem_t *m)
{
    /* volatile char arrays -> copy byte by byte */
    const char *t = g_wav.metadata.title;
    const char *a = g_wav.metadata.artist;
    const char *al = g_wav.metadata.album;
    for (unsigned i = 0; i < META_TEXT_MAX; i++) {
        m->current_meta.title[i]  = t[i];  if (!t[i])  break;
    }
    for (unsigned i = 0; i < META_TEXT_MAX; i++) {
        m->current_meta.artist[i] = a[i];  if (!a[i])  break;
    }
    for (unsigned i = 0; i < META_TEXT_MAX; i++) {
        m->current_meta.album[i]  = al[i]; if (!al[i]) break;
    }
    m->current_meta.duration_seconds = g_wav.duration_seconds;
    m->current_meta.sample_rate      = g_wav.sample_rate;
}

/* open song `idx`, reset buffers, fill all three from the start */
static int load_song(volatile shared_audio_mem_t *m, unsigned idx)
{
    if (idx >= g_song_count) idx = 0;
    if (g_wav_open) { wav_close(&g_wav); g_wav_open = 0; }

    if (wav_open(g_paths[idx], &g_wav) != 0) {
        printf("[HPS] failed to open %s\n", g_paths[idx]);
        return -1;
    }
    g_wav_open = 1;
    g_cur_song = idx;
    g_next_fill = 0;

    publish_meta(m);

    /* reset ring */
    for (unsigned i = 0; i < NUM_BUFFERS; i++) {
        m->buffers[i].state = BUF_EMPTY;
        m->buffers[i].flags = BUF_FLAG_NONE;
        m->buffers[i].size_bytes = 0;
    }
    /* prime-fill all three buffers (initial / new song) */
    for (unsigned i = 0; i < NUM_BUFFERS; i++)
        hps_stream_try_fill_next_buffer(m);

    return 0;
}

/* fill ONE empty buffer (round-robin) with the next raw PCM chunk */
void hps_stream_try_fill_next_buffer(volatile shared_audio_mem_t *m)
{
    if (!g_wav_open) return;

    unsigned idx = g_next_fill;
    if (m->buffers[idx].state != BUF_EMPTY) return;   /* not free yet */

    if (g_wav.bytes_remaining == 0) return;           /* song fully read */

    m->buffers[idx].state = BUF_FILLING;

    uint32_t got = 0; int is_last = 0;
    /* RAW copy: wav_read_pcm_chunk does fread straight into shared mem.
       No transformation -- per the hard requirement. */
    if (wav_read_pcm_chunk(&g_wav, m->audio_data[idx], AUDIO_BUF_SIZE,
                           &got, &is_last) != 0) {
        m->buffers[idx].state = BUF_EMPTY;
        return;
    }

    m->buffers[idx].size_bytes = got;
    m->buffers[idx].flags = is_last ? BUF_FLAG_LAST : BUF_FLAG_NONE;
    m->buffers[idx].state = BUF_READY;

    g_next_fill = (g_next_fill + 1) % NUM_BUFFERS;     /* advance RR */
}

void hps_stream_handle_nios_events(volatile shared_audio_mem_t *m)
{
    uint32_t ev = m->nios_event_flags;
    if (ev == NIOS_EVENT_NONE) {
        if (m->hps_event_ack != HPS_ACK_NONE) m->hps_event_ack = HPS_ACK_NONE;
        return;
    }
    if (m->hps_event_ack != HPS_ACK_NONE) return;

    if (ev & NIOS_EVENT_INITIAL) {
        load_song(m, 0);
        m->song_count = g_song_count;
    } else if (ev & NIOS_EVENT_NEW_SONG) {
        load_song(m, m->nios_arg);
    }
    /* BUF_EMPTY no longer uses the event channel -- buffers are refilled
       by the round-robin top-up pass based on state alone. */

    m->hps_event_ack = ev;
}