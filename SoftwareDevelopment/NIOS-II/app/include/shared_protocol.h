#ifndef SHARED_PROTOCOL_H
#define SHARED_PROTOCOL_H

#include <stdint.h>

#define NUM_BUFFERS    0x00000003u   /* ring depth; MUST match the HPS side */
#define AUDIO_BUF_SIZE 0x00000800u

#define AUDIO_BITS_PER_SAMPLE 0x00000010u  /* 16-bit signed PCM */
#define AUDIO_CHANNELS        0x00000002u  /* stereo */

#define META_TEXT_MAX  64u           /* metadata string capacity */
#define MAX_SONGS      32u           /* playlist capacity */

/* Buffer states */
#define BUF_EMPTY      0x00000000u
#define BUF_FILLING    0x00000001u
#define BUF_READY      0x00000002u
#define BUF_CONSUMING  0x00000003u

/* Buffer flags */
#define BUF_FLAG_NONE  0x00000000u
#define BUF_FLAG_LAST  0x00000001u

/* Events Nios writes, HPS reads */
#define NIOS_EVENT_NONE       0x00000000u
#define NIOS_EVENT_INITIAL    0x00000001u  /* initial info: count + song0 + fill */
#define NIOS_EVENT_NEW_SONG   0x00000002u  /* load song = nios_arg */
#define NIOS_EVENT_BUF_EMPTY  0x00000004u  /* buffer nios_arg went EMPTY: refill */

#define HPS_ACK_NONE          0x00000000u

/* sample rate codes carried in metadata so Nios feeds the engine correctly */
#define SR_8000   8000u
#define SR_16000  16000u
#define SR_44100  44100u
#define SR_48000  48000u

typedef struct {
    volatile uint32_t state;        /* BUF_EMPTY..BUF_CONSUMING */
    volatile uint32_t size_bytes;   /* valid bytes in this buffer */
    volatile uint32_t flags;        /* BUF_FLAG_LAST etc. */
} audio_buffer_desc_t;

typedef struct {
    volatile char     title[META_TEXT_MAX];
    volatile char     artist[META_TEXT_MAX];
    volatile char     album[META_TEXT_MAX];
    volatile uint32_t duration_seconds;
    volatile uint32_t sample_rate;  /* 8000/16000/44100/48000 */
} song_meta_shared_t;

typedef struct {
    /* --- Nios -> HPS --- */
    volatile uint32_t nios_event_flags;  /* one NIOS_EVENT_* */
    volatile uint32_t nios_arg;          /* song index, or buffer index */

    /* --- HPS -> Nios --- */
    volatile uint32_t hps_event_ack;     /* echoes handled event */
    volatile uint32_t song_count;        /* total .wav files found */

    /* current song's metadata (HPS writes on INITIAL / NEW_SONG) */
    volatile song_meta_shared_t current_meta;

    /* ring of 3 buffers */
    volatile audio_buffer_desc_t buffers[NUM_BUFFERS];
    volatile uint8_t audio_data[NUM_BUFFERS][AUDIO_BUF_SIZE];
} shared_audio_mem_t;

/* Physical address of the shared region on the HPS side (H2F + RAM offset).
 * H2F base 0xC0000000 + RAM-as-seen-by-H2F base 0x8000 + shared offset 0x6000. */
#define SHARED_AUDIO_MEM_PHYS  0xC000E000u

#endif