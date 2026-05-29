#ifndef SONG_LIST_H
#define SONG_LIST_H

/* ----------------------------------------------------------------------
 *  song_list.h  --  circular doubly-linked list of songs.
 *
 *  The spec calls for advancing the song pointer through a "linked list of
 *  songs". We build a static circular list over the song indices reported by
 *  the HPS (via shared RAM), so Next/Prev wrap cleanly and song-end -> Next
 *  is a single pointer hop.
 * -------------------------------------------------------------------- */

#include "hw_map.h"

typedef struct song_node {
    uint32_t           index0;   /* 0-based song index into SHARED->meta */
    struct song_node  *next;
    struct song_node  *prev;
} song_node_t;

void                song_list_build(uint32_t count);
song_node_t        *song_list_head(void);
song_node_t        *song_list_next(song_node_t *cur);
song_node_t        *song_list_prev(song_node_t *cur);
uint32_t            song_list_count(void);

#endif /* SONG_LIST_H */