#include "timer_driver.h"

/* Command the timer (drive the 2-bit input PIO). */
static inline void tmr_cmd(uint32_t code)
{
    REG32(TIMER_IN_BASE + PIO_DATA_OFF) = code & TMR_MASK;
}

/* Read the acknowledge output PIO. */
static inline uint32_t tmr_ack(void)
{
    return REG32(TIMER_OUT_BASE + PIO_DATA_OFF) & TMR_MASK;
}

/* Busy-wait until the output shows the expected action. */
static void tmr_wait_ack(uint32_t expected)
{
    while (tmr_ack() != expected)
        ;
}

void timer_init(void)
{
    /* reset -> pause -> idle, each step handshaked */
    tmr_cmd(TMR_RESET);
    tmr_wait_ack(TMR_RESET);
    tmr_cmd(TMR_PAUSE);
    tmr_wait_ack(TMR_PAUSE);
    tmr_cmd(TMR_NOTHING);
}

void timer_resume(void)
{
    tmr_cmd(TMR_RESUME);
    tmr_wait_ack(TMR_RESUME);
    tmr_cmd(TMR_NOTHING);
}

void timer_pause(void)
{
    tmr_cmd(TMR_PAUSE);
    tmr_wait_ack(TMR_PAUSE);
    tmr_cmd(TMR_NOTHING);
}

void timer_reset(void)
{
    /* reset, then settle into paused */
    tmr_cmd(TMR_RESET);
    tmr_wait_ack(TMR_RESET);
    tmr_cmd(TMR_PAUSE);
    tmr_wait_ack(TMR_PAUSE);
    tmr_cmd(TMR_NOTHING);
}