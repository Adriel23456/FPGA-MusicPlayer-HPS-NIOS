#ifndef TIMER_DRIVER_H
#define TIMER_DRIVER_H

#include <stdint.h>

/* TIMER_STATUS_INPUT  (2-bit, NIOS->timer command), 0x13010-0x1301f
 * TIMER_CTRL_OUTPUT   (2-bit, timer->NIOS ack),     0x13000-0x1300f
 * Both decode: 00=nothing, 01=resume, 10=pause, 11=reset */
#define TIMER_IN_BASE    0x00013000u   /* command (PIO input, no IRQ)   */
#define TIMER_OUT_BASE   0x00013010u   /* acknowledge (PIO output)      */

#define PIO_DATA_OFF     0x0

#define TMR_NOTHING      0x0u
#define TMR_RESUME       0x1u
#define TMR_PAUSE        0x2u
#define TMR_RESET        0x3u
#define TMR_MASK         0x3u

#ifndef REG32
#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))
#endif

void timer_init(void);    /* reset -> pause -> nothing, with handshakes  */
void timer_resume(void);  /* 01, wait ack, then nothing                  */
void timer_pause(void);   /* 10, wait ack, then nothing                  */
void timer_reset(void);   /* 11, wait ack, then 10, wait ack, then nothing */

#endif /* TIMER_DRIVER_H */