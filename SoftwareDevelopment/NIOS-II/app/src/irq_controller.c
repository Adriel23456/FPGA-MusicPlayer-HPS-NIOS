#include "irq_controller.h"
#include <stddef.h>   /* NULL */

/* ---- Event latches: written by ISRs, drained by the main loop ---- */
static volatile int      g_reset_fired = 0;   /* reset switch fired         */
static volatile uint32_t g_btn_fired   = 0;   /* pressed button bits (3..0) */

/* ============================================================
 *  ISRs
 *  Both input PIOs are EDGE-capture with bit-clearing enabled: each ISR
 *  reads the edge-capture register, writes back only the bits that fired to
 *  clear them, and latches the event. The mask is armed once in irq_init and
 *  never touched again, so there is no re-arm window for lost presses.
 * ============================================================ */

/* Reset switch, IRQ 2. Latches a full-reset request for the main loop. */
static void reset_isr(void *context, unsigned int id)
{
    (void)context; (void)id;
    uint32_t cap = REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) & 0x1u;
    REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) = cap;   /* clear only fired bit */
    if (cap) g_reset_fired = 1;
}

/* Buttons, IRQ 1 (4 buttons share this line). OR-latches the captured bits;
 * the main loop decides what each means. */
static void btn_isr(void *context, unsigned int id)
{
    (void)context; (void)id;
    uint32_t cap = REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) & BTN_MASK;
    REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) = cap;     /* clear only fired bits */
    g_btn_fired |= cap;
}

/* Audio write IRQ, IRQ 3. Playback is driven from the main loop via FIFO-space
 * polling, so this source masks itself to avoid a recurring unhandled
 * interrupt. Registered so the hardware path is ready for future use. */
static void audio_isr(void *context, unsigned int id)
{
    (void)context; (void)id;
    irq_source_disable(AUDIO_IRQ_NUM);   /* mask this source; FIFO is polled */
}

/* ============================================================
 *  Setup
 * ============================================================ */
void irq_init(void)
{
    /* Reset switch (EDGE): clear any stale capture, register, unmask once. */
    REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) = 0x1u;
    alt_irq_register(RESET_PIO_IRQ, NULL, reset_isr);
    REG32(RESET_PIO_BASE + PIO_IRQ_MASK_OFF) = 0x1u;

    /* Buttons (EDGE): clear stale, register, unmask all four once. */
    REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) = BTN_MASK;
    alt_irq_register(BTN_PIO_IRQ, NULL, btn_isr);
    REG32(BTN_PIO_BASE + PIO_IRQ_MASK_OFF) = BTN_MASK;

    /* Audio write IRQ: registered but main-loop driven (see audio_isr). */
    alt_irq_register(AUDIO_IRQ_NUM, NULL, audio_isr);
}

/* Reserved for future deferred-servicing needs. The reset switch and buttons
 * are drained by the main loop via the *_take() getters, and audio is polled.
 * Kept so the main-loop call site is stable. */
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
    irq_context_t ctx = irq_disable_all();
    bits = g_btn_fired;
    g_btn_fired = 0;
    irq_enable_all(ctx);
    return bits;
}

/* Return (and clear) whether the reset switch fired since the last call. */
int irq_reset_requested_take(void)
{
    int r;
    irq_context_t ctx = irq_disable_all();
    r = g_reset_fired;
    g_reset_fired = 0;
    irq_enable_all(ctx);
    return r;
}