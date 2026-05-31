#include "audio_driver.h"
#include "debug_uart.h"
#include <sys/alt_irq.h>
#include "altera_up_avalon_audio.h"
#include "altera_up_avalon_audio_and_video_config.h"
#include "system.h"

static alt_up_audio_dev     *g_audio = 0;
static alt_up_av_config_dev *g_avcfg = 0;

/* AIS bit in the AV config status register confirms auto-init completed. */
#define AV_CONFIG_STATUS  ((volatile unsigned int *)(AUDIO_CONFIG_BASE + 4))
#define AV_AIS_BIT        (1u << 8)

static inline unsigned int u16cast(int v)
{
    return (unsigned int)(uint16_t)(int16_t)v;
}

/* True if both output FIFOs have room for at least one frame. */
int audio_fifo_has_space(void)
{
    if (!g_audio) return 0;
    return (alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_LEFT)  > 0 &&
            alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_RIGHT) > 0);
}

/* Blocking single-frame write: waits for room, then writes L+R. */
static void write_frame(int16_t s)
{
    while (alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_LEFT)  == 0 ||
           alt_up_audio_write_fifo_space(g_audio, ALT_UP_AUDIO_RIGHT) == 0)
        ;
    alt_up_audio_write_fifo_head(g_audio, u16cast(s), ALT_UP_AUDIO_LEFT);
    alt_up_audio_write_fifo_head(g_audio, u16cast(s), ALT_UP_AUDIO_RIGHT);
}

/* Non-blocking single-frame write: assumes caller already checked space. */
static void write_frame_nofs(int16_t s)
{
    alt_up_audio_write_fifo_head(g_audio, u16cast(s), ALT_UP_AUDIO_LEFT);
    alt_up_audio_write_fifo_head(g_audio, u16cast(s), ALT_UP_AUDIO_RIGHT);
}

int audio_init(void)
{
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
    dbg_puts("[AUDIO] init: complete\r\n");
    return 0;
}

void audio_enable_write_irq(void)  { if (g_audio) alt_up_audio_enable_write_interrupt(g_audio); }
void audio_disable_write_irq(void) { if (g_audio) alt_up_audio_disable_write_interrupt(g_audio); }

/* =====================================================================
 *  FRACTIONAL RESAMPLING ENGINE  (handles ANY source rate incl. 44.1k)
 *
 *  Output is fixed 48 kHz. A read position walks the source at
 *      step = src_rate / 48000   source-samples per output frame
 *  in 16.16 fixed point. Each output frame is the linear interpolation
 *  between source[idx] and source[idx+1] using the fractional part:
 *      step = 48000/48000 = 1.000    -> 1:1
 *      step = 44100/48000 = 0.91875
 *      step = 16000/48000 = 0.3333
 *      step =  8000/48000 = 0.1666
 * ===================================================================== */

/* BLOCKING: plays the whole buffer; returns leftover phase for chunking. */
uint32_t audio_play_buffer(const int16_t *src, unsigned count,
                           audio_rate_t src_rate_hz, uint32_t phase_in)
{
    if (!g_audio || !src || count == 0) return phase_in;

    uint32_t step  = ((uint64_t)(unsigned)src_rate_hz << 16) / AUDIO_HW_RATE_HZ;
    uint32_t phase = phase_in;
    uint32_t limit = ((uint32_t)(count - 1)) << 16;   /* need idx and idx+1 */

    while (phase < limit) {
        uint32_t idx  = phase >> 16;
        uint32_t frac = phase & 0xFFFF;
        int16_t  a = src[idx];
        int16_t  b = src[idx + 1];
        int32_t  v = ((int32_t)a << 16) + (int32_t)(b - a) * (int32_t)frac;
        write_frame((int16_t)((v + (1 << 15)) >> 16));   /* rounded */
        phase += step;
    }
    /* carry sub-sample remainder relative to the start of the next chunk */
    return phase - (((uint32_t)(count - 1)) << 16);
}

/* NON-BLOCKING: same math, but stops as soon as the FIFO is full. Progress
 * is held in *src_index / *phase so the caller resumes exactly where it
 * stopped on the next pass. The slice is done when *src_index >= count-1
 * (we need idx+1 to interpolate, so the last interpolable index is count-1).
 * Returns frames written this call. */
unsigned audio_feed_nb(const int16_t *src, unsigned count,
                       audio_rate_t src_rate_hz,
                       unsigned *src_index, uint32_t *phase)
{
    if (!g_audio || !src || count == 0) return 0;

    uint32_t step  = ((uint64_t)(unsigned)src_rate_hz << 16) / AUDIO_HW_RATE_HZ;
    uint32_t limit = ((uint32_t)(count - 1)) << 16;
    unsigned written = 0;

    /* reconstruct absolute phase from carried index + sub-sample phase */
    uint32_t p = ((uint32_t)(*src_index) << 16) | (*phase & 0xFFFF);

    while (p < limit && audio_fifo_has_space()) {
        uint32_t idx  = p >> 16;
        uint32_t frac = p & 0xFFFF;
        int16_t  a = src[idx];
        int16_t  b = src[idx + 1];
        int32_t  v = ((int32_t)a << 16) + (int32_t)(b - a) * (int32_t)frac;
        write_frame_nofs((int16_t)((v + (1 << 15)) >> 16));
        p += step;
        written++;
    }

    *src_index = p >> 16;          /* save progress for next call */
    *phase     = p & 0xFFFF;
    return written;
}

/* =====================================================================
 *  TEST ONLY: sine source at src_rate, played via the blocking engine.
 * ===================================================================== */
#define TONE_BUF_MAX 2048
static int16_t s_tone_buf[TONE_BUF_MAX];

#define SINE_N 64
static const int16_t SINE_LUT[SINE_N] = {
        0,   3211,   6392,   9511,  12539,  15446,  18204,  20787,
    23169,  25329,  27244,  28897,  30272,  31356,  32137,  32609,
    32767,  32609,  32137,  31356,  30272,  28897,  27244,  25329,
    23169,  20787,  18204,  15446,  12539,   9511,   6392,   3211,
        0,  -3211,  -6392,  -9511, -12539, -15446, -18204, -20787,
   -23169, -25329, -27244, -28897, -30272, -31356, -32137, -32609,
   -32767, -32609, -32137, -31356, -30272, -28897, -27244, -25329,
   -23169, -20787, -18204, -15446, -12539,  -9511,  -6392,  -3211
};

void audio_play_tone(unsigned freq_hz, unsigned duration_ms, audio_rate_t rate)
{
    if (freq_hz == 0) return;

    unsigned src_rate = (unsigned)rate;
    unsigned want     = ((uint64_t)src_rate * duration_ms) / 1000u;

    uint32_t s_inc = ((uint64_t)freq_hz * SINE_N << 16) / src_rate;
    uint32_t s_ph  = 0;     /* sine generation phase  */
    uint32_t r_ph  = 0;     /* resampler carry phase  */

    while (want > 0) {
        unsigned n = (want > (TONE_BUF_MAX - 1)) ? (TONE_BUF_MAX - 1) : want;
        uint32_t p = s_ph;
        for (unsigned i = 0; i <= n; i++) {      /* n+1 so engine reads idx+1 */
            s_tone_buf[i] = SINE_LUT[(p >> 16) & (SINE_N - 1)];
            p += s_inc;
        }
        r_ph  = audio_play_buffer(s_tone_buf, n + 1, rate, r_ph);
        s_ph += s_inc * n;
        want -= n;
    }
}

void audio_run_test(void)
{
    dbg_puts("[AUDIO] === rate sweep test start ===\r\n");
    dbg_puts("[AUDIO] 440Hz @ 48kHz\r\n");   audio_play_tone(440, 1000, RATE_48K);
    dbg_puts("[AUDIO] 440Hz @ 44.1kHz\r\n"); audio_play_tone(440, 1000, RATE_44K1);
    dbg_puts("[AUDIO] 440Hz @ 16kHz\r\n");   audio_play_tone(440, 1000, RATE_16K);
    dbg_puts("[AUDIO] 440Hz @ 8kHz\r\n");    audio_play_tone(440, 1000, RATE_8K);
    alt_up_audio_reset_audio_core(g_audio);
    dbg_puts("[AUDIO] === rate sweep test done ===\r\n");
}
