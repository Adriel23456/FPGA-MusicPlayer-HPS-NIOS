#ifndef DEBUG_UART_H
#define DEBUG_UART_H

#include <stdint.h>

/* JTAG-UART (UART_NIOS_II) avalon_jtag_slave: 0x0008_3060 - 0x0008_3067 */
#ifndef JTAG_UART_BASE_ADDR
#define JTAG_UART_BASE_ADDR   0x00083060u
#endif

#define JTAG_UART_DATA_OFF    0x0
#define JTAG_UART_CTRL_OFF    0x4

#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))

/* Enqueue a string into the software ring buffer (never blocks, never drops
 * unless the ring overflows with no terminal draining it). */
void dbg_puts(const char *s);

/* Push as many queued bytes as fit into the JTAG FIFO right now, then return.
 * Call this every main-loop pass so queued debug output eventually flushes. */
void dbg_flush(void);

#endif /* DEBUG_UART_H */