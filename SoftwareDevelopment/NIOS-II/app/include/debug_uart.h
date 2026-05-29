#ifndef DEBUG_UART_H
#define DEBUG_UART_H

#include <stdint.h>

/* JTAG-UART (UART_NIOS_II) avalon_jtag_slave: 0x0008_3060 - 0x0008_3067 */
#ifndef JTAG_UART_BASE_ADDR
#define JTAG_UART_BASE_ADDR   0x00083060u
#endif

#define JTAG_UART_DATA_OFF    0x0   /* data register    */
#define JTAG_UART_CTRL_OFF    0x4   /* control register */

/* 32-bit volatile lvalue at an absolute address */
#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))

void dbg_puts(const char *s);

#endif /* DEBUG_UART_H */