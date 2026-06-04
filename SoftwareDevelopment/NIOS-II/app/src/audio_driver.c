#include "audio_driver.h"
#include "debug_uart.h"
#include <sys/alt_irq.h>
#include "altera_up_avalon_audio.h"
#include "altera_up_avalon_audio_and_video_config.h"
#include "system.h"

static alt_up_audio_dev     *g_audio = 0;
static alt_up_av_config_dev *g_avcfg = 0;

static uint32_t s_step  = STEP_44K1;  /* SOURCE frames per output frame (16.16) */
static uint32_t s_phase = 0;          /* current sub-frame position             */

static int codec_write_raw(unsigned reg7, unsigned data9)
{
    unsigned spin = 0;
    while (!(AVCFG_STATUS & AVCFG_RDY)) { if (++spin > 2000000u) return -1; }
    AVCFG_ADDRESS = reg7  & 0x7Fu;
    AVCFG_DATA    = data9 & 0x1FFu;
    spin = 0;
    while (!(AVCFG_STATUS & AVCFG_RDY)) { if (++spin > 2000000u) return -1; }
    return (AVCFG_STATUS & AVCFG_ACK) ? -1 : 0;
}

static inline unsigned int u16cast(int v)
{
    return (unsigned int)(uint16_t)(int16_t)v;
}

int audio_fifo_has_space(void)
{
    if (!g_audio) return 0;
    return (alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_LEFT)  > 0 &&
            alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_RIGHT) > 0);
}

/* Blocking stereo frame write: both channels written as a pair (the core does
 * not play a frame until L and R are both present). */
static void write_stereo_frame(int16_t l, int16_t r)
{
    unsigned spin = 0;
    while (alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_LEFT)  == 0 ||
           alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_RIGHT) == 0) {
        if (++spin > 5000000u) return;   /* FIFO not draining -> bail */
    }
    alt_up_audio_write_fifo_head(g_audio, u16cast(l), ALT_UP_AUDIO_LEFT);
    alt_up_audio_write_fifo_head(g_audio, u16cast(r), ALT_UP_AUDIO_RIGHT);
}

/* DAC is fixed at DAC_RATE_HZ (set in audio_init). Pick the FRAME step that
 * maps this source rate onto it. The codec is NOT reprogrammed here. */
audio_rate_t audio_prepare_rate(audio_rate_t src_rate)
{
    switch (src_rate) {
        case RATE_44K1: s_step = STEP_44K1; break;   /* 1:1, bit-exact (untouched) */
        case RATE_16K:  s_step = STEP_16K;  break;
        case RATE_8K:   s_step = STEP_8K;   break;
        default:        s_step = STEP_44K1; break;
    }
    s_phase = 0;
    return src_rate;
}

void audio_play_stereo(const volatile int16_t *inter, unsigned frames)
{
    if (!g_audio || !inter || frames < 2) return;

    /* Fast path: 44.1k source on 44.1k DAC -> 1:1, bit-exact. UNCHANGED. */
    if (s_step == (1u << 16)) {
        for (unsigned f = 0; f < frames; f++)
            write_stereo_frame(inter[2*f], inter[2*f + 1]);
        return;
    }

    /* Resample path (16k / 8k -> 44.1k). phase/idx are in STEREO FRAMES, so
     * idx addresses inter[2*idx] (L) and inter[2*idx+1] (R). L and R are
     * interpolated INDEPENDENTLY with half-LSB rounding before the >>16. */
    uint32_t phase = s_phase;
    uint32_t limit = ((uint32_t)(frames - 1)) << 16;   /* need frame idx and idx+1 */

    while (phase <= limit) {
        uint32_t idx  = phase >> 16;
        uint32_t frac = phase & 0xFFFF;
        int16_t aL = inter[2*idx],     aR = inter[2*idx + 1];
        int16_t bL = inter[2*idx + 2], bR = inter[2*idx + 3];
        int32_t vL = ((int32_t)aL << 16) + (int32_t)(bL - aL) * (int32_t)frac;
        int32_t vR = ((int32_t)aR << 16) + (int32_t)(bR - aR) * (int32_t)frac;
        write_stereo_frame((int16_t)((vL + (1 << 15)) >> 16),
                           (int16_t)((vR + (1 << 15)) >> 16));
        phase += s_step;
    }
    /* carry the sub-frame remainder into the next buffer so seams stay
     * continuous: subtract the frames we fully consumed. */
    s_phase = phase - limit;
}

int audio_init(void)
{
    int e = 0;
    dbg_puts("[AUDIO] init: start\r\n");

    g_avcfg = alt_up_av_config_open_dev(AUDIO_CONFIG_NAME);
    if (g_avcfg == 0) { dbg_puts("[AUDIO] ERROR: AV config open failed\r\n"); return -1; }
    alt_up_av_config_reset(g_avcfg);
    while (!(*AV_CONFIG_STATUS & AV_AIS_BIT))
        ;
    dbg_puts("[AUDIO] AV config auto-init complete\r\n");

    g_audio = alt_up_audio_open_dev(AUDIO_OUT_NAME);
    if (g_audio == 0) { dbg_puts("[AUDIO] ERROR: audio open failed\r\n"); return -1; }
    alt_up_audio_reset_audio_core(g_audio);

    e |= codec_write_raw(0x04, 0x010);   /* analog path: DACSEL=1, BYPASS=0   */
    e |= codec_write_raw(0x05, 0x000);   /* digital path: de-emphasis/mute OFF*/
    e |= codec_write_raw(0x02, 0x07F);   /* L headphone */
    e |= codec_write_raw(0x03, 0x07F);   /* R headphone */

    /* lock the DAC sampling rate ONCE -- never reprogrammed per song */
    e |= codec_write_raw(0x09, 0x000);            /* deactivate */
    e |= codec_write_raw(0x08, CODEC_REG8_DAC);   /* sampling control */
    e |= codec_write_raw(0x09, 0x001);            /* activate   */

    if (e) dbg_puts("[AUDIO] CODEC WRITE FAILED -> path/rate not applied\r\n");
    else   dbg_puts("[AUDIO] codec locked @ DAC_RATE_HZ (DACSEL=1, BYPASS=0)\r\n");

    dbg_puts("[AUDIO] init: complete\r\n");
    return 0;
}

void audio_enable_write_irq(void)  { if (g_audio) alt_up_audio_enable_write_interrupt(g_audio); }
void audio_disable_write_irq(void) { if (g_audio) alt_up_audio_disable_write_interrupt(g_audio); }