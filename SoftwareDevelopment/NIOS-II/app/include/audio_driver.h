#ifndef AUDIO_DRIVER_H
#define AUDIO_DRIVER_H

#include <stdint.h>
#include "system.h"

#define AUDIO_OUT_IRQ_NUM   3

/* The codec is LOCKED to this rate in audio_init and never reprogrammed.
 * All source rates are matched to it in software. */
#define DAC_RATE_HZ      44100u
#define CODEC_REG8_DAC   0x022u    /* WM8731 sampling-control value for 44.1 kHz */
/* If you ever lock the DAC at 48 kHz instead: DAC_RATE_HZ=48000u, CODEC_REG8_DAC=0x000u */

/* ---- AV-config / WM8731 register block (Avalon-mapped) ---- */
#define AV_CONFIG_STATUS  ((volatile unsigned int *)(AUDIO_CONFIG_BASE + 4))
#define AV_AIS_BIT        (1u << 8)

#define AVCFG_STATUS   (*(volatile uint32_t *)(AUDIO_CONFIG_BASE + 0x4))
#define AVCFG_ADDRESS  (*(volatile uint32_t *)(AUDIO_CONFIG_BASE + 0x8))
#define AVCFG_DATA     (*(volatile uint32_t *)(AUDIO_CONFIG_BASE + 0xC))
#define AVCFG_RDY      (1u << 1)
#define AVCFG_ACK      (1u << 0)

/* ---- RESAMPLE STEPS (SOURCE frames per output frame, 16.16) ----
 * step = src_rate / DAC_RATE_HZ. Tweak these to fix speed (see note in .c):
 *   16000/44100 -> 23777   (48k DAC alt: 21845)
 *    8000/44100 -> 11889   (48k DAC alt: 10923) */
#define STEP_44K1   (1u << 16)     /* 44.1k source on 44.1k DAC -> exact 1:1 */
#define STEP_16K    23777u
#define STEP_8K     11889u

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