#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOPCINFO="$REPO_ROOT/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
CPU_NAME="CPU_NIOS_II"
BSP_DIR="$SCRIPT_DIR/bsp"

: "${QUARTUS_ROOTDIR:=/home/dadump/intelFPGA_lite/22.1std/quartus}"
: "${SOPC_KIT_NIOS2:=/home/dadump/intelFPGA_lite/22.1std/nios2eds}"

export QUARTUS_ROOTDIR
export SOPC_KIT_NIOS2
export PATH="$PATH:$SOPC_KIT_NIOS2/bin/gnu/H-x86_64-pc-linux-gnu/bin"

echo "============================================================"
echo " Rebuilding BSP"
echo "============================================================"

rm -rf "$BSP_DIR"

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

make -C "$BSP_DIR"

[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "BSP rebuilt successfully!"
