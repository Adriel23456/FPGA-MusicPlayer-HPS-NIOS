#include "timer_driver.h"
#include "debug_uart.h"

/* command the timer (drive the 2-bit input PIO) */
static inline void tmr_cmd(uint32_t code)
{
    REG32(TIMER_IN_BASE + PIO_DATA_OFF) = code & TMR_MASK;
}

/* read the acknowledge output PIO */
static inline uint32_t tmr_ack(void)
{
    return REG32(TIMER_OUT_BASE + PIO_DATA_OFF) & TMR_MASK;
}

/* busy-wait until the output shows the expected action */
static void tmr_wait_ack(uint32_t expected)
{
    while (tmr_ack() != expected)
        ;
}

void timer_init(void)
{
    dbg_puts("[TIMER] init: start\r\n");

    /* 1) reset, wait for reset ack */
    tmr_cmd(TMR_RESET);
    tmr_wait_ack(TMR_RESET);
    dbg_puts("[TIMER] init: reset acked\r\n");

    /* 2) pause, wait for pause ack */
    tmr_cmd(TMR_PAUSE);
    tmr_wait_ack(TMR_PAUSE);
    dbg_puts("[TIMER] init: pause acked\r\n");

    /* 3) leave input at "do nothing" (no wait) */
    tmr_cmd(TMR_NOTHING);
    dbg_puts("[TIMER] init: complete (idle/paused)\r\n");
}

void timer_resume(void)
{
    dbg_puts("[TIMER] resume\r\n");
    tmr_cmd(TMR_RESUME);
    tmr_wait_ack(TMR_RESUME);
    tmr_cmd(TMR_NOTHING);
    dbg_puts("[TIMER] resumed\r\n");
}

void timer_pause(void)
{
    dbg_puts("[TIMER] pause\r\n");
    tmr_cmd(TMR_PAUSE);
    tmr_wait_ack(TMR_PAUSE);
    tmr_cmd(TMR_NOTHING);
    dbg_puts("[TIMER] paused\r\n");
}

void timer_reset(void)
{
    dbg_puts("[TIMER] reset\r\n");
    /* 1) reset, wait for reset ack */
    tmr_cmd(TMR_RESET);
    tmr_wait_ack(TMR_RESET);
    /* 2) immediately move to pause, wait for pause ack */
    tmr_cmd(TMR_PAUSE);
    tmr_wait_ack(TMR_PAUSE);
    /* 3) leave input at "do nothing" */
    tmr_cmd(TMR_NOTHING);
    dbg_puts("[TIMER] reset complete (paused)\r\n");
}