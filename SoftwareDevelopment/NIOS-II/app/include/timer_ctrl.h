#ifndef TIMER_CTRL_H
#define TIMER_CTRL_H

/* ----------------------------------------------------------------------
 *  timer_ctrl.h  --  Drive the audio-clock timer via the ctrl/status wires.
 *
 *  Protocol (per the component spec):
 *    - write a 2-bit command to TIMER_CTRL_OUTPUT
 *    - the hardware mirrors the executed command on TIMER_STATUS_INPUT
 *    - once mirrored, we drop the control word back to NOP so the active
 *      functional state is held without us continuously asserting it.
 *
 *  This timer is the *display* clock (MM:SS). Song-end is decided by audio
 *  buffer exhaustion, not by this timer (see audio_engine).
 * -------------------------------------------------------------------- */

#include "hw_map.h"

void timer_init(void);            /* leave timer reset + stopped */
int  timer_run(void);             /* start counting; 1 = confirmed */
int  timer_pause(void);           /* hold count;     1 = confirmed */
int  timer_reset(void);           /* zero the count; 1 = confirmed */

#endif /* TIMER_CTRL_H */