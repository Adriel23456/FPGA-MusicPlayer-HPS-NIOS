#ifndef DUMMY_HPS_H
#define DUMMY_HPS_H

/* ----------------------------------------------------------------------
 *  dummy_hps.h  --  Stand-in for the (not-yet-built) HPS data producer.
 *
 *  Until the real HPS<->NIOS handshake exists, this module fills the shared
 *  RAM image so the state machine can be exercised end-to-end on hardware:
 *    - announces DUMMY_SONG_COUNT (>=10) songs
 *    - writes synthetic metadata per song
 *    - fills the batch ring with a test tone / white-ish noise so audio is
 *      audible and song-end actually triggers
 *
 *  Every routine here writes ONLY the fields the real HPS would own, through
 *  the same shared-memory barriers, so deleting this module and attaching the
 *  real producer requires no change to the consumer (state machine / engine).
 * -------------------------------------------------------------------- */

#include "shared_mem.h"

void dummy_hps_boot(void);                 /* announce song_count, HPS_READY */
void dummy_hps_load_song(uint32_t index0); /* meta + first 3 batches         */
void dummy_hps_service_prefetch(void);     /* refill any slot NIOS freed      */

#endif /* DUMMY_HPS_H */