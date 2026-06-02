#include "player_fsm.h"
#include "real_hps.h"
#include "audio_driver.h"
#include "vga_driver.h"
#include "timer_driver.h"
#include "debug_uart.h"
#include "shared_protocol.h"

static player_state_t g_state;
static unsigned       g_song;          /* current 0-based index */
static unsigned       g_count;         /* total songs */
static unsigned       g_consume_idx;   /* next buffer to consume (round-robin) */

/* ---- small UART helper: print "[tag] label=<n>" ---- */
static void dbg_num(const char *prefix, unsigned v)
{
    char t[12]; int ti = 0;
    char b[12]; int n = 0;
    dbg_puts(prefix);
    if (v == 0) { t[ti++] = '0'; }
    while (v) { t[ti++] = (char)('0' + (v % 10u)); v /= 10u; }
    while (ti) b[n++] = t[--ti];
    b[n] = '\0';
    dbg_puts(b);
    dbg_puts("\r\n");
}

/* ---- HPS handshake ----
 * Fire an event + arg, then BUSY-WAIT until the real HPS (running
 * autonomously on the ARM) echoes the bit into hps_event_ack. Then clear our
 * event and wait for the HPS to drop its ack. No hps_service() here -- the
 * HPS is a separate processor, not something we drive. */
static void hps_event(uint32_t ev, uint32_t arg)
{
    shared_audio_mem_t *m = hps_shared();

    dbg_num("[PLAYER] -> HPS event=", ev);
    m->nios_arg         = arg;
    m->nios_event_flags = ev;

    while ((m->hps_event_ack & ev) == 0u)
        ;                                  /* wait for HPS to handle it */
    m->nios_event_flags = NIOS_EVENT_NONE; /* clear -> HPS clears its ack */
    while (m->hps_event_ack != HPS_ACK_NONE)
        ;
    dbg_puts("[PLAYER] HPS ack OK\r\n");
}

/* ---- pull current metadata from shared mem onto the VGA ---- */
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
 * This is the "Song Buffer action": fire-and-forget, NO busy wait. */
static int consume_one_buffer(void)
{
    shared_audio_mem_t *m = hps_shared();
    volatile audio_buffer_desc_t *d = &m->buffers[g_consume_idx];

    if (d->state != BUF_READY) return -1;

    d->state = BUF_CONSUMING;
    unsigned frames = (unsigned)d->size_bytes / 4u;
    int16_t *pcm    = (int16_t *)m->audio_data[g_consume_idx];

    static int16_t mono[AUDIO_BUF_SIZE / 4];
    for (unsigned f = 0; f < frames; f++) mono[f] = pcm[2 * f];

    audio_rate_t rate = hps_rate_from_hz((uint32_t)m->current_meta.sample_rate);
    audio_play_buffer(mono, frames, rate, 0);

    int last = (d->flags & BUF_FLAG_LAST) ? 1 : 0;

    /* Just mark it EMPTY. The HPS scans for EMPTY buffers every poll and
     * refills them on its own -- no event needed. This keeps the event
     * handshake registers FREE for the blocking events (NEW_SONG/INITIAL). */
    d->state = BUF_EMPTY;

    dbg_num("[PLAYER] consumed buf=", g_consume_idx);
    g_consume_idx = (g_consume_idx + 1u) % NUM_BUFFERS;
    return last;
}

/* ---- lifecycle ---- */
void player_init(void)
{
    dbg_puts("[PLAYER] init (initial info action)\r\n");

    g_song        = 0;
    g_consume_idx = 0;
    g_state       = ST_STOPPED;

    /* Initial Info action: busy-waited. HPS reports song_count, publishes
     * song 0 metadata, and prime-fills all three buffers. */
    hps_event(NIOS_EVENT_INITIAL, 0);
    g_count = hps_song_count();
    dbg_num("[PLAYER] song_count=", g_count);

    show_meta();
    vga_set_state("stopped");
    timer_reset();                  /* reset & pause */
    dbg_puts("[PLAYER] init complete (stopped)\r\n");
}

void player_reset(void)
{
    dbg_puts("[PLAYER] reset -> redo init\r\n");
    player_init();
}

/* ---- actions (other IRQs ignored by caller while these run) ---- */
void player_play_pause(void)
{
    if (g_state == ST_PLAYING) {
        dbg_puts("[PLAYER] pause\r\n");
        g_state = ST_PAUSED;        /* stop feeding -> position retained */
        vga_set_state("paused");
        timer_pause();
    } else {
        dbg_puts("[PLAYER] play/resume\r\n");
        g_state = ST_PLAYING;       /* resume from current g_consume_idx */
        vga_set_state("playing");
        timer_resume();
    }
}

void player_next(void)
{
    dbg_puts("[PLAYER] next\r\n");
    timer_reset();
    g_song = (g_song + 1u) % g_count;
    hps_event(NIOS_EVENT_NEW_SONG, g_song);   /* busy-waited: new song load */
    g_consume_idx = 0;
    show_meta();
    g_state = ST_PLAYING;
    vga_set_state("playing");
    timer_resume();
}

void player_prev(void)
{
    dbg_puts("[PLAYER] prev\r\n");
    timer_reset();
    g_song = (g_song + g_count - 1u) % g_count;
    hps_event(NIOS_EVENT_NEW_SONG, g_song);
    g_consume_idx = 0;
    show_meta();                    /* update VGA AFTER the handshake */
    g_state = ST_PLAYING;
    vga_set_state("playing");
    timer_resume();
}

void player_stop(void)
{
    dbg_puts("[PLAYER] stop\r\n");
    /* reload current song from start, but stay stopped/paused at beginning */
    hps_event(NIOS_EVENT_NEW_SONG, g_song);
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

    int r = consume_one_buffer();
    if (r == 1) {
        dbg_puts("[PLAYER] song ended -> auto next\r\n");
        player_next();             /* auto-advance == NextSong */
    }
    /* r == -1: HPS hasn't filled the next buffer yet; retry next loop */
}