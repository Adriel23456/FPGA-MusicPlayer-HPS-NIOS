#ifndef WAV_READER_H
#define WAV_READER_H

#include <stdint.h>
#include <stdio.h>
#include "shared_protocol.h"

typedef struct {
    char title[META_TEXT_MAX];
    char artist[META_TEXT_MAX];
    char album[META_TEXT_MAX];
} wav_metadata_t;

typedef struct {
    FILE *file;

    uint32_t sample_rate;
    uint16_t channels;
    uint16_t bits_per_sample;

    uint32_t data_size;
    uint32_t bytes_remaining;
    long     data_offset;

    uint32_t duration_seconds;

    wav_metadata_t metadata;
} wav_info_t;

int  wav_open(const char *path, wav_info_t *info);
int  wav_read_pcm_chunk(wav_info_t *info, volatile uint8_t *dst,
                        uint32_t max_bytes, uint32_t *bytes_read, int *is_last);
void wav_close(wav_info_t *info);

#endif /* WAV_READER_H */