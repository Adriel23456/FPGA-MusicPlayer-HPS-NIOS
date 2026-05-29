/* ----------------------------------------------------------------------
 *  timer_ctrl.c  --  command/confirm driver for the audio display timer.
 * -------------------------------------------------------------------- */

#include "timer_ctrl.h"

/* Spin until the status wire mirrors `cmd`, then release control to NOP.
   Bounded so a mis-wired status line can never hang the whole player. */
#define TIMER_CONFIRM_TIMEOUT  100000u

static int timer_issue(timer_cmd_t cmd)
{
    REG32(TIMER_CTRL_OUTPUT_BASE) = (uint32_t)cmd;

    uint32_t guard = TIMER_CONFIRM_TIMEOUT;
    while (guard--) {
        if ((REG32(TIMER_STATUS_INPUT_BASE) & 0x3u) == (uint32_t)cmd) {
            /* Confirmed. Drop back to NOP so the functional state latches
               without us holding the command asserted. */
            REG32(TIMER_CTRL_OUTPUT_BASE) = (uint32_t)TIMER_CMD_NOP;
            return 1;
        }
    }
    /* Timed out: still release the bus to NOP, report failure. */
    REG32(TIMER_CTRL_OUTPUT_BASE) = (uint32_t)TIMER_CMD_NOP;
    return 0;
}

void timer_init(void)
{
    (void)timer_issue(TIMER_CMD_RESET);
    /* RESET leaves it stopped; we do not auto-run on init. */
}

int timer_run(void)   { return timer_issue(TIMER_CMD_RUN);   }
int timer_pause(void) { return timer_issue(TIMER_CMD_PAUSE); }
int timer_reset(void) { return timer_issue(TIMER_CMD_RESET); }