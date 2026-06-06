#ifndef AUDIO_DRIVER_H
#define AUDIO_DRIVER_H

#include <stdint.h>
#include "system.h"

#define AUDIO_OUT_IRQ_NUM   3

/* AIS bit in the AV config status register confirms auto-init completed. */
#define AV_CONFIG_STATUS  ((volatile unsigned int *)(AUDIO_CONFIG_BASE + 4))
#define AV_AIS_BIT        (1u << 8)

/* =====================================================================
 *  PER-RATE CONFIGURATION
 *
 *  Three supported source rates: 44.1k, 16k, 8k. Each has two knobs and
 *  NOTHING ELSE decides its behaviour:
 *
 *    CODEC_REG8_<rate> : WM8731 sampling-control value (sets physical DAC rate).
 *    STEP_<rate>       : resample step, SOURCE frames per output frame (16.16).
 *                          65536 (1<<16) = 1:1 (bit-exact, no interpolation)
 *                          > 65536 = faster playback;  < 65536 = slower.
 *
 *  KEY RELATIONSHIP (why the tuned values work):
 *    effective_DAC_rate = src_rate / (STEP / 65536)
 *  Playback is correct speed when STEP is chosen so this equals the actual
 *  DAC rate produced by CODEC_REG8_<rate>. Higher achievable DAC rate = more
 *  usable bandwidth = clearer sound.
 *
 *  Editing either knob takes effect immediately: audio_play_stereo selects
 *  its path from the active STEP, not from any hard-coded constant.
 * ===================================================================== */

/* ---- 44.1 kHz ----
 * STEP 240300 / 65536 = 3.667 source frames per output frame.
 * 44100 / 3.667 = ~12.0 kHz effective DAC rate.
 * NOTE: 240300 is not a power of two, so it cannot be a single (1u << n);
 * keep it as 240300u. */
#define CODEC_REG8_44K1  0x00Cu
#define STEP_44K1        240300u

/* ---- 16 kHz ----
 * Same codec setting as 44.1k (~12.0 kHz DAC), tuned to match by ear.
 * STEP 87950 / 65536 = 1.342 source frames per output frame.
 * 16000 / 1.342 = ~11.9 kHz effective DAC rate (matches the 44.1k path). */
#define CODEC_REG8_16K   0x00Cu
#define STEP_16K         87950u

/* ---- 8 kHz ---- */
#define CODEC_REG8_8K    0x00Eu   /* WM8731 reg8: ADC8K_DAC8K */
#define STEP_8K          (1u << 16)   /* 65536 = 1:1, bit-exact */

typedef enum {
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