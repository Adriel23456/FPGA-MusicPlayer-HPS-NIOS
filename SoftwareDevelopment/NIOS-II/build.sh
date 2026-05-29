#!/bin/bash

APP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Building Nios II Application"
echo "============================================================"

# Patch Makefile to use -Os (size optimization) every build
if [ -f "$APP_DIR/Makefile" ]; then
    sed -i 's|APP_CFLAGS_OPTIMIZATION :=.*|APP_CFLAGS_OPTIMIZATION := -Os|' "$APP_DIR/Makefile"
    echo "[OK] Optimization set to -Os"
fi

make -C "$APP_DIR"

[ $? -ne 0 ] && echo "ERROR: Build failed" && exit 1

echo ""
echo "Build successful!"
echo ""
echo "ELF:"
echo "  $APP_DIR/main.elf"
