#ifndef AUDIO_DRIVER_H
#define AUDIO_DRIVER_H

#include <stdint.h>
#include "system.h"

#ifndef REG32
#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))
#endif

#define AUDIO_OUT_IRQ_NUM   3

/* =====================================================================
 *  AUDIO CORE register map (altera_up_avalon_audio, base AUDIO_OUT_BASE).
 *  Four 32-bit registers; byte offset = word index * 4.
 * ===================================================================== */
#define AUDIO_CONTROL_REG    REG32(AUDIO_OUT_BASE + 0x0)   /* RW */
#define AUDIO_FIFOSPACE_REG  REG32(AUDIO_OUT_BASE + 0x4)   /* RO */
#define AUDIO_LEFTDATA_REG   REG32(AUDIO_OUT_BASE + 0x8)   /* WO: left write FIFO  */
#define AUDIO_RIGHTDATA_REG  REG32(AUDIO_OUT_BASE + 0xC)   /* WO: right write FIFO */

/* Control register bits */
#define AUDIO_CTRL_CR        (1u << 2)   /* clear read FIFOs   */
#define AUDIO_CTRL_CW        (1u << 3)   /* clear write FIFOs  */
#define AUDIO_CTRL_WI        (1u << 9)   /* write-interrupt enable */

/* Fifospace register: free words per write channel (8 bits each) */
#define AUDIO_FIFOSPACE_WSRC_OFST  16    /* right channel free words */
#define AUDIO_FIFOSPACE_WSLC_OFST  24    /* left  channel free words */
#define AUDIO_FIFOSPACE_BYTE_MSK   0xFFu

/* =====================================================================
 *  AUDIO/VIDEO CONFIG core register map (base AUDIO_CONFIG_BASE).
 *  Drives the WM8731 codec over I2C.
 * ===================================================================== */
#define AVCFG_CONTROL_REG    REG32(AUDIO_CONFIG_BASE + 0x0)   /* RW */
#define AVCFG_STATUS_REG     REG32(AUDIO_CONFIG_BASE + 0x4)   /* RO */
#define AVCFG_ADDRESS_REG    REG32(AUDIO_CONFIG_BASE + 0x8)   /* WO: codec reg index */
#define AVCFG_DATA_REG       REG32(AUDIO_CONFIG_BASE + 0xC)   /* WO: codec reg value */

#define AVCFG_CTRL_RESET     (1u << 0)   /* assert core reset + codec auto-init */
#define AVCFG_STATUS_RDY     (1u << 1)   /* core ready for a new transfer */
#define AVCFG_STATUS_AIS     (1u << 8)   /* auto-init sequence complete */

/* WM8731 codec register indices (I2C) */
#define CODEC_REG_LEFT_HP        0x02u
#define CODEC_REG_RIGHT_HP       0x03u
#define CODEC_REG_ANALOG_PATH    0x04u
#define CODEC_REG_DIGITAL_PATH   0x05u
#define CODEC_REG_SAMPLING       0x08u
#define CODEC_REG_ACTIVE         0x09u

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
#define CODEC_REG8_8K    0x00Eu        /* WM8731 reg8: ADC8K_DAC8K */
#define STEP_8K          (1u << 16)    /* 65536 = 1:1, bit-exact */

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