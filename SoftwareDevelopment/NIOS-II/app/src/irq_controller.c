#include "irq_controller.h"
#include "debug_uart.h"
#include "vga_driver.h"
#include <sys/alt_irq.h>

static volatile int      g_reset_fired = 0;
static volatile uint32_t g_btn_fired   = 0;

/* Reset switch is EDGE now: hardware latches the flip. Read, clear, flag. */
static void reset_isr(void *context, alt_u32 id)
{
    (void)context; (void)id;
    uint32_t cap = REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) & 0x1u;
    REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) = cap;   /* clear only fired bit */
    if (cap) g_reset_fired = 1;
}

/* Buttons EDGE-capture: latch each press, clear only fired bits, report. */
static void btn_isr(void *context, alt_u32 id)
{
    (void)context; (void)id;
    uint32_t cap = REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) & BTN_MASK;
    REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) = cap;
    g_btn_fired |= cap;
}

void irq_init(void)
{
    dbg_puts("[IRQ] init: start\r\n");

    /* reset switch (EDGE): clear stale, unmask once, leave armed */
    REG32(RESET_PIO_BASE + PIO_EDGE_CAP_OFF) = 0x1u;
    alt_irq_register(RESET_PIO_IRQ, NULL, reset_isr);
    REG32(RESET_PIO_BASE + PIO_IRQ_MASK_OFF) = 0x1u;
    dbg_puts("[IRQ] reset signal armed (IRQ 2, EDGE)\r\n");

    /* buttons (EDGE): clear stale, unmask once, leave armed */
    REG32(BTN_PIO_BASE + PIO_EDGE_CAP_OFF) = BTN_MASK;
    alt_irq_register(BTN_PIO_IRQ, NULL, btn_isr);
    REG32(BTN_PIO_BASE + PIO_IRQ_MASK_OFF) = BTN_MASK;
    dbg_puts("[IRQ] buttons armed (IRQ 1, EDGE)\r\n");

    dbg_puts("[IRQ] init: complete\r\n");
}

void irq_service(void)
{
    if (g_reset_fired) {
        g_reset_fired = 0;
        dbg_puts("[IRQ] reset received -> wiping screen\r\n");
        vga_reset_volatile();
    }

    uint32_t cap = g_btn_fired;
    if (cap) {
        g_btn_fired &= ~cap;
        if (cap & (1u << 0)) dbg_puts("BTN[0] pressed\r\n");
        if (cap & (1u << 1)) dbg_puts("BTN[1] pressed\r\n");
        if (cap & (1u << 2)) dbg_puts("BTN[2] pressed\r\n");
        if (cap & (1u << 3)) dbg_puts("BTN[3] pressed\r\n");
    }
}