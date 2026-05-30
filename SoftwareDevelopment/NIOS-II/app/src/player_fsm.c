#include "player_fsm.h"
#include "dummy_hps.h"
#include "audio_driver.h"
#include "vga_driver.h"
#include "timer_driver.h"
#include "debug_uart.h"
#include "shared_protocol.h"

static player_state_t g_state;
static unsigned       g_song;          /* current 0-based index */
static unsigned       g_count;         /* total songs */
static unsigned       g_consume_idx;   /* next buffer to consume (circular) */
static int            g_last_seen;     /* saw BUF_FLAG_LAST on consumed buf */

/* ---- helpers ---- */
static void show_meta(unsigned idx)
{
    const song_meta_t *s = hps_song_meta(idx);
    vga_set_song_name(s->name);
    vga_set_artist(s->artist);
    vga_set_album(s->album);
    vga_set_duration(s->duration_sec);
    vga_set_track(idx + 1, g_count);
}

/* fire an event to the HPS and wait for ACK (handshake), then clear */
static void hps_event(uint32_t ev)
{
    shared_audio_mem_t *m = hps_shared();
    m->nios_event_flags = ev;
    while ((m->hps_event_ack & ev) == 0)   /* busy-wait ACK */
        hps_service();                     /* dummy: drive the HPS to respond */
    m->nios_event_flags = NIOS_EVENT_NONE; /* clear -> HPS clears ack */
    hps_service();
}

/* consume exactly one READY buffer into the audio path. returns 1 if it had
   BUF_FLAG_LAST (song finished), 0 otherwise, -1 if nothing ready. */
static int consume_one_buffer(void)
{
    shared_audio_mem_t *m = hps_shared();
    audio_buffer_desc_t *d = &m->buffers[g_consume_idx];

    if (d->state != BUF_READY) return -1;        /* nothing to play yet */

    d->state = BUF_CONSUMING;                    /* READY->CONSUMING */
    unsigned bytes  = d->size_bytes;
    unsigned frames = bytes / 4;                 /* 16-bit stereo */
    int16_t *pcm    = (int16_t *)m->audio_data[g_consume_idx];

    /* play this slice. (Engine takes mono; we feed L channel as the source
       and let it drive both outputs. For the dummy L==R.) */
    /* Build a mono view: reuse L samples. */
    /* NOTE: audio_play_buffer plays mono->stereo; here we pass interleaved
       L by stride. Simplest: play frames of the L channel. */
    static int16_t mono[AUDIO_BUF_SIZE/4];
    for (unsigned f = 0; f < frames; f++) mono[f] = pcm[2*f];
    audio_play_buffer(mono, frames, RATE_48K, 0); /* already at hw rate */

    int last = (d->flags & BUF_FLAG_LAST) ? 1 : 0;
    d->state = BUF_EMPTY;                         /* CONSUMING->EMPTY */
    g_consume_idx = (g_consume_idx + 1) % NUM_BUFFERS;
    return last;
}

/* ---- lifecycle ---- */
void player_init(void)
{
    dbg_puts("[PLAYER] init (step 1: stopped, song 1)\r\n");

    hps_init();
    g_count       = hps_song_count();
    g_song        = 0;
    g_consume_idx = 0;
    g_last_seen   = 0;
    g_state       = ST_STOPPED;

    /* step 1: ask HPS for song 1 (RESTART loads current=0 from start) */
    hps_event(NIOS_EVENT_RESTART);

    /* step 2: update all metadata, state stopped, timer reset+pause */
    show_meta(g_song);
    vga_set_state("stopped");
    timer_reset();   /* reset & pause per timer driver */
}

void player_reset(void)
{
    dbg_puts("[PLAYER] reset -> redo from step 1\r\n");
    player_init();
}

/* ---- actions (interrupts are ignored by caller while these run) ---- */
void player_play_pause(void)
{
    if (g_state == ST_PLAYING) {
        dbg_puts("[PLAYER] pause\r\n");
        g_state = ST_PAUSED;          /* stop feeding -> position retained */
        vga_set_state("paused");
        timer_pause();
    } else { /* PAUSED or STOPPED -> resume/start */
        dbg_puts("[PLAYER] play/resume\r\n");
        g_state = ST_PLAYING;
        vga_set_state("playing");
        timer_resume();
        /* playback continues from g_consume_idx where we left off */
    }
}

void player_next(void)
{
    dbg_puts("[PLAYER] next\r\n");
    timer_reset();
    g_song = (g_song + 1) % g_count;
    hps_event(NIOS_EVENT_NEXT_SONG);
    g_consume_idx = 0; g_last_seen = 0;
    show_meta(g_song);
    g_state = ST_PLAYING;
    vga_set_state("playing");
    timer_resume();                   /* the moment playback (re)begins */
}

void player_prev(void)
{
    dbg_puts("[PLAYER] prev\r\n");
    timer_reset();
    g_song = (g_song + g_count - 1) % g_count;
    hps_event(NIOS_EVENT_PREV_SONG);
    g_consume_idx = 0; g_last_seen = 0;
    show_meta(g_song);                /* update display AFTER handshake */
    g_state = ST_PLAYING;
    vga_set_state("playing");
    timer_resume();
}

void player_stop(void)
{
    dbg_puts("[PLAYER] stop\r\n");
    /* stop feeding, reload current song from start, stay paused at beginning */
    hps_event(NIOS_EVENT_RESTART);
    g_consume_idx = 0; g_last_seen = 0;
    timer_reset();
    g_state = ST_STOPPED;
    vga_set_state("stopped");
}

/* ---- per-loop service: only feeds audio while PLAYING ---- */
void player_service(void)
{
    hps_service();   /* let the dummy HPS keep buffers filled */

    if (g_state != ST_PLAYING) return;

    int r = consume_one_buffer();
    if (r == 1) {
        /* BUF_FLAG_LAST consumed -> song ended -> auto-advance (== next) */
        dbg_puts("[PLAYER] song ended -> auto next\r\n");
        player_next();
    }
    /* r == -1 (no buffer ready yet) just means wait; loop will retry */
}