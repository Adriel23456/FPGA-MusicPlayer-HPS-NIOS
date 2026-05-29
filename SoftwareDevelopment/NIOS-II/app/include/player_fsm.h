#ifndef PLAYER_FSM_H
#define PLAYER_FSM_H

/* ----------------------------------------------------------------------
 *  player_fsm.h  --  the Stopped/Playing/Paused state machine.
 *
 *  Inputs:  button edge events (deferred from the ISR), song-end events
 *           (from the audio engine), and the periodic display tick.
 *  Outputs: audio engine commands, timer commands, VGA redraws.
 *
 *  The FSM always considers (current state x button) before acting, exactly
 *  as required, and updates the VGA after every transition.
 * -------------------------------------------------------------------- */

#include "hw_map.h"

typedef enum {
    ST_STOPPED = 0,
    ST_PLAYING = 1,
    ST_PAUSED  = 2
} player_state_t;

/* Bring the FSM to its reset condition: Stopped, song 1/N, timer reset,
   VGA showing song 1 metadata. Also (re)loads song 1 via the producer. */
void fsm_init(void);

/* Event entry points (all run from the main loop, not from ISRs). */
void fsm_on_buttons(uint32_t edge_mask);  /* raw edge mask from button ISR */
void fsm_on_song_end(void);               /* engine flagged end-of-song    */
void fsm_on_tick_1s(void);                /* ~1 Hz display update          */

player_state_t fsm_state(void);

#endif /* PLAYER_FSM_H */