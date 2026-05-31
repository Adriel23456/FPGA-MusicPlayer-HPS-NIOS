#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOPCINFO="$REPO_ROOT/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
SW_ROOT="$SCRIPT_DIR"
CPU_NAME="CPU_NIOS_II"

BSP_DIR="$SW_ROOT/bsp"
APP_DIR="$SW_ROOT/app"

: "${QUARTUS_ROOTDIR:=/home/dadump/intelFPGA_lite/22.1std/quartus}"
: "${SOPC_KIT_NIOS2:=/home/dadump/intelFPGA_lite/22.1std/nios2eds}"

export QUARTUS_ROOTDIR
export SOPC_KIT_NIOS2
export PATH="$PATH:$SOPC_KIT_NIOS2/bin/gnu/H-x86_64-pc-linux-gnu/bin"

echo "============================================================"
echo " Nios II BSP + Makefile Generator"
echo "============================================================"
echo ""

SRCS=""

for f in "$APP_DIR"/*.c "$APP_DIR"/src/*.c "$APP_DIR"/lib/*.c; do
    [ -f "$f" ] && SRCS="$SRCS $f"
done

SRCS="${SRCS# }"

echo "Sources found:"
for f in $SRCS; do
    echo "  $f"
done

echo ""
echo "[1/3] Generating BSP..."

nios2-bsp hal \
    "$BSP_DIR" \
    "$SOPCINFO" \
    --cpu-name "$CPU_NAME" \
    --set hal.enable_reduced_device_drivers true \
    --set hal.enable_small_c_library true \
    --set hal.enable_lightweight_device_driver_api true \
    --set hal.sys_clk_timer none \
    --set hal.timestamp_timer none \
    --set hal.max_file_descriptors 4 \
    --set hal.enable_exit false

[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

echo ""
echo "[2/3] Generating Makefile..."

nios2-app-generate-makefile \
    --bsp-dir "$BSP_DIR" \
    --app-dir "$APP_DIR" \
    --elf-name main.elf \
    --src-files $SRCS \
    --inc-rdir "$APP_DIR/include"

[ $? -ne 0 ] && echo "ERROR: Makefile generation failed" && exit 1

echo ""
echo "[3/3] Building BSP..."

make -C "$BSP_DIR"

[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "DONE!"
echo "Run:"
echo "  ./build.sh"
