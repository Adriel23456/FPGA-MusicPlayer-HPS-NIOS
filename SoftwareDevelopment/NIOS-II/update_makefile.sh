#!/bin/bash
SW_ROOT="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II"
BSP_DIR="$SW_ROOT/bsp"
APP_DIR="$SW_ROOT/app"
export PATH=$PATH:/mnt/c/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-mingw32/bin

to_win() { echo "$1" | sed 's|/mnt/\([a-z]\)/|\1:/|'; }

echo "=== Scanning source files ==="
SRCS=""
for f in "$APP_DIR"/*.c "$APP_DIR"/src/*.c "$APP_DIR"/lib/*.c; do
    [ -f "$f" ] && SRCS="$SRCS $f"
done
SRCS="${SRCS# }"

echo "Sources found:"
for f in $SRCS; do echo "  $f"; done
echo ""

WIN_SRCS=""
for f in $SRCS; do
    WIN_SRCS="$WIN_SRCS $(to_win "$f")"
done
WIN_SRCS="${WIN_SRCS# }"

nios2-app-generate-makefile.exe \
    --bsp-dir "$(to_win "$BSP_DIR")" \
    --app-dir "$(to_win "$APP_DIR")" \
    --src-files $WIN_SRCS \
    --inc-rdir "$(to_win "$APP_DIR/include")"
[ $? -ne 0 ] && echo "ERROR: Makefile regeneration failed" && exit 1

echo "Done! Run ./build.sh to recompile."
