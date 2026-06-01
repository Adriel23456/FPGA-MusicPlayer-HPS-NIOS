# HPS ↔ Nios II Interconnection Context

## 1. Purpose

This file summarizes the current design decision for the interconnection between the **HPS ARM Cortex-A9** and the **Nios II soft processor** in the FPGA-MusicPlayer-HPS-NIOS project.

The goal is to give another chat, teammate, or Codex enough context to understand the shared-memory protocol without needing the full previous discussion.

---

## 2. Core Architecture

The HPS and Nios II communicate through a **shared memory region** inside the FPGA memory-mapped address space.

The HPS accesses this region from Linux userspace using:

```c
/dev/mem + mmap()
```

The Nios II accesses the same region using direct pointer access from its Platform Designer address map.

Conceptually:

```text
HPS Linux userspace app
        |
        | /dev/mem + mmap()
        v
HPS-to-FPGA bridge
        |
        v
Shared RAM in FPGA fabric
        ^
        |
Nios II direct pointer access
```

The HPS and Nios II are not communicating through UART, SPI, TCP, or direct function calls. They only coordinate through shared RAM.

---

## 3. Correct Control Direction

The HPS does **not** send playback commands to the Nios II.

Playback commands are triggered by hardware events handled by the Nios II side, such as:

```text
buttons
switches
interrupts
```

Correct control model:

```text
Hardware button/switch event
        |
        v
Nios II handles the event
        |
        v
Nios II writes event flag in shared memory
        |
        v
HPS reads event flag
        |
        v
HPS reacts by loading/changing/refilling song data
```

The HPS behaves as:

```text
file reader + WAV parser + audio-buffer producer
```

The Nios II behaves as:

```text
hardware event handler + playback controller + audio-buffer consumer
```

---

## 4. Responsibilities

### HPS Responsibilities

The HPS side is responsible for:

```text
- mapping shared RAM using /dev/mem + mmap()
- scanning the music directory
- counting valid WAV songs
- writing song_count to shared memory
- starting at song index 0
- loading WAV files
- validating WAV format
- extracting raw PCM audio data from WAV files
- filling shared audio buffers
- marking buffers READY
- handling NEXT/PREV/RESTART events from Nios II
- writing ACK bits after handling events
```

The HPS does not control playback timing.

### Nios II Responsibilities

The Nios II side is responsible for:

```text
- handling hardware buttons/switches
- consuming READY audio buffers
- feeding samples to the FPGA audio path
- marking consumed buffers EMPTY
- detecting BUF_FLAG_LAST
- requesting NEXT/PREV/RESTART through event flags
- clearing event flags after HPS acknowledges them
```

The Nios II owns playback behavior.

---

## 5. Shared Memory Should Stay Minimal

Design rule:

```text
Only add a shared memory field if the other processor truly needs to read it.
```

Reason:

```text
More shared fields = more polling
More shared fields = more synchronization rules
More shared fields = more stale-value risks
More shared fields = more integration bugs
```

For version 1, the shared memory contains only:

```text
1. Event flags from Nios II to HPS
2. ACK flags from HPS to Nios II
3. song_count from HPS to Nios II
4. Buffer descriptors
5. Raw audio buffers
```

---

## 6. Fields Intentionally Not Included

The following fields are intentionally **not** included in the minimal version:

```text
magic
version
hps_command
playback_state
requested_song_index
expected_sequence
sequence
checksum
reserved fields
shared-memory data_offset
underrun event
metadata fields
sample_rate
duration
channels
bits_per_sample
```

Why:

```text
- hps_command is removed because HPS does not command playback.
- playback_state is removed because HPS does not need continuous playback status.
- requested_song_index is removed because HPS starts at index 0 and increments/decrements locally.
- expected_sequence is removed because Nios II can keep local buffer order.
- sequence is removed because we now use strict circular buffer order.
- version is unnecessary for version 1.
- checksum/reserved/debug fields are postponed.
- metadata fields are not part of the interconnection unless another subsystem truly needs them.
```

---

## 7. Song Count

The maximum number of songs is 10, but the SD card may contain fewer valid WAV files.

Therefore, HPS must count valid songs first and write the count into shared memory.

Shared field:

```c
volatile uint32_t song_count;
```

Ownership:

```text
HPS writes song_count.
Nios II reads song_count.
```

Valid range:

```text
0 to MAX_SONGS
```

If:

```text
song_count = 0
```

then Nios II should not try to consume audio or request navigation.

If:

```text
song_count = 4
```

then the valid song indexes are:

```text
0, 1, 2, 3
```

If more than 10 valid songs exist, HPS limits the count to 10 for version 1.

---

## 8. Buffer Size Decision

The interconnection uses:

```text
3 audio buffers
16 KB per buffer
```

Header constants:

```c
#define NUM_BUFFERS    0x00000003u
#define AUDIO_BUF_SIZE 0x00004000u  /* 16384 bytes */
```

Total audio buffer area:

```text
3 × 16384 bytes = 49152 bytes = 48 KB
```

This is chosen because the highest required rate is:

```text
44.1 kHz, stereo, 16-bit PCM
```

For that format:

```text
1 sample = 16 bits = 2 bytes
1 stereo frame = 4 bytes
44,100 frames/s × 4 bytes/frame = 176,400 bytes/s
```

One 16 KB buffer lasts:

```text
16384 / 176400 ≈ 0.0928 seconds ≈ 92.8 ms
```

Three buffers provide:

```text
92.8 ms × 3 ≈ 278.4 ms
```

So the Nios II can have almost 278 ms of buffered audio when all three buffers are full.

---

## 9. PCM Meaning

PCM means **Pulse-Code Modulation**.

For this project, the audio format passed to Nios II is:

```text
16-bit signed stereo PCM
```

That means raw audio sample data, usually interleaved as:

```text
Left sample 0
Right sample 0
Left sample 1
Right sample 1
Left sample 2
Right sample 2
...
```

The HPS reads the WAV file, skips/parses the WAV header, and places only the raw PCM audio bytes into shared memory.

The Nios II does not need to parse WAV files.

---

## 10. Event and ACK Mechanism

The Nios II writes event flags when the HPS must react.

Example:

```c
nios_event_flags = NIOS_EVENT_NEXT_SONG;
```

The HPS reads the event, handles it, and writes the same bit to the ACK register:

```c
hps_event_ack = NIOS_EVENT_NEXT_SONG;
```

Purpose of ACK:

```text
Avoid both processors writing the same event register.
```

Ownership:

```text
Nios II owns/writes nios_event_flags.
HPS owns/writes hps_event_ack.
```

Flow:

```text
1. Nios II detects hardware event.
2. Nios II sets event bit in nios_event_flags.
3. HPS reads nios_event_flags.
4. HPS handles the event.
5. HPS writes matching bit to hps_event_ack.
6. Nios II sees ACK.
7. Nios II clears nios_event_flags.
8. HPS sees event cleared.
9. HPS clears hps_event_ack.
```

---

## 11. Buffer Descriptor

A buffer descriptor describes one audio buffer.

Minimal descriptor:

```c
typedef struct {
    volatile uint32_t state;
    volatile uint32_t size_bytes;
    volatile uint32_t flags;
} audio_buffer_desc_t;
```

Fields:

```text
state      -> buffer ownership state
size_bytes -> number of valid bytes in this buffer
flags      -> extra buffer info, currently BUF_FLAG_LAST
```

---

## 12. Buffer State Ownership

Each buffer follows this state cycle:

```text
EMPTY -> FILLING -> READY -> CONSUMING -> EMPTY
```

Ownership rules:

```text
HPS writes:
EMPTY -> FILLING
FILLING -> READY

Nios II writes:
READY -> CONSUMING
CONSUMING -> EMPTY
```

HPS can write audio data only when:

```text
state == BUF_EMPTY
```

Nios II can consume audio data only when:

```text
state == BUF_READY
```

---

## 13. No Sequence Field: Fixed Circular Buffer Order

The `sequence` field is intentionally removed.

Instead, both sides use a strict circular buffer order:

```text
Buffer 0 -> Buffer 1 -> Buffer 2 -> Buffer 0 -> ...
```

HPS local variable:

```c
static uint32_t fill_buffer = 0;
```

Nios II local variable:

```c
static uint32_t current_buffer = 0;
```

HPS fills:

```text
buffer 0
buffer 1
buffer 2
buffer 0
...
```

Nios II consumes:

```text
buffer 0
buffer 1
buffer 2
buffer 0
...
```

Important reset rule:

```text
When NEXT/PREV/RESTART happens, both sides must restart at buffer 0.
```

During a song change:

```text
HPS:
- handles event
- resets buffer states
- starts filling from buffer 0 again

Nios II:
- after ACK/event handling
- resets current_buffer = 0
- starts consuming from buffer 0 again
```

---

## 14. Why `size_bytes` Is Needed

Each buffer has capacity:

```text
16384 bytes
```

But the final buffer of a song may contain less valid data.

Example:

```text
capacity:   16384 bytes
valid data: 3000 bytes
```

Nios II must use `size_bytes` to know how many bytes to send to the audio path.

---

## 15. Why `flags` Is Needed

The important flag for version 1 is:

```c
#define BUF_FLAG_LAST 0x00000001u
```

It means:

```text
This is the final buffer of the current song.
```

This is needed because a song could end exactly on a full 16 KB buffer boundary.

---

## 16. End-of-Song Flow

When HPS reaches the end of the WAV file:

```text
1. HPS fills the final buffer.
2. HPS sets flags = BUF_FLAG_LAST.
3. HPS marks the buffer READY.
4. HPS stops filling more buffers.
5. HPS waits for the next Nios II event.
```

When Nios II consumes a buffer with `BUF_FLAG_LAST`:

```text
1. Nios II finishes playing the buffer.
2. Nios II knows the current song ended.
3. Nios II may request the next song.
4. Nios II sets NIOS_EVENT_NEXT_SONG.
5. HPS handles the event and loads the next song.
```

---

## 17. Minimal Shared Header

```c
#ifndef SHARED_PROTOCOL_H
#define SHARED_PROTOCOL_H

#include <stdint.h>

#define MAX_SONGS       0x0000000Au
#define NUM_BUFFERS     0x00000003u
#define AUDIO_BUF_SIZE  0x00004000u

#define AUDIO_BITS_PER_SAMPLE 0x00000010u
#define AUDIO_CHANNELS        0x00000002u

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

## 18. Header Location

Use one shared header for both processors:

```text
SoftwareDevelopment/common/include/shared_protocol.h
```

Both HPS and Nios II must include the same file so the memory layout matches byte-for-byte.

---

## 19. Final Interconnection Summary

The interconnection is:

```text
Nios II -> event flags -> HPS
HPS -> song_count + audio buffers + ACK -> Nios II
```

It is not:

```text
HPS -> playback commands -> Nios II
```

The protocol is intentionally minimal and based on:

```text
3 circular audio buffers
16 KB per buffer
event/ACK handshake
song_count publication
fixed circular order without sequence fields
```
