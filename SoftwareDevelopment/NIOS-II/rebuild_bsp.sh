#!/bin/bash
SOPCINFO="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus/MusicPlayerPlatformDesign.sopcinfo"
CPU_NAME="CPU_NIOS_II"
BSP_DIR="/mnt/d/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"
export PATH=$PATH:/mnt/c/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-mingw32/bin

to_win() { echo "$1" | sed 's|/mnt/\([a-z]\)/|\1:/|'; }

echo "=== Rebuilding BSP ==="
echo "[1/3] Deleting old BSP..."
rm -rf "$BSP_DIR"

echo "[2/3] Generating new BSP..."
nios2-bsp hal "$(to_win "$BSP_DIR")" "$(to_win "$SOPCINFO")" --cpu-name "$CPU_NAME"
[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

echo "[3/3] Building BSP..."
make -C "$BSP_DIR"
[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo "BSP rebuilt. Run ./build.sh to recompile the application."
