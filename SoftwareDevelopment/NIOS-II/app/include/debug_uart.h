#ifndef DEBUG_UART_H
#define DEBUG_UART_H

/* ----------------------------------------------------------------------
 *  debug_uart.h  --  non-blocking JTAG-UART debug prints.
 *
 *  alt_putstr() BLOCKS when the JTAG write FIFO is full and no host is
 *  draining it (e.g. nios2-terminal not attached). That can stall the whole
 *  player. dbg_puts() instead checks the write-space field in the control
 *  register and DROPS characters when there's no room -- it never blocks.
 *
 *  JTAG UART register map (Altera JTAG UART core):
 *      +0x0  data     bit 15 = RVALID, bits 7..0 = data
 *      +0x4  control  bits 31..16 = WSPACE (write FIFO space available)
 *
 *  Base comes from the system memory map: UART_NIOS_II @ 0x00083060.
 * -------------------------------------------------------------------- */

#include "hw_map.h"

void dbg_puts(const char *s);   /* non-blocking; drops chars if FIFO full */

#endif /* DEBUG_UART_H */