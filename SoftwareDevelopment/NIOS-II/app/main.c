#include "vga_driver.h"
#include "irq_controller.h"
#include "audio_driver.h"
#include "timer_driver.h"
#include "real_hps.h"
#include "player_fsm.h"
#include <stdint.h>

int main(void)
{
    /* bring-up: drivers first, then load song 1 (stopped), then arm IRQs */
    vga_init();
    audio_init();
    timer_init();

    player_init();    /* step 1+2: load song 1, stopped, timer reset+pause */

    irq_init();       /* step 3: arm interrupts */

    while (1) {
        /* feed audio / auto-advance while playing */
        player_service();

        /* reset switch -> redo everything from step 1 */
        if (irq_reset_requested_take()) {
            player_reset();
            continue;                        /* discard any buttons during reset */
        }

        /* buttons: an action runs to completion; handle one, drain the rest.
           per spec, other interrupts during an action are ignored. */
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