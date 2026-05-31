#include "irq_controller.h"
#include "debug_uart.h"
#include <sys/alt_irq.h>

/* ---- Event latches: written by ISRs, drained by the main loop ---- */
static volatile int      g_reset_fired = 0;   /* reset switch fired        */
static volatile uint32_t g_btn_fired   = 0;   /* pressed button bits (3..0)*/

/* ============================================================
 *  ISRs
 *  Both input PIOs are EDGE-capture with bit-clearing enabled, so each ISR
 *  reads the edge-capture register, writes back only the bits that fired to
 *  clear them (leaving any concurrent capture intact), and latches the
 *  event. The mask is armed once in irq_init and never touched again, so
 *  there is no re-arm window in which presses could be lost.
 * ============================================================ */

/* Reset switch, IRQ 2. Latches a full-reset request for the main loop. */
static void reset_isr(void *context, alt_u32 id)
{
    (void)context; (void)id;
    uint32_t cap = REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) & 0x1u;
    REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) = cap;   /* clear only fired bit */
    if (cap) g_reset_fired = 1;
}

/* Buttons, IRQ 1 (4 buttons share this line). Latches which button(s) fired
 * by OR-ing the captured bits; the main loop decides what each means. */
static void btn_isr(void *context, alt_u32 id)
{
    (void)context; (void)id;
    uint32_t cap = REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) & BTN_MASK;
    REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) = cap;     /* clear only fired bits */
    g_btn_fired |= cap;
}

/* Audio write IRQ, IRQ 3. Playback is driven from the main loop via FIFO-
 * space polling, so this source has nothing to service here; it simply
 * silences itself to avoid a recurring unhandled interrupt. Registered so
 * the hardware path is set up for future interrupt-driven streaming. */
static void audio_isr(void *context, alt_u32 id)
{
    (void)context; (void)id;
    alt_irq_disable(AUDIO_IRQ_NUM);   /* mask this source; FIFO is polled */
}

/* ============================================================
 *  Setup
 * ============================================================ */
void irq_init(void)
{
    dbg_puts("[IRQ] init: start\r\n");

    /* Reset switch (EDGE): clear any stale capture, register, unmask once. */
    REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) = 0x1u;
    alt_irq_register(RESET_PIO_IRQ, NULL, reset_isr);
    REG32(RESET_PIO_BASE + PIO_IRQ_MASK_OFF) = 0x1u;
    dbg_puts("[IRQ] reset switch armed (IRQ 2, EDGE)\r\n");

    /* Buttons (EDGE): clear stale, register, unmask all four once. */
    REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) = BTN_MASK;
    alt_irq_register(BTN_PIO_IRQ, NULL, btn_isr);
    REG32(BTN_PIO_BASE + PIO_IRQ_MASK_OFF) = BTN_MASK;
    dbg_puts("[IRQ] buttons armed (IRQ 1, EDGE)\r\n");

    /* Audio write IRQ: registered but main-loop driven (see audio_isr). */
    alt_irq_register(AUDIO_IRQ_NUM, NULL, audio_isr);
    dbg_puts("[IRQ] audio write IRQ registered (IRQ 3)\r\n");

    dbg_puts("[IRQ] init: complete\r\n");
}

/* Reserved for future deferred-servicing needs. No work today: the reset
 * switch and buttons are drained by the main loop via the *_take() getters,
 * and audio is polled. Kept so the main-loop call site is stable. */
void irq_service(void)
{
    /* intentionally empty */
}

/* ============================================================
 *  Main-loop drains (critical sections guard the read-modify-write so an
 *  ISR firing mid-update can't drop an event)
 * ============================================================ */

/* Read + clear the latched button bits atomically. */
uint32_t irq_buttons_take(void)
{
    uint32_t bits;
    alt_irq_context ctx = alt_irq_disable_all();
    bits = g_btn_fired;
    g_btn_fired = 0;
    alt_irq_enable_all(ctx);
    return bits;
}

/* Return (and clear) whether the reset switch fired since the last call. */
int irq_reset_requested_take(void)
{
    int r;
    alt_irq_context ctx = alt_irq_disable_all();
    r = g_reset_fired;
    g_reset_fired = 0;
    alt_irq_enable_all(ctx);
    return r;
}