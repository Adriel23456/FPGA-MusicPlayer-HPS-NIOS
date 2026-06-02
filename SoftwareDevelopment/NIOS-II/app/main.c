#include "vga_driver.h"
#include "debug_uart.h"
#include "irq_controller.h"
#include "audio_driver.h"
#include "timer_driver.h"
#include "real_hps.h"
#include "player_fsm.h"
#include <unistd.h>

int main(void)
{
    dbg_puts("\r\n[BOOT] Music player bring-up\r\n");

    vga_init();
    if (audio_init() != 0) dbg_puts("[BOOT] audio init failed\r\n");
    timer_init();

    player_init();    /* step 1+2: load song 1, stopped, timer reset+pause */

    irq_init();       /* step 3: arm interrupts */

    dbg_puts("[BOOT] running\r\n");
    while (1) {
        /* feed audio / auto-advance while playing */
        player_service();
        dbg_flush();        /* drain any queued debug bytes into the FIFO */

        /* reset switch -> redo everything from step 1 */
        if (irq_reset_requested_take()) {   /* see note below */
            player_reset();
            continue;                        /* discard any buttons during reset */
        }

        /* buttons: drained here; per spec, an action runs to completion and
           other interrupts during it are ignored (we simply handle one and
           drain the rest). */
        uint32_t b = irq_buttons_take();
        if (b) {
            if      (b & (1u << 3)) player_play_pause();  /* BTN3 */
            else if (b & (1u << 0)) player_next();        /* BTN0 */
            else if (b & (1u << 1)) player_prev();        /* BTN1 */
            else if (b & (1u << 2)) player_stop();        /* BTN2 */
            /* any other latched buttons this pass are intentionally dropped */
        }
    }
    return 0;
}