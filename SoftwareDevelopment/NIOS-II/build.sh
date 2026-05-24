#!/bin/bash
APP_DIR="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app"
export PATH=$PATH:/mnt/c/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-mingw32/bin

echo "=== Building Nios II Application ==="
make -C "$APP_DIR"
[ $? -ne 0 ] && echo "ERROR: Build failed" && exit 1
echo ""
echo "Build successful!"
echo "  ELF: $APP_DIR/main.elf"
