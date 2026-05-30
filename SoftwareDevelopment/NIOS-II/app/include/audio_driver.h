#ifndef AUDIO_DRIVER_H
#define AUDIO_DRIVER_H

#include <stdint.h>

#define AUDIO_OUT_IRQ_NUM   3
#define AUDIO_HW_RATE_HZ    48000u   /* fixed codec rate */

/* Source sample rates we accept. Stored as the actual rate in Hz, because
 * 44.1 kHz is NOT an integer divisor of 48 kHz -> we need fractional
 * resampling, not an integer repeat factor. */
typedef enum {
    RATE_48K  = 48000,
    RATE_44K1 = 44100,
    RATE_16K  = 16000,
    RATE_8K   = 8000
} audio_rate_t;

int  audio_init(void);
void audio_enable_write_irq(void);
void audio_disable_write_irq(void);

/* ---- REUSABLE ENGINE ----
 * Play `count` mono 16-bit samples captured at `src_rate_hz` on the fixed
 * 48 kHz output. Uses fractional linear-interpolating resampling, so any
 * source rate works (44.1k included), pitch preserved, imaging suppressed.
 * Returns the fractional phase left over, so chunked calls stay seamless. */
uint32_t audio_play_buffer(const int16_t *src, unsigned count,
                           audio_rate_t src_rate_hz, uint32_t phase_in);

void audio_play_tone(unsigned freq_hz, unsigned duration_ms, audio_rate_t rate);
void audio_run_test(void);

#endif /* AUDIO_DRIVER_H */