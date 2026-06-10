#ifndef VGA_DRIVER_H
#define VGA_DRIVER_H

/* ---- Character Buffer for VGA Display (direct register access) ---- */
#define VGA_CHAR_BUF_BASE   0x00010000u   /* avalon_char_buffer_slave  */
#define VGA_CHAR_CTRL_BASE  0x00013068u   /* avalon_char_control_slave */

/* control-slave word offsets */
#define VGA_CTRL_REG    0                 /* Control    register */
#define VGA_RESOL_REG   1                 /* Resolution register (RO) */
#define VGA_CLEAR_BIT   (1u << 16)        /* R bit: write 1 to clear screen */

/* on-board VGA DAC character grid */
#define VGA_COLS    80
#define VGA_ROWS    60

/* ---- Static layout (x = column, y = row) ---- */
#define VGA_MARGIN_X        2
#define VGA_FIELD_X         4             /* values are indented under labels */

#define VGA_SEP_TOP_Y       2
#define VGA_META_LABEL_Y    4
#define VGA_NAME_Y          5
#define VGA_ARTIST_Y        6
#define VGA_ALBUM_Y         7
#define VGA_DURATION_Y      8
#define VGA_SONG_LABEL_Y    10
#define VGA_TRACK_Y         11
#define VGA_STATE_LABEL_Y   13
#define VGA_STATE_Y         14
#define VGA_SEP_BOT_Y       16

/* ---- Dynamic field widths (how many cells to blank before redraw) ---- */
#define VGA_NAME_W       48
#define VGA_ARTIST_W     48
#define VGA_ALBUM_W      48
#define VGA_DURATION_W   5    /* MM:SS */
#define VGA_TRACK_W      7    /* CC/TT */
#define VGA_STATE_W      10   /* playing / paused / stopped */
#define VGA_SEP_W        48

/* ---- API ---- */
void vga_init(void);                 /* clear + draw static template   */
void vga_clear(void);                /* hardware clear via Control reg */
void vga_draw_template(void);        /* draw the never-changing parts  */

void vga_set_song_name(const char *name);
void vga_set_artist(const char *artist);
void vga_set_album(const char *album);
void vga_set_duration(unsigned int total_seconds);            /* -> MM:SS */
void vga_set_track(unsigned int current, unsigned int total); /* -> CC/TT */
void vga_set_state(const char *state);

void vga_reset_volatile(void);   /* blank all dynamic fields, keep template */

#endif /* VGA_DRIVER_H */