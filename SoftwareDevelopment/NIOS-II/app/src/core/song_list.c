/* ----------------------------------------------------------------------
 *  song_list.c  --  static circular doubly-linked song list.
 *
 *  Storage is a fixed array (no heap on the NIOS -- avoids fragmentation and
 *  keeps the footprint deterministic). The nodes are linked into a ring so
 *  Next from the last wraps to the first, and Prev from the first wraps to
 *  the last.
 * -------------------------------------------------------------------- */

#include "song_list.h"

static song_node_t s_nodes[MAX_SONGS];
static uint32_t    s_count = 0;

void song_list_build(uint32_t count)
{
    if (count == 0) count = 1;
    if (count > MAX_SONGS) count = MAX_SONGS;
    s_count = count;

    for (uint32_t i = 0; i < count; i++) {
        s_nodes[i].index0 = i;
        s_nodes[i].next = &s_nodes[(i + 1u) % count];
        s_nodes[i].prev = &s_nodes[(i + count - 1u) % count];
    }
}

song_node_t *song_list_head(void)            { return &s_nodes[0]; }
song_node_t *song_list_next(song_node_t *c)  { return c ? c->next : &s_nodes[0]; }
song_node_t *song_list_prev(song_node_t *c)  { return c ? c->prev : &s_nodes[0]; }
uint32_t     song_list_count(void)           { return s_count; }