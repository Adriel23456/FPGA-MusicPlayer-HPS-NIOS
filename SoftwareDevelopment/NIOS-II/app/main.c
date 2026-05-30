#include "vga_driver.h"
#include "debug_uart.h"
#include "irq_controller.h"
#include "audio_driver.h"
#include <unistd.h>   /* usleep */

int main(void)
{
    dbg_puts("\r\n[BOOT] Nios II VGA driver bring-up\r\n");

    vga_init();        /* clear + static template */

    vga_set_song_name("Bohemian Rhapsody");
    vga_set_artist("Queen");
    vga_set_album("A Night at the Opera");
    vga_set_duration(355);
    vga_set_track(1, 25);
    vga_set_state("playing");

    /* bring up audio (AV config + audio core) BEFORE arming interrupts */
    if (audio_init() == 0) {
        audio_run_test();          /* 48k -> 16k -> 8k sweep on boot */
    }

    irq_init();                    /* VGA reset switch, buttons, audio IRQ */

    dbg_puts("[BOOT] idle (waiting for signals)\r\n");
    while (1) {
        irq_service();

        /* reset switch requested an audio re-test: run it in the main loop */
        if (irq_audio_retest_requested()) {
            irq_audio_retest_clear();
            dbg_puts("[AUDIO] reset -> re-running audio test\r\n");
            audio_run_test();
        }
    }
    return 0;
}