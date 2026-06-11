#ifndef PLAYER_FSM_H
#define PLAYER_FSM_H

typedef enum { ST_STOPPED, ST_PLAYING, ST_PAUSED } player_state_t;

void player_init(void);     /* full reset: load song 1, stopped, timer reset */
void player_service(void);  /* call every main-loop pass: feeds audio, polls */

/* button actions (called from main after draining the button latch) */
void player_play_pause(void);
void player_next(void);
void player_prev(void);
void player_stop(void);
void player_reset(void);    /* reset switch -> redo init from step 1 */

#endif /* PLAYER_FSM_H */