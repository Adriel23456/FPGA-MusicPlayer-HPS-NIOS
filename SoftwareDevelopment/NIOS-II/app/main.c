#include <sys/alt_stdio.h>
#include <unistd.h>

#define CHAR_BUF_BASE    ((volatile char *)  0x00080000)
#define CHAR_CTRL_BASE   ((volatile int *)   0x00083080)
#define CTRL_REG         0
#define RESOL_REG        1

// 100ms guard: VGA_CHAR_BUFFER is on 25MHz domain and takes
// significantly longer to initialize than NIOS II on 50MHz domain.
#define VGA_RESET_GUARD_US  100000

static inline void vga_put_char(int x, int y, char c)
{
    CHAR_BUF_BASE[(y << 7) | x] = c;
}

static void vga_put_string(int x, int y, const char *str)
{
    while (*str)
        vga_put_char(x++, y, *str++);
}

static void vga_clear_screen(void)
{
    CHAR_CTRL_BASE[CTRL_REG] = (1 << 16);
    while (CHAR_CTRL_BASE[CTRL_REG] & (1 << 16));
}

int main(void)
{
    usleep(VGA_RESET_GUARD_US);
    vga_clear_screen();
    vga_put_string(36, 29, "Hello World!");
    alt_putstr("Hello from Nios II!\n");

    while (1);
    return 0;
}