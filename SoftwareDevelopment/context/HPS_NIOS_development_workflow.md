# HPS ↔ Nios II Interconnection Development Workflow

## 1. Purpose

This file defines the proposed development workflow for implementing the HPS ↔ Nios II interconnection in the FPGA-MusicPlayer-HPS-NIOS project.

It focuses specifically on the coding and integration process for:

```text
HPS Linux userspace application
Nios II bare-metal application
Shared memory protocol
Buffer handshaking
Event/ACK handshaking
WAV/PCM streaming
```

---

## 2. Current Assumption

The Nios II side already has a playback implementation capable of playing dummy sounds.

Therefore, the interconnection work should not require rewriting the entire Nios II playback system.

Instead, the new goal is to provide a shared-memory audio input source:

```text
Before:
dummy sound generator -> Nios II audio output

After:
HPS-filled shared buffers -> Nios II audio output
```

The Nios II code should receive audio chunks from shared memory and feed them into the existing playback/audio-output logic.

---

## 3. Development Philosophy

Do not test everything at once.

Correct order:

```text
1. Shared protocol compiles.
2. HPS protocol logic works with fake memory.
3. Nios II protocol logic compiles.
4. HPS can access real shared RAM.
5. Nios II and HPS see the same RAM.
6. Dummy buffer handshake works.
7. Event/ACK handshake works.
8. HPS streams real WAV/PCM data.
9. Nios II sends shared-buffer data to audio output.
```

Main rule:

```text
Do not test audio until memory sharing works.
Do not test WAV streaming until buffer ownership works.
Do not test song changes until event/ACK works.
```

---

## 4. Shared Protocol First

Create the shared protocol header first.

Location:

```text
SoftwareDevelopment/common/include/shared_protocol.h
```

This file must be included by both:

```text
HPS Linux application
Nios II bare-metal application
```

It defines:

```text
MAX_SONGS
NUM_BUFFERS
AUDIO_BUF_SIZE
buffer states
buffer flags
Nios II event flags
ACK constants
audio_buffer_desc_t
shared_audio_mem_t
```

Do not maintain two separate copies unless absolutely necessary.

---

## 5. Recommended HPS Folder Structure

```text
SoftwareDevelopment/HPS-ARM_Cortex-A9/
├── Makefile
├── include/
│   ├── fpga_mem.h
│   ├── hps_fpga_comm.h
│   ├── hps_audio_streamer.h
│   └── wav_reader.h
└── src/
    ├── main.c
    ├── hps_fpga_comm.c
    ├── hps_audio_streamer.c
    └── wav_reader.c
```

Responsibilities:

```text
hps_fpga_comm.c:
- open /dev/mem
- mmap shared RAM
- unmap/close
- return pointer to shared_audio_mem_t

hps_audio_streamer.c:
- initialize shared fields
- count songs
- manage current song index
- fill buffers in circular order
- handle Nios II events
- reset stream on NEXT/PREV/RESTART

wav_reader.c:
- open WAV files
- parse WAV header
- validate format
- locate PCM data
- read PCM chunks
```

---

## 6. Recommended Nios II Folder Structure

```text
SoftwareDevelopment/NIOS-II/
├── app/
│   ├── main.c
│   ├── nios_shared_comm.c
│   ├── nios_audio_source.c
│   └── nios_events.c
├── include/
│   ├── nios_shared_comm.h
│   ├── nios_audio_source.h
│   └── nios_events.h
└── bsp/
```

Responsibilities:

```text
nios_shared_comm.c:
- define shared RAM pointer
- read song_count
- read/write buffer states
- write event flags
- read ACK flags

nios_audio_source.c:
- expose shared-buffer audio chunks to existing playback code
- manage current_buffer local variable
- mark buffers CONSUMING/EMPTY

nios_events.c:
- convert button/switch actions into NIOS_EVENT_* flags
- wait for HPS ACK
```

---

## 7. HPS Development Stages

### HPS Stage 1 — Compile-Only Skeleton

Create basic files and compile them before adding logic.

Minimum `main.c`:

```c
int main(void)
{
    return 0;
}
```

Minimum `hps_fpga_comm.h`:

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

Goal:

```text
HPS project compiles cleanly before real hardware logic.
```

### HPS Stage 2 — Fake Shared Memory Backend

Before testing `/dev/mem`, create fake shared memory mode.

Use compile flag:

```text
-DUSE_FAKE_SHARED_MEM
```

Fake backend:

```c
static shared_audio_mem_t fake_shared;

volatile shared_audio_mem_t *hps_fpga_get_shared(void)
{
    return &fake_shared;
}
```

Goal:

```text
Test HPS shared-memory logic on the PC without the board.
```

### HPS Stage 3 — Shared Memory Initialization

Implement:

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

### HPS Stage 4 — Song Counter

Implement:

```c
uint32_t hps_count_valid_songs(const char *music_dir);
```

First version may count `.wav` files. Later, valid means:

```text
file opens correctly
WAV format is supported
16-bit signed PCM
stereo
supported sample rate
```

After counting:

```c
shared->song_count = song_count;
```

Test cases:

```text
0 WAV files  -> song_count = 0
1 WAV file   -> song_count = 1
10 WAV files -> song_count = 10
15 WAV files -> song_count = 10
```

### HPS Stage 5 — Dummy Buffer Filling

Before reading real WAV files, fill buffers with dummy test patterns.

Example:

```c
int hps_fill_dummy_buffer(volatile shared_audio_mem_t *shared, uint32_t buffer_id)
{
    if (shared->buffers[buffer_id].state != BUF_EMPTY) {
        return -1;
    }

    shared->buffers[buffer_id].state = BUF_FILLING;

    for (uint32_t i = 0; i < AUDIO_BUF_SIZE; i++) {
        shared->audio_data[buffer_id][i] = (uint8_t)(buffer_id + i);
    }

    shared->buffers[buffer_id].size_bytes = AUDIO_BUF_SIZE;
    shared->buffers[buffer_id].flags = BUF_FLAG_NONE;
    shared->buffers[buffer_id].state = BUF_READY;

    return 0;
}
```

Goal:

```text
Prove HPS correctly performs EMPTY -> FILLING -> READY.
```

### HPS Stage 6 — Circular Buffer Fill Logic

Since there is no sequence field, the HPS must use a local circular index.

```c
static uint32_t fill_buffer = 0;

void hps_try_fill_next_buffer(volatile shared_audio_mem_t *shared)
{
    if (shared->buffers[fill_buffer].state == BUF_EMPTY) {
        hps_fill_dummy_buffer(shared, fill_buffer);
        fill_buffer = (fill_buffer + 1) % NUM_BUFFERS;
    }
}
```

Rule:

```text
HPS fills buffer 0 -> 1 -> 2 -> 0 -> ...
```

On song change or restart:

```c
fill_buffer = 0;
```

### HPS Stage 7 — Event Handling

Implement HPS-side event handling.

```c
void hps_handle_nios_events(volatile shared_audio_mem_t *shared)
{
    uint32_t events = shared->nios_event_flags;

    if (events & NIOS_EVENT_NEXT_SONG) {
        shared->hps_event_ack |= NIOS_EVENT_NEXT_SONG;
    }

    if (events & NIOS_EVENT_PREV_SONG) {
        shared->hps_event_ack |= NIOS_EVENT_PREV_SONG;
    }

    if (events & NIOS_EVENT_RESTART) {
        shared->hps_event_ack |= NIOS_EVENT_RESTART;
    }

    if (shared->nios_event_flags == NIOS_EVENT_NONE) {
        shared->hps_event_ack = HPS_ACK_NONE;
    }
}
```

### HPS Stage 8 — Real `/dev/mem` Backend

After fake-memory tests work, implement real mapping in `hps_fpga_comm.c`.

This module hides:

```text
open("/dev/mem")
mmap()
munmap()
close()
```

The rest of the HPS code should only use:

```c
volatile shared_audio_mem_t *shared = hps_fpga_get_shared();
```

### HPS Stage 9 — WAV Reader

Implement:

```c
int wav_open(const char *path, wav_info_t *info);
int wav_read_pcm_chunk(wav_info_t *info,
                       volatile uint8_t *dst,
                       uint32_t max_bytes,
                       uint32_t *bytes_read,
                       int *is_last);
void wav_close(wav_info_t *info);
```

HPS validates:

```text
16-bit signed PCM
stereo
supported sample rate
```

### HPS Stage 10 — Real Audio Buffer Filling

Replace dummy filling with WAV/PCM filling.

Flow:

```text
1. Check buffer state == BUF_EMPTY.
2. Set state = BUF_FILLING.
3. Read up to AUDIO_BUF_SIZE bytes of PCM from WAV file.
4. Write data into audio_data[buffer_id].
5. Set size_bytes.
6. If final chunk, set flags = BUF_FLAG_LAST.
7. Else, flags = BUF_FLAG_NONE.
8. Set state = BUF_READY.
```

---

## 8. Nios II Development Stages

### Nios II Stage 1 — Compile-Only Skeleton

Create:

```text
nios_shared_comm.h/.c
nios_audio_source.h/.c
nios_events.h/.c
main.c
```

Minimum `main.c`:

```c
#include "shared_protocol.h"

int main(void)
{
    while (1) {
    }

    return 0;
}
```

### Nios II Stage 2 — Shared Memory Pointer

Define the shared RAM base address from Platform Designer.

Example placeholder:

```c
#define SHARED_RAM_BASE 0x00020000u
```

Then:

```c
volatile shared_audio_mem_t *shared =
    (volatile shared_audio_mem_t *)SHARED_RAM_BASE;
```

This address must match the Nios II Platform Designer address map.

### Nios II Stage 3 — Song Count Reader

Implement:

```c
uint32_t nios_get_song_count(void)
{
    return shared->song_count;
}
```

Behavior:

```text
if song_count == 0:
    do not consume buffers
    optionally show no songs available

if song_count > 0:
    proceed with buffer consumption
```

### Nios II Stage 4 — Shared Buffer Audio Source Adapter

Since the colleague already has Nios II dummy playback, create an adapter that provides audio chunks from shared memory.

Suggested API:

```c
typedef struct {
    volatile uint8_t *data;
    uint32_t size_bytes;
    uint32_t flags;
    uint32_t buffer_id;
} nios_audio_chunk_t;

int nios_get_next_audio_chunk(nios_audio_chunk_t *chunk);
void nios_release_audio_chunk(uint32_t buffer_id);
```

Purpose:

```text
nios_get_next_audio_chunk():
- checks current circular buffer
- if READY, marks it CONSUMING
- returns pointer, size, flags, buffer_id

existing audio playback code:
- sends chunk.data to audio hardware for chunk.size_bytes bytes

nios_release_audio_chunk():
- marks that buffer EMPTY
```

### Nios II Stage 5 — Circular Buffer Consumer

No sequence checking is needed.

Use local circular index:

```c
static uint32_t current_buffer = 0;
```

Example:

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

void nios_release_audio_chunk(uint32_t buffer_id)
{
    shared->buffers[buffer_id].state = BUF_EMPTY;
    current_buffer = (current_buffer + 1) % NUM_BUFFERS;
}
```

On song change or restart:

```c
current_buffer = 0;
```

### Nios II Stage 6 — Event Generation

Implement event functions:

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
void nios_wait_for_ack(uint32_t event)
{
    while ((shared->hps_event_ack & event) == 0) {
        /*
         * Version 1: simple wait.
         * Later: add timeout if needed.
         */
    }

    shared->nios_event_flags &= ~event;
}
```

### Nios II Stage 7 — Button Integration

Only after event generation works manually, connect buttons.

Button ISR should stay small:

```text
detect which button was pressed
set a local request flag
return
```

The main loop can then call:

```text
nios_request_next_song()
nios_request_prev_song()
nios_request_restart()
```

Avoid doing heavy shared-memory or audio work inside the ISR.

### Nios II Stage 8 — Existing Audio Playback Integration

The colleague already has dummy audio playback.

The integration should replace the dummy source with the shared buffer source.

Conceptual flow:

```text
while playing:
    if nios_get_next_audio_chunk(&chunk):
        send chunk.data to existing audio output path
        send exactly chunk.size_bytes bytes
        if chunk.flags has BUF_FLAG_LAST:
            request next song after release
        nios_release_audio_chunk(chunk.buffer_id)
```

Important rule:

```text
Never read beyond chunk.size_bytes.
```

---

## 9. Integration Tests

### Integration Test 1 — HPS Fake Memory Test

Environment:

```text
PC / development machine
No board required
```

Goal:

```text
Test HPS protocol logic using fake shared memory.
```

### Integration Test 2 — HPS Real Shared RAM Access

Environment:

```text
Board required
FPGA programmed
HPS bridge enabled
```

Goal:

```text
Prove HPS can access shared RAM through /dev/mem + mmap().
```

Example:

```text
HPS writes 0xDEADBEEF.
HPS reads 0xDEADBEEF.
```

This proves only:

```text
HPS -> bridge -> shared RAM
```

### Integration Test 3 — HPS and Nios II See Same RAM

Goal:

```text
Prove both processors are connected to the same shared RAM.
```

Test:

```text
HPS writes 0xDEADBEEF.
Nios II reads it.
Nios II writes 0xA55A1234.
HPS reads it.
```

### Integration Test 4 — Dummy Buffer Handshake

Goal:

```text
Prove the buffer state protocol works.
```

Test:

```text
HPS fills dummy buffer.
HPS marks it READY.
Nios II sees READY.
Nios II marks CONSUMING.
Nios II reads/counts dummy bytes.
Nios II marks EMPTY.
HPS refills the buffer.
```

### Integration Test 5 — Event/ACK Handshake

Goal:

```text
Prove event ownership works.
```

Test:

```text
Nios II sets NIOS_EVENT_NEXT_SONG.
HPS sees event.
HPS acknowledges using hps_event_ack.
Nios II sees ACK.
Nios II clears nios_event_flags.
HPS clears hps_event_ack.
```

Repeat for:

```text
NIOS_EVENT_PREV_SONG
NIOS_EVENT_RESTART
```

### Integration Test 6 — Real WAV/PCM Streaming Without Audio

Goal:

```text
Prove HPS can read real WAV files and place PCM data into shared buffers.
```

Test:

```text
HPS scans music directory.
HPS writes song_count.
HPS opens song 0.
HPS validates WAV format.
HPS fills buffers with real PCM data.
Nios II consumes buffers and counts/discards bytes.
Nios II detects BUF_FLAG_LAST.
```

### Integration Test 7 — Real WAV/PCM Streaming With Audio Output

Goal:

```text
Connect shared-buffer data to the colleague's existing Nios II audio playback.
```

Test:

```text
HPS fills shared buffers with real PCM data.
Nios II receives chunks through nios_get_next_audio_chunk().
Nios II sends chunks to existing audio output path.
Audio plays continuously.
```

Check:

```text
no obvious gaps
NEXT works
PREV works
RESTART works
end-of-song triggers expected behavior
```

---

## 10. Final Coding Order

Recommended order:

```text
1. shared_protocol.h
2. HPS fake shared-memory backend
3. HPS shared-memory initialization
4. HPS song counter
5. HPS dummy buffer filler
6. HPS circular fill logic
7. HPS event handler
8. Nios II shared-memory pointer setup
9. Nios II song_count reader
10. Nios II shared-buffer audio source adapter
11. Nios II circular buffer consumer
12. Nios II event generator + ACK wait
13. HPS real /dev/mem backend
14. HPS WAV reader
15. HPS real PCM buffer filler
16. Nios II button integration
17. Nios II existing audio playback integration
```

This order lets each part be tested before adding the next layer.
