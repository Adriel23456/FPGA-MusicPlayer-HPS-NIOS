#ifndef AUDIO_ENGINE_H
#define AUDIO_ENGINE_H

/* ----------------------------------------------------------------------
 *  audio_engine.h  --  write-interrupt-driven streaming to the WM8731.
 *
 *  Responsibilities:
 *    - open + reset the audio core and the AV-config core
 *    - on a write interrupt (FIFO >=75% empty), refill both L/R FIFOs from
 *      the current shared-RAM batch, honouring the song's logical sample
 *      rate by replicating each frame (CODEC_HW_RATE / logical_rate) times
 *    - advance through the 3-slot batch ring, requesting the next batch
 *    - report song-end when the batch flagged is_last is fully drained
 *    - support pause (mute the write IRQ / stop draining), resume, stop
 *      (reset position to song start), and a clean FIFO flush on song change
 *
 *  Song-end policy: AUDIO-BUFFER-DRIVEN. The 25 s timer is display only.
 * -------------------------------------------------------------------- */

#include "hw_map.h"
#include "shared_mem.h"

/* Called from the audio ISR (deferred-safe: just sets a flag the main loop
   acts on) when the current song's audio is fully consumed. */
typedef void (*song_end_cb_t)(void);

void audio_init(song_end_cb_t on_song_end);

/* Begin/replay streaming for the song whose batches are in the ring.
   `logical_rate` is the song's announced rate (8000/16000/48000). */
void audio_start(uint32_t logical_rate);

void audio_pause(void);    /* stop draining, keep position             */
void audio_resume(void);   /* re-enable write IRQ, continue            */
void audio_stop(void);     /* flush FIFOs + reset play position to 0   */

/* Reset all play position state for a new song (called on next/prev). */
void audio_rewind_for_new_song(uint32_t logical_rate);

/* Did the engine flag end-of-song? (cleared by reading.) */
int  audio_consume_song_end_flag(void);

/* Drift-free elapsed playback time (seconds) for the current song, derived
   from the count of source frames actually streamed. The display layer reads
   this each tick instead of counting software loop iterations. */
uint32_t audio_elapsed_seconds(void);

#endif /* AUDIO_ENGINE_H */