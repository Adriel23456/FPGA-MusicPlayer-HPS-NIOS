#include "vga_driver.h"
#include "debug_uart.h"
#include "irq_controller.h"
#include <unistd.h>   /* usleep */

int main(void)
{
    dbg_puts("\r\n[BOOT] Nios II VGA driver bring-up\r\n");

    vga_init();        /* clear + static template */

    /* leave a clean, known-good frame on screen */
    vga_set_song_name("Bohemian Rhapsody");
    vga_set_artist("Queen");
    vga_set_album("A Night at the Opera");
    vga_set_duration(355);
    vga_set_track(1, 25);
    vga_set_state("playing");

    /* arm interrupts AFTER the display is up and stable */
    irq_init();

    dbg_puts("[BOOT] idle (waiting for signals)\r\n");
    while (1) {
        irq_service();
    }
    return 0;
}