#include "player_fsm.h"
#include "real_hps.h"
#include "audio_driver.h"
#include "vga_driver.h"
#include "timer_driver.h"
#include "shared_protocol.h"

static player_state_t g_state;
static unsigned       g_song;          /* current 0-based index */
static unsigned       g_count;         /* total songs */
static unsigned       g_consume_idx;   /* next buffer to consume (round-robin) */

/* program the codec to the current song's native rate (called on load) */
static void apply_song_rate(void)
{
    shared_audio_mem_t *m = hps_shared();
    audio_prepare_rate(hps_rate_from_hz((uint32_t)m->current_meta.sample_rate));
}

/* ---- HPS handshake ----
 * Fire an event + arg, then busy-wait until the real HPS (running
 * autonomously on the ARM) echoes the bit into hps_event_ack. Then clear our
 * event and wait for the HPS to drop its ack. The HPS is a separate
 * processor, not something we drive. */
static void hps_event(uint32_t ev, uint32_t arg)
{
    shared_audio_mem_t *m = hps_shared();

    m->nios_arg         = arg;
    m->nios_event_flags = ev;

    while ((m->hps_event_ack & ev) == 0u)
        ;                                  /* wait for HPS to handle it */
    m->nios_event_flags = NIOS_EVENT_NONE; /* clear -> HPS clears its ack */
    while (m->hps_event_ack != HPS_ACK_NONE)
        ;
}

/* pull current metadata from shared mem onto the VGA */
static void show_meta(void)
{
    song_meta_t s;
    hps_current_meta(&s);
    vga_set_song_name(s.name);
    vga_set_artist(s.artist);
    vga_set_album(s.album);
    vga_set_duration(s.duration_sec);
    vga_set_track(g_song + 1, g_count);
}

/* ---- consume one READY buffer; signal HPS to refill it (round-robin) ----
 * Returns 1 if the consumed buffer had BUF_FLAG_LAST (song ended),
 * 0 if a normal buffer was played, -1 if nothing was ready yet.
 * Fire-and-forget, NO busy wait. */
static int consume_one_buffer(void)
{
    shared_audio_mem_t *m = hps_shared();
    volatile audio_buffer_desc_t *d = &m->buffers[g_consume_idx];

    if (d->state != BUF_READY) return -1;

    d->state = BUF_CONSUMING;

    unsigned frames = (unsigned)d->size_bytes / 4u;        /* 4 bytes / stereo frame */
    volatile int16_t *pcm = (volatile int16_t *)m->audio_data[g_consume_idx];

    /* native-rate, true-stereo playback (no fractional resample, no mono fold) */
    audio_play_stereo(pcm, frames);

    int last = (d->flags & BUF_FLAG_LAST) ? 1 : 0;
    d->state = BUF_EMPTY;

    g_consume_idx = (g_consume_idx + 1u) % NUM_BUFFERS;
    return last;
}

/* ---- lifecycle ---- */
void player_init(void)
{
    g_song        = 0;
    g_consume_idx = 0;
    g_state       = ST_STOPPED;

    /* Initial Info action: busy-waited. HPS reports song_count, publishes
     * song 0 metadata, and prime-fills all three buffers. */
    hps_event(NIOS_EVENT_INITIAL, 0);
    g_count = hps_song_count();
    apply_song_rate();

    show_meta();
    vga_set_state("stopped");
    timer_reset();                  /* reset & pause */
}

void player_reset(void)
{
    player_init();
}

/* ---- actions (other IRQs ignored by caller while these run) ---- */
void player_play_pause(void)
{
    if (g_state == ST_PLAYING) {
        g_state = ST_PAUSED;        /* stop feeding -> position retained */
        vga_set_state("paused");
        timer_pause();
    } else {
        g_state = ST_PLAYING;       /* resume from current g_consume_idx */
        vga_set_state("playing");
        timer_resume();
    }
}

void player_next(void)
{
    timer_reset();
    g_song = (g_song + 1u) % g_count;
    hps_event(NIOS_EVENT_NEW_SONG, g_song);   /* busy-waited: new song load */
    apply_song_rate();
    g_consume_idx = 0;
    show_meta();
    g_state = ST_PLAYING;
    vga_set_state("playing");
    timer_resume();
}

void player_prev(void)
{
    timer_reset();
    g_song = (g_song + g_count - 1u) % g_count;
    hps_event(NIOS_EVENT_NEW_SONG, g_song);
    apply_song_rate();
    g_consume_idx = 0;
    show_meta();                    /* update VGA AFTER the handshake */
    g_state = ST_PLAYING;
    vga_set_state("playing");
    timer_resume();
}

void player_stop(void)
{
    /* reload current song from start, but stay stopped at the beginning */
    hps_event(NIOS_EVENT_NEW_SONG, g_song);
    apply_song_rate();
    g_consume_idx = 0;
    timer_reset();
    g_state = ST_STOPPED;
    vga_set_state("stopped");
}

/* ---- per-loop service: only feeds audio while PLAYING ----
 * The HPS runs autonomously, so there is no hps_service() to call here. */
void player_service(void)
{
    if (g_state != ST_PLAYING) return;

    /* Play up to a few ready buffers back-to-back so the DAC FIFO never
     * starves between main-loop passes, but cap the batch so buttons still
     * get serviced promptly. */
    for (int i = 0; i < 2; i++) {
        int r = consume_one_buffer();
        if (r == 1) { player_next(); return; }   /* song ended -> auto next */
        if (r == -1) return;                      /* nothing ready -> let main loop run */
    }
}