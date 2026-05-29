/* ----------------------------------------------------------------------
 *  audio_engine.c  --  WM8731 streaming via the UP Audio core.
 *
 *  The UP Audio core exposes four 32-bit registers; we use the HAL driver
 *  (altera_up_avalon_audio.h) for portability. Each output FIFO holds 128
 *  words; the core raises a WRITE interrupt when a write FIFO is >=75% empty
 *  and clears it when it falls below 75% empty. We refill on that interrupt.
 *
 *  Sample-rate handling
 *  --------------------
 *  The CODEC runs at one fixed rate (CODEC_HW_RATE, e.g. 48 kHz). To "play"
 *  an 8 kHz or 16 kHz song without reconfiguring the CODEC, we replicate
 *  each source frame `rep = CODEC_HW_RATE / logical_rate` times into the
 *  FIFO (6x for 8 kHz, 3x for 16 kHz, 1x for 48 kHz). This is the standard,
 *  glitch-free way to mix rates on a single hardware clock. If you later
 *  add true CODEC re-clocking, do it in audio_start() and set rep = 1.
 *
 *  Position model
 *  --------------
 *  - consume_slot: which ring slot we're playing (index into SHARED->ring)
 *  - frame_idx:    next stereo frame within that slot
 *  - rep_left:     replications remaining for the current frame
 *  These fully describe "where we are", so pause simply stops refilling and
 *  resume continues from the same triple. Stop zeroes them and flushes.
 * -------------------------------------------------------------------- */

#include "audio_engine.h"
#include "debug_uart.h"
#include "altera_up_avalon_audio.h"
#include "sys/alt_irq.h"
#include "system.h"   /* AUDIO_OUT_NAME, AUDIO_CONFIG_NAME (generated) */
#include "altera_up_avalon_audio_and_video_config.h"

/* ---- engine state ------------------------------------------------------ */
static alt_up_audio_dev      *g_audio   = 0;
static alt_up_av_config_dev  *g_config  = 0;
static song_end_cb_t          g_end_cb  = 0;

static volatile uint32_t g_rep         = 1;   /* replication factor          */
static volatile uint32_t g_consume     = 0;   /* ring slot being played      */
static volatile uint32_t g_frame_idx   = 0;   /* frame within the slot       */
static volatile uint32_t g_rep_left    = 1;   /* reps remaining for frame    */
static volatile int      g_streaming   = 0;   /* draining enabled?           */
static volatile int      g_song_end    = 0;   /* sticky end-of-song flag     */

/* Count of SOURCE frames consumed for the current song (i.e. logical frames
   at the song's own rate, NOT replicated FIFO writes). This is the drift-free
   time base: elapsed_seconds = g_src_frames_played / logical_rate. We bump it
   once per source frame, when its last replication is pushed. */
static volatile uint32_t g_src_frames_played = 0;
static volatile uint32_t g_logical_rate      = CODEC_HW_RATE;

/* How many words to try to push per IRQ. We keep both L and R FIFOs topped;
   write_fifo_space tells us the real room, so this is just an upper bound to
   bound ISR time. 128-word FIFO -> push up to ~96 frames per service. */
#define REFILL_BUDGET_FRAMES  96u

/* ---- helpers ----------------------------------------------------------- */

/* Convert a stored int16 sample to the 32-bit value the FIFO expects.
   The leftdata/rightdata registers are flush-right; sign-extension into the
   upper bits is harmless because the serializer takes the low bits per the
   configured bit length. We mask to 16 bits and sign-extend cleanly. */
static inline unsigned int frame_word(int16_t s)
{
    return (unsigned int)(int)s;   /* sign-extended; flush-right LSBs valid */
}

/* True if the slot currently pointed at has no more frames to give. */
static inline int slot_exhausted(const volatile audio_batch_t *b)
{
    return g_frame_idx >= b->valid_frames;
}

/* Advance to the next ring slot. Asks the HPS (when present) to prefetch the
   slot we just finished. Returns 0 if the just-finished slot was the last. */
static int advance_slot(void)
{
    const volatile audio_batch_t *finished = &SHARED->ring[g_consume];
    int was_last = finished->is_last ? 1 : 0;

    /* Tell the producer this slot is free to refill (prefetch handshake).
       The producer side isn't implemented yet; we still publish the request
       and the freed consume_slot so it works the moment HPS is attached. */
    g_consume = (g_consume + 1u) % BATCH_RING_SLOTS;
    SHARED_BARRIER();
    SHARED->ctrl.consume_slot = g_consume;
    SHARED->ctrl.nios_request = REQ_NEXT_BATCH;
    SHARED->ctrl.req_token   += 1u;
    SHARED_BARRIER();

    g_frame_idx = 0;
    g_rep_left  = g_rep;
    return was_last ? 0 : 1;
}

/* Pull the next (already-replicated) source frame's L/R pair.
   Returns 1 if a frame was produced into *l,*r; 0 if the song is exhausted. */
static int next_frame(int16_t *l, int16_t *r)
{
    const volatile audio_batch_t *b = &SHARED->ring[g_consume];

    if (slot_exhausted(b)) {
        if (b->is_last) return 0;          /* genuine end of song           */
        if (!advance_slot()) return 0;     /* advanced onto a last/empty    */
        b = &SHARED->ring[g_consume];
        if (b->valid_frames == 0) return 0;
    }

    uint32_t base = g_frame_idx * 2u;      /* interleaved L,R                */
    *l = b->sample[base + 0];
    *r = b->sample[base + 1];

    /* Consume one replication; when spent, move to the next source frame and
       count that source frame as played (this is the elapsed-time tick). */
    if (--g_rep_left == 0) {
        g_rep_left = g_rep;
        g_frame_idx++;
        g_src_frames_played++;
    }
    return 1;
}

/* ---- write-interrupt service ------------------------------------------- */
static void audio_isr(void *context)
{
    (void)context;

    if (!g_streaming) {
        /* Paused/stopped: mask further write IRQs so we stop being called. */
        alt_up_audio_disable_write_interrupt(g_audio);
        return;
    }

    unsigned int budget = REFILL_BUDGET_FRAMES;
    while (budget--) {
        /* Both channels must have room; the core won't play until both
           have data, so we keep them lock-step. */
        if (alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_LEFT)  == 0 ||
            alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_RIGHT) == 0) {
            break;   /* FIFO full enough; IRQ will re-fire when it drains */
        }

        int16_t l, r;
        if (!next_frame(&l, &r)) {
            /* Song fully drained: stop streaming, flag for the main loop. */
            g_streaming = 0;
            g_song_end  = 1;
            alt_up_audio_disable_write_interrupt(g_audio);
            if (g_end_cb) g_end_cb();
            break;
        }

        alt_up_audio_write_fifo_head(g_audio, frame_word(l), ALT_UP_AUDIO_LEFT);
        alt_up_audio_write_fifo_head(g_audio, frame_word(r), ALT_UP_AUDIO_RIGHT);
    }
}

/* ---- public API -------------------------------------------------------- */

void audio_init(song_end_cb_t on_song_end)
{
    g_end_cb = on_song_end;

    /* Bring up the AV-config core and wait for WM8731 auto-init (AIS bit).
       The wait is BOUNDED: if the codec never reports auto-init complete
       (clock/config issue), we time out and continue rather than hang the
       whole player. Audio may not work in that case, but VGA and buttons
       will, so the system stays diagnosable. */
    dbg_puts("AUDIO: open av_config...\n");
    g_config = alt_up_av_config_open_dev(AUDIO_CONFIG_NAME);
    if (g_config) {
        dbg_puts("AUDIO: av_config opened, reset + wait AIS...\n");
        alt_up_av_config_reset(g_config);

        uint32_t guard = 5000000u;   /* bounded; generous for a slow I2C cfg */
        while (!(REG32(AUDIO_CONFIG_BASE_ADDR + AUDIO_STATUS_OFF) & AUDIO_AIS_BIT)
               && guard) {
            guard--;
        }
        if (guard == 0) {
            dbg_puts("AUDIO: AIS wait TIMED OUT (codec not initialised)\n");
        } else {
            dbg_puts("AUDIO: codec auto-init complete\n");
        }
    } else {
        dbg_puts("AUDIO: av_config open FAILED (check AUDIO_CONFIG_NAME)\n");
    }

    /* Open + reset the audio core (clears all four FIFOs). */
    dbg_puts("AUDIO: open audio core...\n");
    g_audio = alt_up_audio_open_dev(AUDIO_OUT_NAME);
    if (g_audio) {
        alt_up_audio_reset_audio_core(g_audio);

        /* Register the write-interrupt ISR (kept masked until we play). */
#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
        alt_ic_isr_register(0, AUDIO_OUT_IRQ, audio_isr, (void *)0, (void *)0);
#else
        alt_irq_register(AUDIO_OUT_IRQ, (void *)0, audio_isr);
#endif
        alt_up_audio_disable_write_interrupt(g_audio);
        dbg_puts("AUDIO: audio core ready\n");
    } else {
        dbg_puts("AUDIO: audio core open FAILED (check AUDIO_OUT_NAME)\n");
    }
}

static void set_rate(uint32_t logical_rate)
{
    if (logical_rate == 0) logical_rate = CODEC_HW_RATE;
    g_logical_rate = logical_rate;
    uint32_t rep = CODEC_HW_RATE / logical_rate;
    g_rep = (rep == 0) ? 1u : rep;
}

void audio_start(uint32_t logical_rate)
{
    if (!g_audio) return;
    set_rate(logical_rate);

    g_rep_left  = g_rep;
    g_song_end  = 0;
    g_streaming = 1;

    /* Enabling the write IRQ will immediately fire (FIFOs are empty => 100%
       empty => >=75% empty), kicking off the first refill from the ISR. */
    alt_up_audio_enable_write_interrupt(g_audio);
}

void audio_pause(void)
{
    g_streaming = 0;
    if (g_audio) alt_up_audio_disable_write_interrupt(g_audio);
    /* Position state (g_consume / g_frame_idx / g_rep_left) is preserved. */
}

void audio_resume(void)
{
    if (!g_audio) return;
    g_song_end  = 0;
    g_streaming = 1;
    alt_up_audio_enable_write_interrupt(g_audio);
}

void audio_stop(void)
{
    g_streaming = 0;
    if (g_audio) {
        alt_up_audio_disable_write_interrupt(g_audio);
        alt_up_audio_reset_audio_core(g_audio);   /* flush both FIFOs */
    }
    /* Reset play position to the start of the song's first batch. */
    g_consume           = 0;
    g_frame_idx         = 0;
    g_rep_left          = g_rep;
    g_song_end          = 0;
    g_src_frames_played = 0;            /* elapsed time back to 0 */
    SHARED_BARRIER();
    SHARED->ctrl.consume_slot = 0;
    SHARED_BARRIER();
}

void audio_rewind_for_new_song(uint32_t logical_rate)
{
    /* Same as stop, but also re-derive the replication factor for the
       incoming song. Streaming is left disabled; caller starts it. */
    audio_stop();
    set_rate(logical_rate);
    g_rep_left = g_rep;
}

int audio_consume_song_end_flag(void)
{
    if (g_song_end) {
        g_song_end = 0;
        return 1;
    }
    return 0;
}

uint32_t audio_elapsed_seconds(void)
{
    /* Drift-free: derived from source frames actually pushed, divided by the
       song's logical rate. Snapshot the volatile once to avoid a torn read. */
    uint32_t frames = g_src_frames_played;
    uint32_t rate   = g_logical_rate ? g_logical_rate : CODEC_HW_RATE;
    return frames / rate;
}