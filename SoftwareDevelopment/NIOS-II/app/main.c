#include <sys/alt_stdio.h>

// ── Base addresses (from Address Map) ────────────────────────
#define CHAR_BUF_BASE    ((volatile char *)  0x00080000)
#define CHAR_CTRL_BASE   ((volatile int *)   0x00083080)

// Control register offsets (word-addressed)
#define CTRL_REG         0   // bit 16 = R (clear screen)
#define RESOL_REG        1   // read-only: [31:16]=lines, [15:0]=chars

// ── Write a single character at screen position (x, y) ───────
static inline void vga_put_char(int x, int y, char c)
{
    // X-Y address: bits[6:0]=x, bits[12:7]=y
    int offset = (y << 7) | x;
    CHAR_BUF_BASE[offset] = c;
}

// ── Write a null-terminated string starting at (x, y) ────────
static void vga_put_string(int x, int y, const char *str)
{
    while (*str)
    {
        vga_put_char(x++, y, *str++);
    }
}

// ── Clear screen by setting R bit in Control register ─────────
static void vga_clear_screen(void)
{
    CHAR_CTRL_BASE[CTRL_REG] = (1 << 16);  // assert R bit
    // Wait until clear is done (R bit returns to 0)
    while (CHAR_CTRL_BASE[CTRL_REG] & (1 << 16));
}

// ─────────────────────────────────────────────────────────────
int main(void)
{
    vga_clear_screen();
    vga_put_string(36, 29, "Hello World!");  // roughly centered

    while (1);
    return 0;
}