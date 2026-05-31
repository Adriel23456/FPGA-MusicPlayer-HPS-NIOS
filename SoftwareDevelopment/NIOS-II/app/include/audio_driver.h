#ifndef AUDIO_DRIVER_H
#define AUDIO_DRIVER_H

#include <stdint.h>

/* AUDIO_OUT (write-only, 16-bit, IRQ 3) + AUDIO_CONFIG (I2C). The codec runs
 * at a FIXED 48 kHz; any source rate is converted to it by the fractional
 * resampling engine below. */
#define AUDIO_OUT_IRQ_NUM   3
#define AUDIO_HW_RATE_HZ    48000u

/* Source sample rates. Stored as the actual rate in Hz because 44.1 kHz is
 * NOT an integer divisor of 48 kHz -> fractional resampling is required. */
typedef enum {
    RATE_48K  = 48000,
    RATE_44K1 = 44100,
    RATE_16K  = 16000,
    RATE_8K   = 8000
} audio_rate_t;

int  audio_init(void);
void audio_enable_write_irq(void);
void audio_disable_write_irq(void);

/* ---- REUSABLE ENGINE (blocking) ----
 * Play `count` mono 16-bit samples captured at `src_rate_hz` on the fixed
 * 48 kHz output, using 16.16 fixed-point fractional linear-interpolating
 * resampling. Blocks until the whole buffer has been pushed. `phase_in` is
 * the leftover fractional position from the previous chunk (0 to start);
 * the returned value feeds the next call so chunked playback stays
 * phase-continuous (no seam clicks). Used by the tone self-test. */
uint32_t audio_play_buffer(const int16_t *src, unsigned count,
                           audio_rate_t src_rate_hz, uint32_t phase_in);

/* ---- REUSABLE ENGINE (non-blocking) ----
 * Same resampling as above, but pushes ONLY as many output frames as fit in
 * the FIFO right now, then returns immediately -- so the caller's main loop
 * stays responsive (this is what makes pause = "stop calling this").
 *
 * Progress is carried in *src_index (which source sample we're on) and
 * *phase (16.16 sub-sample position). Call repeatedly with the same buffer
 * until *src_index >= count, which signals the slice is fully played.
 * Returns the number of output frames actually written this call. */
unsigned audio_feed_nb(const int16_t *src, unsigned count,
                       audio_rate_t src_rate_hz,
                       unsigned *src_index, uint32_t *phase);

/* True if the output FIFO currently has room for at least one stereo frame. */
int audio_fifo_has_space(void);

/* ---- TEST ONLY ---- */
void audio_play_tone(unsigned freq_hz, unsigned duration_ms, audio_rate_t rate);
void audio_run_test(void);

#endif /* AUDIO_DRIVER_H */