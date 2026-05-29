/* ----------------------------------------------------------------------
 *  debug_uart.c  --  non-blocking JTAG-UART writes.
 *
 *  Writes a character only if the JTAG write FIFO reports space (WSPACE in
 *  the upper 16 bits of the control register). If there's no space, the
 *  character is DROPPED rather than waiting -- so a detached terminal can
 *  never stall the player. This is the safe way to leave debug prints in a
 *  shipped build.
 * -------------------------------------------------------------------- */

#include "debug_uart.h"

#define JTAG_DATA  REG32(JTAG_UART_BASE_ADDR + JTAG_UART_DATA_OFF)
#define JTAG_CTRL  REG32(JTAG_UART_BASE_ADDR + JTAG_UART_CTRL_OFF)
#define JTAG_WSPACE() (JTAG_CTRL >> 16)   /* writable FIFO slots available */

void dbg_puts(const char *s)
{
    while (*s) {
        /* Only write when there is room; otherwise drop this char and move
           on. Never spin waiting for space -> never blocks the system. */
        if (JTAG_WSPACE() > 0) {
            JTAG_DATA = (uint32_t)(unsigned char)*s;
        }
        s++;
    }
}