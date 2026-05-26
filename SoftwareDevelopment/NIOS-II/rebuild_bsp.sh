#!/bin/bash

SOPCINFO="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo"
CPU_NAME="CPU_NIOS_II"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Rebuilding BSP"
echo "============================================================"

rm -rf "$BSP_DIR"

nios2-bsp hal \
    "$BSP_DIR" \
    "$SOPCINFO" \
    --cpu-name "$CPU_NAME"

[ $? -ne 0 ] && echo "ERROR: BSP generation failed" && exit 1

make -C "$BSP_DIR"

[ $? -ne 0 ] && echo "ERROR: BSP build failed" && exit 1

echo ""
echo "BSP rebuilt successfully!"
