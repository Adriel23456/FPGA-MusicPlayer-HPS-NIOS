#include "audio_filter_hw.h"

#if AUDIO_FILTER_HW_ENABLE
#include "io.h"

enum {
    AUDIO_FILTER_REG_MODE   = 0,
    AUDIO_FILTER_REG_LEFT_IN = 1,
    AUDIO_FILTER_REG_RIGHT_IN = 2,
    AUDIO_FILTER_REG_CTRL    = 3,
    AUDIO_FILTER_REG_LEFT_OUT = 4,
    AUDIO_FILTER_REG_RIGHT_OUT = 5
};

audio_filter_mode_t audio_filter_hw_mode_from_sample(void)
{
    return (audio_filter_mode_t)(IORD_32DIRECT(FILTER_SELECT_HW_BASE, 0) & 0x3u);
}

void audio_filter_hw_apply(int16_t *left, int16_t *right)
{
    uint32_t status;
    audio_filter_mode_t mode;

    if (!left || !right) return;

    mode = audio_filter_hw_mode_from_sample();
    if (mode == AUDIO_FILTER_BYPASS) return;

    IOWR_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_MODE * 4, (uint32_t)mode);
    IOWR_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_LEFT_IN * 4, (uint32_t)(uint16_t)(*left));
    IOWR_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_RIGHT_IN * 4, (uint32_t)(uint16_t)(*right));
    IOWR_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_CTRL * 4, 0x1u);

    do {
        status = IORD_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_CTRL * 4);
    } while (status & 0x1u);

    *left  = (int16_t)IORD_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_LEFT_OUT * 4);
    *right = (int16_t)IORD_32DIRECT(AUDIO_FILTER_HW_BASE, AUDIO_FILTER_REG_RIGHT_OUT * 4);
}
#else
audio_filter_mode_t audio_filter_hw_mode_from_sample(void)
{
    return AUDIO_FILTER_BYPASS;
}

void audio_filter_hw_apply(int16_t *left, int16_t *right)
{
    (void)left;
    (void)right;
}
#endif