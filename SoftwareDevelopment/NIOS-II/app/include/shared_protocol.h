#ifndef SHARED_PROTOCOL_H
#define SHARED_PROTOCOL_H

#include <stdint.h>

/* Number of shared audio buffers. */
#define NUM_BUFFERS    0x00000003u

/* Size of each audio buffer in bytes. 0x2000 = 8192 bytes. */
#define AUDIO_BUF_SIZE 0x00002000u

/* Audio format assumed by the interconnection. */
#define AUDIO_BITS_PER_SAMPLE 0x00000010u  /* 16-bit signed PCM */
#define AUDIO_CHANNELS        0x00000002u  /* stereo */

/* Buffer states. */
#define BUF_EMPTY      0x00000000u
#define BUF_FILLING    0x00000001u
#define BUF_READY      0x00000002u
#define BUF_CONSUMING  0x00000003u

/* Buffer flags. */
#define BUF_FLAG_NONE  0x00000000u
#define BUF_FLAG_LAST  0x00000001u

/* Events written by Nios II and read by HPS. */
#define NIOS_EVENT_NONE       0x00000000u
#define NIOS_EVENT_NEXT_SONG  0x00000001u
#define NIOS_EVENT_PREV_SONG  0x00000002u
#define NIOS_EVENT_RESTART    0x00000004u

/* HPS acknowledgment value. HPS writes back the same event bit. */
#define HPS_ACK_NONE          0x00000000u

typedef struct {
    /* Ownership state.
     *   HPS:    EMPTY -> FILLING -> READY
     *   Nios:   READY -> CONSUMING -> EMPTY */
    volatile uint32_t state;

    /* Number of valid audio bytes in this buffer. */
    volatile uint32_t size_bytes;

    /* Buffer flags. Version 1 uses BUF_FLAG_LAST. */
    volatile uint32_t flags;
} audio_buffer_desc_t;

typedef struct {
    /* Nios writes event bits here; HPS reads and handles them. */
    volatile uint32_t nios_event_flags;

    /* HPS writes ack bits here after handling; Nios reads and clears. */
    volatile uint32_t hps_event_ack;

    /* Buffer descriptors. */
    audio_buffer_desc_t buffers[NUM_BUFFERS];

    /* Raw PCM audio chunks. 16-bit signed PCM, stereo. */
    volatile uint8_t audio_data[NUM_BUFFERS][AUDIO_BUF_SIZE];
} shared_audio_mem_t;

#endif