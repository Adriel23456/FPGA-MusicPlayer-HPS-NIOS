#include <sys/alt_stdio.h>
#include <unistd.h>
#include "altera_up_avalon_audio.h"
#include "altera_up_avalon_audio_and_video_config.h"
#include "system.h"

// ── VGA ──────────────────────────────────────────────────────
#define CHAR_BUF_BASE       ((volatile char *) 0x00080000)
#define CHAR_CTRL_BASE      ((volatile int *)  0x00083080)
#define CTRL_REG            0
#define RESOL_REG           1
#define VGA_RESET_GUARD_US  200000

static inline void vga_put_char(int x, int y, char c)
{
    CHAR_BUF_BASE[(y << 7) | x] = c;
}

static void vga_put_string(int x, int y, const char *str)
{
    while (*str)
        vga_put_char(x++, y, *str++);
}

static void vga_clear_screen(void)
{
    CHAR_CTRL_BASE[CTRL_REG] = (1 << 16);
    while (CHAR_CTRL_BASE[CTRL_REG] & (1 << 16));
}

// ── Audio Config status register (AIS = bit 8) ───────────────
#define AUDIO_CONFIG_STATUS  ((volatile unsigned int *)(AUDIO_CONFIG_BASE + 4))
#define AIS_BIT              (1 << 8)

static void audio_wait_auto_init(void)
{
    // Poll AIS bit until WM8731 auto-initialization is complete
    while (!(*AUDIO_CONFIG_STATUS & AIS_BIT));
}

// ── Audio ─────────────────────────────────────────────────────
#define SAMPLE_RATE         96000
#define TONE_FREQ           440
#define HALF_PERIOD_SAMPLES (SAMPLE_RATE / (TONE_FREQ * 2))
#define TONE_POS            ((unsigned int) 0x7FFF)
#define TONE_NEG            ((unsigned int) 0x8001)
#define TONE_DURATION_SEC   5
#define TONE_TOTAL_SAMPLES  (SAMPLE_RATE * TONE_DURATION_SEC)

static void vga_safe_update(void)
{
    vga_clear_screen();
    usleep(VGA_RESET_GUARD_US);  // wait for 25MHz domain to stabilize
}

static void vga_clear_line(int y)
{
    for (int x = 0; x < 80; x++)
        vga_put_char(x, y, ' ');
}

int main(void)
{
    usleep(VGA_RESET_GUARD_US);
    vga_clear_screen();

    vga_put_string(30, 27, "Hello World!");
    vga_put_string(23, 29, "Waiting for audio init...");
    alt_putstr("Hello from Nios II!\n");

    alt_up_av_config_dev *av_config =
        alt_up_av_config_open_dev(AUDIO_CONFIG_NAME);

    if (av_config == NULL) {
        alt_putstr("ERROR: Could not open AV config\n");
        vga_clear_line(29);
        vga_put_string(28, 29, "AV Config FAILED!");
        while (1);
    }

    alt_up_av_config_reset(av_config);
    audio_wait_auto_init();
    alt_putstr("AV Config auto-init complete.\n");

    vga_clear_line(29);
    vga_put_string(26, 29, "Audio init complete!");

    alt_up_audio_dev *audio_dev =
        alt_up_audio_open_dev(AUDIO_OUT_NAME);

    if (audio_dev == NULL) {
        alt_putstr("ERROR: Could not open audio device\n");
        vga_clear_line(29);
        vga_put_string(30, 29, "Audio FAILED!");
        while (1);
    }

    alt_up_audio_reset_audio_core(audio_dev);
    alt_putstr("Playing 440Hz tone...\n");

    vga_clear_line(29);
    vga_put_string(28, 29, "Playing 440Hz tone...");

    unsigned int sample_count = 0;
    unsigned int half_period  = 0;
    unsigned int sample       = TONE_POS;

    while (sample_count < TONE_TOTAL_SAMPLES)
    {
        if (alt_up_audio_write_fifo_space(audio_dev, ALT_UP_AUDIO_LEFT)  > 0 &&
            alt_up_audio_write_fifo_space(audio_dev, ALT_UP_AUDIO_RIGHT) > 0)
        {
            alt_up_audio_write_fifo_head(audio_dev, sample, ALT_UP_AUDIO_LEFT);
            alt_up_audio_write_fifo_head(audio_dev, sample, ALT_UP_AUDIO_RIGHT);
            half_period++;
            sample_count++;
            if (half_period >= HALF_PERIOD_SAMPLES)
            {
                half_period = 0;
                sample = (sample == TONE_POS) ? TONE_NEG : TONE_POS;
            }
        }
    }

    alt_up_audio_reset_audio_core(audio_dev);
    alt_putstr("Audio test complete.\n");

    vga_clear_line(29);
    vga_put_string(24, 29, "Audio test complete!");

    while (1);
    return 0;
}