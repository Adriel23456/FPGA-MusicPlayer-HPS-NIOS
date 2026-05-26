#!/bin/bash

SOC_NAME="MusicPlayerPlatformDesign"

ELF="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/app/main.elf"
BSP_DIR="/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/SoftwareDevelopment/NIOS-II/bsp"

SOPCINFO_DIR="$(dirname "/media/adriel/Extra/Escritorio/FPGA-MusicPlayer-HPS-NIOS/MusicPlayerQuartus22/MusicPlayerPlatformDesign.sopcinfo")"

MENTOR="$SOPCINFO_DIR/$SOC_NAME/testbench/mentor"

SUBMODULES="$SOPCINFO_DIR/$SOC_NAME/testbench/${SOC_NAME}_tb/simulation/submodules"

export PATH="$PATH:/home/adriel/intelFPGA_lite/22.1std/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin"
export QUARTUS_ROOTDIR="/home/adriel/intelFPGA_lite/22.1std/quartus"
export SOPC_KIT_NIOS2="/home/adriel/intelFPGA_lite/22.1std/nios2eds"

echo "============================================================"
echo " Nios II Simulation Prep"
echo "============================================================"

if [ ! -f "$ELF" ]; then
    echo "ERROR:"
    echo "  ELF not found."
    echo "Run ./build.sh first."
    exit 1
fi

mkdir -p "$MENTOR"

echo "[1/3] Copying ELF..."
cp "$ELF" "$MENTOR/main.elf"

echo "[2/3] Reading RAM base..."

RAM_BASE=$(grep "_BASE" "$BSP_DIR/system.h" | grep "RAM_" | awk '{print $3}' | head -1)

if [ -z "$RAM_BASE" ]; then
    echo "ERROR: RAM base not found."
    exit 1
fi

echo "RAM_BASE = $RAM_BASE"

echo "[3/3] ELF -> HEX..."

elf2hex \
    --input="$MENTOR/main.elf" \
    --output="$SUBMODULES/${SOC_NAME}_RAM.hex" \
    --width=32 \
    --base="$RAM_BASE" \
    --end=0x7ffff

[ $? -ne 0 ] && echo "ERROR: elf2hex failed" && exit 1

echo ""
echo "============================================================"
echo " DONE! Now open ModelSim and run:"
echo "============================================================"
echo "   cd $MENTOR"
echo "   do msim_setup.tcl"
echo "   add wave /${SOC_NAME}_tb/*"
echo "   ld_debug"
echo "   run 2.5ms"
echo "============================================================"
