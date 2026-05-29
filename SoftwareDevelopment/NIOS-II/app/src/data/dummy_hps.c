/* ----------------------------------------------------------------------
 *  dummy_hps.c  --  synthetic producer for bring-up / testing.
 *
 *  Models the contract described in shared_mem.h. Generates a fixed number
 *  of "songs", each rendered as a finite test tone so that:
 *    - audio is audible through the WM8731
 *    - the batch ring drains in finite time -> song-end fires -> Next flow
 *
 *  Total frames per song are derived from the song's logical rate and the
 *  hardcoded 25 s length, so a 48 kHz song is genuinely 25 s of samples
 *  while an 8 kHz song is 25 s worth of 8 kHz frames (the engine replicates
 *  them up to the 48 kHz hardware clock).
 * -------------------------------------------------------------------- */

#include "dummy_hps.h"

/* Cycle the three test rates across the 10 songs so rate-switching is
   exercised: songs 0,3,6,9 -> 48k; 1,4,7 -> 16k; 2,5,8 -> 8k. */
static uint32_t rate_for_song(uint32_t i)
{
    switch (i % 3u) {
        case 0:  return RATE_48K;
        case 1:  return RATE_16K;
        default: return RATE_8K;
    }
}

/* Total source frames for a song at its logical rate. */
static uint32_t total_frames_for_song(uint32_t rate)
{
    return rate * HARDCODED_SONG_SECONDS;   /* frames == samples-per-channel */
}

/* ---- minimal string copy (no libc dependency in this layer) ------------ */
static void vcopy(volatile char *dst, const char *src, int cap)
{
    int i = 0;
    for (; i < cap - 1 && src[i]; i++) dst[i] = src[i];
    dst[i] = '\0';
}

/* Build a simple square-ish tone frame. Frequency steps per song so each
   "track" sounds distinct. Amplitude kept modest to protect ears/speakers. */
static int16_t tone_sample(uint32_t global_frame, uint32_t rate, uint32_t song)
{
    uint32_t freq = 220u + song * 40u;                 /* 220..580 Hz       */
    uint32_t half = rate / (freq * 2u);
    if (half == 0) half = 1;
    int phase = (int)((global_frame / half) & 1u);
    return phase ? (int16_t)0x3000 : (int16_t)-0x3000;  /* ~ -2 dBFS square  */
}

/* Per-song running frame cursor so successive batch fills are continuous. */
static uint32_t s_song_cursor[MAX_SONGS];
static uint32_t s_active_song;

/* Fill one ring slot starting at the song's current cursor. */
static void fill_slot(uint32_t slot, uint32_t song)
{
    volatile audio_batch_t *b = &SHARED->ring[slot];
    uint32_t rate   = rate_for_song(song);
    uint32_t total  = total_frames_for_song(rate);
    uint32_t cursor = s_song_cursor[song];

    uint32_t remaining = (cursor < total) ? (total - cursor) : 0u;
    uint32_t n = (remaining < BATCH_FRAMES) ? remaining : BATCH_FRAMES;

    for (uint32_t f = 0; f < n; f++) {
        int16_t v = tone_sample(cursor + f, rate, song);
        b->sample[f * 2u + 0] = v;   /* L */
        b->sample[f * 2u + 1] = v;   /* R */
    }

    b->valid_frames = n;
    b->is_last      = (cursor + n >= total) ? 1u : 0u;
    b->seq         += 1u;
    s_song_cursor[song] = cursor + n;

    SHARED_BARRIER();
}

void dummy_hps_boot(void)
{
    SHARED->ctrl.hps_state      = HPS_BOOTING;
    SHARED->ctrl.nios_request   = REQ_IDLE;
    SHARED->ctrl.song_count     = DUMMY_SONG_COUNT;
    SHARED->ctrl.requested_song = 0;
    SHARED->ctrl.fill_slot      = 0;
    SHARED->ctrl.consume_slot   = 0;
    SHARED->ctrl.req_token      = 0;
    SHARED->ctrl.ack_token      = 0;

    /* Pre-populate all metadata so any song selection renders instantly. */
    for (uint32_t i = 0; i < DUMMY_SONG_COUNT; i++) {
        volatile song_meta_t *m = &SHARED->meta[i];
        char namebuf[META_NAME_LEN];
        /* "Test Track NN" */
        const char *base = "Test Track ";
        int k = 0;
        while (base[k]) { namebuf[k] = base[k]; k++; }
        namebuf[k++] = (char)('0' + ((i + 1) / 10));
        namebuf[k++] = (char)('0' + ((i + 1) % 10));
        namebuf[k]   = '\0';

        vcopy(m->name,   namebuf,        META_NAME_LEN);
        vcopy(m->artist, "Dummy Artist", META_ART_LEN);
        vcopy(m->album,  "Bringup Album", META_ALB_LEN);
        m->duration_sec = HARDCODED_SONG_SECONDS;
        m->sample_rate  = rate_for_song(i);

        s_song_cursor[i] = 0;
    }

    SHARED_BARRIER();
    SHARED->ctrl.hps_state = HPS_READY;
    SHARED_BARRIER();
}

void dummy_hps_load_song(uint32_t index0)
{
    if (index0 >= SHARED->ctrl.song_count) return;
    s_active_song = index0;
    s_song_cursor[index0] = 0;          /* restart this track from 0 */

    /* Provide the first three batches up front (as the spec describes). */
    for (uint32_t s = 0; s < BATCH_RING_SLOTS; s++) {
        fill_slot(s, index0);
    }
    SHARED->ctrl.fill_slot   = 0;
    SHARED->ctrl.requested_song = index0;
    SHARED_BARRIER();
    SHARED->ctrl.hps_state = HPS_SONG_READY;
    SHARED_BARRIER();
}

/* Called from the main loop: if the NIOS freed a slot (consume_slot moved),
   refill the slot the producer still owns. This mimics prefetch without a
   real handshake -- we simply keep `fill_slot` chasing `consume_slot`. */
void dummy_hps_service_prefetch(void)
{
    uint32_t consume = SHARED->ctrl.consume_slot;
    uint32_t fill    = SHARED->ctrl.fill_slot;

    /* Refill every slot that is "behind" the consumer and not yet last. */
    while (fill != consume) {
        if (!SHARED->ring[fill].is_last) {
            fill_slot(fill, s_active_song);
        }
        fill = (fill + 1u) % BATCH_RING_SLOTS;
    }
    SHARED->ctrl.fill_slot = fill;
    SHARED_BARRIER();
}