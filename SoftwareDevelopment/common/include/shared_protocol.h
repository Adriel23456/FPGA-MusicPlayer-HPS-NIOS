#ifndef SHARED_PROTOCOL_H
#define SHARED_PROTOCOL_H

#include <stdint.h>

#define SHARED_PROTOCOL_MAGIC   0x4850534Eu  /* HPSN */
#define SHARED_PROTOCOL_VERSION 0x00000001u

/*
 * Shared audio memory lives inside RAM_NIOS_II, but not at the beginning:
 * Nios II code also starts in that RAM. Both HPS and Nios II add this offset
 * to their own view of RAM_NIOS_II before casting to shared_audio_mem_t.
 */
#define SHARED_AUDIO_MEM_OFFSET 0x00020000u

#define MAX_SONGS       0x0000000Au

#define NUM_BUFFERS     0x00000003u
#define AUDIO_BUF_SIZE  0x00004000u  /* 16384 bytes */

#define AUDIO_BITS_PER_SAMPLE 0x00000010u  /* 16-bit signed PCM */
#define AUDIO_CHANNELS        0x00000002u  /* stereo */

#define META_TEXT_MAX   0x00000040u  /* 64 bytes */

#define BUF_EMPTY       0x00000000u
#define BUF_FILLING     0x00000001u
#define BUF_READY       0x00000002u
#define BUF_CONSUMING   0x00000003u

#define BUF_FLAG_NONE   0x00000000u
#define BUF_FLAG_LAST   0x00000001u

#define NIOS_EVENT_NONE       0x00000000u
#define NIOS_EVENT_NEXT_SONG  0x00000001u
#define NIOS_EVENT_PREV_SONG  0x00000002u
#define NIOS_EVENT_RESTART    0x00000004u

#define HPS_ACK_NONE          0x00000000u

typedef struct {
    volatile uint32_t state;
    volatile uint32_t size_bytes;
    volatile uint32_t flags;
} audio_buffer_desc_t;

typedef struct {
    volatile uint32_t valid;
    volatile uint32_t duration_seconds;
    volatile uint32_t sample_rate_hz;

    volatile char title[META_TEXT_MAX];
    volatile char artist[META_TEXT_MAX];
    volatile char album[META_TEXT_MAX];
} song_metadata_t;

typedef struct {
    volatile uint32_t protocol_magic;
    volatile uint32_t protocol_version;
    volatile uint32_t nios_event_flags;
    volatile uint32_t hps_event_ack;
    volatile uint32_t song_count;

    song_metadata_t current_metadata;

    audio_buffer_desc_t buffers[NUM_BUFFERS];

    volatile uint8_t audio_data[NUM_BUFFERS][AUDIO_BUF_SIZE];
} shared_audio_mem_t;

#endif /* SHARED_PROTOCOL_H */
