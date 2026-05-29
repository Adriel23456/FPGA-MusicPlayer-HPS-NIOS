#include "vga_driver.h"
#include "debug_uart.h"
#include <stdint.h>

/* byte-wide character buffer, X-Y addressed */
static volatile char     *const CHAR_BUF  = (volatile char *)     VGA_CHAR_BUF_BASE;
/* word-wide control slave */
static volatile uint32_t *const CHAR_CTRL = (volatile uint32_t *) VGA_CHAR_CTRL_BASE;

/* 80x60 X-Y byte offset: X in bits 6-0, Y in bits 12-7 */
static inline unsigned vga_offset(unsigned x, unsigned y)
{
    return (y << 7) | x;
}

static void vga_put_char(unsigned x, unsigned y, char c)
{
    if (x >= VGA_COLS || y >= VGA_ROWS)
        return;
    CHAR_BUF[vga_offset(x, y)] = c;
}

static void vga_put_string(unsigned x, unsigned y, const char *s)
{
    while (*s && x < VGA_COLS)
        CHAR_BUF[vga_offset(x++, y)] = *s++;
}

/* blank `width` cells so a shorter new value never leaves stale chars */
static void vga_clear_field(unsigned x, unsigned y, unsigned width)
{
    for (unsigned i = 0; i < width && (x + i) < VGA_COLS; i++)
        CHAR_BUF[vga_offset(x + i, y)] = ' ';
}

static void vga_draw_separator(unsigned y)
{
    for (unsigned x = 0; x < VGA_SEP_W && (VGA_MARGIN_X + x) < VGA_COLS; x++)
        CHAR_BUF[vga_offset(VGA_MARGIN_X + x, y)] = '=';
}

/* ---- 2-digit zero-padded helper (no libc) ---- */
static void put2(char *dst, unsigned v)
{
    if (v > 99u) v = 99u;
    dst[0] = (char)('0' + (v / 10u));
    dst[1] = (char)('0' + (v % 10u));
}

/* ---- hardware clear ---- */
void vga_clear(void)
{
    dbg_puts("[VGA] clear: assert R bit\r\n");
    CHAR_CTRL[VGA_CTRL_REG] = VGA_CLEAR_BIT;
    while (CHAR_CTRL[VGA_CTRL_REG] & VGA_CLEAR_BIT)
        ;   /* R stays 1 until the buffer is fully cleared */
    dbg_puts("[VGA] clear: done\r\n");
}

/* ---- static template (drawn once) ---- */
void vga_draw_template(void)
{
    dbg_puts("[VGA] draw static template\r\n");
    vga_draw_separator(VGA_SEP_TOP_Y);
    vga_put_string(VGA_MARGIN_X, VGA_META_LABEL_Y,  "Song Metadata:");
    vga_put_string(VGA_MARGIN_X, VGA_SONG_LABEL_Y,  "Current Song:");
    vga_put_string(VGA_MARGIN_X, VGA_STATE_LABEL_Y, "Current State:");
    vga_draw_separator(VGA_SEP_BOT_Y);
    dbg_puts("[VGA] static template ready\r\n");
}

void vga_init(void)
{
    dbg_puts("[VGA] init: start\r\n");
    vga_clear();
    vga_draw_template();
    dbg_puts("[VGA] init: complete\r\n");
}

/* ---- dynamic field updaters (each clears then writes its own field) ---- */
void vga_set_song_name(const char *name)
{
    dbg_puts("[VGA] song name: "); dbg_puts(name); dbg_puts("\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_NAME_Y, VGA_NAME_W);
    vga_put_string (VGA_FIELD_X, VGA_NAME_Y, name);
}

void vga_set_artist(const char *artist)
{
    dbg_puts("[VGA] artist: "); dbg_puts(artist); dbg_puts("\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_ARTIST_Y, VGA_ARTIST_W);
    vga_put_string (VGA_FIELD_X, VGA_ARTIST_Y, artist);
}

void vga_set_album(const char *album)
{
    dbg_puts("[VGA] album: "); dbg_puts(album); dbg_puts("\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_ALBUM_Y, VGA_ALBUM_W);
    vga_put_string (VGA_FIELD_X, VGA_ALBUM_Y, album);
}

void vga_set_duration(unsigned int total_seconds)
{
    char buf[6];
    put2(&buf[0], total_seconds / 60u);   /* MM */
    buf[2] = ':';
    put2(&buf[3], total_seconds % 60u);   /* SS */
    buf[5] = '\0';

    dbg_puts("[VGA] duration: "); dbg_puts(buf); dbg_puts("\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_DURATION_Y, VGA_DURATION_W);
    vga_put_string (VGA_FIELD_X, VGA_DURATION_Y, buf);
}

void vga_set_track(unsigned int current, unsigned int total)
{
    char buf[6];
    put2(&buf[0], current);
    buf[2] = '/';
    put2(&buf[3], total);
    buf[5] = '\0';

    dbg_puts("[VGA] track: "); dbg_puts(buf); dbg_puts("\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_TRACK_Y, VGA_TRACK_W);
    vga_put_string (VGA_FIELD_X, VGA_TRACK_Y, buf);
}

void vga_set_state(const char *state)
{
    dbg_puts("[VGA] state: "); dbg_puts(state); dbg_puts("\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_STATE_Y, VGA_STATE_W);
    vga_put_string (VGA_FIELD_X, VGA_STATE_Y, state);
}

void vga_reset_volatile(void)
{
    dbg_puts("[VGA] reset: wiping volatile fields\r\n");
    vga_clear_field(VGA_FIELD_X, VGA_NAME_Y,     VGA_NAME_W);
    vga_clear_field(VGA_FIELD_X, VGA_ARTIST_Y,   VGA_ARTIST_W);
    vga_clear_field(VGA_FIELD_X, VGA_ALBUM_Y,    VGA_ALBUM_W);
    vga_clear_field(VGA_FIELD_X, VGA_DURATION_Y, VGA_DURATION_W);
    vga_clear_field(VGA_FIELD_X, VGA_TRACK_Y,    VGA_TRACK_W);
    vga_clear_field(VGA_FIELD_X, VGA_STATE_Y,    VGA_STATE_W);
}