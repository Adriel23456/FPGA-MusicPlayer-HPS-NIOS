#ifndef INPUTS_H
#define INPUTS_H

/* ----------------------------------------------------------------------
 *  inputs.h  --  Push-button (interrupt) and reset-switch drivers.
 *
 *  Buttons are a standard Altera edge-capture PIO:
 *      B0 = Next, B1 = Prev, B2 = Stop, B3 = Play/Pause
 *  An IRQ fires when any enabled bit captures an edge. The ISR reads and
 *  clears the edgecapture register and hands the raw mask to a callback.
 *
 *  The reset switch (SW0) is polled, not interrupt-driven: it must work as
 *  a hard system reset even when the HPS is later attached.
 * -------------------------------------------------------------------- */

#include "hw_map.h"

/* Button bit masks (match the edge-capture register bit positions). */
#define BTN_NEXT        (1u << 0)
#define BTN_PREV        (1u << 1)
#define BTN_STOP        (1u << 2)
#define BTN_PLAYPAUSE   (1u << 3)
#define BTN_ALL_MASK    (BTN_NEXT | BTN_PREV | BTN_STOP | BTN_PLAYPAUSE)

/* Callback invoked from the button ISR with the captured edge mask. */
typedef void (*btn_callback_t)(uint32_t edge_mask);

void buttons_init(btn_callback_t cb);   /* register ISR + enable IRQs */

int  switch_reset_asserted(void);       /* 1 if SW0 currently high    */

#endif /* INPUTS_H */