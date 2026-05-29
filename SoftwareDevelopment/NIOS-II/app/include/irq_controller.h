#ifndef IRQ_CONTROLLER_H
#define IRQ_CONTROLLER_H

#include <stdint.h>

/* ---- Reset (wipe) signal: 1-bit input PIO, IRQ 2 ---- */
#define RESET_PIO_BASE     0x00083020u
#define RESET_PIO_IRQ      2

/* ---- Buttons: 4-bit input PIO, IRQ 1 (all 4 share this line) ---- */
#define BTN_PIO_BASE       0x00083030u
#define BTN_PIO_IRQ        1
#define BTN_COUNT          4
#define BTN_MASK           0xFu   /* bits 3..0 */

/* Standard Altera PIO register byte offsets */
#define PIO_DATA_OFF       0x0
#define PIO_DIRECTION_OFF  0x4
#define PIO_IRQ_MASK_OFF   0x8
#define PIO_EDGE_CAP_OFF   0xC

#ifndef REG32
#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))
#endif

/* Register and arm every interrupt source. Call once after VGA init. */
void irq_init(void);
void irq_service(void);   /* call from main loop to finish level-IRQ work */

#endif /* IRQ_CONTROLLER_H */