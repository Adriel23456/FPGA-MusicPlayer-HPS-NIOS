#include <stdint.h>
#include <dirent.h>
#include <string.h>
#include <stdio.h>

#include "wav_reader.h"
#include "hps_audio_streamer.h"

static uint32_t fill_buffer = 0;
static wav_info_t current_wav;
static int current_wav_open = 0;

#define MUSIC_PATH_MAX 256u

static char song_paths[MAX_SONGS][MUSIC_PATH_MAX];
static uint32_t playlist_count = 0;
static uint32_t current_song_index = 0;

void hps_stream_init_shared(volatile shared_audio_mem_t *shared){

    if (shared == 0){
        return;
    }

    shared->nios_event_flags = NIOS_EVENT_NONE;
    shared->hps_event_ack = HPS_ACK_NONE;
    shared->song_count= 0;
    fill_buffer = 0;

    //initialize all buffers 
    for(uint32_t i = 0; i < NUM_BUFFERS; i++){
        shared->buffers[i].state = BUF_EMPTY;
        shared->buffers[i].size_bytes = 0;
        shared->buffers[i].flags = BUF_FLAG_NONE;
    }

    shared->current_metadata.valid = 0;
    shared->current_metadata.duration_seconds = 0;

    for (uint32_t i = 0; i < META_TEXT_MAX; i++) {
        shared->current_metadata.title[i] = '\0';
        shared->current_metadata.artist[i] = '\0';
        shared->current_metadata.album[i] = '\0';
    }
}

static int has_wav_extension(const char* filename){
    const char *dot;

    if (filename == 0){
        return 0;
   }

   dot = strrchr(filename, '.');

   if(dot == 0){
        return 0;
   }

   return strcmp (".wav", dot) == 0;
}

uint32_t hps_count_valid_songs(const char* music_dir){
    DIR *dir;
    struct dirent *entry;
    uint32_t count = 0;

    if(music_dir == 0){
        return 0;
    }

    dir = opendir(music_dir);
    
    if(dir == 0){
        return 0;
    }

    while ((entry = readdir(dir))!= 0)
    {
        if(has_wav_extension(entry->d_name)){
            count ++;
            if(count>= MAX_SONGS){
                break;
            }
        }
    }
    
    closedir(dir);
    return count;
}

static int build_song_path(char *dst, uint32_t dst_size, const char *music_dir,
const char *filename){
    int written;

    if(dst == 0 || dst_size == 0 || filename == 0 || music_dir == 0){
        return -1;
    }

    written = snprintf(dst, dst_size, "%s/%s", music_dir, filename);

    if (written < 0 || (uint32_t)written >= dst_size) {
        return -1;
    }

    return 0;
}

int hps_stream_load_playlist(volatile shared_audio_mem_t *shared,
                             const char *music_dir)
{
    DIR *dir;
    struct dirent *entry;

    if (shared == 0 || music_dir == 0) {
        return -1;
    }

    playlist_count = 0u;
    current_song_index = 0u;

    dir = opendir(music_dir);

    if (dir == 0) {
        shared->song_count = 0u;
        return -1;
    }

    while ((entry = readdir(dir)) != 0) {
        if (has_wav_extension(entry->d_name)) {
            if (playlist_count >= MAX_SONGS) {
                break;
            }

            if (build_song_path(song_paths[playlist_count],
                                MUSIC_PATH_MAX,
                                music_dir,
                                entry->d_name) == 0) {
                playlist_count++;
            }
        }
    }

    closedir(dir);

    shared->song_count = playlist_count;

    if (playlist_count == 0u) {
        return 0;
    }

    /*
     * Start the first song automatically.
     */
    if (hps_stream_start_wav_file(shared, song_paths[0]) != 0) {
        shared->song_count = 0u;
        playlist_count = 0u;
        return -1;
    }

    return 0;
}

int hps_stream_try_fill_next_buffer(volatile shared_audio_mem_t *shared){
    uint32_t bytes_read = 0;
    int is_last = 0;
        
    if (shared == 0){
        return -1;
    }

    if (!current_wav_open) {
        return -1;
    }

    if(shared->buffers[fill_buffer].state != BUF_EMPTY){
        return 0;
    }

    shared->buffers[fill_buffer].state = BUF_FILLING;

    if (wav_read_pcm_chunk(&current_wav, shared->audio_data[fill_buffer],
        AUDIO_BUF_SIZE, &bytes_read, &is_last) != 0){
            shared->buffers[fill_buffer].state = BUF_EMPTY;
            return -1;
    }
    if(bytes_read == 0){
        shared->buffers[fill_buffer].state = BUF_EMPTY;
        return 0;
    }

    shared->buffers[fill_buffer].size_bytes = bytes_read;
    shared->buffers[fill_buffer].flags = is_last ? BUF_FLAG_LAST : BUF_FLAG_NONE;
    shared->buffers[fill_buffer].state = BUF_READY;
    
    fill_buffer = (fill_buffer + 1)  % NUM_BUFFERS;
    return 1;
}

static void hps_stream_reset_buffers(volatile shared_audio_mem_t *shared)
{
    if (shared == 0) {
        return;
    }

    for (uint32_t i = 0; i < NUM_BUFFERS; i++) {
        shared->buffers[i].state = BUF_EMPTY;
        shared->buffers[i].size_bytes = 0;
        shared->buffers[i].flags = BUF_FLAG_NONE;
    }

    fill_buffer = 0;
}

static void copy_shared_text(const char *src, volatile char *target){
    uint32_t i = 0;
    if(src == 0 || target == 0){
        return;
    }

    for(i = 0; i < META_TEXT_MAX - 1u && src[i] != '\0'; i++){
        target[i] = src[i];
    }

    target[i] = '\0';

    for (i = i + 1u; i < META_TEXT_MAX; i++) {
        target[i] = '\0';
    }
}

int hps_stream_start_wav_file(volatile shared_audio_mem_t *shared, const char *path){
    if (shared == 0 || path == 0){
        return -1;
    }
    if(current_wav_open){
        wav_close(&current_wav);
        current_wav_open = 0;
    }
    hps_stream_reset_buffers(shared);

    shared->current_metadata.valid = 0;
    shared->current_metadata.duration_seconds = 0;

    if(wav_open(path, &current_wav)!= 0){
        return -1;
    }

    current_wav_open = 1;

    copy_shared_text(current_wav.metadata.title,
                    shared->current_metadata.title);

    copy_shared_text(current_wav.metadata.artist,
                    shared->current_metadata.artist);

    copy_shared_text(current_wav.metadata.album,
                    shared->current_metadata.album);

    shared->current_metadata.duration_seconds = current_wav.duration_seconds;

    /*
     * Write valid last.
     * Nios II should only read metadata when valid == 1.
     */
    shared->current_metadata.valid = 1;

    fill_buffer = 0;

    return 0;
}

void hps_stream_handle_nios_events(volatile shared_audio_mem_t *shared)
{
    uint32_t events;

    if (shared == 0) {
        return;
    }

    events = shared->nios_event_flags;

    if (events == NIOS_EVENT_NONE) {
        shared->hps_event_ack = HPS_ACK_NONE;
        return;
    }

    if (playlist_count == 0u) {
        shared->hps_event_ack |= events;
        return;
    }

    if (events & NIOS_EVENT_NEXT_SONG) {
        uint32_t next_index = (current_song_index + 1u) % playlist_count;

        if (hps_stream_start_wav_file(shared, song_paths[next_index]) == 0) {
            current_song_index = next_index;
            shared->hps_event_ack |= NIOS_EVENT_NEXT_SONG;
        }

        return;
    }

    if (events & NIOS_EVENT_PREV_SONG) {
        uint32_t prev_index;

        if (current_song_index == 0u) {
            prev_index = playlist_count - 1u;
        } else {
            prev_index = current_song_index - 1u;
        }

        if (hps_stream_start_wav_file(shared, song_paths[prev_index]) == 0) {
            current_song_index = prev_index;
            shared->hps_event_ack |= NIOS_EVENT_PREV_SONG;
        }

        return;
    }

    if (events & NIOS_EVENT_RESTART) {
        if (hps_stream_start_wav_file(shared, song_paths[current_song_index]) == 0) {
            shared->hps_event_ack |= NIOS_EVENT_RESTART;
        }

        return;
    }
}