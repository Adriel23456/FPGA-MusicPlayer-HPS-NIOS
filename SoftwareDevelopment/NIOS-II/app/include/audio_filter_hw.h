#ifndef AUDIO_FILTER_HW_H
#define AUDIO_FILTER_HW_H

#include <stdint.h>

/* Optional hardware filter accelerator. Disabled by default until the IP is
 * added to Platform Designer and its base address is assigned. */
#ifndef AUDIO_FILTER_HW_ENABLE
#define AUDIO_FILTER_HW_ENABLE 0
#endif

#ifndef FILTER_SELECT_HW_ENABLE
#define FILTER_SELECT_HW_ENABLE 0
#endif

/* Expected Avalon-MM register block layout for the filter accelerator.
 * These defaults are placeholders and can be overridden at build time.
 */
#ifndef AUDIO_FILTER_HW_BASE
#define AUDIO_FILTER_HW_BASE 0x00000000u
#endif

#ifndef FILTER_SELECT_HW_BASE
#define FILTER_SELECT_HW_BASE 0x00000000u
#endif

typedef enum {
    AUDIO_FILTER_BYPASS = 0,
    AUDIO_FILTER_LOWPASS = 1,
    AUDIO_FILTER_BANDPASS = 2,
    AUDIO_FILTER_EQ = 3
} audio_filter_mode_t;

audio_filter_mode_t audio_filter_hw_mode_from_sample(void);
void audio_filter_hw_apply(int16_t *left, int16_t *right);

#endif /* AUDIO_FILTER_HW_H */