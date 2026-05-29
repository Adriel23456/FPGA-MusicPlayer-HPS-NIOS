/* ----------------------------------------------------------------------
 *  vga_ui.c  --  raw char-buffer renderer (no HAL driver dependency).
 *
 *  The Character Buffer for VGA Display has TWO Avalon slaves:
 *    - control slave (VGA_CHAR_CTRL_BASE): word-addressed. Reg 0 = control
 *      (bit 16 = clear-screen R bit); reg 1 = resolution (read-only).
 *    - char buffer slave (VGA_CHAR_BUF_BASE): X-Y addressed. The byte offset
 *      of cell (x,y) is (y << 7) | x, for the 80x60 resolution (X in bits
 *      0..6, Y in bits 7..12).
 *
 *  We use raw register access (not the UP HAL driver) so the project does
 *  not depend on altera_up_avalon_character_buffer_with_dma.h being present
 *  in the BSP. The clear handshake is BOUNDED by a timeout so a slow/odd
 *  readback can never hang the whole player.
 * -------------------------------------------------------------------- */

#include "vga_ui.h"
#include "debug_uart.h"
#include <unistd.h>   /* usleep */

/* ---- low-level glyph plotting ------------------------------------------ */
static inline void put_char(int x, int y, char c)
{
    if (x < 0 || x >= VGA_COLS || y < 0 || y >= VGA_ROWS) return;
    REG8(VGA_CHAR_BUF_BASE + ((unsigned)y << 7) + (unsigned)x) = (uint8_t)c;
}

static void put_str(int x, int y, const char *s)
{
    while (*s && x < VGA_COLS) {
        put_char(x++, y, *s++);
    }
}

static void clear_line(int y)
{
    for (int x = 0; x < VGA_COLS; x++) put_char(x, y, ' ');
}

/* Clear the whole screen by writing spaces to every cell.
   We deliberately do NOT use the control-register clear-bit handshake here:
   that readback was the original hang. Writing spaces directly is reliable
   and only 80*60 = 4800 byte writes -- fast and unconditional. */
static void clear_all(void)
{
    for (int y = 0; y < VGA_ROWS; y++) {
        for (int x = 0; x < VGA_COLS; x++) {
            put_char(x, y, ' ');
        }
    }
}

/* ---- tiny formatting helpers (no stdio: keep .text small) -------------- */
static void u_to_2digit(uint32_t v, char *out /* >=3 */)
{
    if (v > 99) v = 99;
    out[0] = (char)('0' + (v / 10));
    out[1] = (char)('0' + (v % 10));
    out[2] = '\0';
}

static void fmt_mmss(uint32_t total_sec, char *out /* >=6 */)
{
    uint32_t m = total_sec / 60u;
    uint32_t s = total_sec % 60u;
    char mm[3], ss[3];
    u_to_2digit(m, mm);
    u_to_2digit(s, ss);
    out[0] = mm[0]; out[1] = mm[1]; out[2] = ':';
    out[3] = ss[0]; out[4] = ss[1]; out[5] = '\0';
}

static void fmt_index(uint32_t idx1, uint32_t total, char *out /* >=6 */)
{
    char a[3], b[3];
    u_to_2digit(idx1, a);
    u_to_2digit(total, b);
    out[0] = a[0]; out[1] = a[1]; out[2] = '/';
    out[3] = b[0]; out[4] = b[1]; out[5] = '\0';
}

static const char *state_text(ui_state_t st)
{
    switch (st) {
        case UI_PLAYING: return "Playing";
        case UI_PAUSED:  return "Paused ";
        default:         return "Stopped";
    }
}

/* ---- fixed row coordinates --------------------------------------------- */
#define COL_LABEL   4
#define COL_VALUE   6
#define ROW_META_HDR    3
#define ROW_NAME        4
#define ROW_ARTIST      5
#define ROW_ALBUM       6
#define ROW_DURATION    7
#define ROW_CUR_HDR     10
#define ROW_CUR_VAL     11
#define ROW_STATE_HDR   14
#define ROW_STATE_VAL   15
#define ROW_ELAP_HDR    18
#define ROW_ELAP_VAL    19

void vga_init(void)
{
    dbg_puts("VGA: clearing screen...\n");
    clear_all();
    /* Write an obvious marker so we can confirm the char buffer is reachable
       even before any real content is drawn. If you see "VGA OK" in the
       top-left corner of the monitor, writes to VGA_CHAR_BUF_BASE are landing. */
    put_str(0, 0, "VGA OK");
    dbg_puts("VGA: ready\n");
}

void vga_render(const volatile song_meta_t *meta,
                uint32_t index0,
                uint32_t total,
                ui_state_t state,
                uint32_t elapsed_sec)
{
    char dur[6], idx[6];

    clear_all();

    put_str(COL_LABEL, ROW_META_HDR, "Song Metadata:");
    put_str(COL_VALUE, ROW_NAME,     (const char *)meta->name);
    put_str(COL_VALUE, ROW_ARTIST,   (const char *)meta->artist);
    put_str(COL_VALUE, ROW_ALBUM,    (const char *)meta->album);

    fmt_mmss(meta->duration_sec, dur);
    put_str(COL_VALUE, ROW_DURATION, dur);

    put_str(COL_LABEL, ROW_CUR_HDR, "Current Song:");
    fmt_index(index0 + 1u, total, idx);
    put_str(COL_VALUE, ROW_CUR_VAL, idx);

    put_str(COL_LABEL, ROW_STATE_HDR, "Current State:");
    put_str(COL_VALUE, ROW_STATE_VAL, state_text(state));

    put_str(COL_LABEL, ROW_ELAP_HDR, "Elapsed:");
    vga_update_elapsed(elapsed_sec);
}

void vga_update_elapsed(uint32_t elapsed_sec)
{
    char buf[6];
    fmt_mmss(elapsed_sec, buf);
    clear_line(ROW_ELAP_VAL);
    put_str(COL_VALUE, ROW_ELAP_VAL, buf);
}