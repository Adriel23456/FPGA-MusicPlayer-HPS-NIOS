/* ----------------------------------------------------------------------
 *  inputs.c  --  edge-capture button ISR + reset-switch polling.
 * -------------------------------------------------------------------- */

#include "inputs.h"
#include "sys/alt_irq.h"   /* alt_ic_isr_register / alt_irq_register */

static btn_callback_t g_btn_cb = 0;

/* ---- Button interrupt service routine ----------------------------------
 * Reads the edge-capture register, clears it immediately (write-1-to-clear),
 * then defers the decision to the registered callback. We keep the ISR tiny:
 * no FIFO work, no VGA work -- just capture the event and hand it off. The
 * state machine (called from the callback) is responsible for debounced,
 * state-aware handling. */
static void button_isr(void *context)
{
    (void)context;

    uint32_t edges = REG32(REG_BTN_INPUT_BASE + PIO_EDGECAP_OFF) & BTN_ALL_MASK;

    /* Write-1-to-clear the captured edges so the IRQ deasserts. */
    REG32(REG_BTN_INPUT_BASE + PIO_EDGECAP_OFF) = edges;

    if (g_btn_cb && edges) {
        g_btn_cb(edges);
    }
}

void buttons_init(btn_callback_t cb)
{
    g_btn_cb = cb;

    /* Clear any stale captured edges before enabling. */
    REG32(REG_BTN_INPUT_BASE + PIO_EDGECAP_OFF) = BTN_ALL_MASK;

    /* Enable interrupt generation for all four buttons. */
    REG32(REG_BTN_INPUT_BASE + PIO_IRQ_MASK_OFF) = BTN_ALL_MASK;

    /* Register the ISR with the NIOS II interrupt controller.
       The enhanced HAL uses alt_ic_isr_register; the legacy API uses
       alt_irq_register. We target the enhanced API and fall back via the
       preprocessor for older BSPs. */
#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
    alt_ic_isr_register(
        0,                 /* interrupt controller id (internal) */
        BTN_PIO_IRQ,       /* IRQ line set in Platform Designer   */
        button_isr,
        (void *)0,
        (void *)0);
#else
    alt_irq_register(BTN_PIO_IRQ, (void *)0, button_isr);
#endif
}

int switch_reset_asserted(void)
{
    return (REG32(REG_SW_INPUT_BASE + PIO_DATA_OFF) & 0x1u) ? 1 : 0;
}