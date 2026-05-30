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
 *  bits that fired (bit-clearing enabled on both PIOs -> per-bit
 *  independence, no missed presses), and latch the event for the main
 *  loop. All real work (screen wipes, song changes, long busy-waits) runs
 *  in the main loop, never in interrupt context.
 * ============================================================ */

/* ---- Reset switch: 1-bit input PIO, EDGE, IRQ 2 ---- */
#define RESET_PIO_BASE     0x00083020u
#define RESET_PIO_IRQ      2

/* ---- Buttons: 4-bit input PIO, EDGE, IRQ 1 (all 4 share this line) ---- */
#define BTN_PIO_BASE       0x00083030u
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

/* Register and arm every interrupt source. Call once, AFTER the drivers
 * (VGA/audio/timer) are up and stable. */
void irq_init(void);

/* Per-main-loop housekeeping for interrupt-driven state. Currently a no-op
 * placeholder kept so callers don't have to change if future sources need
 * deferred servicing. Safe to call every pass. */
void irq_service(void);

/* Atomically read + clear the latched button bits. Bit n set => BTN[n] was
 * pressed since the last call. Drained by the main loop, which dispatches
 * the matching player action. */
uint32_t irq_buttons_take(void);

/* Returns 1 exactly once if the reset switch fired since the last call,
 * then clears the latch. Used by the main loop to trigger a full
 * player reset (redo from step 1). */
int irq_reset_requested_take(void);

#endif /* IRQ_CONTROLLER_H */