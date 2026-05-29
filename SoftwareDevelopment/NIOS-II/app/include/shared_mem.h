#ifndef SHARED_MEM_H
#define SHARED_MEM_H

/* ======================================================================
 *  shared_mem.h  --  HPS <-> NIOS II shared-RAM contract.
 *
 *  IMPORTANT SCOPE NOTE
 *  --------------------
 *  This project does NOT implement the HPS<->NIOS handshake/prefetch logic.
 *  A teammate will finish that later. What we DO own here is the *contract*:
 *  the exact byte layout both sides agree on, the pointer arithmetic, and
 *  the memory barriers so that when the real producer (HPS) is connected,
 *  the NIOS consumer side already behaves correctly.
 *
 *  The whole structure lives at SHARED_RAM_BASE_ADDR (0x40000). Both the
 *  NIOS data master and the HPS h2f masters can see this region, so every
 *  field that one side writes and the other reads is declared `volatile`
 *  and is touched only through the barrier helpers below.
 *
 *  Layout (offsets relative to SHARED_RAM_BASE_ADDR):
 *
 *    +0x0000  control_block_t   handshake flags, song count, requested song,
 *                               active logical sample rate, batch ring state
 *    +0x0100  song_meta_t[]     metadata for each song (name/artist/album/dur)
 *    +0x2000  audio batch ring  three batches of int16 stereo samples
 *
 *  meta[MAX_SONGS] is 0x1000 bytes (128 B * 32), so it spans 0x0100..0x1100;
 *  the audio ring starts at 0x2000 leaving headroom for the producer to grow
 *  the metadata region without disturbing the audio buffers.
 * ====================================================================== */

#include <stdint.h>
#include "hw_map.h"

/* ---- Memory barrier ----------------------------------------------------
 * On NIOS II the data master is in-order, but the compiler can still reorder
 * loads/stores. A compiler barrier is sufficient to keep our reads/writes of
 * the shared block ordered with respect to the flag handshakes. (If the
 * fabric path to the HPS were cached we'd also need cache flushes; the
 * shared RAM here is uncached on-chip/HPS bridge, so a compiler barrier is
 * the correct, minimal guarantee.) */
#define SHARED_BARRIER()  __asm__ volatile ("" ::: "memory")

/* ---- Handshake flag values (NIOS writes requests, HPS writes ack/ready) - */
typedef enum {
    REQ_IDLE        = 0,
    REQ_SONG_LOAD   = 1,   /* NIOS asks HPS to fetch song `requested_song`   */
    REQ_NEXT_BATCH  = 2    /* NIOS asks HPS to prefetch the next audio batch */
} shared_request_t;

typedef enum {
    HPS_BOOTING     = 0,
    HPS_READY       = 1,   /* song_count valid, system may start            */
    HPS_SONG_READY  = 2,   /* requested song's meta + first batches present */
    HPS_BATCH_READY = 3    /* a freshly prefetched batch is available        */
} shared_hps_state_t;

/* Logical (per-song) sample rates the HPS may announce for a track. */
typedef enum {
    RATE_8K  = 8000,
    RATE_16K = 16000,
    RATE_48K = 48000
} logical_rate_t;

/* ---- Audio batch geometry ----------------------------------------------
 * The NIOS does not have RAM for a whole song, so audio arrives in batches.
 * We model a 3-slot ring (matches "first 3 batches" on startup). Each batch
 * holds interleaved 16-bit L/R samples. */
#define BATCH_FRAMES        2048u                 /* stereo frames per batch */
#define BATCH_RING_SLOTS    3u
#define BATCH_SAMPLES       (BATCH_FRAMES * 2u)   /* L+R int16 per batch     */

typedef struct {
    volatile int16_t sample[BATCH_SAMPLES];       /* L0,R0,L1,R1, ...        */
    volatile uint32_t valid_frames;               /* <= BATCH_FRAMES         */
    volatile uint32_t is_last;                    /* 1 => final batch of song*/
    volatile uint32_t seq;                         /* monotone batch counter  */
} audio_batch_t;

/* ---- Per-song metadata -------------------------------------------------- */
typedef struct {
    volatile char     name[META_NAME_LEN];
    volatile char     artist[META_ART_LEN];
    volatile char     album[META_ALB_LEN];
    volatile uint32_t duration_sec;               /* used to render MM:SS    */
    volatile uint32_t sample_rate;                /* logical_rate_t value    */
} song_meta_t;

/* ---- Control block ------------------------------------------------------ */
typedef struct {
    volatile uint32_t hps_state;       /* shared_hps_state_t (HPS writes)    */
    volatile uint32_t nios_request;    /* shared_request_t   (NIOS writes)   */
    volatile uint32_t song_count;      /* >=10 (HPS writes at boot)          */
    volatile uint32_t requested_song;  /* 0-based index NIOS wants           */
    volatile uint32_t ack_token;       /* echoes NIOS request seq for sync   */
    volatile uint32_t req_token;       /* NIOS increments per request        */

    /* Batch ring bookkeeping. NIOS owns `consume_slot`; HPS owns `fill_slot`.
       Neither writes the other's index -> single-writer per field, so the
       compiler barrier is all the synchronisation we need. */
    volatile uint32_t fill_slot;       /* next slot HPS will fill            */
    volatile uint32_t consume_slot;    /* next slot NIOS will play           */
    volatile uint32_t _pad[2];
} control_block_t;

/* ---- Full shared image -------------------------------------------------- */
typedef struct {
    control_block_t  ctrl;                         /* @ +0x0000             */
    uint8_t          _gap_meta[0x0100 - sizeof(control_block_t)];
    song_meta_t      meta[MAX_SONGS];              /* @ +0x0100 (0x1000 B)  */
    uint8_t          _gap_audio[0x2000
                       - (0x0100 + sizeof(song_meta_t) * MAX_SONGS)];
    audio_batch_t    ring[BATCH_RING_SLOTS];       /* @ +0x2000             */
} shared_image_t;

/* The one true pointer into the shared region. */
#define SHARED  ((volatile shared_image_t *)(SHARED_RAM_BASE_ADDR))

#endif /* SHARED_MEM_H */