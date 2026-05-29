/* ======================================================================
 *  main.c  --  NIOS II interrupt-driven music player.
 *
 *  Boot sequence:
 *    1. VGA up, splash.
 *    2. Audio engine up (AV-config + WM8731 auto-init, audio core reset,
 *       write-IRQ ISR registered but masked).
 *    3. Producer boot: announces >=10 songs into shared RAM (dummy for now;
 *       drop-in replaceable by the real HPS handshake later).
 *    4. Buttons up (edge-capture PIO + ISR).
 *    5. FSM init: Stopped, song 1/N, song 1 loaded, timer reset, VGA drawn.
 *
 *  Steady state: ISRs only *flag* work; the main loop performs it:
 *    - button edges  -> fsm_on_buttons
 *    - song-end flag -> fsm_on_song_end
 *    - ~1 Hz tick    -> fsm_on_tick_1s   (display clock)
 *    - reset switch  -> full software re-init (works with HPS attached too)
 *
 *  The button ISR is intentionally thin: it captures the edge mask into a
 *  pending variable and returns. We service it in the loop so the FSM (which
 *  does VGA + handshake work) never runs in interrupt context.
 * ====================================================================== */

#include <sys/alt_stdio.h>
#include "sys/alt_irq.h"
#include <unistd.h>

#include "hw_map.h"
#include "shared_mem.h"
#include "debug_uart.h"
#include "vga_ui.h"
#include "audio_engine.h"
#include "inputs.h"
#include "timer_ctrl.h"
#include "player_fsm.h"
#include "dummy_hps.h"

/* ---- ISR -> main-loop mailboxes (volatile: written in IRQ context) ----- */
static volatile uint32_t g_pending_buttons = 0;
static volatile int      g_pending_songend = 0;

/* Button ISR callback: accumulate edges, defer all real work. */
static void on_button_edges(uint32_t edge_mask)
{
    g_pending_buttons |= edge_mask;
}

/* Audio engine callback (runs in audio ISR): just raise a flag. */
static void on_song_end_isr(void)
{
    g_pending_songend = 1;
}

/* Atomically take-and-clear the pending button mask. Buttons share the same
   IRQ priority space, so a short critical section is enough; we briefly
   disable interrupts to avoid losing an edge that arrives mid-read. */
static uint32_t take_buttons(void)
{
    alt_irq_context ctx = alt_irq_disable_all();
    uint32_t m = g_pending_buttons;
    g_pending_buttons = 0;
    alt_irq_enable_all(ctx);
    return m;
}

/* Full software reset of the player subsystem. Safe to call repeatedly and
   safe once the HPS is attached: it re-announces songs, reloads song 1, and
   returns the FSM to Stopped. */
static void system_software_reset(void)
{
    audio_stop();
    (void)timer_reset();

    dummy_hps_boot();          /* re-announce song table (HPS would do this) */
    while (SHARED->ctrl.hps_state != HPS_READY) { /* wait for producer */ }

    fsm_init();                /* Stopped, song 1/N, VGA drawn */

    g_pending_buttons = 0;
    g_pending_songend = 0;
}

int main(void)
{
    /* All boot prints use dbg_puts (non-blocking): even with no terminal
       attached, or a full JTAG FIFO, these never stall the player. Each
       checkpoint prints BEFORE the step it guards, so the last line you see
       in the terminal is the step that hung. */
    dbg_puts("BOOT: start\n");

    /* 1. VGA + splash */
    dbg_puts("BOOT: vga_init...\n");
    vga_init();
    dbg_puts("BOOT: vga_init done\n");

    /* 2. Audio */
    dbg_puts("BOOT: audio_init...\n");
    audio_init(on_song_end_isr);
    dbg_puts("BOOT: audio_init done\n");

    /* 3. Timer (reset, stopped) */
    dbg_puts("BOOT: timer_init...\n");
    timer_init();
    dbg_puts("BOOT: timer_init done\n");

    /* 4. Producer announces the song catalogue (dummy stand-in for HPS) */
    dbg_puts("BOOT: dummy_hps_boot...\n");
    dummy_hps_boot();
    while (SHARED->ctrl.hps_state != HPS_READY) {
        /* In the real system this waits for the HPS to publish song_count. */
    }
    dbg_puts("BOOT: producer ready\n");

    /* 5. Buttons (edge-capture IRQ) */
    dbg_puts("BOOT: buttons_init...\n");
    buttons_init(on_button_edges);
    dbg_puts("BOOT: buttons_init done\n");

    /* 6. FSM: Stopped, song 1/N, song 1 loaded, timer reset, VGA drawn */
    dbg_puts("BOOT: fsm_init...\n");
    fsm_init();
    dbg_puts("BOOT: fsm_init done\n");

    dbg_puts("Ready. B0=Next B1=Prev B2=Stop B3=Play/Pause\n");

    /* ---- event loop ---------------------------------------------------- */
    int prev_switch = switch_reset_asserted();
    uint32_t tick_accum_us = 0;
    const uint32_t LOOP_US = 5000;   /* 5 ms loop period */

    for (;;) {
        /* (a) system reset switch -- rising edge triggers a full reset */
        int sw = switch_reset_asserted();
        if (sw && !prev_switch) {
            dbg_puts("System reset requested.\n");
            system_software_reset();
            prev_switch = sw;
            tick_accum_us = 0;
            continue;
        }
        prev_switch = sw;

        /* (b) buttons */
        uint32_t btns = take_buttons();
        if (btns) {
            fsm_on_buttons(btns);
        }

        /* (c) song end */
        if (g_pending_songend) {
            g_pending_songend = 0;
            fsm_on_song_end();
        }

        /* (d) keep the producer's batch ring topped up (prefetch stand-in).
               Harmless once the real HPS owns this -- it just won't move. */
        dummy_hps_service_prefetch();

        /* (e) ~1 Hz display tick */
        tick_accum_us += LOOP_US;
        if (tick_accum_us >= 1000000u) {
            tick_accum_us -= 1000000u;
            fsm_on_tick_1s();
        }

        usleep(LOOP_US);
    }

    return 0;   /* never reached */
}