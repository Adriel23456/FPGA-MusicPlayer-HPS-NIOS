#include "audio_driver.h"

static uint32_t s_step  = STEP_44K1;  /* SOURCE frames per output frame (16.16) */
static uint32_t s_phase = 0;          /* current sub-frame position             */
static int      s_ready = 0;          /* set once init has configured the codec */

/* Write one WM8731 register over I2C through the AV config core. */
static void codec_write_reg(unsigned reg, unsigned data)
{
    while ((AVCFG_STATUS_REG & AVCFG_STATUS_RDY) == 0u)
        ;                                   /* wait for the core to accept a transfer */
    AVCFG_ADDRESS_REG = reg  & 0xFFu;
    AVCFG_DATA_REG    = data & 0xFFFFu;
}

static inline unsigned int u16cast(int v)
{
    return (unsigned int)(uint16_t)(int16_t)v;
}

/* Free words currently available in each write FIFO. */
static inline unsigned audio_wspace_left(void)
{
    return (AUDIO_FIFOSPACE_REG >> AUDIO_FIFOSPACE_WSLC_OFST) & AUDIO_FIFOSPACE_BYTE_MSK;
}
static inline unsigned audio_wspace_right(void)
{
    return (AUDIO_FIFOSPACE_REG >> AUDIO_FIFOSPACE_WSRC_OFST) & AUDIO_FIFOSPACE_BYTE_MSK;
}

int audio_fifo_has_space(void)
{
    if (!s_ready) return 0;
    return (audio_wspace_left() > 0 && audio_wspace_right() > 0);
}

/* Both channels written as a pair (the core does not play a frame until L and
 * R are both present, per the audio-core datasheet). */
static void write_stereo_frame(int16_t l, int16_t r)
{
    unsigned spin = 0;
    while (audio_wspace_left() == 0 || audio_wspace_right() == 0) {
        if (++spin > 5000000u) return;      /* FIFO not draining -> bail */
    }
    AUDIO_LEFTDATA_REG  = u16cast(l);
    AUDIO_RIGHTDATA_REG = u16cast(r);
}

/* Program the codec sampling register (deactivate, set, activate). Format and
 * clocking are left as the AV-config auto-init set them. */
static void codec_set_reg8(unsigned reg8)
{
    codec_write_reg(CODEC_REG_ACTIVE,   0x000);   /* deactivate */
    codec_write_reg(CODEC_REG_SAMPLING, reg8);    /* sampling control */
    codec_write_reg(CODEC_REG_ACTIVE,   0x001);   /* activate */
}

/* For the active source rate, program its codec reg8 AND set its step. Both
 * come straight from the per-rate defines, so editing a define in the header
 * is honoured here with no other change required. */
audio_rate_t audio_prepare_rate(audio_rate_t src_rate)
{
    switch (src_rate) {
        case RATE_44K1: codec_set_reg8(CODEC_REG8_44K1); s_step = STEP_44K1; break;
        case RATE_16K:  codec_set_reg8(CODEC_REG8_16K);  s_step = STEP_16K;  break;
        case RATE_8K:   codec_set_reg8(CODEC_REG8_8K);   s_step = STEP_8K;   break;
        default:        codec_set_reg8(CODEC_REG8_44K1); s_step = STEP_44K1; break;
    }
    s_phase = 0;
    return src_rate;
}

void audio_play_stereo(const volatile int16_t *inter, unsigned frames)
{
    if (!s_ready || !inter || frames < 2) return;

    /* Path is chosen from the ACTIVE step (set by audio_prepare_rate from the
     * per-rate define), not from any hard-coded number. step == 1:1 -> exact
     * passthrough; anything else -> resample at that step. */
    if (s_step == (1u << 16)) {
        /* 1:1, bit-exact (no interpolation) */
        for (unsigned f = 0; f < frames; f++)
            write_stereo_frame(inter[2*f], inter[2*f + 1]);
        return;
    }

    /* Resample path. phase/idx are in STEREO FRAMES, so idx addresses
     * inter[2*idx] (L) and inter[2*idx+1] (R). A LARGER s_step consumes the
     * source faster -> faster playback; SMALLER -> slower. L and R are
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
    /* carry sub-frame remainder into the next buffer so seams stay continuous */
    s_phase = phase - limit;
}

int audio_init(void)
{
    /* Reset the AV config core; it auto-initialises the codec over I2C. */
    AVCFG_CONTROL_REG = AVCFG_CTRL_RESET;
    while (!(AVCFG_STATUS_REG & AVCFG_STATUS_AIS))
        ;                                   /* wait for auto-init to complete */

    /* Reset the audio core: clear read + write FIFOs, then release. */
    AUDIO_CONTROL_REG = AUDIO_CTRL_CR | AUDIO_CTRL_CW;
    AUDIO_CONTROL_REG = 0u;

    /* Signal-path configuration over I2C. */
    codec_write_reg(CODEC_REG_ANALOG_PATH,  0x010);   /* DACSEL=1, BYPASS=0 */
    codec_write_reg(CODEC_REG_DIGITAL_PATH, 0x000);   /* de-emphasis/mute off */
    codec_write_reg(CODEC_REG_LEFT_HP,      0x07F);   /* L headphone */
    codec_write_reg(CODEC_REG_RIGHT_HP,     0x07F);   /* R headphone */

    s_ready = 1;
    return 0;
}

void audio_enable_write_irq(void)  { AUDIO_CONTROL_REG |= AUDIO_CTRL_WI;  }
void audio_disable_write_irq(void) { AUDIO_CONTROL_REG &= ~AUDIO_CTRL_WI; }