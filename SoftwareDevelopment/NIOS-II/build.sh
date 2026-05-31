#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

: "${QUARTUS_ROOTDIR:=/home/dadump/intelFPGA_lite/22.1std/quartus}"
: "${SOPC_KIT_NIOS2:=/home/dadump/intelFPGA_lite/22.1std/nios2eds}"

export QUARTUS_ROOTDIR
export SOPC_KIT_NIOS2
export PATH="$PATH:$SOPC_KIT_NIOS2/bin/gnu/H-x86_64-pc-linux-gnu/bin"

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
