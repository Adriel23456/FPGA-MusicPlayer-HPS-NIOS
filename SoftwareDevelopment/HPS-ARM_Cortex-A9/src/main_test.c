#include <stdio.h>
#include <stdint.h>

#include "shared_protocol.h"
#include "fpga_mem.h"
#include "hps_fpga_comm.h"
#include "hps_audio_streamer.h"
#include "wav_reader.h"

static void test_shared_init(volatile shared_audio_mem_t *shared)
{
    hps_stream_init_shared(shared);

    printf("Shared memory initialized.\n");
    printf("song_count = %u\n", shared->song_count);

    for (uint32_t i = 0; i < NUM_BUFFERS; i++) {
        printf("buffer %u state = %u\n", i, shared->buffers[i].state);
    }
}

static void test_song_counter(volatile shared_audio_mem_t *shared)
{
    uint32_t song_count = hps_count_valid_songs("./music");
    shared->song_count = song_count;

    printf("\nDetected WAV songs: %u\n", song_count);
    printf("shared->song_count = %u\n", shared->song_count);
}


static void test_event_handshake(volatile shared_audio_mem_t *shared)
{
    printf("\nTesting Nios II event handling...\n");

    hps_stream_init_shared(shared);

    shared->nios_event_flags = NIOS_EVENT_NEXT_SONG;

    printf("Before HPS handler:\n");
    printf("nios_event_flags = %u\n", shared->nios_event_flags);
    printf("hps_event_ack = %u\n", shared->hps_event_ack);

    hps_stream_handle_nios_events(shared);

    printf("After HPS handler:\n");
    printf("nios_event_flags = %u\n", shared->nios_event_flags);
    printf("hps_event_ack = %u\n", shared->hps_event_ack);

    shared->nios_event_flags = NIOS_EVENT_NONE;
    hps_stream_handle_nios_events(shared);

    printf("After fake Nios II clears event:\n");
    printf("nios_event_flags = %u\n", shared->nios_event_flags);
    printf("hps_event_ack = %u\n", shared->hps_event_ack);
}



static void test_wav_reader(void)
{
    wav_info_t wav;
    uint8_t test_buffer[AUDIO_BUF_SIZE];
    uint32_t bytes_read = 0;
    int is_last = 0;

    printf("\nTesting WAV reader...\n");

    if (wav_open("./music/Damtaro-Superman-_freetouse.com_.wav", &wav) != 0) {
        printf("ERROR: Failed to open WAV file.\n");
        return;
    }

    printf("WAV opened successfully.\n");
    printf("Sample rate: %u\n", wav.sample_rate);
    printf("Channels: %u\n", wav.channels);
    printf("Bits/sample: %u\n", wav.bits_per_sample);
    printf("Duration: %u sec\n", wav.duration_seconds);
    printf("Title: %s\n", wav.metadata.title);
    printf("Artist: %s\n", wav.metadata.artist);
    printf("Album: %s\n", wav.metadata.album);
    printf("Data size: %u bytes\n", wav.data_size);
    printf("Bytes remaining: %u bytes\n", wav.bytes_remaining);

    if (wav_read_pcm_chunk(&wav,
                           test_buffer,
                           AUDIO_BUF_SIZE,
                           &bytes_read,
                           &is_last) == 0) {
        printf("\nFirst PCM chunk read successfully.\n");
        printf("bytes_read = %u\n", bytes_read);
        printf("is_last = %d\n", is_last);
        printf("bytes_remaining = %u\n", wav.bytes_remaining);
        printf("first byte = %u\n", test_buffer[0]);
        printf("second byte = %u\n", test_buffer[1]);
    } else {
        printf("\nERROR: Failed to read first PCM chunk.\n");
    }

    wav_close(&wav);
}

static void test_real_wav_stream_to_shared_buffer(volatile shared_audio_mem_t *shared)
{
    const char *path = "./music/Damtaro-Superman-_freetouse.com_.wav";
    int result;

    printf("\nTesting real WAV stream into shared buffers...\n");

    if (hps_stream_start_wav_file(shared, path) != 0) {
        printf("ERROR: Could not start WAV stream.\n");
        return;
    }

    printf("Started WAV stream successfully.\n");
    printf("Metadata valid = %u\n", shared->current_metadata.valid);
    printf("Title = %s\n", (const char *)shared->current_metadata.title);
    printf("Artist = %s\n", (const char *)shared->current_metadata.artist);
    printf("Album = %s\n", (const char *)shared->current_metadata.album);
    printf("Duration = %u sec\n", shared->current_metadata.duration_seconds);

    result = hps_stream_try_fill_next_buffer(shared);

    if (result == 1) {
        printf("\nFilled real PCM buffer 0.\n");
        printf("buffer 0 state = %u\n", shared->buffers[0].state);
        printf("buffer 0 size_bytes = %u\n", shared->buffers[0].size_bytes);
        printf("buffer 0 flags = %u\n", shared->buffers[0].flags);
        printf("buffer 0 first byte = %u\n", shared->audio_data[0][0]);
        printf("buffer 0 second byte = %u\n", shared->audio_data[0][1]);
    } else if (result == 0) {
        printf("No buffer filled. Buffer was probably not EMPTY.\n");
    } else {
        printf("ERROR: Failed to fill real PCM buffer 0.\n");
    }

    result = hps_stream_try_fill_next_buffer(shared);

    if (result == 1) {
        printf("\nFilled real PCM buffer 1.\n");
        printf("buffer 1 state = %u\n", shared->buffers[1].state);
        printf("buffer 1 size_bytes = %u\n", shared->buffers[1].size_bytes);
        printf("buffer 1 flags = %u\n", shared->buffers[1].flags);
    } else {
        printf("Second real buffer fill result = %d\n", result);
    }

    result = hps_stream_try_fill_next_buffer(shared);

    if (result == 1) {
        printf("\nFilled real PCM buffer 2.\n");
        printf("buffer 2 state = %u\n", shared->buffers[2].state);
        printf("buffer 2 size_bytes = %u\n", shared->buffers[2].size_bytes);
        printf("buffer 2 flags = %u\n", shared->buffers[2].flags);
    } else {
        printf("Third real buffer fill result = %d\n", result);
    }

    result = hps_stream_try_fill_next_buffer(shared);

    if (result == 0) {
        printf("\nCorrectly stopped filling because buffer 0 is not EMPTY.\n");
    } else {
        printf("\nUnexpected fourth fill result = %d\n", result);
    }
}

static void test_playlist_and_events(volatile shared_audio_mem_t *shared)
{
    printf("\nTesting playlist loader and events...\n");

    if (hps_stream_load_playlist(shared, "./music") != 0) {
        printf("ERROR: Failed to load playlist.\n");
        return;
    }

    printf("Playlist loaded.\n");
    printf("shared->song_count = %u\n", shared->song_count);
    printf("Current metadata:\n");
    printf("valid = %u\n", shared->current_metadata.valid);
    printf("title = %s\n", (const char *)shared->current_metadata.title);
    printf("artist = %s\n", (const char *)shared->current_metadata.artist);
    printf("album = %s\n", (const char *)shared->current_metadata.album);
    printf("duration = %u sec\n", shared->current_metadata.duration_seconds);

    printf("\nFilling initial buffers...\n");
    hps_stream_try_fill_next_buffer(shared);
    hps_stream_try_fill_next_buffer(shared);
    hps_stream_try_fill_next_buffer(shared);

    for (uint32_t i = 0; i < NUM_BUFFERS; i++) {
        printf("buffer %u state = %u, size = %u, flags = %u\n",
               i,
               shared->buffers[i].state,
               shared->buffers[i].size_bytes,
               shared->buffers[i].flags);
    }

    printf("\nSimulating NEXT event...\n");
    shared->nios_event_flags = NIOS_EVENT_NEXT_SONG;
    hps_stream_handle_nios_events(shared);

    printf("After NEXT:\n");
    printf("hps_event_ack = %u\n", shared->hps_event_ack);
    printf("metadata valid = %u\n", shared->current_metadata.valid);
    printf("title = %s\n", (const char *)shared->current_metadata.title);
    printf("artist = %s\n", (const char *)shared->current_metadata.artist);
    printf("album = %s\n", (const char *)shared->current_metadata.album);

    for (uint32_t i = 0; i < NUM_BUFFERS; i++) {
        printf("buffer %u state = %u, size = %u, flags = %u\n",
               i,
               shared->buffers[i].state,
               shared->buffers[i].size_bytes,
               shared->buffers[i].flags);
    }

    shared->nios_event_flags = NIOS_EVENT_NONE;
    hps_stream_handle_nios_events(shared);

    printf("After fake Nios II clears NEXT:\n");
    printf("nios_event_flags = %u\n", shared->nios_event_flags);
    printf("hps_event_ack = %u\n", shared->hps_event_ack);
}

static void test_polling_loop_limited(volatile shared_audio_mem_t *shared)
{
    uint32_t fake_nios_consume = 0;

    printf("\nTesting limited polling loop...\n");

    if (hps_stream_load_playlist(shared, "./music") != 0) {
        printf("ERROR: Failed to load playlist.\n");
        return;
    }

    for (uint32_t i = 0; i < 10u; i++) {
        int fill_result;

        hps_stream_handle_nios_events(shared);

        fill_result = hps_stream_try_fill_next_buffer(shared);

        printf("poll %u: fill_result = %d\n", i, fill_result);

        /*
         * Fake Nios II behavior:
         * If the next buffer to consume is READY, consume it and release it.
         */
        if (shared->buffers[fake_nios_consume].state == BUF_READY) {
            printf("Fake Nios II consumes buffer %u.\n", fake_nios_consume);

            shared->buffers[fake_nios_consume].state = BUF_EMPTY;
            shared->buffers[fake_nios_consume].size_bytes = 0;
            shared->buffers[fake_nios_consume].flags = BUF_FLAG_NONE;

            fake_nios_consume = (fake_nios_consume + 1u) % NUM_BUFFERS;
        }
    }

    for (uint32_t i = 0; i < NUM_BUFFERS; i++) {
        printf("buffer %u state = %u, size = %u, flags = %u\n",
               i,
               shared->buffers[i].state,
               shared->buffers[i].size_bytes,
               shared->buffers[i].flags);
    }
}

int main(void)
{
    volatile shared_audio_mem_t *shared;

    if (hps_fpga_init(RAM_S1_PHYS, sizeof(shared_audio_mem_t)) != 0) {
        printf("ERROR: hps_fpga_init failed.\n");
        return 1;
    }

    shared = hps_fpga_get_shared();

    if (shared == 0) {
        printf("ERROR: shared memory pointer is NULL.\n");
        hps_fpga_close();
        return 1;
    }

    printf("Fake/shared memory backend initialized.\n");
    printf("Shared memory size: %zu bytes\n", sizeof(shared_audio_mem_t));

    hps_stream_init_shared(shared);

    test_song_counter(shared);
    test_event_handshake(shared);
    test_wav_reader();
    test_real_wav_stream_to_shared_buffer(shared);
    test_playlist_and_events(shared);
    test_polling_loop_limited(shared);

    hps_fpga_close();

    return 0;
}