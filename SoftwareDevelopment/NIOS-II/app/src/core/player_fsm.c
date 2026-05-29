/* ----------------------------------------------------------------------
 *  player_fsm.c  --  interrupt-driven Stopped/Playing/Paused machine.
 *
 *  Button semantics (B0 Next, B1 Prev, B2 Stop, B3 Play/Pause):
 *
 *    Play/Pause:
 *        Stopped/Paused -> resume from saved position, start FIFO stream,
 *                          run timer  -> Playing
 *        Playing        -> stop FIFO drain, save position, pause timer
 *                          -> Paused
 *    Next / Prev:
 *        from any state  -> advance/retreat song pointer, reset position,
 *                          reset timer, start streaming new song -> Playing
 *    Stop:
 *        from any state  -> flush FIFO, reset position to song start,
 *                          reset timer -> Stopped
 *    Song-end (auto):
 *        triggers the Next flow.
 *
 *  Every transition ends with a VGA redraw so the displayed state is always
 *  current. The timer here is the *display* clock only; elapsed seconds come
 *  from the 1 Hz tick while Playing.
 * -------------------------------------------------------------------- */

#include "player_fsm.h"
#include "audio_engine.h"
#include "timer_ctrl.h"
#include "vga_ui.h"
#include "song_list.h"
#include "dummy_hps.h"
#include "inputs.h"
#include "shared_mem.h"

/* ---- FSM state --------------------------------------------------------- */
static player_state_t  g_state    = ST_STOPPED;
static song_node_t    *g_cur      = 0;
static uint32_t        g_elapsed  = 0;   /* seconds shown on the display */

/* ---- helpers ----------------------------------------------------------- */

static const volatile song_meta_t *cur_meta(void)
{
    return &SHARED->meta[g_cur->index0];
}

static uint32_t cur_rate(void)
{
    return SHARED->meta[g_cur->index0].sample_rate;
}

static ui_state_t to_ui(player_state_t s)
{
    return (s == ST_PLAYING) ? UI_PLAYING
         : (s == ST_PAUSED)  ? UI_PAUSED
                             : UI_STOPPED;
}

/* Single point that pushes the whole screen for the current situation. */
static void redraw(void)
{
    vga_render(cur_meta(),
               g_cur->index0,
               song_list_count(),
               to_ui(g_state),
               g_elapsed);
}

/* Ask the producer to (re)load a song's metadata + first batches, point the
   engine at the start, and reset the display clock. Does NOT start playback. */
static void prepare_song(song_node_t *node)
{
    g_cur = node;

    /* Producer loads metadata + first 3 batches into the ring. */
    dummy_hps_load_song(g_cur->index0);
    SHARED->ctrl.requested_song = g_cur->index0;
    SHARED->ctrl.nios_request   = REQ_SONG_LOAD;
    SHARED->ctrl.req_token     += 1u;
    SHARED_BARRIER();

    audio_rewind_for_new_song(cur_rate());
    (void)timer_reset();
    g_elapsed = 0;
}

/* ---- transition actions ------------------------------------------------ */

static void enter_playing(void)
{
    audio_start(cur_rate());   /* engine resumes from saved position */
    (void)timer_run();
    g_state = ST_PLAYING;
    redraw();
}

static void enter_playing_resume(void)
{
    audio_resume();
    (void)timer_run();
    g_state = ST_PLAYING;
    redraw();
}

static void enter_paused(void)
{
    audio_pause();
    (void)timer_pause();
    g_state = ST_PAUSED;
    redraw();
}

static void enter_stopped(void)
{
    audio_stop();              /* flush + position to 0 */
    (void)timer_reset();
    g_elapsed = 0;
    g_state = ST_STOPPED;
    redraw();
}

/* Shared Next/Prev body. */
static void change_song(song_node_t *target)
{
    /* Always lands in Playing per the spec. */
    audio_stop();
    prepare_song(target);
    enter_playing();           /* fresh start of the new song */
}

/* ---- button handling --------------------------------------------------- */

static void handle_play_pause(void)
{
    switch (g_state) {
        case ST_PLAYING:
            enter_paused();
            break;
        case ST_PAUSED:
            enter_playing_resume();
            break;
        case ST_STOPPED:
        default:
            /* resume-from-start: position is already 0 after a stop/init */
            enter_playing();
            break;
    }
}

void fsm_on_buttons(uint32_t edge_mask)
{
    /* Priority order if multiple edges arrive together: Stop dominates, then
       Next, then Prev, then Play/Pause. This keeps behaviour deterministic
       under simultaneous presses. */
    if (edge_mask & BTN_STOP) {
        enter_stopped();
        return;
    }
    if (edge_mask & BTN_NEXT) {
        change_song(song_list_next(g_cur));
        return;
    }
    if (edge_mask & BTN_PREV) {
        change_song(song_list_prev(g_cur));
        return;
    }
    if (edge_mask & BTN_PLAYPAUSE) {
        handle_play_pause();
        return;
    }
}

/* ---- automatic song-end ------------------------------------------------ */
void fsm_on_song_end(void)
{
    /* Only meaningful while playing; auto-advance to the next track. */
    if (g_state == ST_PLAYING) {
        change_song(song_list_next(g_cur));
    }
}

/* ---- 1 Hz display tick ------------------------------------------------- */
void fsm_on_tick_1s(void)
{
    if (g_state != ST_PLAYING) return;

    /* Elapsed time comes from the audio engine's source-frame counter, which
       is locked to the CODEC's playback clock -- no software drift. The 2-bit
       hardware timer is display-only and not consulted for this value. */
    g_elapsed = audio_elapsed_seconds();
    if (g_elapsed > HARDCODED_SONG_SECONDS) g_elapsed = HARDCODED_SONG_SECONDS;
    vga_update_elapsed(g_elapsed);
}

/* ---- init -------------------------------------------------------------- */
void fsm_init(void)
{
    song_list_build(SHARED->ctrl.song_count);
    g_cur     = song_list_head();
    g_state   = ST_STOPPED;
    g_elapsed = 0;

    /* On reset: Stopped, song 1/N, fetch song 1, reset timer, draw. */
    prepare_song(g_cur);
    redraw();
}

player_state_t fsm_state(void) { return g_state; }