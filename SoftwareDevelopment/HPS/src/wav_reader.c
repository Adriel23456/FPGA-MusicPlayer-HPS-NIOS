#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "wav_reader.h"

#define WAV_FORMAT_PCM 1u

static int read_exact(FILE *file, void *dst, size_t size)
{
    return (fread(dst, 1, size, file) == size) ? 0 : -1;
}

static int is_supported_sample_rate(uint32_t sample_rate)
{
    return sample_rate == 8000u || sample_rate == 16000u || sample_rate == 44100u;
}

static void clear_metadata(wav_metadata_t *metadata)
{
    if (metadata == NULL) return;
    metadata->title[0]  = '\0';
    metadata->artist[0] = '\0';
    metadata->album[0]  = '\0';
}

static void copy_metadata_text(char *dst, size_t dst_size,
                               const char *src, uint32_t src_size)
{
    size_t copy_size;

    if (dst == NULL || src == NULL || dst_size == 0u) return;

    copy_size = src_size;
    if (copy_size >= dst_size) copy_size = dst_size - 1u;

    memcpy(dst, src, copy_size);
    dst[copy_size] = '\0';

    /* Trim trailing NULs / whitespace that some WAV metadata strings carry. */
    while (copy_size > 0u &&
           (dst[copy_size - 1u] == '\0' || dst[copy_size - 1u] == ' '  ||
            dst[copy_size - 1u] == '\n' || dst[copy_size - 1u] == '\r')) {
        dst[copy_size - 1u] = '\0';
        copy_size--;
    }
}

static int skip_bytes(FILE *file, uint32_t size)
{
    if (size == 0u) return 0;
    return (fseek(file, (long)size, SEEK_CUR) == 0) ? 0 : -1;
}

static int skip_padding_if_needed(FILE *file, uint32_t size)
{
    if (size & 1u)
        return (fseek(file, 1L, SEEK_CUR) == 0) ? 0 : -1;
    return 0;
}

/* Parse a LIST/INFO chunk for title/artist/album; skip anything else. */
static int parse_info_metadata_chunk(FILE *file, uint32_t list_content_size,
                                     wav_metadata_t *metadata)
{
    long     list_start, current_pos;
    uint32_t consumed;
    char     list_type[4];

    if (file == NULL || metadata == NULL) return -1;
    if (list_content_size < 4u)           return -1;

    list_start = ftell(file);
    if (list_start < 0) return -1;

    if (read_exact(file, list_type, sizeof(list_type)) != 0) return -1;

    if (memcmp(list_type, "INFO", 4) != 0)
        return skip_bytes(file, list_content_size - 4u);   /* not INFO */

    consumed = 4u;

    while (consumed + 8u <= list_content_size) {
        char     info_id[4];
        uint32_t info_size;
        char     temp[META_TEXT_MAX];

        if (read_exact(file, info_id, sizeof(info_id)) != 0 ||
            read_exact(file, &info_size, sizeof(info_size)) != 0) {
            return -1;
        }
        consumed += 8u;

        if (info_size > 0u) {
            uint32_t read_size = info_size;
            if (read_size >= META_TEXT_MAX) read_size = META_TEXT_MAX - 1u;

            if (read_exact(file, temp, read_size) != 0) return -1;
            temp[read_size] = '\0';

            if (info_size > read_size) {
                if (skip_bytes(file, info_size - read_size) != 0) return -1;
            }

            if (memcmp(info_id, "INAM", 4) == 0) {
                copy_metadata_text(metadata->title, META_TEXT_MAX, temp, read_size);
            } else if (memcmp(info_id, "IART", 4) == 0) {
                copy_metadata_text(metadata->artist, META_TEXT_MAX, temp, read_size);
            } else if (memcmp(info_id, "IPRD", 4) == 0 ||
                       memcmp(info_id, "IALB", 4) == 0) {
                copy_metadata_text(metadata->album, META_TEXT_MAX, temp, read_size);
            }
        }

        consumed += info_size;

        if (info_size & 1u) {                       /* even-byte padding */
            if (fseek(file, 1L, SEEK_CUR) != 0) return -1;
            consumed += 1u;
        }
    }

    /* Skip any leftover bytes in the LIST chunk. */
    current_pos = ftell(file);
    if (current_pos < 0) return -1;

    consumed = (uint32_t)(current_pos - list_start);
    if (consumed < list_content_size)
        return skip_bytes(file, list_content_size - consumed);

    return 0;
}

int wav_open(const char *path, wav_info_t *info)
{
    char riff_id[4], wave_id[4], chunk_id[4];
    uint32_t riff_size, chunk_size;
    uint16_t audio_format, channels, block_align, bits_per_sample;
    uint32_t sample_rate, byte_rate;
    int  found_fmt = 0, found_data = 0;
    long data_offset;

    if (path == NULL || info == NULL) return -1;

    memset(info, 0, sizeof(*info));
    clear_metadata(&info->metadata);

    info->file = fopen(path, "rb");
    if (info->file == NULL) return -1;

    if (read_exact(info->file, riff_id, sizeof(riff_id)) != 0 ||
        read_exact(info->file, &riff_size, sizeof(riff_size)) != 0 ||
        read_exact(info->file, wave_id, sizeof(wave_id)) != 0) {
        wav_close(info);
        return -1;
    }
    (void)riff_size;

    if (memcmp(riff_id, "RIFF", 4) != 0 || memcmp(wave_id, "WAVE", 4) != 0) {
        wav_close(info);
        return -1;
    }

    /* Scan chunks. Don't stop at "data": metadata may follow it, so record the
     * data offset and keep scanning, then seek back at the end. */
    while (read_exact(info->file, chunk_id, sizeof(chunk_id)) == 0 &&
           read_exact(info->file, &chunk_size, sizeof(chunk_size)) == 0) {

        if (memcmp(chunk_id, "fmt ", 4) == 0) {
            if (chunk_size < 16u) { wav_close(info); return -1; }

            if (read_exact(info->file, &audio_format, sizeof(audio_format)) != 0 ||
                read_exact(info->file, &channels, sizeof(channels)) != 0 ||
                read_exact(info->file, &sample_rate, sizeof(sample_rate)) != 0 ||
                read_exact(info->file, &byte_rate, sizeof(byte_rate)) != 0 ||
                read_exact(info->file, &block_align, sizeof(block_align)) != 0 ||
                read_exact(info->file, &bits_per_sample, sizeof(bits_per_sample)) != 0) {
                wav_close(info);
                return -1;
            }
            (void)byte_rate;
            (void)block_align;

            if (chunk_size > 16u) {
                if (skip_bytes(info->file, chunk_size - 16u) != 0) {
                    wav_close(info);
                    return -1;
                }
            }

            if (audio_format != WAV_FORMAT_PCM     ||
                channels != AUDIO_CHANNELS         ||
                bits_per_sample != AUDIO_BITS_PER_SAMPLE ||
                !is_supported_sample_rate(sample_rate)) {
                wav_close(info);
                return -1;
            }

            info->sample_rate     = sample_rate;
            info->channels        = channels;
            info->bits_per_sample = bits_per_sample;
            found_fmt = 1;

        } else if (memcmp(chunk_id, "LIST", 4) == 0) {
            if (parse_info_metadata_chunk(info->file, chunk_size, &info->metadata) != 0) {
                wav_close(info);
                return -1;
            }

        } else if (memcmp(chunk_id, "data", 4) == 0) {
            data_offset = ftell(info->file);
            if (data_offset < 0) { wav_close(info); return -1; }

            info->data_offset     = data_offset;
            info->data_size       = chunk_size;
            info->bytes_remaining = chunk_size;

            /* skip data for now so metadata scanning can continue */
            if (skip_bytes(info->file, chunk_size) != 0) {
                wav_close(info);
                return -1;
            }
            found_data = 1;

        } else {
            if (skip_bytes(info->file, chunk_size) != 0) {
                wav_close(info);
                return -1;
            }
        }

        if (skip_padding_if_needed(info->file, chunk_size) != 0) {
            wav_close(info);
            return -1;
        }
    }

    if (!found_fmt || !found_data) { wav_close(info); return -1; }

    /* duration = data_size / (sample_rate * channels * bytes_per_sample) */
    {
        uint32_t bytes_per_second =
            info->sample_rate * info->channels * (info->bits_per_sample / 8u);
        if (bytes_per_second != 0u)
            info->duration_seconds = info->data_size / bytes_per_second;
    }

    /* fallbacks for missing metadata */
    if (info->metadata.title[0]  == '\0') copy_metadata_text(info->metadata.title,  META_TEXT_MAX, "Unknown Title",  13u);
    if (info->metadata.artist[0] == '\0') copy_metadata_text(info->metadata.artist, META_TEXT_MAX, "Unknown Artist", 14u);
    if (info->metadata.album[0]  == '\0') copy_metadata_text(info->metadata.album,  META_TEXT_MAX, "Unknown Album",  13u);

    /* seek back to the start of raw PCM data for wav_read_pcm_chunk() */
    if (fseek(info->file, info->data_offset, SEEK_SET) != 0) {
        wav_close(info);
        return -1;
    }
    info->bytes_remaining = info->data_size;

    return 0;
}

int wav_read_pcm_chunk(wav_info_t *info, volatile uint8_t *dst,
                       uint32_t max_bytes, uint32_t *bytes_read, int *is_last)
{
    uint32_t to_read;

    if (info == NULL || info->file == NULL || dst == NULL ||
        bytes_read == NULL || is_last == NULL) {
        return -1;
    }
    if (max_bytes == 0u) return -1;

    *bytes_read = 0u;
    *is_last    = 0;

    if (info->bytes_remaining == 0u) {
        *is_last = 1;
        return 0;
    }

    to_read = max_bytes;
    if (to_read > info->bytes_remaining) to_read = info->bytes_remaining;

    if (fread((void *)dst, 1, to_read, info->file) != to_read) return -1;

    info->bytes_remaining -= to_read;
    *bytes_read = to_read;
    if (info->bytes_remaining == 0u) *is_last = 1;

    return 0;
}

void wav_close(wav_info_t *info)
{
    if (info == NULL) return;

    if (info->file != NULL) {
        fclose(info->file);
        info->file = NULL;
    }

    info->sample_rate      = 0u;
    info->channels         = 0u;
    info->bits_per_sample  = 0u;
    info->data_size        = 0u;
    info->bytes_remaining  = 0u;
    info->data_offset      = 0L;
    info->duration_seconds = 0u;

    clear_metadata(&info->metadata);
}