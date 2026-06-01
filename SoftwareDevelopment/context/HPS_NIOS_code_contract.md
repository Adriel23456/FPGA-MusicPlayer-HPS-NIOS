# HPS ↔ Nios II Code Contract

## 1. Purpose

This file defines the expected code-level contract for the HPS ↔ Nios II interconnection in the FPGA-MusicPlayer-HPS-NIOS project.

It is meant to guide future development in another chat, teammate discussion, or Codex session.

The interconnection is based on:

```text
shared memory
3 circular audio buffers
16 KB per buffer
event/ACK handshake
song_count publication
no sequence field
no HPS playback commands
```

---

## 2. Shared Protocol Header

Both HPS and Nios II must include the same header:

```text
SoftwareDevelopment/common/include/shared_protocol.h
```

There should not be separate manually-maintained copies unless absolutely necessary.

Minimal protocol:

```c
#ifndef SHARED_PROTOCOL_H
#define SHARED_PROTOCOL_H

#include <stdint.h>

#define MAX_SONGS       0x0000000Au

#define NUM_BUFFERS     0x00000003u
#define AUDIO_BUF_SIZE  0x00004000u  /* 16384 bytes */

#define AUDIO_BITS_PER_SAMPLE 0x00000010u  /* 16-bit signed PCM */
#define AUDIO_CHANNELS        0x00000002u  /* stereo */

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
    volatile uint32_t nios_event_flags;
    volatile uint32_t hps_event_ack;
    volatile uint32_t song_count;

    audio_buffer_desc_t buffers[NUM_BUFFERS];

    volatile uint8_t audio_data[NUM_BUFFERS][AUDIO_BUF_SIZE];

} shared_audio_mem_t;

#endif
```

---

## 3. Ownership Rules

### Nios II-owned shared fields

Nios II writes:

```text
nios_event_flags
BUF_READY -> BUF_CONSUMING
BUF_CONSUMING -> BUF_EMPTY
```

HPS may read those fields, but should not write them except during initial shared-memory reset before normal operation starts.

### HPS-owned shared fields

HPS writes:

```text
hps_event_ack
song_count
BUF_EMPTY -> BUF_FILLING
BUF_FILLING -> BUF_READY
buffer size_bytes
buffer flags
audio_data[][]
```

Nios II may read those fields, but should not write them.

---

## 4. Circular Buffer Rule

There is no `sequence` field.

Both processors must follow fixed circular order:

```text
buffer 0 -> buffer 1 -> buffer 2 -> buffer 0 -> ...
```

HPS keeps a local variable:

```c
static uint32_t fill_buffer = 0;
```

Nios II keeps a local variable:

```c
static uint32_t current_buffer = 0;
```

Both must reset their local index to zero on song change or restart:

```c
fill_buffer = 0;      /* HPS side */
current_buffer = 0;   /* Nios II side */
```

---

## 5. HPS Module Contract

Recommended HPS modules:

```text
hps_fpga_comm.c/.h
hps_audio_streamer.c/.h
wav_reader.c/.h
```

---

## 6. `hps_fpga_comm.h` Contract

This module owns `/dev/mem` and `mmap()`.

No other HPS module should directly call `/dev/mem` or `mmap()`.

Expected API:

```c
#ifndef HPS_FPGA_COMM_H
#define HPS_FPGA_COMM_H

#include <stdint.h>
#include <stddef.h>
#include "shared_protocol.h"

int hps_fpga_init(uintptr_t phys_base, size_t map_size);
void hps_fpga_close(void);

volatile shared_audio_mem_t *hps_fpga_get_shared(void);

#endif
```

### `hps_fpga_init()`

Purpose:

```text
Open /dev/mem.
Map the shared RAM physical address.
Store the mapped pointer internally.
```

Returns:

```text
0 on success
negative value on error
```

Must not:

```text
parse WAV files
fill audio buffers
handle Nios II events
```

### `hps_fpga_close()`

Purpose:

```text
Unmap shared RAM.
Close /dev/mem.
Clear internal pointer.
```

### `hps_fpga_get_shared()`

Purpose:

```text
Return pointer to shared_audio_mem_t.
```

Must return:

```text
valid pointer after hps_fpga_init()
NULL or invalid only if init failed
```

---

## 7. Fake Shared Memory Backend

For PC-side tests, HPS code may support fake shared memory.

Compile flag:

```text
-DUSE_FAKE_SHARED_MEM
```

Expected behavior:

```c
static shared_audio_mem_t fake_shared;

volatile shared_audio_mem_t *hps_fpga_get_shared(void)
{
    return &fake_shared;
}
```

Purpose:

```text
Test HPS protocol logic without the FPGA board.
```

---

## 8. `hps_audio_streamer.h` Contract

This module owns the HPS-side streaming logic.

Expected API:

```c
#ifndef HPS_AUDIO_STREAMER_H
#define HPS_AUDIO_STREAMER_H

#include <stdint.h>
#include "shared_protocol.h"

void hps_stream_init_shared(volatile shared_audio_mem_t *shared);

uint32_t hps_count_valid_songs(const char *music_dir);

int hps_stream_start_song(volatile shared_audio_mem_t *shared,
                          const char *music_dir,
                          uint32_t song_index);

int hps_stream_try_fill_next_buffer(volatile shared_audio_mem_t *shared);

void hps_stream_handle_nios_events(volatile shared_audio_mem_t *shared);

void hps_stream_reset_buffers(volatile shared_audio_mem_t *shared);

#endif
```

---

## 9. `hps_stream_init_shared()`

Purpose:

```text
Initialize shared memory fields to safe startup values.
```

Expected behavior:

```c
void hps_stream_init_shared(volatile shared_audio_mem_t *shared)
{
    shared->nios_event_flags = NIOS_EVENT_NONE;
    shared->hps_event_ack = HPS_ACK_NONE;
    shared->song_count = 0;

    for (uint32_t i = 0; i < NUM_BUFFERS; i++) {
        shared->buffers[i].state = BUF_EMPTY;
        shared->buffers[i].size_bytes = 0;
        shared->buffers[i].flags = BUF_FLAG_NONE;
    }
}
```

Must happen before normal streaming begins.

---

## 10. `hps_count_valid_songs()`

Purpose:

```text
Scan the music directory and count valid WAV files.
```

Version 1 may initially count `.wav` files only.

Final validation should check:

```text
file opens correctly
WAV format is supported
16-bit signed PCM
stereo
supported sample rate
```

Must clamp count to:

```c
MAX_SONGS
```

After counting, caller should write:

```c
shared->song_count = count;
```

---

## 11. `hps_stream_start_song()`

Purpose:

```text
Start streaming a specific song index.
```

Expected behavior:

```text
validate song_index
open selected WAV file
validate WAV format
reset buffers
reset local fill_buffer to 0
prepare internal WAV reader state
begin filling from buffer 0
```

Must not:

```text
send PLAY/PAUSE/NEXT commands to Nios II
```

The HPS does not command playback.

---

## 12. `hps_stream_try_fill_next_buffer()`

Purpose:

```text
If the current circular buffer is EMPTY, fill it with the next PCM chunk.
```

Expected behavior:

```text
1. Check shared->buffers[fill_buffer].state.
2. If not BUF_EMPTY, return without writing.
3. Set state = BUF_FILLING.
4. Read up to AUDIO_BUF_SIZE bytes of PCM.
5. Write PCM bytes into audio_data[fill_buffer].
6. Set size_bytes.
7. Set flags = BUF_FLAG_LAST if final chunk, else BUF_FLAG_NONE.
8. Set state = BUF_READY.
9. Advance fill_buffer = (fill_buffer + 1) % NUM_BUFFERS.
```

Important order:

```text
write audio data first
write size_bytes and flags second
write state = BUF_READY last
```

Must not:

```text
write into a buffer unless state == BUF_EMPTY
write state READY before data is complete
skip circular order
```

---

## 13. `hps_stream_handle_nios_events()`

Purpose:

```text
React to Nios II event flags.
```

Expected behavior:

```text
If NIOS_EVENT_NEXT_SONG:
    move to next local song index
    reset stream
    start filling from buffer 0
    write ACK bit

If NIOS_EVENT_PREV_SONG:
    move to previous local song index
    reset stream
    start filling from buffer 0
    write ACK bit

If NIOS_EVENT_RESTART:
    restart current local song index
    reset stream
    start filling from buffer 0
    write ACK bit

If nios_event_flags == NIOS_EVENT_NONE:
    clear hps_event_ack
```

Important:

```text
HPS maintains current_song_index locally.
No requested_song_index field exists in shared memory.
```

Must not:

```text
modify nios_event_flags during normal operation
send playback commands to Nios II
```

---

## 14. `hps_stream_reset_buffers()`

Purpose:

```text
Prepare shared buffers for a new song or restart.
```

Expected behavior:

```text
set all buffer states to BUF_EMPTY
set all size_bytes to 0
set all flags to BUF_FLAG_NONE
reset local fill_buffer to 0
```

This must happen on:

```text
NEXT
PREV
RESTART
startup
```

---

## 15. `wav_reader.h` Contract

This module owns WAV parsing and PCM extraction.

Expected API:

```c
#ifndef WAV_READER_H
#define WAV_READER_H

#include <stdint.h>

typedef struct {
    /* implementation-specific file handle/state */
    uint32_t sample_rate;
    uint32_t data_size;
    uint32_t bytes_remaining;
} wav_info_t;

int wav_open(const char *path, wav_info_t *info);

int wav_read_pcm_chunk(wav_info_t *info,
                       volatile uint8_t *dst,
                       uint32_t max_bytes,
                       uint32_t *bytes_read,
                       int *is_last);

void wav_close(wav_info_t *info);

#endif
```

Required WAV format:

```text
16-bit signed PCM
stereo
supported sample rates: 8 kHz, 16 kHz, 44.1 kHz
```

The WAV reader must return only raw PCM bytes.

Nios II must not parse WAV headers.

---

## 16. Nios II Module Contract

Recommended Nios II modules:

```text
nios_shared_comm.c/.h
nios_audio_source.c/.h
nios_events.c/.h
```

---

## 17. `nios_shared_comm.h` Contract

This module owns the shared memory pointer and simple shared-memory access helpers.

Expected API:

```c
#ifndef NIOS_SHARED_COMM_H
#define NIOS_SHARED_COMM_H

#include <stdint.h>
#include "shared_protocol.h"

void nios_shared_init(uintptr_t shared_base);

volatile shared_audio_mem_t *nios_shared_get(void);

uint32_t nios_get_song_count(void);

#endif
```

### `nios_shared_init()`

Purpose:

```text
Set the local shared_audio_mem_t pointer using the Platform Designer shared RAM base address.
```

Example:

```c
static volatile shared_audio_mem_t *shared = 0;

void nios_shared_init(uintptr_t shared_base)
{
    shared = (volatile shared_audio_mem_t *)shared_base;
}
```

---

## 18. `nios_audio_source.h` Contract

This module adapts shared buffers into the existing Nios II audio playback code.

Expected API:

```c
#ifndef NIOS_AUDIO_SOURCE_H
#define NIOS_AUDIO_SOURCE_H

#include <stdint.h>

typedef struct {
    volatile uint8_t *data;
    uint32_t size_bytes;
    uint32_t flags;
    uint32_t buffer_id;
} nios_audio_chunk_t;

void nios_audio_source_reset(void);

int nios_get_next_audio_chunk(nios_audio_chunk_t *chunk);

void nios_release_audio_chunk(uint32_t buffer_id);

#endif
```

---

## 19. `nios_audio_source_reset()`

Purpose:

```text
Reset local circular consumer index to buffer 0.
```

Expected behavior:

```c
current_buffer = 0;
```

Must be called on:

```text
startup
NEXT
PREV
RESTART
after HPS ACK when switching streams
```

---

## 20. `nios_get_next_audio_chunk()`

Purpose:

```text
Check if the current circular buffer is READY.
If yes, mark it CONSUMING and return its data pointer, size, flags, and buffer ID.
```

Expected behavior:

```c
int nios_get_next_audio_chunk(nios_audio_chunk_t *chunk)
{
    if (shared->buffers[current_buffer].state != BUF_READY) {
        return 0;
    }

    shared->buffers[current_buffer].state = BUF_CONSUMING;

    chunk->data = shared->audio_data[current_buffer];
    chunk->size_bytes = shared->buffers[current_buffer].size_bytes;
    chunk->flags = shared->buffers[current_buffer].flags;
    chunk->buffer_id = current_buffer;

    return 1;
}
```

Must not:

```text
consume buffers out of circular order
read from a buffer unless state == BUF_READY
read beyond size_bytes
mark buffer EMPTY before playback code is finished with it
```

---

## 21. `nios_release_audio_chunk()`

Purpose:

```text
Release a buffer after the existing audio playback code finishes consuming it.
```

Expected behavior:

```c
void nios_release_audio_chunk(uint32_t buffer_id)
{
    shared->buffers[buffer_id].state = BUF_EMPTY;
    current_buffer = (current_buffer + 1) % NUM_BUFFERS;
}
```

Must not:

```text
release a buffer before all size_bytes have been consumed
advance current_buffer before releasing
```

---

## 22. `nios_events.h` Contract

This module owns Nios II event generation and ACK handling.

Expected API:

```c
#ifndef NIOS_EVENTS_H
#define NIOS_EVENTS_H

#include <stdint.h>

void nios_request_next_song(void);
void nios_request_prev_song(void);
void nios_request_restart(void);

int nios_wait_for_ack(uint32_t event);

#endif
```

---

## 23. Nios II Event Functions

Expected behavior:

```c
void nios_request_next_song(void)
{
    shared->nios_event_flags |= NIOS_EVENT_NEXT_SONG;
}

void nios_request_prev_song(void)
{
    shared->nios_event_flags |= NIOS_EVENT_PREV_SONG;
}

void nios_request_restart(void)
{
    shared->nios_event_flags |= NIOS_EVENT_RESTART;
}
```

ACK wait:

```c
int nios_wait_for_ack(uint32_t event)
{
    while ((shared->hps_event_ack & event) == 0) {
        /*
         * Version 1: simple wait.
         * Later: add timeout.
         */
    }

    shared->nios_event_flags &= ~event;
    return 0;
}
```

After ACK for NEXT/PREV/RESTART:

```text
Nios II must reset current_buffer to 0.
```

---

## 24. Existing Nios II Playback Integration

Your colleague already has Nios II dummy playback.

The new integration should replace the dummy source with shared-buffer chunks.

Conceptual usage:

```c
nios_audio_chunk_t chunk;

if (nios_get_next_audio_chunk(&chunk)) {
    /*
     * Existing playback code sends chunk.data to audio hardware.
     * It must send exactly chunk.size_bytes bytes.
     */

    if (chunk.flags & BUF_FLAG_LAST) {
        /*
         * Current song ended.
         * Request next song after releasing the buffer.
         */
    }

    nios_release_audio_chunk(chunk.buffer_id);
}
```

Important:

```text
The existing playback code must not read beyond chunk.size_bytes.
The shared buffer must not be marked EMPTY until playback has consumed it.
```

---

## 25. Reset Rules

On startup:

```text
HPS initializes shared fields.
Nios II sets current_buffer = 0.
HPS sets fill_buffer = 0.
```

On NEXT/PREV/RESTART:

```text
Nios II sets event flag.
HPS handles event.
HPS resets buffers.
HPS sets fill_buffer = 0.
HPS starts filling from buffer 0.
HPS sets ACK.
Nios II sees ACK.
Nios II clears event.
Nios II sets current_buffer = 0.
```

This reset rule is critical because there is no sequence field.

---

## 26. Must-Not Rules

### HPS must not

```text
send playback commands to Nios II
write nios_event_flags during normal operation
write into a buffer unless it is BUF_EMPTY
set BUF_READY before data, size_bytes, and flags are valid
skip circular buffer order
```

### Nios II must not

```text
parse WAV headers
read from a buffer unless it is BUF_READY
read beyond size_bytes
write hps_event_ack
consume buffers out of circular order
mark a buffer EMPTY before playback is done with it
```

---

## 27. Summary

The code contract is:

```text
HPS owns file/WAV reading and buffer production.
Nios II owns hardware events and buffer consumption.
Both communicate only through shared_audio_mem_t.
No sequence field exists.
Correctness depends on fixed circular order and reset-to-buffer-0 on song changes.
```
