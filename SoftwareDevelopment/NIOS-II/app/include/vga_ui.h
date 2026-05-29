#ifndef VGA_UI_H
#define VGA_UI_H

/* ----------------------------------------------------------------------
 *  vga_ui.h  --  Whole-screen metadata/state renderer for the char buffer.
 *
 *  Screen layout (80x60 grid), rendered fresh on every state change and on
 *  every timer tick:
 *
 *      Song Metadata:
 *        <name>
 *        <artist>
 *        <album>
 *        <duration MM:SS>
 *
 *      Current Song:
 *        NN/MM
 *
 *      Current State:
 *        <Playing|Paused|Stopped>
 *
 *      Elapsed:
 *        MM:SS
 * -------------------------------------------------------------------- */

#include "hw_map.h"
#include "shared_mem.h"

typedef enum {
    UI_STOPPED = 0,
    UI_PLAYING = 1,
    UI_PAUSED  = 2
} ui_state_t;

void vga_init(void);   /* safe clear + settle for the 25 MHz domain */

/* Full redraw. `index0` is 0-based; rendered as 1-based NN/MM. */
void vga_render(const volatile song_meta_t *meta,
                uint32_t index0,
                uint32_t total,
                ui_state_t state,
                uint32_t elapsed_sec);

/* Light update: only repaint the elapsed-time line (called each tick). */
void vga_update_elapsed(uint32_t elapsed_sec);

#endif /* VGA_UI_H */