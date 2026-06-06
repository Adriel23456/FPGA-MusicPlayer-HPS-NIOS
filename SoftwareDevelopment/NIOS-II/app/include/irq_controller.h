#ifndef IRQ_CONTROLLER_H
#define IRQ_CONTROLLER_H

#include <stdint.h>

/* ============================================================
 *  Interrupt controller for the music player.
 *
 *  Sources (all PIO-based):
 *    - Reset switch : 1-bit, EDGE-capture, IRQ 2  -> full system reset
 *    - Buttons      : 4-bit, EDGE-capture, IRQ 1  -> player actions
 *    - Audio out    : write FIFO,          IRQ 3  -> registered, FIFO is
 *                                                    main-loop driven
 *
 *  ISRs do the minimum: read the edge-capture register, clear only the
 *  bits that fired, and latch the event for the main loop. All real work
 *  runs in the main loop, never in interrupt context.
 * ============================================================ */

/* ---- Reset switch: 1-bit input PIO, EDGE, IRQ 2 ---- */
#define RESET_PIO_BASE     0x00013020u
#define RESET_PIO_IRQ      2

/* ---- Buttons: 4-bit input PIO, EDGE, IRQ 1 (all 4 share this line) ---- */
#define BTN_PIO_BASE       0x00013030u
#define BTN_PIO_IRQ        1
#define BTN_COUNT          4
#define BTN_MASK           0xFu        /* bits 3..0 */

/* ---- Audio data core write interrupt ---- */
#define AUDIO_IRQ_NUM      3

/* Standard Altera PIO register byte offsets */
#define PIO_DATA_OFF       0x0
#define PIO_DIRECTION_OFF  0x4
#define PIO_IRQ_MASK_OFF   0x8
#define PIO_EDGE_CAP_OFF   0xC

#ifndef REG32
#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))
#endif

/* ============================================================
 *  Nios II interrupt-kernel interface.
 *
 *  The header for these is intentionally NOT included; the symbols are
 *  provided by the linked BSP and declared locally so this module pulls in
 *  no HAL headers. Global enable/disable is done directly on the CPU status
 *  register (PIE bit), per-source registration uses the BSP kernel.
 * ============================================================ */
#define NIOS2_STATUS_PIE_MSK  0x1u    /* status.PIE: global interrupt enable */

typedef int irq_context_t;                       /* saved status register */
typedef void (*irq_isr_func_t)(void *context, unsigned int id);

extern int alt_irq_register(unsigned int id, void *context, irq_isr_func_t isr);

/* Mask a single interrupt source by clearing its bit in the CPU ienable
 * control register (ctl3). Replaces the legacy inline alt_irq_disable. */
static inline void irq_source_disable(unsigned int id)
{
    unsigned int ienable;
    __asm__ volatile ("rdctl %0, ienable" : "=r"(ienable));
    ienable &= ~(1u << id);
    __asm__ volatile ("wrctl ienable, %0" :: "r"(ienable));
}

/* Save status and globally disable interrupts; returns prior status. */
static inline irq_context_t irq_disable_all(void)
{
    irq_context_t ctx;
    __asm__ volatile ("rdctl %0, status" : "=r"(ctx));
    __asm__ volatile ("wrctl status, %0" :: "r"(ctx & ~NIOS2_STATUS_PIE_MSK));
    return ctx;
}

/* Restore the status register saved by irq_disable_all(). */
static inline void irq_enable_all(irq_context_t ctx)
{
    __asm__ volatile ("wrctl status, %0" :: "r"(ctx));
}

/* Register and arm every interrupt source. Call once, AFTER the drivers
 * (VGA/audio/timer) are up and stable. */
void irq_init(void);

/* Per-main-loop housekeeping placeholder. Safe to call every pass. */
void irq_service(void);

/* Atomically read + clear the latched button bits. Bit n set => BTN[n] was
 * pressed since the last call. */
uint32_t irq_buttons_take(void);

/* Returns 1 exactly once if the reset switch fired since the last call,
 * then clears the latch. */
int irq_reset_requested_take(void);

#endif /* IRQ_CONTROLLER_H */