#include "dummy_hps.h"
#include "audio_driver.h"
#include "debug_uart.h"
#include <string.h>

/* The shared region. DUMMY: a normal global in Nios RAM.
 * REAL HPS: delete this and make hps_shared() return the bridge address. */
static shared_audio_mem_t g_shared;

shared_audio_mem_t *hps_shared(void) { return &g_shared; }

/* --- three dummy songs, each a distinct tone at a distinct rate --- */
static const song_meta_t SONGS[3] = {
    { "Tone A 440",  "Dummy Artist 1", "Album One",   10, 440, RATE_48K  },
    { "Tone B 660",  "Dummy Artist 2", "Album Two",    8, 660, RATE_16K  },
    { "Tone C 330",  "Dummy Artist 3", "Album Three", 12, 330, RATE_8K   },
};

unsigned hps_song_count(void) { return 3; }

const song_meta_t *hps_song_meta(unsigned index)
{
    if (index >= 3) index = 0;
    return &SONGS[index];
}

/* dummy fill: which song the HPS is currently serving, and how far in */
static unsigned g_cur_song   = 0;
static unsigned g_fill_chunk = 0;     /* how many buffers of this song filled */
static unsigned g_total_chunks = 0;   /* total buffers this song will produce */

/* generate one buffer's worth of the current song's tone into a descriptor */
static void fill_one_buffer(unsigned buf_idx, int is_last)
{
    shared_audio_mem_t *m = &g_shared;
    unsigned frames = AUDIO_BUF_SIZE / 4;
    int16_t *pcm    = (int16_t *)m->audio_data[buf_idx];

    static uint32_t phase;
    const song_meta_t *s = &SONGS[g_cur_song];
    unsigned src_rate = AUDIO_HW_RATE_HZ / ((unsigned)s->rate / 1u); /* see note */
    /* generate a plain tone; exact pitch is irrelevant for the timer test */
    uint32_t inc = ((uint64_t)s->tone_hz * 65536u) / AUDIO_HW_RATE_HZ;
    for (unsigned f = 0; f < frames; f++) {
        int16_t v = ((phase >> 16) & 1) ? 12000 : -12000;
        pcm[2*f + 0] = v;
        pcm[2*f + 1] = v;
        phase += inc;
    }

    m->buffers[buf_idx].size_bytes = frames * 4;
    m->buffers[buf_idx].flags = is_last ? BUF_FLAG_LAST : BUF_FLAG_NONE;
    m->buffers[buf_idx].state = BUF_READY;
}

/* (re)start serving a song from buffer 0 */
static void start_song(unsigned song)
{
    shared_audio_mem_t *m = &g_shared;
    g_cur_song   = song % 3;
    g_fill_chunk = 0;

    unsigned frames_per_buf = AUDIO_BUF_SIZE / 4;
    unsigned bufs_per_sec   = AUDIO_HW_RATE_HZ / frames_per_buf;
    unsigned secs           = SONGS[g_cur_song].duration_sec;
    g_total_chunks = secs * bufs_per_sec;
    if (g_total_chunks == 0) g_total_chunks = 1;

    /* DEBUG: prove this code is live and show the computed count */
    dbg_puts("[HPS] start_song chunks=");
    {
        char b[8]; int n=0; unsigned v=g_total_chunks;
        char t[8]; int ti=0;
        if(!v) t[ti++]='0';
        while(v){ t[ti++]='0'+(v%10); v/=10; }
        while(ti) b[n++]=t[--ti];
        b[n]='\0'; dbg_puts(b);
    }
    dbg_puts("\r\n");

    for (unsigned i = 0; i < NUM_BUFFERS; i++) {
        m->buffers[i].state = BUF_EMPTY;
        m->buffers[i].flags = BUF_FLAG_NONE;
        m->buffers[i].size_bytes = 0;
    }
}

void hps_init(void)
{
    dbg_puts("[HPS] dummy init\r\n");
    memset(&g_shared, 0, sizeof(g_shared));
    g_shared.nios_event_flags = NIOS_EVENT_NONE;
    g_shared.hps_event_ack    = HPS_ACK_NONE;
    start_song(0);
}

/* Emulate the HPS: react to events, keep EMPTY buffers filled until LAST. */
void hps_service(void)
{
    shared_audio_mem_t *m = &g_shared;

    /* 1) handle a pending Nios event (song change / restart) */
    uint32_t ev = m->nios_event_flags;
    if (ev != NIOS_EVENT_NONE && m->hps_event_ack == HPS_ACK_NONE) {
        if      (ev & NIOS_EVENT_NEXT_SONG) start_song(g_cur_song + 1);
        else if (ev & NIOS_EVENT_PREV_SONG) start_song(g_cur_song + 2); /* -1 mod 3 */
        else if (ev & NIOS_EVENT_RESTART)   start_song(g_cur_song);
        m->hps_event_ack = ev;       /* ACK the same bit */
    }
    if (ev == NIOS_EVENT_NONE) {
        m->hps_event_ack = HPS_ACK_NONE;   /* clear ack once Nios cleared event */
    }

    /* 2) keep buffers filled while song not fully produced */
    if (g_fill_chunk < g_total_chunks) {
        for (unsigned i = 0; i < NUM_BUFFERS; i++) {
            if (m->buffers[i].state == BUF_EMPTY) {
                m->buffers[i].state = BUF_FILLING;
                int is_last = (g_fill_chunk + 1 >= g_total_chunks);
                fill_one_buffer(i, is_last);
                g_fill_chunk++;
                if (g_fill_chunk >= g_total_chunks) break;
            }
        }
    }
}