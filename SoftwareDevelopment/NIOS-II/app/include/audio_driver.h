#ifndef AUDIO_DRIVER_H
#define AUDIO_DRIVER_H

#include <stdint.h>
#include "system.h"

#define AUDIO_OUT_IRQ_NUM   3

/* AIS bit in the AV config status register confirms auto-init completed. */
#define AV_CONFIG_STATUS  ((volatile unsigned int *)(AUDIO_CONFIG_BASE + 4))
#define AV_AIS_BIT        (1u << 8)

/* WM8731 sampling-control (reg 8) values, Normal mode, BOSR = 1 (384fs). */
#define CODEC_REG8_48K   0x002u   /* ADC48K_DAC48K */
#define CODEC_REG8_32K   0x006u   /* ADC32K_DAC32K -> used for 16k playback */
#define CODEC_REG8_8K    0x00Eu   /* ADC8K_DAC8K   */
#define CODEC_REG8_44K1  0x022u   /* ADC44K1_DAC44K1 */

/* ---- PLAYBACK SPEED STEPS (SOURCE frames per output frame, 16.16) ----
 * Speed tuning lever:  too slow -> INCREASE the step;  too fast -> DECREASE it.
 *   65536 (1<<16) = 1:1.
 *
 * 8k  : native on the 8k codec  -> 1:1, bit-exact (perfect, do not change).
 * 16k : codec at 32k, step 1<<17 plays at the correct speed with clear quality.
 * 44.1k: codec reg8 0x22, played 1:1 (bit-exact). This is the known-good path
 *        -- adding a fractional step here caused slowdown + background noise,
 *        so 44.1k stays on the 1:1 fast path. A small residual pitch offset is
 *        inherent to MCLK 18.432 MHz (true 44.1k needs 11.2896 MHz).
 * 48k : native, 1:1. */
#define STEP_8K     (1u << 16)     /* native, 1:1 (perfect) */
#define STEP_16K    (1u << 17)     /* correct speed + clear quality */
#define STEP_44K1   (1u << 16)     /* 1:1 bit-exact -> nice quality, no noise */
#define STEP_48K    (1u << 16)

typedef enum {
    RATE_48K  = 48000,
    RATE_44K1 = 44100,
    RATE_16K  = 16000,
    RATE_8K   = 8000
} audio_rate_t;

int  audio_init(void);
void audio_enable_write_irq(void);
void audio_disable_write_irq(void);

audio_rate_t audio_prepare_rate(audio_rate_t src_rate);
void         audio_play_stereo(const volatile int16_t *interleaved, unsigned frames);

int audio_fifo_has_space(void);

#endif /* AUDIO_DRIVER_H */